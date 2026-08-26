# pi-setup

[pi 코딩 에이전트](https://github.com/badlogic/pi-mono) 설정 모음 — 스킬, 익스텐션, 서브에이전트, 그리고 과하지 않은 권한 정책. 새 머신에서 명령 한 줄로 복원한다.

**랜딩 페이지:** https://cskwork.github.io/pi-setup-public/ · **English:** [README.md](README.md)

## 빠른 시작

```bash
git clone https://github.com/cskwork/pi-setup-public.git ~/pi-setup-public
~/pi-setup/install.sh
pi auth   # 사용하는 프로바이더에 로그인
# pi 재시작
```

`install.sh`는 `~/.pi/agent/{AGENTS.md, settings.json, extensions, agents, skills}`를 이 저장소로 심볼릭 링크하고, 아래 패키지를 전부 설치하고, 기본 권한 설정을 배치한다. 기존 파일은 백업되며 덮어쓰지 않는다.

이후 로컬에서 바뀐 내용은 `~/pi-setup/sync.sh`로 저장소에 반영한다.

## 구성

### 스킬 (27)

| 스킬 | 하는 일 | 출처 |
|---|---|---|
| `agent-browser` | 에이전트용 브라우저 자동화 CLI | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| `api-and-interface-design` | 안정적인 API·인터페이스 설계 — 계약 우선, Hyrum의 법칙, 멱등키 확보, 일관된 에러 형태 | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) |
| `browser-qa` | 어떤 사이트든 브라우저 QA — YAML DAG 시나리오, 엔진 선택(네이티브 `agent_browser` 도구 우선), API 증적, `superqa` 런타임; Playwright E2E 패턴은 `reference/e2e-patterns.md` | [cskwork/browser-qa](https://github.com/cskwork/browser-qa) |
| `db-intelligence` | DB 스킬 하나로 4개 엔진 — PostgreSQL, MySQL, SQLite, MongoDB. 자격증명 안전 + 읽기 우선 + 스키마 선행; 도메인 증거 아티팩트(엔티티 그래프 + 보편 언어 + 데이터 형태) 생성 | local |
| `playwright-cli` | 브라우저 직접 조작, Playwright 테스트 작성/디버깅 | local |
| `call-agent` | 작업을 가장 적합한 다른 AI CLI로 넘김 | [cskwork/call-agent](https://github.com/cskwork/call-agent) |
| `verify` | 5단계 검증 — "빌드 통과 = 검증됨"을 거부한다 | [cskwork/verify-skill](https://github.com/cskwork/verify-skill) |
| `verification-before-completion` | 주장보다 증거 먼저 — 검증 안 된 완료 선언 금지 | [obra/superpowers](https://github.com/obra/superpowers) |
| `pi-settings` | pi 자체 settings.json 감사·구성 — 스킬 격리, 서브에이전트 라우팅, 패키지 | local |
| `diagnosing-bugs` | 버그·성능 회귀 진단 루프 — 재현 → 최소화 → 가설 → 계측 → 수정 → 회귀 테스트 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `tdd` | 테스트 주도 개발 — red-green-refactor, 통합 테스트, mocking 패턴 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `code-review` | 기준점 이후 변경을 Standards/Spec 두 축으로 병렬 서브에이전트 리뷰 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `implement` | 스펙·티켓 기반으로 작업 구현 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `research` | 신뢰 원천 조사 후 결과를 Markdown로 저장 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `domain-modeling` | 프로젝트 도메인 모델 구축 — CONTEXT.md, ADR | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `improve-codebase-architecture` | 개선 기회 스캔 → HTML 리포트 → 선택 항목 그릴링 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `resolving-merge-conflicts` | 진행 중인 git merge/rebase 충돌 해결 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `grilling` | 계획·결정을 끝까지 압박 검증 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `wait-what` | 멈춤 — 직전 메시지가 안 통했으면 다시 제안 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `writing-for-agents` | 에이전트용 문서 작성 — skills, AGENTS.md, CLAUDE.md | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `handoff` | 대화를 다음 에이전트용 인수인계 문서로 압축 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `teach` | 워크스페이스 내에서 기술·개념을 가르침 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `find-skills` | 새 에이전트 스킬 탐색/설치 | local |
| `gpt-image-2` | Codex CLI + ChatGPT 요금제로 이미지 생성 | local |
| `impeccable` | 프론트엔드 디자인 리뷰 및 다듬기 | [oddxinformatics/impeccable](https://github.com/oddxinformatics/impeccable) |
| `ego-browser` | 로그인 상태를 공유하는 에이전트 친화 브라우저 | [citrolabs/ego-lite](https://github.com/citrolabs/ego-lite) |
| `pi-sixpack` | SwarmForge 방식 6역할 게이트 파이프라인 (Wave 0 병렬 탐색 → specifier→coder→cleaner→architect∥hardender→QA, 팩 2/4/6) | [cskwork/aidt-swarmforge-harness](https://github.com/cskwork/aidt-swarmforge-harness) 이식 |

### 익스텐션

`pi install`로 설치된다 (`settings.json` 참고):

| 패키지 | 용도 |
|---|---|
| `npm:@gotgenes/pi-permission-system` | 패턴 기반 권한 관리 (아래 참고) |
| `npm:@narumitw/pi-goal` | 세션 목표 — 완료까지 계속 작업 |
| `npm:@narumitw/pi-usage` | 사용량/비용 추적 |
| `npm:pi-subagents` | 서브에이전트 오케스트레이션 |
| `npm:pi-lens` | 실시간 코드 피드백 — LSP, 린터, 포매터, 타입 검사 |
| `npm:pi-background-tasks` | 이름 붙인 백그라운드 셸 작업 |
| `npm:context-mode` | 큰 도구 출력이 컨텍스트를 먹지 않게 함 |
| `npm:pi-memory` (`@samfp/`) | 학습된 선호를 영구 저장 |
| `npm:pi-mcp-adapter` | 컨텍스트 낭비 없는 MCP 서버 연결 |
| `npm:pi-web-access` | 웹 검색/페치 |
| `npm:pi-simplify` | 코드 단순화 |
| `npm:pi-markdown-preview` | 마크다운 렌더 미리보기 |
| `npm:pi-powerline-footer` | 상태 푸터 |
| `npm:glm-vision` | GLM-4.6V 비전 |
| `npm:@juicesharp/rpiv-todo` | 할 일 관리 |
| `npm:@juicesharp/rpiv-ask-user-question` | 구조화된 질문 |
| `npm:pi-ponytail` | 게으른 시니어 개발자 모드(YAGNI 사다리) — coder/cleaner에 스킬 연결; 기본 `off`, `/ponytail`로 켜기 |
| `npm:pi-agent-browser-native` | agent-browser를 네이티브 `agent_browser` 도구로 — browser-qa 엔진 캐스케이드 1순위 (업스트림 `agent-browser` CLI 필요, install.sh가 설치) |

추가로 `extensions/`에 로컬 익스텐션이 있다: `permission-gate.ts` (위험 명령 확인), `dirty-repo-guard.ts` (세션 전환 시 미커밋 변경 가드), `herdr-agent-state.ts`.

### 서브에이전트 모델 프로필 (6)

`profiles/pi-subagents/*.json` — 식스팩 파이프라인의 게이트별 모델을 통째로 교체한다.
`/subagents-load-profile <codex-only|claude-only|mix|glm-max>`

| 게이트 | `codex-only` | `claude-only` | `mix` | `glm-max` |
|---|---|---|---|---|
| specifier | sol · high | sonnet-5 · high | opus-5 · high | glm-5.3 · max |
| coder | luna · max | opus-5 · high | codex sol · high | glm-5.3 · max |
| cleaner | luna · xhigh · fast | haiku-4-5 · med | luna · xhigh · fast | glm-5.3 · max |
| sw-architect | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| hardender | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| qa | luna · xhigh · fast | sonnet-5 · med | glm-5.3 · med | glm-5.3 · max |

hardender에는 항상 최상위 모델을 붙인다. 주어진 문서를 읽는 다른 게이트와 달리 검사 항목 자체를 스스로 만들어내야 하고, 실패했을 때 조용히 `PASS`를 내보내 이후 어떤 게이트도 이를 잡지 못하며, BLOCK 권한을 가지기 때문이다.

**유틸리티 에이전트** — 모든 프로필은 게이트가 아닌 에이전트도 2단 티어로
배정한다. `planner`와 `security`는 해당 프로필의 상위 모델을 받고(무엇을
만들지 판단하는 역할이라서), `refactorer`·`doc-writer`·`git-ops`·
`javascript-pro`·`typescript-pro`·`delegate`·`scout`·`researcher`·
`reviewer`·`worker`·`tester`·`debugger`는 저렴하고 빠른 쪽을 받는다.

**함정 — 에이전트 frontmatter에 `model:`을 넣지 말 것.** pi-subagents는
frontmatter의 `model:`을 `agentOverrides`보다 **먼저** 해석한다. 따라서 `.md`에
모델을 박아둔 에이전트는 모든 프로필을 조용히 무시한다. 이 저장소의
`agents/*.md`에는 의도적으로 `model:` 줄이 없다 — 라우팅의 단일 진실 공급원은
프로필이다. 특정 에이전트가 프로필을 절대 따르면 안 될 때만 다시 넣는다.

**팩 프로필** — `two-pack`과 `four-pack`은 `glm-max` 모델을 해당 팩이 실제로
돌리는 게이트에만 고정한다 (two-pack: coder → qa; four-pack: specifier →
coder → refactorer → sw-architect → qa). 역할 순서는 업스트림 SwarmForge
브랜치를 따르며, pi 파이프라인의 독립 QA 게이트는 모든 팩에 유지된다.
팩이 이미 정해져 있다면 로드하면 된다. 유틸리티 에이전트의 스킬 목록은
그대로 남아 통째 로드해도 아무것도 벗겨지지 않는다. 팩 6은 모델 프로필을
그대로 쓴다.

### 기본 스킬 연결

모든 프로필이 `agentOverrides.<agent>.skills`를 설정해 호출마다 연결할 필요 없이 에이전트와 함께 스킬이 로드된다:

- **QA/브라우저** — `qa`, `qa-tester`, `qa-auditor`, `agent-browser`에 `browser-qa` (+ 필요한 곳에 `agent-browser`, `playwright-cli`)
- **페르소나** — `customer-agent`, `persona-product-tester`에 `browser-qa` + `agent-browser`
- **검증/TDD/디버깅** — `verify`, `tester`, `hardender`, `debugger`, `coder`에 검증/TDD/체계적 디버깅 스킬
- **도메인 데이터** — `specifier`, `hardender`, `qa`에 `db-intelligence` (코딩 전 도메인 데이터 확보, 무결성 프로브, 읽기 전용 DB 증거)
- **미니멀리즘** — `coder`에 `ponytail`, `cleaner`/`refactorer`에 `ponytail-review`
- **아키텍처** — `sw-architect`에 `api-and-interface-design` (`skills/`에 실물 복사본이 있어 새로 클론해도 동작한다). 에이전트 프롬프트는 *무엇을* 볼지 정하고, 스킬은 판단 근거를 제공한다 — Hyrum의 법칙, 멱등키(idempotency key) 확보와 TOCTOU 함정, 에러 형태 일관성, 추가 전용 변경 규칙.

식스팩의 **Wave 0**은 명세 전에 이 스킬들을 병렬로 퍼뜨린다: Jira 요구사항(atlassian-cli, 있을 때) ∥ 코드 그래프 ∥ DB 증거 ∥ 브라우저 현재 동작 — 읽기 전용 의존성 DAG 노드들이며, 이 아티팩트를 명세가 반드시 인용해야 한다.

### 권한 정책 (기본값)

`configs/permissions.json`이 `extensions/pi-permission-system/config.json`으로 배치된다. 체감은 기본 pi와 거의 같다 — 읽기, 파일 도구, 스킬, ctx 도구, 일반 셸 명령은 확인 없이 통과하고, 정말 필요한 곳에만 가드를 둔다:

- `.env*`와 `~/.ssh/*`는 모든 도구에서 읽기 차단 (`path` deny, 전역 적용)
- `rm -rf /`(및 `--no-preserve-root` 변형)는 거부, 그 외 `rm`/`rmdir`/`sudo`는 확인
- 디스크 초기화/파티션(`diskutil erase*`, `secureErase*`, `partitionDisk*`)은 거부
- 나머지는 허용

실제 사용 중인 설정은 **본인 것**이다. 이 저장소에서는 gitignore 처리되어 있고, pi 권한 모달로 수정한 내용은 로컬에만 남는다. 저장소 사본은 새로 설치하는 사람을 위한 깔끔한 기본값으로 유지한다.

## 구조

```
AGENTS.md            운영 지침 (~/.pi/agent로 심볼릭 링크)
settings.json        프로바이더 + 패키지
configs/             권한 기본값 (공개)
skills/              선별한 스킬 27개
agents/              서브에이전트 역할 프롬프트
extensions/          로컬 TS 익스텐션
scripts/             check-docs.py — 문서/설정 불일치 CI 가드
                     prune-sessions.sh — 세션 기록 보존 기간 정리
install.sh           새 머신 부트스트랩
sync.sh              로컬 변경을 GitHub로 저장
```

## 백업

`sync.sh`가 로컬 변경을 커밋하고 푸시한다. 메모리와 세션 데이터는 의도적으로 이 저장소 바깥에 둔다.

### 세션 보존 기간

`~/.pi/agent/sessions/`는 모든 세션을 JSONL로 저장하며 **사용자 프롬프트가 원문 그대로**
남는다. 자동 정리가 없어 무한정 쌓인다(여기서 첫 정리 전 기준 72 MB / 385개). 로컬에만
있고 어떤 저장소에도 커밋되지 않는다.

```bash
scripts/prune-sessions.sh              # 미리보기(삭제 안 함), 90일 보존
scripts/prune-sessions.sh --apply      # 삭제, 먼저 tar.gz 백업
DAYS=30 scripts/prune-sessions.sh --apply
scripts/prune-sessions.sh --apply --no-backup
```

`--no-backup`을 주지 않으면 삭제된 파일은 세션 디렉터리 옆
`sessions.prune-backup-<시각>.tar.gz`로 보관되므로 되돌릴 수 있다.
