#!/usr/bin/env bash
# MAD 개발 환경 자동 설치 - 우분투 노트북 / WSL 우분투 / 본체 노트북 공통 (호스트에서 실행).
# docs/DEV_ENV.md 의 설치 단계를 한 번에 한다. 여러 번 실행해도 안전하다 (이미 된 단계는 건너뜀).
#
#   저장소를 아직 안 받았을 때 (한 줄):
#     bash <(curl -fsSL https://raw.githubusercontent.com/MAD2027/MAD2027/main/scripts/installer/setup-host.sh)
#   저장소가 있을 때:
#     ./scripts/installer/setup-host.sh
#
# 옵션: --dir <경로>      저장소 위치 (기본: 이 스크립트가 든 저장소, 없으면 ~/mad2027)
#       --team <팀id>     camera | gps | lidar | control | fusion | vehicle(본체, ROS_DOMAIN_ID=0)
#       --domain-id <N>   ROS_DOMAIN_ID (팀 범위 안)
#       --no-vscode       VS Code 설치 건너뛰기 (본체 노트북 등)
#       --dry-run         실제로 바꾸지 않고 할 일만 출력
# 비대화식 실행: MAD_GIT_NAME, MAD_GIT_EMAIL, MAD_TEAM, MAD_DOMAIN_ID 환경 변수
set -euo pipefail

ORG_REPO="MAD2027/MAD2027"
SSH_URL="git@github.com:${ORG_REPO}.git"
# ROS_DOMAIN_ID 범위 (docs/TEAM_GUIDE.md "ROS_DOMAIN_ID 배정" 과 같아야 함)
declare -A RANGE=([camera]="10 19" [gps]="20 29" [lidar]="30 39" [control]="40 49" [fusion]="50 59" [vehicle]="0 0")

DRY=false; VSCODE=true; DIR="${MAD_DIR:-}"; TEAM="${MAD_TEAM:-}"; DOMAIN="${MAD_DOMAIN_ID:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR=$2; shift ;;
    --team) TEAM=$2; shift ;;
    --domain-id) DOMAIN=$2; shift ;;
    --no-vscode) VSCODE=false ;;
    --dry-run) DRY=true ;;
    -h|--help) sed -n '2,17p' "${BASH_SOURCE[0]}" 2>/dev/null || true; exit 0 ;;
    *) echo "알 수 없는 옵션: $1 (--help)"; exit 1 ;;
  esac
  shift
done

step=0
say()  { printf '\n\033[1m▶ %s. %s\033[0m\n' "$((++step))" "$*"; }
ok()   { printf '  ✅ %s\n' "$*"; }
info() { printf '  · %s\n' "$*"; }
warn() { printf '  ⚠️  %s\n' "$*"; }
die()  { printf '\n❌ %s\n' "$*" >&2; exit 1; }
run()  { if $DRY; then printf '  + %s\n' "$*"; else "$@"; fi; }
has()  { command -v "$1" >/dev/null 2>&1; }
TTY=false; { : </dev/tty; } 2>/dev/null && TTY=true
ask() {  # ask <질문> <기본값> → 답 출력
  local answer=""
  if $TTY && ! $DRY; then read -r -p "  ? $1${2:+ [$2]}: " answer </dev/tty || true; fi
  printf '%s' "${answer:-$2}"
}

# ── 0. 환경 확인 ──────────────────────────────────────────────
say "환경 확인"
[ "$(id -u)" -ne 0 ] || die "root 가 아닌 본인 계정으로 실행하세요 (필요할 때 sudo 를 묻습니다)."
# shellcheck disable=SC1091
. /etc/os-release 2>/dev/null || die "우분투에서만 실행할 수 있습니다."
[ "${ID:-}" = ubuntu ] || die "우분투에서만 실행할 수 있습니다 (현재: ${PRETTY_NAME:-알 수 없음}). 윈도우는 WSL 우분투 안에서 실행합니다."
WSL=false; grep -qi microsoft /proc/version 2>/dev/null && WSL=true
ok "${PRETTY_NAME}$($WSL && echo ' (WSL)')"
$WSL && VSCODE=false   # WSL 은 윈도우 쪽 VS Code 를 쓴다
has sudo || die "sudo 가 필요합니다."
$DRY && warn "--dry-run: 실제로 바꾸지 않습니다."

