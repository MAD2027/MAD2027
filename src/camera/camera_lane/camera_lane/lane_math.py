"""차선 중심 오프셋 계산 (ROS 의존성 없음 → 단위 테스트 용이)."""

from __future__ import annotations


def lane_center_offset(left_x_m: float, right_x_m: float) -> float:
    """차량 중심 대비 차선 중심의 좌우 오프셋 [m] (왼쪽 +)."""
    if right_x_m >= left_x_m:
        raise ValueError("오른쪽 차선은 왼쪽 차선보다 오른쪽(작은 y)에 있어야 합니다.")
    return (left_x_m + right_x_m) / 2.0
