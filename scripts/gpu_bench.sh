#!/usr/bin/env bash
# 본체 노트북(NVIDIA GPU)에서 "도커 안 GPU 성능 = 직접 실행 성능" 인지 측정한다 (이슈 #57).
# 반드시 **호스트**(컨테이너 밖) 저장소 폴더에서 실행한다. 컨테이너는 이 스크립트가 직접 띄운다.
#
#   ./scripts/gpu_bench.sh                   준비 → 호스트·컨테이너 번갈아 측정 → 비교 표
#   ./scripts/gpu_bench.sh --runs 500        항목별 측정 횟수 (기본 200)
#   ./scripts/gpu_bench.sh --model yolo26s.yaml   다른 모델 (또는 카메라 팀의 .pt 가중치 경로)
#
# 순서: 호스트 → 컨테이너 → 컨테이너 → 호스트 (ABBA). 노트북이 점점 뜨거워져 느려지는 영향을 양쪽에 똑같이 나눈다.
# 측정용 패키지(약 5GB)는 .cache/gpu-bench/py 에 한 번만 설치하고 호스트·컨테이너가 같이 쓴다.
# 다 쓰면 지워도 된다: rm -rf .cache/gpu-bench
set -euo pipefail
cd "$(dirname "$0")/.."

bench_args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --runs|--model|--imgsz) bench_args+=("$1" "$2"); shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "알 수 없는 옵션: $1 (--help)"; exit 1 ;;
  esac
  shift
done

die() { printf '\n❌ %s\n' "$*" >&2; exit 1; }
[ -f /.dockerenv ] && die "컨테이너 안입니다. 호스트 터미널(본체 우분투)의 저장소 폴더에서 실행하세요."
nvidia-smi -L >/dev/null 2>&1 \
  || die "호스트에서 nvidia-smi 가 동작하지 않습니다. NVIDIA 드라이버를 먼저 설치하세요 (docs/DEV_ENV.md 본체 노트북)."
pyver=$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')
[ "$pyver" = 3.10 ] || die "호스트 Python 이 $pyver 입니다. 컨테이너와 같은 3.10(우분투 22.04 기본)이어야 같은 패키지를 쓸 수 있습니다."

export DEV_NAME=mad-gpu-bench   # 이미 떠 있는 개발 컨테이너(GPU 없이 시작됐을 수 있음)와 섞이지 않게
dir=.cache/gpu-bench
results="$dir/results/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$dir" "$results"
touch "$dir/COLCON_IGNORE"   # colcon build 가 설치된 패키지를 뒤지지 않게

echo "▶ 1. 측정 환경"
nvidia-smi --query-gpu=name,driver_version,power.limit --format=csv,noheader | sed 's/^/  GPU: /'
ac=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -1 || true)
[ "$ac" = 1 ] || echo "  ⚠️  전원 어댑터가 연결되어 있지 않습니다. 배터리에서는 GPU 클럭이 낮아집니다. 충전기를 꽂고 측정하세요."
echo "  측정 중에는 다른 프로그램(브라우저, 영상, colcon build 등)을 끄세요."

echo "▶ 2. GPU 가 컨테이너에 연결되는지 확인"
./scripts/dev.sh --gpu -- nvidia-smi -L \
  || die "컨테이너에서 GPU 가 보이지 않습니다. ./scripts/installer/setup-host.sh 를 실행해 NVIDIA Container Toolkit 을 설치하세요."

echo "▶ 3. 측정용 패키지 (처음 한 번, 수 GB 다운로드)"
stamp="$dir/py/.requirements"
if ! cmp -s scripts/gpu_bench_requirements.txt "$stamp"; then
  rm -rf "$dir/py"
  # 컨테이너의 pip 로 설치 → 호스트에 pip/venv 가 없어도 되고, 양쪽이 같은 파일을 쓴다
  ./scripts/dev.sh -- pip3 install --no-cache-dir --ignore-installed --target "$dir/py" -r scripts/gpu_bench_requirements.txt
  cp scripts/gpu_bench_requirements.txt "$stamp"
fi
echo "  준비됨: $dir/py"

# 호스트와 컨테이너에 똑같은 조건 (ROS 의 PYTHONPATH 를 섞지 않고, ultralytics 설정도 저장소 안에)
envs=(PYTHONPATH="$dir/py" YOLO_CONFIG_DIR="$dir/config" YOLO_OFFLINE=true PYTHONNOUSERSITE=1)
host()      { env "${envs[@]}" python3 scripts/gpu_bench.py --label "$1" --out "$results/$1.json" "${bench_args[@]}"; }
container() { ./scripts/dev.sh --gpu -- env "${envs[@]}" python3 scripts/gpu_bench.py --label "$1" --out "$results/$1.json" "${bench_args[@]}"; }

echo "▶ 4. 측정 (호스트 → 컨테이너 → 컨테이너 → 호스트, 몇 분 걸립니다)"
host host-1
container container-1
container container-2
host host-2

echo "▶ 5. 비교"
python3 scripts/gpu_bench.py --compare "$results"/*.json | tee "$results/report.md"
echo
echo "결과: $results/report.md → 이 내용을 이슈 #57 에 댓글로 붙여 주세요."
