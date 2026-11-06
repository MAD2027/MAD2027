import pytest
from camera_lane.lane_math import lane_center_offset


def test_centered():
    assert lane_center_offset(1.75, -1.75) == pytest.approx(0.0)


def test_shifted_left():
    assert lane_center_offset(2.0, -1.5) == pytest.approx(0.25)


def test_invalid_order():
    with pytest.raises(ValueError):
        lane_center_offset(-1.0, 1.0)
