# 처음 시작하는 사람을 위한 안내 (git · GitHub · ROS2 기초)

코딩, git, ROS2 가 처음인 팀원을 위한 문서입니다. 다른 문서들은 이 문서의 용어를 안다고 가정하고 쓰여 있습니다.
설치는 [DEV_ENV.md](DEV_ENV.md), 작업 규칙은 [CONTRIBUTING.md](CONTRIBUTING.md) 를 봅니다.

## 1. 터미널이 세 종류 있다

명령어가 안 될 때 가장 흔한 원인은 **엉뚱한 터미널에서 실행한 것**입니다. 문서의 코드블록 첫 줄에 어디서 실행하는지 적어 둡니다.

| 표시 | 어디 | 프롬프트 모양 | 여기서 하는 일 |
|---|---|---|---|
| `# [호스트]` | 내 PC 의 우분투 터미널 (윈도우는 시작 메뉴의 **Ubuntu 22.04**) | `홍길동@내PC:~/mad2027$` | Docker 설치, SSH 키, 저장소 clone, `./scripts/dev.sh` 로 컨테이너 들어가기 |
| `# [컨테이너]` | 공용 개발 컨테이너 안 (VS Code 터미널 또는 `./scripts/dev.sh`) | `ubuntu@...:/ws$` | **빌드·실행·테스트·커밋 등 거의 모든 작업** |
| `# [PowerShell]` | 윈도우 PowerShell | `PS C:\Users\...>` | WSL 설치, USB 연결(usbipd)만 |

- 컨테이너 = 모든 PC 에 똑같이 깔린 "가상 우분투 22.04 + ROS2 Humble". 내 PC 에 ROS2 를 깔지 않아도 됩니다.
- 컨테이너 안의 `/ws` 폴더와 호스트의 `~/mad2027` 폴더는 **같은 폴더**입니다. 어느 쪽에서 파일을 고쳐도 양쪽에 보입니다.
- 터미널을 여러 개 쓰려면 호스트 터미널을 새로 열고 다시 `./scripts/dev.sh` 를 실행합니다 (같은 컨테이너로 들어감). VS Code 는 터미널 패널의 `+` 를 누릅니다.

## 2. git 과 GitHub 용어

| 용어 | 뜻 | 비유 |
|---|---|---|
| 저장소 (repository) | 프로젝트 폴더 + 모든 변경 기록 | 공동 작업 노트 |
| clone | GitHub 의 저장소를 내 PC 로 처음 복사 | 노트 복사본 받기 |
| 커밋 (commit) | 바꾼 내용을 설명과 함께 기록으로 남김 | 저장 + 메모 |
| 브랜치 (branch) | main 을 건드리지 않고 따로 작업하는 갈래 | 연습장 |
| `main` | 모두가 합의한 정식 버전. 직접 고치지 않습니다 | 정본 |
| push | 내 커밋을 GitHub 에 올림 | 제출 |
| fetch / pull | GitHub 의 새 변경을 내 PC 로 가져옴 | 새 버전 받기 |
| PR (Pull Request) | "내 브랜치를 main 에 합쳐 주세요" 요청. 리뷰와 자동 검사(CI)가 여기서 일어남 | 검토 요청서 |
| 병합 (merge) | PR 을 main 에 합침. 사람(리뷰어)이 버튼을 누릅니다 | 정본에 반영 |
| 충돌 (conflict) | 두 사람이 같은 줄을 다르게 고쳐서 git 이 자동으로 못 합침 | 수정 겹침 |
| 이슈 (issue) | 할 일 / 버그 기록. 모든 작업은 이슈에서 시작 | 할 일 카드 |

### 지금 상태를 확인하는 명령 (모르겠으면 일단 이것부터)
```bash
# [컨테이너]
git status                 # 지금 브랜치, 바뀐 파일, 커밋 안 한 파일
git diff                   # 아직 커밋 안 한 변경 내용 (q 로 나가기)
git log --oneline -10      # 최근 커밋 10개
git branch --show-current  # 지금 브랜치 이름
```

### 하루 작업 한 바퀴 (#12 이슈, 카메라 팀 예시)
```bash
# [컨테이너]
./scripts/start_task.sh camera 12 lane-offset   # 최신 main 에서 camera/12-lane-offset 브랜치 생성
# ... 코드 수정 ...
git status                                      # 무엇이 바뀌었는지 확인
git add -p                                      # 바뀐 부분을 하나씩 보여 주며 담을지 물어봄 (아래 표)
git commit -m "camera: 차선 중심 오프셋 계산 (#12)"
./scripts/check.sh camera                       # PR 전 검사 (스타일 + 빌드 + 테스트)
git push -u origin HEAD                         # GitHub 에 올리기 (처음 push 하는 브랜치만 -u origin HEAD)
```
`git add -p` 의 질문에는 `y`(담기), `n`(안 담기), `s`(더 잘게 나누기), `q`(그만) 로 답합니다. 새로 만든 파일은 `-p` 로 안 보이므로 `git add <파일>` 로 담습니다.

