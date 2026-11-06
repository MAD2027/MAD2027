# [SIM] 카메라 팀 차선 정보. 단위 SI, 좌표계 header.frame_id (보통 base_link).
# header.stamp = 영상 촬영 시각 (발행 시각 아님)

std_msgs/Header header
float32 offset_m      # 차선 중심의 좌우 오프셋 [m], 왼쪽 +
float32 curvature     # 곡률 [1/m], 왼쪽으로 굽으면 +
