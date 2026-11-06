"""system.launch.py 를 실제로 불러와 생성해 본다 (CI 는 런치를 실행하지 않으므로 여기서 확인)."""

import importlib.util
from pathlib import Path

import pytest

PKG = Path(__file__).resolve().parent.parent


def load_launch(monkeypatch, share: Path):
    pytest.importorskip("launch_ros", reason="ROS2 환경(컨테이너/CI)에서만 실행")
    from ament_index_python.packages import PackageNotFoundError

    spec = importlib.util.spec_from_file_location("system_launch", PKG / "launch" / "system.launch.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    def fake_share(package: str) -> str:
        if package == "mad_bringup":
            return str(share)
        raise PackageNotFoundError(package)  # 팀 패키지는 미설치로 처리

    monkeypatch.setattr(module, "get_package_share_directory", fake_share)
    return module


def make_share(tmp_path: Path, static_tf: str) -> Path:
    (tmp_path / "config").mkdir()
    (tmp_path / "config" / "system.yaml").write_text((PKG / "config" / "system.yaml").read_text(encoding="utf-8"))
    (tmp_path / "config" / "static_tf.yaml").write_text(static_tf, encoding="utf-8")
    return tmp_path


def test_system_launch_with_static_tf(monkeypatch, tmp_path):
    share = make_share(tmp_path, "static_transforms:\n  - {parent: base_link, child: camera_link}\n")
    module = load_launch(monkeypatch, share)
    from launch.actions import DeclareLaunchArgument, LogInfo
    from launch_ros.actions import Node

    entities = module.generate_launch_description().entities
    args = [e for e in entities if isinstance(e, DeclareLaunchArgument)]
    nodes = [e for e in entities if isinstance(e, Node)]
    assert [a.name for a in args] == ["use_sim_time"]
    assert [n.node_executable for n in nodes] == ["system_monitor", "static_transform_publisher"]
    # TEAM_LAUNCHES 의 미설치 패키지는 오류 없이 건너뜀 로그
    assert sum(isinstance(e, LogInfo) for e in entities) == len(module.TEAM_LAUNCHES)


def test_shipped_static_tf_loads(monkeypatch, tmp_path):
    share = make_share(tmp_path, (PKG / "config" / "static_tf.yaml").read_text(encoding="utf-8"))
    module = load_launch(monkeypatch, share)
    module.generate_launch_description()
