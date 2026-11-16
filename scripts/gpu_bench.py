#!/usr/bin/env python3
"""GPU 성능 측정: 같은 PyTorch/YOLO 를 호스트(직접 실행)와 공용 컨테이너에서 돌려 비교한다 (이슈 #57).

보통은 scripts/gpu_bench.sh 가 호스트·컨테이너 실행과 비교까지 한 번에 한다. 직접 쓸 때:

  python3 scripts/gpu_bench.py --label host --out .cache/gpu-bench/results/host-1.json
  python3 scripts/gpu_bench.py --compare .cache/gpu-bench/results/*.json

측정 항목 (모두 CUDA 동기화 후 시간 측정, 앞부분 warmup 은 버림)
  matmul_fp16/fp32  행렬 곱 TFLOPS          → 순수 GPU 연산. 도커 손해가 있다면 여기서 보여야 한다
  h2d_1080p         1080p 영상 1장 CPU→GPU   → 메모리 복사 경로
  yolo_forward      YOLO 모델 추론만 (텐서)  → 카메라 노드의 GPU 부분
  yolo_predict      1080p 영상 → 전처리·추론·NMS 전체 → 실제 노드와 가까운 값 (CPU 영향 포함)

이 스크립트는 torch/ultralytics 를 쓰지만 공용 이미지에는 아직 없다.
gpu_bench.sh 가 .cache/gpu-bench/py 에 고정 버전(scripts/gpu_bench_requirements.txt)을 설치해
호스트와 컨테이너가 **같은 파일**을 쓰게 한다 (버전이 다르면 비교가 무의미: arXiv 2312.07220).
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import statistics
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# 이 비율 이내의 차이는 측정 오차(발열·클럭 변동)로 본다
NOISE_PCT = 5.0


def sh(cmd: list[str]) -> str:
    if not shutil.which(cmd[0]):
        return ""
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=20).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def gpu_state() -> dict:
    """클럭·전력·온도·스로틀 이유. 노트북은 전원/발열에 따라 크게 달라지므로 결과와 함께 남긴다."""
    q = "clocks.sm,clocks.max.sm,power.draw,power.limit,temperature.gpu,pstate,clocks_throttle_reasons.active"
    out = sh(["nvidia-smi", f"--query-gpu={q}", "--format=csv,noheader,nounits"])
    keys = ["sm_clock_mhz", "sm_clock_max_mhz", "power_w", "power_limit_w", "temp_c", "pstate", "throttle_reasons"]
    values = [v.strip() for v in out.splitlines()[0].split(",")] if out else []
    state = dict(zip(keys, values, strict=True)) if len(values) == len(keys) else {}
    ac = [f.read_text().strip() for f in Path("/sys/class/power_supply").glob("A*/online")]
    state["ac_power"] = "연결" if "1" in ac else ("배터리" if ac else "알 수 없음")
    return state


def timed(fn, warmup: int, runs: int, sync) -> list[float]:
    """fn 을 warmup 번 버리고 runs 번 실행한 시간(ms) 목록."""
    for _ in range(warmup):
        fn()
    sync()
    times = []
    for _ in range(runs):
        t0 = time.perf_counter()
        fn()
        sync()
        times.append((time.perf_counter() - t0) * 1000)
    return times


def summary(times: list[float]) -> dict:
    s = sorted(times)
    return {
        "mean_ms": round(statistics.fmean(s), 3),
        "p50_ms": round(s[len(s) // 2], 3),
        "p95_ms": round(s[min(len(s) - 1, int(len(s) * 0.95))], 3),
        "fps": round(1000 / statistics.fmean(s), 1),
    }


def bench(args: argparse.Namespace) -> dict:
    try:
        import numpy as np
        import torch
    except ImportError as e:
        sys.exit(f"❌ {e}. scripts/gpu_bench.sh 로 실행하세요 (측정용 패키지를 .cache/gpu-bench 에 설치함).")
    if not torch.cuda.is_available():
        sys.exit(
            "❌ PyTorch 가 GPU 를 찾지 못했습니다.\n"
            "   호스트: nvidia-smi 가 동작하는지, 드라이버 버전이 torch 의 CUDA 버전을 지원하는지 확인\n"
            "   컨테이너: ./scripts/dev.sh -- nvidia-smi 로 GPU 가 연결됐는지 확인 (setup-host.sh 의 NVIDIA 단계)"
        )
    dev = torch.device("cuda")
    sync = torch.cuda.synchronize
    torch.backends.cudnn.benchmark = True
    results: dict = {}
    print(f"[{args.label}] GPU: {torch.cuda.get_device_name(0)}, torch {torch.__version__} (CUDA {torch.version.cuda})")

    # 1) 행렬 곱 - 순수 GPU 연산
    n = 4096
    for name, dtype in (("matmul_fp16", torch.float16), ("matmul_fp32", torch.float32)):
        a = torch.randn(n, n, device=dev, dtype=dtype)
        b = torch.randn(n, n, device=dev, dtype=dtype)
        t = timed(lambda a=a, b=b: a @ b, 10, max(20, args.runs // 4), sync)
        r = summary(t)
        r["tflops"] = round(2 * n**3 / (statistics.fmean(t) / 1000) / 1e12, 2)
        results[name] = r
        print(f"  {name:<14} {r['tflops']:>8} TFLOPS")

    # 2) 1080p 영상 1장 CPU → GPU 복사 (일반 메모리, ROS 메시지에서 받은 numpy 와 같은 경우)
    img = np.random.randint(0, 255, (1080, 1920, 3), dtype=np.uint8)
    results["h2d_1080p"] = summary(timed(lambda: torch.from_numpy(img).to(dev), 10, args.runs, sync))
    print(f"  {'h2d_1080p':<14} {results['h2d_1080p']['mean_ms']:>8} ms")

    # 3) YOLO. 가중치 파일을 받지 않도록 모델 구조(yaml)에서 만들고 seed 를 고정한다 (속도는 학습된 가중치와 같음).
    #    기본 yolo26n 은 NMS 가 없는 구조(end2end)라 무작위 가중치여도 후처리 시간이 결과 수에 흔들리지 않는다
    os.environ.setdefault("YOLO_OFFLINE", "true")
    from ultralytics import YOLO

    torch.manual_seed(0)
    model = YOLO(args.model)
    net = model.model.to(dev).eval()
    for name, half in (("yolo_forward_fp16", True), ("yolo_forward_fp32", False)):
        m = net.half() if half else net.float()
        x = torch.rand(1, 3, args.imgsz, args.imgsz, device=dev, dtype=torch.float16 if half else torch.float32)
        with torch.inference_mode():
            results[name] = summary(timed(lambda m=m, x=x: m(x), 30, args.runs, sync))
        print(f"  {name:<18} {results[name]['mean_ms']:>8} ms  ({results[name]['fps']} FPS)")
    net.float()

    # 4) 실제 노드에 가까운 전체 경로: 1080p numpy 영상 → 전처리 → 추론(FP16) → 후처리
    def predict():
        model.predict(img, imgsz=args.imgsz, half=True, device=0, verbose=False)

    results["yolo_predict"] = summary(timed(predict, 30, args.runs, sync))
    print(f"  {'yolo_predict':<18} {results['yolo_predict']['mean_ms']:>8} ms  ({results['yolo_predict']['fps']} FPS)")

    import ultralytics

    return {
        "label": args.label,
        "where": "컨테이너" if Path("/.dockerenv").exists() else "호스트",
        "captured_at": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
        "hostname": platform.node(),
        "gpu": torch.cuda.get_device_name(0),
        "driver": sh(["nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader"]),
        "versions": {
            "python": platform.python_version(),
            "torch": torch.__version__,
            "cuda": torch.version.cuda,
            "cudnn": torch.backends.cudnn.version(),
            "ultralytics": ultralytics.__version__,
            "numpy": np.__version__,
        },
        "settings": {"model": args.model, "imgsz": args.imgsz, "runs": args.runs},
        "gpu_state_before": args.state_before,
        "gpu_state_after": gpu_state(),
        "results": results,
    }


def state_text(s: dict) -> str:
    if not s.get("sm_clock_mhz"):
        return f"전원 {s.get('ac_power', '?')}"
    return (
        f"전원 {s['ac_power']}, {s['temp_c']}°C, SM {s['sm_clock_mhz']}/{s['sm_clock_max_mhz']}MHz, "
        f"{s['power_w']}/{s['power_limit_w']}W"
    )


def compare(paths: list[str]) -> int:
    runs = [json.loads(Path(p).read_text(encoding="utf-8")) for p in paths]
    groups: dict[str, list[dict]] = {}
    for r in runs:
        groups.setdefault(r["where"], []).append(r)
    if set(groups) != {"호스트", "컨테이너"}:
        print("호스트와 컨테이너 결과가 모두 있어야 비교할 수 있습니다:", ", ".join(paths))
        return 1
    host, cont = groups["호스트"], groups["컨테이너"]
    seen = {json.dumps(r["versions"], sort_keys=True) for r in runs}
    if len(seen) > 1:
        print("⚠️  호스트와 컨테이너의 패키지 버전이 다릅니다. 이 비교는 믿을 수 없습니다:")
        for r in runs:
            print(f"   {r['label']}: {r['versions']}")

    def best(group: list[dict], key: str) -> float:
        # 같은 쪽 여러 번 측정 중 가장 빠른 값 (발열·백그라운드 작업의 영향을 줄임)
        if key.startswith("matmul"):
            return max(r["results"][key]["tflops"] for r in group)
        return round(min(r["results"][key]["mean_ms"] for r in group), 3)

    first = runs[0]
    ver, cfg = first["versions"], first["settings"]
    lines = [
        f"### GPU 측정: 호스트 vs 컨테이너 ({first['gpu']}, 드라이버 {first['driver']})",
        "",
        f"- torch {ver['torch']} (CUDA {ver['cuda']}), ultralytics {ver['ultralytics']}, "
        f"모델 {cfg['model']} {cfg['imgsz']}px",
        f"- 항목별 {cfg['runs']}회 측정 x 호스트 {len(host)}번 / 컨테이너 {len(cont)}번 (각 쪽 가장 좋은 값으로 비교)",
        "- 측정 직후 상태: " + "; ".join(f"{r['label']} {state_text(r['gpu_state_after'])}" for r in runs),
        "",
        "| 항목 | 호스트 | 컨테이너 | 차이 (컨테이너 기준, +면 컨테이너가 느림) |",
        "|---|---|---|---|",
    ]
    worst = 0.0
    for key in host[0]["results"]:
        h, c = best(host, key), best(cont, key)
        if key.startswith("matmul"):
            pct = (h - c) / h * 100  # TFLOPS: 낮을수록 느림
            hv, cv = f"{h} TFLOPS", f"{c} TFLOPS"
        else:
            pct = (c - h) / h * 100
            hv, cv = f"{h} ms", f"{c} ms"
        worst = max(worst, pct)
        mark = "✅" if pct <= NOISE_PCT else "⚠️"
        lines.append(f"| {key} | {hv} | {cv} | {mark} {pct:+.1f}% |")
    lines.append("")
    if worst <= NOISE_PCT:
        lines.append(f"**결론: 컨테이너가 {NOISE_PCT:.0f}% 넘게 느린 항목 없음 → 손해 없음 (측정 오차 범위).**")
    else:
        lines.append(
            f"**결론: 컨테이너가 최대 {worst:.1f}% 느림.** 전원(AC)·발열 상태를 확인하고 다시 측정해도 같으면 "
            "이슈 #57 에 결과를 올려 원인(드라이버 기능, NVIDIA_DRIVER_CAPABILITIES 등)을 검토합니다."
        )
    print("\n".join(lines))
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--label", default="run", help="결과 이름 (예: host-1, container-1)")
    p.add_argument("--out", help="결과 JSON 경로")
    p.add_argument("--model", default="yolo26n.yaml", help="YOLO 모델 구조 또는 가중치 (.yaml / .pt)")
    p.add_argument("--imgsz", type=int, default=640)
    p.add_argument("--runs", type=int, default=200, help="항목별 측정 횟수")
    p.add_argument("--compare", nargs="+", metavar="JSON", help="결과 파일들을 비교해 표로 출력")
    args = p.parse_args()
    if args.compare:
        return compare(args.compare)
    args.state_before = gpu_state()
    data = bench(args)
    if args.out:
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"  → {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
