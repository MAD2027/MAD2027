# 개발 환경 설치 (새 노트북에 적용하기)

모든 PC 는 **같은 공용 개발 컨테이너**(Ubuntu 22.04 + ROS2 Humble, 본체 노트북 기준 환경) 안에서 개발합니다.
PC 의 OS 는 컨테이너를 띄우는 데만 쓰이고, 코드가 실행되는 환경은 모두 같습니다. 배경은 [TARGET_ENV.md](TARGET_ENV.md) 를 참고하세요.

| 내 PC | 방법 | 소요 시간 |
|---|---|---|
| [윈도우 10/11 노트북](#윈도우-노트북) | WSL2(우분투) + Docker + VS Code | 처음 40~60분 |
| [우분투 노트북](#우분투-노트북) | Docker + VS Code | 처음 20~30분 |
| [본체 노트북](#본체-노트북) | Docker + `scripts/dev.sh` (+ 실기 테스트 러너) | 처음 30분 |

> **우분투 · WSL · 본체는 [자동 설치](#자동-설치-우분투--wsl--본체-공통-권장) 스크립트 하나로 대부분 끝납니다.** 아래 수동 절차는 스크립트가 막혔을 때나 무엇을 하는지 알고 싶을 때 봅니다.

> 처음에는 공용 이미지(약 3~4GB)를 내려받는 데 시간이 걸립니다. 학교 와이파이보다 빠른 네트워크에서 받는 것을 권장합니다.

> 코딩·git·ROS2 가 처음이라면 [BEGINNER.md](BEGINNER.md) 에서 용어와 "첫 노드 실행" 을 먼저 보세요.
> 아래 코드블록 첫 줄의 `# [호스트]` 는 내 PC 의 우분투 터미널, `# [컨테이너]` 는 공용 개발 컨테이너 안 터미널, `# [PowerShell]` 은 윈도우 PowerShell 을 뜻합니다.

---

## 자동 설치 (우분투 · WSL · 본체 공통, 권장)

아래 "GitHub 로그인" 부터 "저장소 받기" 까지의 단계를 스크립트 하나가 대신합니다. 여러 번 실행해도 안전합니다 (이미 된 단계는 건너뜀).
윈도우는 먼저 [윈도우 노트북](#윈도우-노트북) 1~2단계(WSL 설치, `.wslconfig`)와 4단계(VS Code)를 한 뒤 **WSL 우분투 터미널**에서 실행합니다.

```bash
# [호스트] 저장소를 아직 안 받았을 때 (한 줄)
bash <(curl -fsSL https://raw.githubusercontent.com/MAD2027/MAD2027/main/scripts/installer/setup-host.sh)
# [호스트] 저장소가 이미 있을 때
~/mad2027/scripts/installer/setup-host.sh
```

| 스크립트가 하는 일 | 내가 할 일 |
|---|---|
| git·curl·Docker·GitHub CLI(`gh`) 설치, 우분투 노트북이면 VS Code + Dev Containers 확장 | sudo 비밀번호 입력 |
| git 이름/이메일, ROS_DOMAIN_ID(팀 범위 검사) 를 `~/.bashrc` 에 설정 | 이름, 이메일, 팀, 배정받은 번호 입력 |
| SSH 키 생성 → GitHub 에 등록, 22번 포트가 막혔으면 443 우회 | 브라우저가 열리면 표시된 코드 입력 후 **Authorize** 클릭 |
| Organization push 권한 확인 | 권한이 없다고 나오면 초대 수락 / 관리자에게 팀 추가 요청 |
| `~/mad2027` 에 clone (https 로 받아 둔 저장소는 SSH 로 전환) | - |
| 공용 이미지 받기, 컨테이너에서 `env_check.py` | - |

- 옵션: `--team gps --domain-id 23` (묻지 않고 지정), `--dir <경로>`, `--no-vscode`, `--dry-run` (할 일만 출력). `--help` 로 전체 보기.
- 끝나면 새 터미널을 열고(ROS_DOMAIN_ID 적용) `code ~/mad2027` → **Reopen in Container**. 처음 Docker 를 설치했다면 로그아웃 후 다시 로그인합니다 (WSL 은 PowerShell 에서 `wsl --shutdown`).
- 스크립트가 중간에 멈추면 출력된 메시지를 보고 고친 뒤 **같은 명령을 다시 실행**합니다. 아래 수동 절차와 결과가 같으므로, 막히는 단계만 수동으로 해도 됩니다.

## GitHub 로그인 (SSH 키, PC 마다 처음 한 번)

GitHub 은 `git push` 할 때 **비밀번호를 받지 않습니다**. 이 저장소는 모든 PC 에서 **SSH 키** 로 로그인하는 방법으로 통일합니다.
(SSH 키 = 내 PC 에만 있는 "열쇠 파일". 짝이 되는 "자물쇠"(공개 키)를 GitHub 계정에 등록해 두면 비밀번호 없이 push 할 수 있습니다.)

**1) 이름/이메일 설정과 키 만들기** (윈도우는 WSL 의 우분투 터미널에서)
```bash
# [호스트]
git config --global user.name "홍길동"                     # 커밋에 남을 이름
git config --global user.email "github-가입-이메일"
ssh-keygen -t ed25519 -C "github-가입-이메일"              # 질문에는 모두 Enter (기본 위치, 암호 없음)
cat ~/.ssh/id_ed25519.pub                                   # 출력된 한 줄(ssh-ed25519 ...)을 복사
```
> `id_ed25519` (`.pub` 없는 파일)는 비밀 열쇠입니다. 절대 다른 사람에게 보내거나 GitHub 에 붙여 넣지 않습니다.

**2) GitHub 에 공개 키 등록**: GitHub 오른쪽 위 프로필 사진 → **Settings → SSH and GPG keys → New SSH key** → Title 에 PC 이름(예: `내 노트북`), Key 에 복사한 한 줄을 붙여 넣고 **Add SSH key**.

**3) 확인**
```bash
# [호스트]
ssh -T git@github.com        # 처음엔 "Are you sure ...?" 에 yes 입력
# → "Hi <아이디>! You've successfully authenticated ..." 가 나오면 성공
```
- 학교/회사 네트워크가 22번 포트를 막아 `Connection timed out` 이 나면 `~/.ssh/config` 에 아래를 넣고 다시 확인합니다.
  ```
  Host github.com
    HostName ssh.github.com
    Port 443
  ```
- **이미 저장소를 받아 둔 경우**: 예전에 https 주소로 clone 했다면 push 할 때 Username/Password 를 묻습니다. 저장소 폴더에서 주소를 SSH 로 바꿉니다 (한 번만, 코드는 그대로).
  ```bash
  # [호스트] (저장소 폴더, 예: cd ~/mad2027)
  git remote -v                                                   # https://github.com/... 이면 아래 실행
  git remote set-url origin git@github.com:MAD2027/MAD2027.git
  git remote -v                                                   # git@github.com:MAD2027/MAD2027.git 확인
  git fetch origin                                                # 에러 없이 끝나면 연결 성공
  ```
- 이 설정은 컨테이너에도 그대로 전달됩니다. VS Code 컨테이너는 이름/이메일을 자동으로 복사하고, `./scripts/dev.sh` 는 호스트의 `~/.gitconfig`, `~/.ssh` 를 읽기 전용으로 연결합니다. 그래서 **git 설정은 항상 호스트에서** 바꿉니다 (컨테이너 안의 `git config --global` 은 실패합니다).

---

## 윈도우 노트북

### 1. WSL2 와 우분투 설치
PowerShell 을 **관리자 권한**으로 열고 실행합니다.
```powershell
wsl --install -d Ubuntu-22.04
```
재부팅 후 나타나는 우분투 창에서 사용자 이름과 비밀번호를 만듭니다. 이후 "우분투 터미널"은 시작 메뉴의 **Ubuntu 22.04** 를 말합니다.

### 2. WSL 자원과 네트워크 설정 (본체 노트북 사양에 맞추기)
메모장으로 `%UserProfile%\.wslconfig` 파일을 만들고 다음 내용을 넣습니다.
```ini
[wsl2]
# 본체 노트북 사양 (python3 scripts/env_check.py 출력의 CPU 코어 수, RAM)
processors=4
memory=8GB
# 다른 PC/본체와 ROS2 토픽을 주고받으려면 필요 (Windows 11 22H2 이상)
networkingMode=mirrored
```
PowerShell 에서 `wsl --shutdown` 을 실행하면 다음 실행부터 적용됩니다.
> Windows 10 은 `networkingMode=mirrored` 를 지원하지 않습니다. 이 경우 컨테이너 안에서만 개발하고, 본체와의 통신 테스트는 실기 테스트나 원격 접속으로 합니다.

### 3. Docker 설치 (우분투 터미널에서)
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```
우분투 창을 닫았다가 다시 열고 `docker run hello-world` 가 성공하는지 확인합니다.
> Docker Desktop for Windows 를 써도 됩니다. 이 경우 Settings → Resources → WSL Integration 에서 Ubuntu-22.04 를 켭니다.

### 4. VS Code 설치
- 윈도우에 [VS Code](https://code.visualstudio.com/) 를 설치합니다.
- 확장 프로그램 **WSL**(ms-vscode-remote.remote-wsl), **Dev Containers**(ms-vscode-remote.remote-containers) 를 설치합니다.

### 5. 저장소 받기 (⚠️ 반드시 우분투 터미널에서, 리눅스 홈 폴더에)
먼저 [GitHub 로그인 (SSH 키)](#github-로그인-ssh-키-pc-마다-처음-한-번) 을 끝냅니다.
```bash
# [호스트] (WSL 우분투 터미널)
sudo apt update && sudo apt install -y git
git config --global core.autocrlf input          # 윈도우 줄바꿈(CRLF) 섞임 방지

cd ~
git clone git@github.com:MAD2027/MAD2027.git ~/mad2027
cd ~/mad2027
echo 'export ROS_DOMAIN_ID=12' >> ~/.bashrc && source ~/.bashrc   # 본인 번호 (TEAM_GUIDE.md)
code .
```
> `C:\Users\...` (`/mnt/c/...`) 에 받으면 빌드가 매우 느리고 권한/줄바꿈 문제가 생깁니다. 반드시 `~` 아래에 받습니다.

### 6. 컨테이너 열기
VS Code 우측 하단 알림에서 **Reopen in Container** 를 누르거나, `F1` → `Dev Containers: Reopen in Container` 를 실행합니다.
- 설정을 고르라고 하면 **MAD ROS2 (공용 이미지)** 를 선택합니다.
- 처음에는 이미지를 내려받은 뒤 `scripts/setup.sh` 가 자동으로 실행되고, 마지막에 본체 환경과 비교한 결과가 출력됩니다.

### 7. 동작 확인 (컨테이너 터미널)
```bash
# [컨테이너]
colcon build --symlink-install
source install/setup.bash
ros2 launch mad_bringup system.launch.py      # Ctrl+C 로 종료
rviz2                                             # GUI 창이 뜨면 성공 (WSLg)
```

### 윈도우에서 아두이노/USB 센서 쓰기 (필요할 때만)
WSL 에서는 USB 장치가 기본적으로 보이지 않습니다. [usbipd-win](https://github.com/dorssel/usbipd-win/releases) 을 설치한 뒤 **관리자 PowerShell** 에서 연결합니다.
```powershell
usbipd list                          # 아두이노의 BUSID 확인 (예: 2-3)
usbipd bind --busid 2-3              # 처음 한 번
usbipd attach --wsl --busid 2-3      # 꽂을 때마다
```
그다음 `.devcontainer/devcontainer.json` 의 `--privileged`, `--volume=/dev:/dev` 주석을 해제하고 **Rebuild Container** 를 실행합니다. 컨테이너 안에서 `ls /dev/ttyACM*` 로 장치가 보이는지 확인합니다.

---

## 우분투 노트북

Ubuntu 20.04/22.04/24.04 어느 버전이든 됩니다. 컨테이너 안은 항상 22.04 + Humble 입니다.
```bash
# [호스트]
# 1. Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER          # 로그아웃 후 다시 로그인

# 2. git / VS Code
sudo apt install -y git
sudo snap install code --classic
code --install-extension ms-vscode-remote.remote-containers

# 3. GitHub 로그인: 위의 "GitHub 로그인 (SSH 키)" 1~3) 을 먼저 진행

# 4. 저장소
git clone git@github.com:MAD2027/MAD2027.git ~/mad2027 && cd ~/mad2027
echo 'export ROS_DOMAIN_ID=12' >> ~/.bashrc && source ~/.bashrc
code .                                  # → Reopen in Container
```
- 본체보다 사양이 높은 노트북은 `python3 scripts/env_check.py` 가 알려 주는 `--cpus`/`--memory` 값을 devcontainer.json 에 넣거나, `./scripts/dev.sh --match-target` 을 사용합니다.
- 우분투에 ROS2 를 직접 설치했더라도 **개발과 테스트는 컨테이너에서** 합니다. 직접 설치한 환경은 본체와 버전이 다를 수 있습니다.

### VS Code 없이 터미널만 쓰기
```bash
# [호스트] (저장소 폴더, 예: cd ~/mad2027)
./scripts/dev.sh                  # 공용 컨테이너 셸 (다른 터미널에서 다시 실행하면 같은 컨테이너로 들어감)
./scripts/dev.sh --hw             # USB 센서/아두이노 연결
./scripts/dev.sh --pull           # 공용 이미지 업데이트
```
- 프롬프트가 `ubuntu@...:/ws$` 로 바뀌면 컨테이너 안입니다. `exit` 로 나옵니다.
- `dev.sh` 는 호스트의 git 설정과 SSH 키를 연결하고, 처음 들어올 때 커밋 전 스타일 검사(pre-commit 훅)를 자동으로 설치합니다. 그래서 컨테이너 안에서 바로 `git commit` / `git push` 할 수 있습니다.

---

## 본체 노트북

본체는 **차량에서 실제로 돌아가는 PC** 이자 기준 환경입니다. 본체도 같은 공용 컨테이너 안에서 실행합니다.
```bash
# [호스트]
# 1. Docker, git 설치 (우분투 노트북과 동일)
# 2. GitHub 로그인(위 "GitHub 로그인 (SSH 키)") 후 저장소 받기
git clone git@github.com:MAD2027/MAD2027.git ~/mad2027 && cd ~/mad2027

# 3. 기준 환경 기록 (최초 1회, 그리고 본체 구성이 바뀔 때마다) → PR
./scripts/dev.sh -- python3 scripts/env_check.py --capture

# 4. 차량 실행 (특정 버전으로)
git fetch --tags && git switch --detach v0.3.0
./scripts/dev.sh --hw -- bash -c 'source /opt/ros/humble/setup.bash && colcon build && source install/setup.bash && ros2 launch mad_bringup system.launch.py'
```
이어서 [TARGET_ENV.md - 본체 노트북을 러너로 등록](TARGET_ENV.md#본체-노트북을-러너로-등록-관리자-1회) 을 진행하면 팀원들이 원격으로 실기 테스트를 돌릴 수 있습니다.

---

## AI 코딩 도구 (Claude Code · Codex · Grok)
컨테이너를 만들 때 자동으로 설치됩니다. **컨테이너 터미널에서** 실행하고 로그인합니다 (윈도우 PowerShell 에서 실행하지 않음).
```bash
./scripts/ai_tools.sh status
claude        # 또는 codex, grok
```
자세한 규칙: [AI_TOOLS.md](AI_TOOLS.md)

## 공용 이미지 업데이트
의존성(package.xml, requirements.txt)이나 Dockerfile 이 main 에 병합되면 이미지가 자동으로 다시 빌드됩니다.
- VS Code: `F1` → **Dev Containers: Rebuild Container**
- 터미널: `./scripts/dev.sh --pull`

## 자주 쓰는 스크립트

| 명령 | 설명 |
|---|---|
| `./scripts/start_task.sh <팀> <이슈> <설명>` | 최신 main 에서 작업 브랜치 생성 |
| `./scripts/finish_task.sh` | 작업 마무리: 검사 → push(처음이면 `-u`) → PR 생성 링크 |
| `./scripts/sync_main.sh` | 작업 브랜치에 최신 main 병합 |
| `./scripts/check.sh [팀]` | 스타일 + 빌드 + 테스트 + 아두이노 컴파일 (CI 와 동일) |
| `./scripts/new_package.sh <팀> <이름> [python\|cpp]` | ROS2 패키지 생성 (저장소 스타일 ruff/clang-format 과 충돌하는 ament 린터는 자동 제외) |
| `python3 scripts/env_check.py` | 본체 노트북 기준 환경과 비교 |
| `./scripts/dev.sh [--hw] [--match-target]` | VS Code 없이 공용 컨테이너 사용 |
| `python3 scripts/teams.py sync` | 팀 설정 변경 후 생성 파일 갱신 |

## ROS 배포판을 바꿀 때 (관리자)
다음 값을 함께 바꾸고 PR 을 올립니다. 모든 팀이 영향을 받으므로 리더 회의에서 먼저 합의합니다.
- `.devcontainer/Dockerfile`, `.devcontainer/build-local/devcontainer.json` 의 `ROS_DISTRO`
- `.github/workflows/ci.yml` 의 `ROS_DISTRO` 와 기본 이미지 태그
- `scripts/teams.py` 의 `dev_image` 태그(`humble`), `.github/workflows/dev-image.yml` 의 태그
- 본체 노트북에서 `--capture` 를 다시 실행

## 문제 해결

| 증상 | 해결 |
|---|---|
| Reopen in Container 에서 이미지를 받지 못함 (`denied`, `not found`) | 관리자가 아직 공용 이미지를 만들지 않았거나 비공개 상태입니다 ([ORG_SETUP.md 7단계](ORG_SETUP.md)). 임시로 `F1` → Reopen in Container → **로컬 빌드** 설정을 선택합니다. |
| 다른 사람 토픽이 보임 | `echo $ROS_DOMAIN_ID` 확인 후 본인 번호로 설정하고 컨테이너를 다시 엽니다 |
| `env_check` 에서 ❌ | 컨테이너 밖(호스트)에서 실행했거나 이미지가 오래된 것입니다. 컨테이너 안에서 실행하고 Rebuild 합니다 |
| rviz2 창이 안 뜸 | 우분투: 호스트에서 `xhost +local:` 실행. 윈도우: `wsl --update` 로 WSLg 최신화 |
| `Package 'xxx' not found` | `source install/setup.bash`. 새 의존성이면 `rosdep install --from-paths src --ignore-src -y` |
| `git push` 에서 `Permission denied (publickey)` | SSH 키가 GitHub 에 등록되지 않았거나 다른 키입니다. 호스트에서 `ssh -T git@github.com` 으로 확인합니다. VS Code 컨테이너에서만 실패하면 호스트에서 `ssh-add ~/.ssh/id_ed25519` 후 컨테이너를 다시 엽니다 |
| `git push` 에서 `ERROR: Permission to MAD2027/MAD2027.git denied to <내 아이디>` | 로그인은 됐지만 **저장소 쓰기 권한이 없는** 경우입니다. ① GitHub 알림/메일의 **Organization 초대를 수락**했는지 확인 (https://github.com/MAD2027 에서 확인) ② 관리자에게 내 팀(`team-camera` 등)에 추가해 달라고 요청합니다 (팀에 들어가야 Write 권한이 생김, [ORG_SETUP.md 3단계](ORG_SETUP.md#3-팀원-초대와-팀-만들기)). 권한이 생기기 전에 커밋한 내용은 그대로 두었다가 다시 `git push` 하면 됩니다 |
| `ERROR: Repository not found` (clone/push) | 주소 오타이거나, 비공개 저장소인데 아직 초대를 수락하지 않은 경우입니다. 주소(`git remote -v`)와 초대 수락을 확인합니다 |
| `git push` 가 Username/Password 를 물음 | 저장소를 https 주소로 받은 경우입니다. [이미 저장소를 받아 둔 경우](#github-로그인-ssh-키-pc-마다-처음-한-번) 대로 `git remote set-url origin git@github.com:MAD2027/MAD2027.git` |
| 컨테이너 안 `git commit` 에서 "Please tell me who you are" | 호스트에서 `git config --global user.name/user.email` 을 설정하고 컨테이너를 다시 엽니다 (`exit` 후 `./scripts/dev.sh`) |
| 커밋이 pre-commit 에 막힘 | 자동 수정된 파일을 `git add` 후 다시 커밋합니다 |
| main 에 커밋했다며 막힘 | `git switch -c <팀>/<이슈>-<설명>` 으로 브랜치를 만들고 커밋합니다 |
| `/dev/ttyACM0` 권한 오류 | devcontainer.json 의 `--privileged` 주석을 해제하고 Rebuild 합니다. 윈도우는 `usbipd attach` 를 확인합니다 |
| 윈도우에서 빌드가 너무 느림 | 저장소가 `/mnt/c` 아래에 있지 않은지 확인합니다 (`pwd`). `~` 아래로 다시 clone 합니다 |
