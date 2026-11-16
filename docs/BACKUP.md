# 자동 백업 (주간 / 월간)

저장소가 망가지거나 실수로 지워져도 되살릴 수 있도록 GitHub Actions 가 백업을 자동으로 만듭니다.
설정 파일: `.github/workflows/backup.yml`, `.github/scripts/backup.js`

| 종류 | 언제 (KST) | 이름 | 보존 |
|---|---|---|---|
| 주간 | 매주 월요일 03:43 | `backup-weekly-YYYY-MM-DD` | 최근 5개 |
| 월간 | 매월 1일 10:37 | `backup-monthly-YYYY-MM` | 최근 12개 |

보존 개수를 넘은 오래된 백업은 자동으로 지워집니다. 오래 남겨야 하는 백업(대회 직전 등)은 파일을 내려받아 따로 보관하세요.

## 무엇이 백업되나
| 파일 | 내용 |
|---|---|
| `mad.bundle` | 저장소 전체: 모든 브랜치·태그와 이력 (`git bundle`) |
| `github-data.tar.gz` | GitHub 에만 있는 기록: 이슈, PR, 댓글, 리뷰 댓글, 라벨, 마일스톤, 릴리스 (JSON) |
| `SHA256SUMS` | 두 파일이 손상되지 않았는지 확인하는 체크섬 |

빠지는 것: 본체 노트북의 rosbag(`bags/`), 저장소 설정(Ruleset, Secrets, 팀 구성), 이미지·첨부 파일 원본(JSON 안에는 링크만 남음).

## 어디에 보관되나
- **GitHub**: 저장소 **Releases** 의 프리릴리스(Pre-release). 버전 릴리스(`v1.2.0`)와 섞이지 않습니다. `버전 릴리스` 워크플로는 프리릴리스를 무시하고 다음 버전 번호를 계산합니다.
- **노션**: 진행 리포트와 같은 데이터베이스 `작업 기록 (주간 / 월간)` 에 행이 하나 생깁니다. 유형은 `주간 백업`/`월간 백업`, `릴리스` 칸에 백업 이름, `GitHub 리포트` 칸에 백업 릴리스 링크, 페이지 본문에 백업 내용과 복원 방법이 들어갑니다. 설정은 [NOTION.md](NOTION.md) 와 같고, 설정이 없으면 노션 기록만 건너뜁니다.
  - 리포트와 백업을 따로 보려면 노션에서 데이터베이스 보기(View)를 추가하고 `유형` 으로 필터를 거세요.

## 지금 바로 백업하기
**Actions → 자동 백업 → Run workflow** 에서 `weekly` 또는 `monthly` 를 고릅니다. 같은 날(월간은 같은 달)에 다시 실행하면 그 백업을 새로 덮어씁니다.

## 실패했을 때
`🚨 자동 백업 실패` 이슈(`ci:backup-failure` 라벨)가 열립니다. 로그를 보고 고친 뒤 다시 실행하면 성공할 때 이슈가 자동으로 닫힙니다.

## 복원하기
1. Releases 에서 원하는 `backup-...` 의 `mad.bundle`, `github-data.tar.gz`, `SHA256SUMS` 를 한 폴더에 내려받습니다.
2. 파일이 온전한지 확인합니다.
   ```bash
   sha256sum -c SHA256SUMS
   ```
3. 저장소를 되살립니다. 모든 브랜치가 `origin/...` 으로 들어옵니다.
   ```bash
   git clone mad.bundle MAD2027
   ```
4. 새 GitHub 저장소로 올릴 때는 (관리자) 빈 저장소를 만든 뒤 모든 브랜치와 태그를 올립니다.
   ```bash
   cd MAD2027
   git remote set-url origin https://github.com/<조직>/<새 저장소>.git
   git push origin 'refs/remotes/origin/*:refs/heads/*' --tags
   ```
5. 이슈·PR 기록은 압축을 풀어 JSON 으로 봅니다. GitHub 에 자동으로 다시 만들어지지는 않습니다.
   ```bash
   tar xzf github-data.tar.gz
   ```
