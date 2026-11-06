"""센서 장착 위치(static TF) 설정 읽기 (ROS 의존성 없음 → 단위 테스트 용이)."""

from __future__ import annotations

from dataclasses import dataclass

import yaml


@dataclass(frozen=True)
class StaticTransform:
    parent: str
    child: str
    xyz: tuple[float, float, float] = (0.0, 0.0, 0.0)
    rpy: tuple[float, float, float] = (0.0, 0.0, 0.0)

    def args(self) -> list[str]:
        """tf2_ros static_transform_publisher (Humble) 의 명령행 인자."""
        x, y, z = self.xyz
        roll, pitch, yaw = self.rpy
        values = {"x": x, "y": y, "z": z, "roll": roll, "pitch": pitch, "yaw": yaw}
        out = [item for key, value in values.items() for item in (f"--{key}", str(value))]
        return out + ["--frame-id", self.parent, "--child-frame-id", self.child]


def _vector(item: dict, key: str, index: int) -> tuple[float, float, float]:
    value = item.get(key, [0.0, 0.0, 0.0])
    if not isinstance(value, list) or len(value) != 3:
        raise ValueError(f"static_transforms[{index}].{key} 는 숫자 3개의 목록이어야 합니다 (m 또는 rad)")
    return tuple(float(v) for v in value)


def load_static_transforms(path: str) -> list[StaticTransform]:
    with open(path, encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    transforms = []
    children = set()
    for i, item in enumerate(data.get("static_transforms") or []):
        parent, child = str(item.get("parent", "")), str(item.get("child", ""))
        if not parent or not child:
            raise ValueError(f"static_transforms[{i}] 에 parent/child 가 없습니다")
        if parent == child:
            raise ValueError(f"static_transforms[{i}]: parent 와 child 가 같습니다 ({child})")
        if child in children:
            raise ValueError(f"static_transforms[{i}]: child '{child}' 가 중복됩니다 (프레임의 부모는 하나)")
        children.add(child)
        transforms.append(StaticTransform(parent, child, _vector(item, "xyz", i), _vector(item, "rpy", i)))
    return transforms