if [ -z "$DIR" ]; then
  here=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$here" ] && git -C "$here" remote get-url origin 2>/dev/null | grep -qi "${ORG_REPO}"; then DIR=$here; else DIR="$HOME/mad2027"; fi
fi
case "$DIR" in /mnt/*) $WSL && die "저장소를 /mnt/... (윈도우 디스크) 에 두면 매우 느립니다. --dir ~/mad2027 처럼 리눅스 홈 아래를 쓰세요." ;; esac
info "저장소 위치: $DIR"

# ── 1. 기본 도구 ──────────────────────────────────────────────
say "기본 도구 (git, curl, ssh, gh)"
need=(); for p in git curl openssh-client ca-certificates; do dpkg -s "$p" >/dev/null 2>&1 || need+=("$p"); done
if [ ${#need[@]} -gt 0 ]; then run sudo apt-get update -qq; run sudo apt-get install -y "${need[@]}"; fi
if ! has gh; then
  info "GitHub CLI(gh) 설치 - GitHub 로그인을 브라우저 클릭으로 하기 위해"
  run sudo mkdir -p -m 755 /etc/apt/keyrings
  if $DRY; then run "curl ... githubcli-archive-keyring.gpg → /etc/apt/keyrings, cli.github.com 저장소 등록"; else
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  fi
  run sudo apt-get update -qq; run sudo apt-get install -y gh
fi
ok "기본 도구 준비"

# ── 2. Docker ─────────────────────────────────────────────────
say "Docker"
if ! has docker; then
  $WSL && info "WSL 에서는 설치 중 'Docker Desktop 권장' 안내와 20초 대기가 나옵니다. 그대로 기다리면 됩니다."
  if $DRY; then run "curl -fsSL https://get.docker.com | sudo sh"; else curl -fsSL https://get.docker.com | sudo sh; fi
fi
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then run sudo usermod -aG docker "$USER"; fi
if [ "$(ps -o comm= -p 1 2>/dev/null)" = systemd ]; then
  run sudo systemctl enable --now docker
elif $WSL; then
  if ! grep -qs '^systemd=true' /etc/wsl.conf; then
    run sudo sh -c 'printf "\n[boot]\nsystemd=true\n" >> /etc/wsl.conf'
    warn "WSL 에 systemd 를 켰습니다. 이번에는 임시로 Docker 를 켜고, 다음부터는 자동으로 켜집니다."
    warn "설치가 끝나면 PowerShell 에서 'wsl --shutdown' 후 우분투를 다시 여세요."
  fi
  run sudo service docker start
fi
dk() { if id -nG | tr ' ' '\n' | grep -qx docker; then bash -c "$1"; else sg docker -c "$1"; fi; }   # 그룹 재로그인 전에도 docker 사용
$DRY || dk "docker info >/dev/null" || die "Docker 가 실행되지 않습니다. 'sudo service docker start' 후 다시 실행하세요."
ok "Docker 준비"

# ── 3. VS Code (우분투 노트북만) ──────────────────────────────
if $VSCODE; then
  say "VS Code + Dev Containers 확장"
  has code || run sudo snap install code --classic
  run code --install-extension ms-vscode-remote.remote-containers --force
  ok "VS Code 준비"
fi

# ── 4. git 이름/이메일, 팀, ROS_DOMAIN_ID ─────────────────────
say "git 사용자 정보와 ROS_DOMAIN_ID"
name=$(git config --global user.name || true); email=$(git config --global user.email || true)
[ -n "$name" ] || name=$(ask "커밋에 남길 이름 (예: 홍길동)" "${MAD_GIT_NAME:-}")
[ -n "$email" ] || email=$(ask "GitHub 가입 이메일" "${MAD_GIT_EMAIL:-}")
{ [ -n "$name" ] && [ -n "$email" ]; } || $DRY || die "이름과 이메일이 필요합니다. (MAD_GIT_NAME / MAD_GIT_EMAIL 로도 줄 수 있음)"
run git config --global user.name "$name"; run git config --global user.email "$email"
$WSL && run git config --global core.autocrlf input
ok "git: ${name:-?} <${email:-?}>"

while :; do
  [ -n "$TEAM" ] || TEAM=$(ask "팀 (camera / gps / lidar / control / fusion / vehicle=본체)" "$($DRY && echo camera)")
  if [ -n "${RANGE[$TEAM]:-}" ]; then break; fi
  if ! $TTY || $DRY; then die "팀을 알 수 없습니다: '${TEAM}' (--team camera 등)"; fi
  warn "camera / gps / lidar / control / fusion / vehicle 중 하나를 입력하세요."; TEAM=""
done
read -r lo hi <<< "${RANGE[$TEAM]}"
while :; do
  [ -n "$DOMAIN" ] || DOMAIN=$(ask "ROS_DOMAIN_ID (${TEAM}: ${lo}~${hi}, 팀장에게 배정받은 번호)" "$lo")
  if [[ "$DOMAIN" =~ ^[0-9]+$ ]] && [ "$DOMAIN" -ge "$lo" ] && [ "$DOMAIN" -le "$hi" ]; then break; fi
  if ! $TTY || $DRY; then die "ROS_DOMAIN_ID ${DOMAIN} 은 ${TEAM} 범위(${lo}~${hi}) 밖입니다."; fi
  warn "${lo}~${hi} 사이 숫자를 입력하세요."; DOMAIN=""
done
begin="# >>> MAD ROS_DOMAIN_ID >>>"; end="# <<< MAD ROS_DOMAIN_ID <<<"
if ! $DRY; then
  touch ~/.bashrc
  sed -i "/^${begin}\$/,/^${end}\$/d" ~/.bashrc
  printf '%s\nexport ROS_DOMAIN_ID=%s   # %s 팀 (setup-host.sh)\n%s\n' "$begin" "$DOMAIN" "$TEAM" "$end" >> ~/.bashrc
  grep -n '^export ROS_DOMAIN_ID=' ~/.bashrc | grep -v 'setup-host.sh' | sed 's/^/  ⚠️  다른 설정이 남아 있음 (지워 주세요): ~\/.bashrc:/' || true
fi
export ROS_DOMAIN_ID=$DOMAIN
ok "ROS_DOMAIN_ID=${DOMAIN} (~/.bashrc)"

# ── 5. GitHub 연결 (SSH 키) ───────────────────────────────────
say "GitHub 연결 (SSH 키)"
key="$HOME/.ssh/id_ed25519"
if [ ! -f "$key" ]; then run mkdir -p -m 700 "$HOME/.ssh"; run ssh-keygen -q -t ed25519 -N "" -C "${email:-mad}" -f "$key"; fi
ssh_status() {  # ssh_status <호스트> <포트> → ok | denied | blocked
  local out; out=$(ssh -T -p "$2" -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new "git@$1" 2>&1 || true)
  case "$out" in *"successfully authenticated"*) echo ok ;; *"Permission denied"*) echo denied ;; *) echo blocked ;; esac
}
if $DRY; then
  run "ssh -T git@github.com 로 확인 → 실패하면 gh auth login --web (브라우저 승인) + gh ssh-key add"
else
  st=$(ssh_status github.com 22)
  if [ "$st" = blocked ]; then
    st=$(ssh_status ssh.github.com 443)
    if [ "$st" != blocked ] && ! grep -qs 'ssh.github.com' ~/.ssh/config; then
      printf '\nHost github.com\n  HostName ssh.github.com\n  Port 443\n' >> ~/.ssh/config
      chmod 600 ~/.ssh/config; info "22번 포트가 막혀 443 포트로 우회하도록 ~/.ssh/config 를 설정했습니다."
    fi
  fi
  [ "$st" = blocked ] && die "GitHub 에 SSH 로 연결할 수 없습니다 (22, 443 포트 모두). 네트워크를 바꿔 다시 실행하세요."
  if [ "$st" != ok ]; then
    info "SSH 키를 GitHub 계정에 등록합니다. 브라우저가 열리면 표시된 코드를 입력하고 승인하세요."
    if gh auth status -h github.com >/dev/null 2>&1; then gh auth refresh -h github.com -s admin:public_key
    else gh auth login -h github.com -p ssh --web --skip-ssh-key -s admin:public_key; fi
    gh ssh-key add "$key.pub" --title "MAD $(hostname)" 2>&1 | grep -v 'already' || true
    st=$(ssh_status github.com 22)
    [ "$st" = ok ] || die "SSH 키 등록 후에도 인증되지 않습니다. docs/DEV_ENV.md 'GitHub 로그인' 을 따라 수동으로 확인하세요."
  fi
  ok "ssh -T git@github.com 인증 성공"
  if gh auth status -h github.com >/dev/null 2>&1; then
    if [ "$(gh api "repos/${ORG_REPO}" --jq .permissions.push 2>/dev/null || true)" = true ]; then ok "${ORG_REPO} 에 push 권한 있음"
    else warn "${ORG_REPO} 에 push 권한이 없습니다. 초대 수락: https://github.com/orgs/${ORG_REPO%%/*}/invitation , 아니면 관리자에게 팀 추가 요청"; fi
  fi
fi

# ── 6. 저장소 받기 ────────────────────────────────────────────
say "저장소 받기"
if [ -d "$DIR/.git" ]; then
  url=$(git -C "$DIR" remote get-url origin)
  case "$url" in https://*) run git -C "$DIR" remote set-url origin "$SSH_URL"; info "https 주소를 SSH 로 바꿨습니다." ;; esac
  ok "이미 있음: $DIR"
elif [ -e "$DIR" ]; then
  die "$DIR 이 이미 있지만 git 저장소가 아닙니다. 옮기거나 --dir 로 다른 위치를 지정하세요."
else
  run git clone "$SSH_URL" "$DIR"; ok "받음: $DIR"
fi

# ── 7. 공용 개발 이미지와 환경 비교 ───────────────────────────
say "공용 개발 이미지 (처음 3~4GB, 시간이 걸립니다)"
if $DRY; then run "$DIR/scripts/dev.sh --pull"; run "$DIR/scripts/dev.sh -- python3 scripts/env_check.py"
else
  dk "cd '$DIR' && ./scripts/dev.sh --pull" || die "이미지를 받지 못했습니다. 네트워크 확인 후 다시 실행하세요."
  dk "cd '$DIR' && ./scripts/dev.sh -- python3 scripts/env_check.py" || warn "본체 기준 환경과 다른 항목이 있습니다 (위 출력 참고)."
fi
ok "이미지 준비"

# ── 끝 ────────────────────────────────────────────────────────
printf '\n\033[1m✅ 설치 완료\033[0m\n'
info "새 터미널을 열거나 'source ~/.bashrc' (ROS_DOMAIN_ID 적용)"
id -nG "$USER" | tr ' ' '\n' | grep -qx docker && ! id -nG | tr ' ' '\n' | grep -qx docker && info "docker 를 sudo 없이 쓰려면 로그아웃 후 다시 로그인 (WSL 은 'wsl --shutdown')"
if $WSL; then info "윈도우 VS Code 에서: 우분투 터미널에 'code $DIR' → Reopen in Container"
elif $VSCODE; then info "VS Code: 'code $DIR' → Reopen in Container"; fi
info "터미널만 쓸 때: cd $DIR && ./scripts/dev.sh"
info "다음: docs/CONTRIBUTING.md (작업 흐름), docs/BEGINNER.md (처음이라면)"
