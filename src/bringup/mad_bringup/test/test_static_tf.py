from pathlib import Path

import pytest

from mad_bringup.static_tf import StaticTransform, load_static_transforms

SHIPPED = Path(__file__).resolve().parent.parent / "config" / "static_tf.yaml"


def write(tmp_path, text):
    path = tmp_path / "static_tf.yaml"
    path.write_text(text, encoding="utf-8")
    return str(path)


def test_shipped_config_valid():
    load_static_transforms(str(SHIPPED))


def test_load_and_args(tmp_path):
    text = "static_transforms:\n  - {parent: base_link, child: camera_link, xyz: [0.3, 0, 0.5]}\n"
    (tf,) = load_static_transforms(write(tmp_path, text))
    assert tf == StaticTransform("base_link", "camera_link", (0.3, 0.0, 0.5), (0.0, 0.0, 0.0))
    args = tf.args()
    assert args[:2] == ["--x", "0.3"] and args[-4:] == ["--frame-id", "base_link", "--child-frame-id", "camera_link"]


@pytest.mark.parametrize(
    "item",
    [
        "{child: camera_link}",  # parent 없음
        "{parent: base_link, child: base_link}",  # 자기 자신
        "{parent: base_link, child: camera_link, xyz: [0, 0]}",  # 숫자 3개 아님
    ],
)
def test_invalid_rejected(tmp_path, item):
    with pytest.raises(ValueError):
        load_static_transforms(write(tmp_path, f"static_transforms:\n  - {item}\n"))


def test_duplicate_child_rejected(tmp_path):
    item = "{parent: base_link, child: camera_link}"
    with pytest.raises(ValueError):
        load_static_transforms(write(tmp_path, f"static_transforms:\n  - {item}\n  - {item}\n"))
