"""fusion.launch.py 를 실제로 불러와 생성해 본다 (CI 는 런치를 실행하지 않으므로 여기서 확인)."""

import importlib.util
from pathlib import Path

import pytest

PKG = Path(__file__).resolve().parent.parent


def test_fusion_launch(monkeypatch):
    pytest.importorskip("launch_ros", reason="ROS2 환경(컨테이너/CI)에서만 실행")
    from launch.actions import DeclareLaunchArgument
    from launch_ros.actions import Node

    spec = importlib.util.spec_from_file_location("fusion_launch", PKG / "launch" / "fusion.launch.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    monkeypatch.setattr(module, "get_package_share_directory", lambda package: str(PKG))

    entities = module.generate_launch_description().entities
    assert [e.name for e in entities if isinstance(e, DeclareLaunchArgument)] == ["use_sim_time"]
    assert [e.node_executable for e in entities if isinstance(e, Node)] == ["fusion_node"]