push 후에는 GitHub 저장소 페이지 위쪽의 노란 **Compare & pull request** 버튼(또는 터미널에 출력된 링크)을 눌러 PR 을 만듭니다. 양식(템플릿)이 자동으로 채워지므로 `Closes #12`, 테스트 방법, AI 도구 사용을 적습니다. 자세한 규칙은 [CONTRIBUTING.md](CONTRIBUTING.md).

> `git push` 에서 막히면 [DEV_ENV.md - GitHub 로그인](DEV_ENV.md#github-로그인-ssh-키-pc-마다-처음-한-번) 을 확인합니다. 충돌이 나면 [TEAM_GUIDE.md - 충돌 해결](TEAM_GUIDE.md#충돌-해결).

## 3. ROS2 용어

| 용어 | 뜻 | 이 저장소에서 |
|---|---|---|
| 노드 (node) | 한 가지 일을 하는 실행 프로그램 | `fusion_node`, `system_monitor`, 각 팀의 차선 인식 노드 등 |
| 토픽 (topic) | 노드끼리 데이터를 주고받는 이름 붙은 통로. 보내는 쪽 = 발행(publish), 받는 쪽 = 구독(subscribe) | `/system/status`, `/camera/lane_info` |
| 메시지 (message) | 토픽으로 오가는 데이터의 형식 | `mad_interfaces/msg/NodeStatus`. 팀 간 메시지는 `src/interfaces/` 에만 정의 |
| 패키지 (package) | 노드·설정·launch 파일을 묶은 단위. `package.xml` 이 있는 폴더 | `src/fusion/mad_fusion/` |
| launch 파일 | 여러 노드를 설정과 함께 한 번에 켜는 파일 | `mad_bringup/launch/system.launch.py` |
| 파라미터 | 노드 실행 시 바꿀 수 있는 설정값 (코드에 숫자를 박지 않음) | `config/*.yaml`, `rate_hz` |
| 워크스페이스 | `src/` 를 빌드해 `build/` `install/` `log/` 가 생기는 폴더 | `/ws` (git 에는 `src/` 만 올라감) |

### 코드를 실행하기까지 3단계 (왜 매번 이렇게 하나)
```bash
# [컨테이너]
cd /ws
colcon build --symlink-install    # 1) 빌드: src/ 의 패키지를 install/ 에 설치
source install/setup.bash         # 2) 등록: 지금 터미널에 "install/ 의 패키지를 써라" 라고 알려 줌
ros2 run <패키지> <실행파일>         # 3-a) 노드 하나 실행
ros2 launch <패키지> <파일>.launch.py  # 3-b) launch 파일로 여러 노드 실행
```
- `source` 는 **터미널마다** 필요합니다. 새로 연 컨테이너 터미널은 자동으로 해 주지만, 빌드 직후 이미 열려 있던 터미널은 직접 다시 합니다.
- `--symlink-install` 로 빌드하면 Python 코드만 고쳤을 때는 다시 빌드하지 않아도 됩니다. 새 노드(실행 파일)·launch·config 파일을 추가했거나 `setup.py`/`package.xml` 을 고쳤다면 다시 빌드합니다.
- 실행 중인 노드는 `Ctrl+C` 로 끕니다.
- 특정 패키지만 빌드: `colcon build --symlink-install --packages-select <패키지>`

### 실행 중인 시스템을 들여다보는 명령 (다른 터미널에서)
| 명령 | 알려 주는 것 |
|---|---|
| `ros2 node list` | 지금 켜져 있는 노드 |
| `ros2 topic list` | 지금 존재하는 토픽 |
| `ros2 topic echo /system/status` | 그 토픽에 오가는 메시지 내용 (Ctrl+C 로 종료) |
| `ros2 topic hz <토픽>` | 메시지가 초당 몇 번 오는지 |
| `ros2 topic info <토픽> -v` | 누가 발행하고 누가 구독하는지 |
| `ros2 pkg executables <패키지>` | `ros2 run` 으로 실행할 수 있는 이름 |
| `ros2 param list` / `ros2 param get <노드> <이름>` | 노드의 파라미터 값 |
| `ros2 interface show mad_interfaces/msg/NodeStatus` | 메시지 형식 |
| `rqt_graph` | 노드와 토픽 연결을 그림으로 (GUI) |

> 다른 팀원의 토픽까지 보이면 `ROS_DOMAIN_ID` 가 겹친 것입니다 → [TEAM_GUIDE.md](TEAM_GUIDE.md#ros_domain_id-배정)

## 4. 실습: 내 첫 노드 만들어 실행하기 (20분)

1초마다 하트비트를 `/system/status` 로 보내는 노드를 만듭니다. 이 저장소의 모든 노드가 지켜야 하는 규칙(루트 `AGENTS.md` 8번)이기도 합니다.
연습용이므로 커밋하지 않고 마지막에 지웁니다. 팀 이름 `camera` 는 자기 팀 id 로 바꿔도 됩니다.

**1) 패키지 만들기**
```bash
# [컨테이너]
cd /ws
./scripts/new_package.sh camera camera_hello python
# → src/camera/camera_hello/ 생성. 코드는 src/camera/camera_hello/camera_hello/ 안에 둡니다
```

**2) 노드 코드 작성**: `src/camera/camera_hello/camera_hello/hello_node.py` 파일을 만들고 붙여 넣습니다.
```python
import rclpy
from rclpy.node import Node

from mad_interfaces.msg import NodeStatus


class HelloNode(Node):
    def __init__(self) -> None:
        super().__init__("hello_node")  # 노드 이름
        self.message = self.declare_parameter("message", "안녕하세요").value  # 파라미터
        self.pub = self.create_publisher(NodeStatus, "/system/status", 10)  # 발행할 토픽
        self.create_timer(1.0, self.on_timer)  # 1초마다 on_timer 실행

    def on_timer(self) -> None:
        msg = NodeStatus()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.team = "camera"
        msg.node_name = self.get_name()
        msg.level = NodeStatus.OK
        msg.message = self.message
        self.pub.publish(msg)
        self.get_logger().info(f"보냄: {self.message}")


def main() -> None:
    rclpy.init()
    node = HelloNode()
    try:
        rclpy.spin(node)  # Ctrl+C 를 누를 때까지 계속 실행
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()
```

