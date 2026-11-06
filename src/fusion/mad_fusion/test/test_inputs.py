from pathlib import Path

import pytest

from mad_fusion.inputs import InputTracker, load_inputs

CONFIG = """
inputs:
  - {name: lane, team: camera, topic: /lane, type: std_msgs/msg/String, timeout_sec: 0.2}
  - {name: gps, team: gps, topic: /gps/fix, type: sensor_msgs/msg/NavSatFix, timeout_sec: 0.5}
  - {name: debug, team: lidar, topic: /dbg, type: std_msgs/msg/String, required: false}
"""


def write(tmp_path, text):
    path = tmp_path / "inputs.yaml"
    path.write_text(text, encoding="utf-8")
    return str(path)


def test_load_inputs(tmp_path):
    inputs = load_inputs(write(tmp_path, CONFIG))
    assert [i.name for i in inputs] == ["lane", "gps", "debug"]
    assert inputs[2].required is False and inputs[2].timeout_sec == 0.5


def test_default_config_is_empty_list(tmp_path):
    assert load_inputs(write(tmp_path, "inputs: []\n")) == []


def test_missing_key_rejected(tmp_path):
    with pytest.raises(ValueError):
        load_inputs(write(tmp_path, "inputs:\n  - {name: lane, team: camera, topic: /lane}\n"))


@pytest.mark.parametrize(
    "item",
    [
        "{name: lane, team: camera, topic: /lane, type: LaneInfo}",  # 패키지/msg 누락
        "{name: lane, team: camera, topic: /lane, type: mad_interfaces/LaneInfo}",
        "{name: lane, team: camera, topic: lane, type: std_msgs/msg/String}",  # 상대 토픽
    ],
)
def test_malformed_type_or_topic_rejected(tmp_path, item):
    with pytest.raises(ValueError):
        load_inputs(write(tmp_path, f"inputs:\n  - {item}\n"))


# ── 저장소에 실제로 들어 있는 fusion_inputs.yaml 검사 (센서 팀 출력 계약) ──
SHIPPED = Path(__file__).resolve().parent.parent / "config" / "fusion_inputs.yaml"


def test_shipped_inputs_valid():
    load_inputs(str(SHIPPED))


def test_shipped_input_types_resolvable():
    """메시지 타입이 실제로 존재하는지 (타입 오타를 CI 에서 잡는다).

    공용 이미지에 이미 설치된 메시지 패키지(sensor_msgs 등)는 package.xml 에 의존성이 빠져도 통과하므로,
    새 메시지 패키지를 쓰면 package.xml 의 exec_depend 는 리뷰에서 확인한다.
    """
    utilities = pytest.importorskip("rosidl_runtime_py.utilities", reason="ROS2 환경(컨테이너/CI)에서만 실행")
    for item in load_inputs(str(SHIPPED)):
        try:
            utilities.get_message(item.type)
        except (AttributeError, ModuleNotFoundError, ValueError) as e:
            pytest.fail(
                f"{item.name}: 메시지 타입 {item.type} 를 찾을 수 없습니다 ({e}). 타입 이름 오타 또는 package.xml 의존성 확인"
            )


def test_ready_only_when_required_inputs_fresh(tmp_path):
    tracker = InputTracker(load_inputs(write(tmp_path, CONFIG)))
    assert not tracker.ready(now=0.0)
    tracker.update("lane", "L", now=1.0)
    assert not tracker.ready(now=1.0)  # gps 아직 없음
    tracker.update("gps", "G", now=1.0)
    assert tracker.ready(now=1.1)  # debug 는 required 아님
    assert not tracker.ready(now=1.3)  # lane 0.2초 초과
    assert set(tracker.stale(now=1.3)) == {"lane", "debug"}
    assert tracker.latest()["gps"] == "G"
