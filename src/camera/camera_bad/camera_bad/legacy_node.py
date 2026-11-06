"""[SIM] 규칙 위반 예시: ROS1 API 사용 (금지)."""

import os, sys
import rospy


def main():
    rospy.init_node("legacy_node")
    print("ROS1 API 와 print 를 쓰는 금지된 예시입니다. 이 줄은 일부러 아주 길게 써서 ruff 의 줄 길이 120자 제한을 넘깁니다 ............")