**3) 실행 파일로 등록**: `src/camera/camera_hello/setup.py` 에서 `console_scripts` 를 찾아 대괄호 안에 한 줄을 넣습니다.
```python
    entry_points={
        "console_scripts": [
            "hello_node = camera_hello.hello_node:main",  # 실행이름 = 패키지.파일:함수
        ],
    },
```

**4) 빌드하고 실행**
```bash
# [컨테이너] 터미널 1
colcon build --symlink-install --packages-select camera_hello
source install/setup.bash
ros2 run camera_hello hello_node
# → 1초마다 "보냄: 안녕하세요"
```
```bash
# [컨테이너] 터미널 2
ros2 topic echo /system/status                     # 메시지 확인
ros2 run mad_bringup system_monitor                # 터미널 1 을 Ctrl+C 로 끄면 2초 뒤 "하트비트 끊김" 경고
```
파라미터 바꿔 실행: `ros2 run camera_hello hello_node --ros-args -p message:=반가워요`

**5) 정리** (연습용 패키지 삭제)
```bash
# [컨테이너]
rm -rf src/camera/camera_hello build/camera_hello install/camera_hello
git status    # 바뀐 파일이 없으면 깨끗하게 정리된 것
```

실제 기능을 만들 때도 순서는 같습니다: 이슈 → `start_task.sh` → `new_package.sh` → 노드 작성 → `entry_points` 등록 → 빌드·실행 → launch 파일 → 커밋 → PR.
팀 노드를 전체 시스템에 넣는 방법은 [GUIDE.md 5장](GUIDE.md#5-통합과-차량-실행) 을 봅니다.

## 5. 자주 막히는 곳

| 증상 | 원인 → 해결 |
|---|---|
| `ros2: command not found` | 호스트 터미널입니다 → `./scripts/dev.sh` 로 컨테이너에 들어갑니다 |
| `Package 'xxx' not found` | 빌드를 안 했거나 `source install/setup.bash` 를 안 함 |
| `No executable found` | `setup.py` 의 `console_scripts` 등록 후 다시 빌드하지 않음 |
| 코드를 고쳤는데 그대로 | `--symlink-install` 없이 빌드함 → 붙여서 다시 빌드 |
| 토픽이 안 보임 | 두 터미널의 `ROS_DOMAIN_ID` 가 다름 (`echo $ROS_DOMAIN_ID`) |
| 커밋이 막힘 (pre-commit) | 스타일 검사가 파일을 자동으로 고친 것 → `git add` 후 같은 명령으로 다시 커밋 |
| `git push` 에서 거부 | [DEV_ENV.md 문제 해결](DEV_ENV.md#문제-해결) |

그래도 모르겠으면 에러 메시지 **전체**를 복사해 팀 채팅이나 이슈에 올립니다. "안 돼요" 보다 에러 메시지 한 줄이 훨씬 빨리 해결됩니다.
