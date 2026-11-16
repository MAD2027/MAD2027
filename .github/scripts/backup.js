// 주간/월간 자동 백업 (backup.yml 에서 actions/github-script 로 불러 쓴다)
//   exportData   : 이슈·PR·댓글·라벨·마일스톤·릴리스를 JSON 파일로 저장
//   publish      : 프리릴리스를 만들고 백업 파일을 첨부
//   prune        : 보존 개수를 넘긴 오래된 백업 릴리스와 태그 삭제
//   toNotion     : 노션 "작업 기록" 데이터베이스에 백업 기록 행 추가
const fs = require('fs');
const path = require('path');
const { notion, text, block } = require('./report.js');

const PREFIX = 'backup-';
const KEEP = { weekly: 5, monthly: 12 };
const NAME = { weekly: '주간', monthly: '월간' };

// 한국 시간 기준 날짜
const kst = (now = new Date()) => new Date(now.getTime() + 9 * 3600000).toISOString();

function planFor(kind, now = new Date()) {
  if (!KEEP[kind]) throw new Error(`알 수 없는 백업 종류: ${kind}`);
  const day = kst(now).slice(0, 10);
  const id = kind === 'monthly' ? day.slice(0, 7) : day;
  return { kind, day, tag: `${PREFIX}${kind}-${id}`, title: `${NAME[kind]} 백업 ${id}`, keep: KEEP[kind] };
}

async function exportData({ github, context, dir }) {
  const repo = context.repo;
  const all = (fn, extra = {}) => github.paginate(fn, { ...repo, per_page: 100, ...extra });
  const sets = {
    // 이슈 API 가 PR 을 섞어 줄 때가 있어 빼 둔다 (PR 은 pulls.json)
    issues: (await all(github.rest.issues.listForRepo, { state: 'all' })).filter(i => !i.pull_request),
    pulls: await all(github.rest.pulls.list, { state: 'all' }),
    issue_comments: await all(github.rest.issues.listCommentsForRepo),
    review_comments: await all(github.rest.pulls.listReviewCommentsForRepo),
    labels: await all(github.rest.issues.listLabelsForRepo),
    milestones: await all(github.rest.issues.listMilestones, { state: 'all' }),
    releases: (await all(github.rest.repos.listReleases)).filter(r => !r.tag_name.startsWith(PREFIX)),
  };
  fs.mkdirSync(dir, { recursive: true });
  const counts = {};
  for (const [name, rows] of Object.entries(sets)) {
    fs.writeFileSync(path.join(dir, `${name}.json`), JSON.stringify(rows, null, 1));
    counts[name] = rows.length;
  }
  return counts;
}

function releaseBody({ plan, stats, files }) {
  const lines = [
    `자동 백업 (${plan.title}). 이 릴리스는 버전이 아니라 백업 보관용 프리릴리스입니다.`,
    '',
    '| 내용 | 개수 |',
    '|---|---|',
    `| 브랜치 | ${stats.branches} |`,
    `| 태그 | ${stats.tags} |`,
    `| 이슈 | ${stats.issues} |`,
    `| PR | ${stats.pulls} |`,
    `| 댓글 (이슈·PR + 리뷰) | ${stats.issue_comments + stats.review_comments} |`,
    '',
    '**파일**',
    ...files.map(f => `- \`${f.name}\` ${(f.size / 1048576).toFixed(2)} MB`),
    '',
    `sha256 은 \`SHA256SUMS\` 에 있습니다. 복원 방법은 \`docs/BACKUP.md\` 를 보세요.`,
    `보존: 최근 ${plan.keep}개. 더 오래된 ${NAME[plan.kind]} 백업은 자동으로 지워집니다.`,
  ];
  return lines.join('\n');
}

async function publish({ github, context, plan, stats, files }) {
  const repo = context.repo;
  // 같은 날(같은 달) 다시 실행하면 이전 것을 지우고 새로 만든다
  try {
    const { data: old } = await github.rest.repos.getReleaseByTag({ ...repo, tag: plan.tag });
    await github.rest.repos.deleteRelease({ ...repo, release_id: old.id });
  } catch (e) {
    if (e.status !== 404) throw e;
  }
  try {
    await github.rest.git.deleteRef({ ...repo, ref: `tags/${plan.tag}` });
  } catch (e) {
    if (e.status !== 422 && e.status !== 404) throw e;
  }
  const withSize = files.map(f => ({ ...f, size: fs.statSync(f.path).size }));
  const { data: rel } = await github.rest.repos.createRelease({
    ...repo,
    tag_name: plan.tag,
    target_commitish: context.sha,
    name: plan.title,
    body: releaseBody({ plan, stats, files: withSize }),
    prerelease: true,
    make_latest: 'false',
  });
  for (const f of withSize) {
    await github.rest.repos.uploadReleaseAsset({
      ...repo,
      release_id: rel.id,
      name: f.name,
      data: fs.readFileSync(f.path),
      headers: { 'content-type': 'application/octet-stream', 'content-length': f.size },
    });
  }
  return { url: rel.html_url, files: withSize };
}

async function prune({ github, context, plan }) {
  const repo = context.repo;
  const mine = `${PREFIX}${plan.kind}-`;
  const rels = (await github.paginate(github.rest.repos.listReleases, { ...repo, per_page: 100 }))
    .filter(r => r.prerelease && r.tag_name.startsWith(mine))
    .sort((a, b) => b.tag_name.localeCompare(a.tag_name));
  const removed = [];
  for (const r of rels.slice(plan.keep)) {
    await github.rest.repos.deleteRelease({ ...repo, release_id: r.id });
    try {
      await github.rest.git.deleteRef({ ...repo, ref: `tags/${r.tag_name}` });
    } catch (e) {
      if (e.status !== 422 && e.status !== 404) throw e;
    }
    removed.push(r.tag_name);
  }
  return removed;
}

async function toNotion({ plan, stats, release, token, databaseId }) {
  const properties = {
    제목: { title: [text(plan.title)] },
    유형: { select: { name: `${NAME[plan.kind]} 백업` } },
    기간: { date: { start: plan.day } },
    릴리스: { rich_text: [text(plan.tag)] },
    'GitHub 리포트': { url: release.url },
  };
  const item = s => block('bulleted_list_item', [text(s)]);
  const children = [
    block('paragraph', [text('GitHub 백업 릴리스: '), text(plan.tag, release.url)]),
    block('heading_2', [text('백업 내용')]),
    item(`브랜치 ${stats.branches}개, 태그 ${stats.tags}개`),
    item(`이슈 ${stats.issues}개, PR ${stats.pulls}개, 댓글 ${stats.issue_comments + stats.review_comments}개`),
    item(`라벨 ${stats.labels}개, 마일스톤 ${stats.milestones}개, 릴리스 ${stats.releases}개`),
    block('heading_2', [text('파일')]),
    ...release.files.map(f => item(`${f.name} (${(f.size / 1048576).toFixed(2)} MB)`)),
    block('heading_2', [text('복원 방법')]),
    block('paragraph', [text('저장소의 docs/BACKUP.md 를 따라 합니다. 요약: 릴리스에서 mad.bundle 을 내려받아 '),
      text('git clone mad.bundle MAD2027')]),
    block('paragraph', [text(`이 백업은 최근 ${plan.keep}개만 보존되므로, 오래되면 위 릴리스 링크가 사라집니다.`)]),
  ];
  const page = await notion('pages', 'POST', token, { parent: { database_id: databaseId }, properties, children });
  return page.url;
}

module.exports = { planFor, exportData, publish, prune, toNotion, PREFIX };
