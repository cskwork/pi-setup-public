# pi-setup

[pi 코딩 에이전트](https://github.com/badlogic/pi-mono) 설정 모음이다. 스킬, 익스텐션, 서브에이전트, 그리고 무언가를 망가뜨릴 수 있는 명령만 막는 권한 정책. 새 머신에서 명령 한 줄로 복원한다.

**랜딩 페이지:** https://cskwork.github.io/pi-setup-public/ (퍼블릭 레포) · **English:** [README.md](README.md)

## 빠른 시작

### macOS, Linux, Git Bash

```bash
git clone https://github.com/cskwork/pi-setup-public.git ~/pi-setup-public
~/pi-setup-public/install.sh
pi auth                      # OAuth 프로바이더 (anthropic, openai-codex, amazon-bedrock)
$EDITOR ~/.pi-setup.env      # API 키 프로바이더, 예: ZAI_API_KEY=...
# 셸을 다시 연 뒤 pi 재시작
```

### Windows PowerShell

```powershell
git clone https://github.com/cskwork/pi-setup-public.git "$HOME\pi-setup-public"
Set-Location "$HOME\pi-setup-public"
if ((Get-ExecutionPolicy) -eq 'Restricted') {
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
}
.\install.ps1
pi auth                      # OAuth 프로바이더 (anthropic, openai-codex, amazon-bedrock)
notepad $HOME\.pi-setup.env  # API 키 프로바이더, 예: ZAI_API_KEY=...
# PowerShell을 다시 연 뒤 pi 재시작
```

설치 스크립트는 `~/.pi/agent/{AGENTS.md, settings.json, extensions, agents, skills}`를 이 저장소로 심볼릭 링크하고, 아래 패키지를 전부 설치하고, 기본 권한 설정을 배치한다. 기존 파일은 덮어쓰지 않고 백업해 둔다.

또한 셸 프로필에 관리 블록을 추가해 Pi에만 V8 힙 8 GiB를 준다. 다른 Node 프로세스는 기본값을 유지하고, 기존 `NODE_OPTIONS`도 보존하며, 호출할 때마다 현재 NVM/npm의 Pi 실행 파일을 찾는다. 저장소를 옮겼다면 설치 스크립트를 다시 실행한다. 제거하려면 `pi-setup Pi-only Node heap` 표식 사이의 블록을 지운다. Windows PowerShell 5.1과 PowerShell 7을 모두 사용하면 각 셸에서 `install.ps1`을 한 번씩 실행한다. 조직 정책이 PowerShell 프로필 실행을 강제로 막는 환경에서는 관리자 정책 변경이 필요하다.

### 프로바이더 자격증명

Pi는 프로바이더별로 정해진 환경 변수가 설정되어 있을 때만 그 프로바이더를 등록한다. `settings.json`이 참조하는 모델의 프로바이더가 등록되지 않으면 서브에이전트를 띄울 때마다 `[pi-subagents] Skipping fallback model '<id>' because it is unavailable in this environment.` 경고가 찍힌다.

그래서 설치 스크립트는 추적되는 `.env.example`을 복사해 `~/.pi-setup.env`를 권한 `600`으로 만들고, Pi 실행 전에 `scripts/pi-env.sh`를 읽는 두 번째 관리 블록을 셸 프로필에 추가한다. 이 로더는:

- `~/.pi-setup.env`를 **기본값으로만** 읽는다. 이미 export된 변수가 항상 이기므로 `ZAI_API_KEY=... pi ...` 같은 일회성 지정과 CI 시크릿이 그대로 유지된다.
- `ZAI_API_KEY`와 `Z_AI_API_KEY`를 양방향으로 미러링한다. Pi는 앞의 이름을, Z.ai Vision MCP 서버는 뒤의 이름을 읽기 때문이다. 키는 둘 중 아무 이름으로나 한 번만 저장하면 된다.

실제 비밀 파일은 저장소 **밖에** 있으므로 커밋되거나 공개 미러로 나갈 수 없다. 경로는 `PI_SETUP_ENV_FILE`로 바꿀 수 있다.

**키가 없는 것은 오류가 아니다.** pi-subagents는 등록되지 않은 프로바이더의 모델마다 실행당 한 번씩 경고를 찍고, 이를 끄는 설정은 없다. 그래서 `settings.json`이 경로로 쓰지만 키가 없는 프로바이더에는 로더가 `unset-placeholder` 값을 넣는다. 그러면 프로바이더가 등록되어 경고가 사라진다. 자격증명은 틀리지만 그 경로는 이미 조용하다. Pi가 모델을 호출하고, 실패하면 폴백 체인의 다음 후보로 넘어간다. 진짜 키는 항상 placeholder를 이기며, 같은 셸에서 프로필을 다시 source 해도 마찬가지다. 경고를 보고 싶으면 `PI_SETUP_NO_PLACEHOLDER=1`로 끄면 된다.

설치 마지막에는 `settings.json`이 경로로 쓰지만 자격증명이 없는 프로바이더를 나열한다. 문제가 아니라 안내다. 로더를 제거하려면 `pi-setup provider env` 표식 사이의 블록을 지우면 된다.

기본 모델은 사고 수준 `xhigh`의 `openai-codex/gpt-5.6-sol`이다. 서브에이전트는 `openai-codex/gpt-5.6-sol`을 쓴다. 설계 역할(specifier, sw-architect, hardender, architect)은 `high` 사고, 나머지는 `medium` 사고를 쓴다. Sol 경로는 Anthropic·Z.ai 폴백을 유지하고, Z.ai 경로는 `max` 사고로 돈다. `models.json`은 GLM-5.3-Flash의 텍스트·이미지 입력을 계속 선언한다. Z.ai 경로는 `ZAI_API_KEY`가 설정되어 있을 때 사용되고, 없으면 해당 역할은 조용히 Anthropic·OpenAI 단계로 내려간다.

이후 로컬에서 바뀐 내용은 `~/pi-setup-public/sync.sh`로 저장소에 반영한다.

## 구성

### 스킬 (30)

| 스킬 | 하는 일 | 출처 |
|---|---|---|
| `agent-browser` | 에이전트용 브라우저 자동화 CLI | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| `api-and-interface-design` | 안정적인 API·인터페이스 설계: 계약 우선, Hyrum의 법칙, 멱등키 확보, 일관된 에러 형태 | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) |
| `browser-qa` | 어떤 사이트든 브라우저 QA: YAML DAG 시나리오, 엔진 선택(네이티브 `agent_browser` 도구 우선), API 증적, `superqa` 런타임; Playwright E2E 패턴은 `reference/e2e-patterns.md` | [cskwork/browser-qa](https://github.com/cskwork/browser-qa) |
| `db-intelligence` | DB 스킬 하나로 4개 엔진: PostgreSQL, MySQL, SQLite, MongoDB. 자격증명 안전 + 읽기 우선 + 스키마 선행; 도메인 증거 아티팩트(엔티티 그래프 + 보편 언어 + 데이터 형태) 생성 | local |
| `playwright-cli` | 브라우저 직접 조작, Playwright 테스트 작성/디버깅 | local |
| `call-agent` | 작업에 맞는 다른 AI CLI로 넘김; claude 래퍼는 `CLAUDE_MODEL`로 모델 교체 | [cskwork/call-agent](https://github.com/cskwork/call-agent) |
| `verify` | 5단계 검증. "빌드 통과 = 검증됨"을 거부한다 | [cskwork/verify-skill](https://github.com/cskwork/verify-skill) |
| `create-verification-skill` | 실제 앱을 구동해 증거를 남기는 프로젝트 전용 검증 스킬을 생성한다 | [cursor/plugins](https://github.com/cursor/plugins/tree/main/pstack/skills/create-verification-skill) |
| `verification-before-completion` | 주장보다 증거 먼저. 검증 안 된 완료 선언 금지 | [obra/superpowers](https://github.com/obra/superpowers) |
| `pi-settings` | pi 자체 settings.json 감사·구성: 스킬 격리, 서브에이전트 라우팅, 패키지 | local |
| `sync-agent-prompt` | pi-setup, pi-setup-public, promptbox 온보딩 프롬프트 세 곳의 AGENTS.md 운영 계약과 필수 스킬 동기화; 쓰기 전 as-is → to-be 비교 후 확인 | local |
| `diagnosing-bugs` | 버그·성능 회귀 진단 루프: 재현 → 최소화 → 가설 → 계측 → 수정 → 회귀 테스트 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `tdd` | 테스트 주도 개발: red-green-refactor, 통합 테스트, mocking 패턴 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `unslop` | AI 문체 패턴을 걷어내고 사람다운 목소리로 다듬기 | [cursor/plugins](https://github.com/cursor/plugins/tree/main/pstack/skills/unslop) |
| `code-review` | 기준점 이후 변경을 Standards/Spec 두 축으로 병렬 서브에이전트 리뷰 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `implement` | 스펙·티켓 기반으로 작업 구현 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `research` | 신뢰 원천 조사 후 결과를 Markdown로 저장 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `domain-modeling` | CONTEXT.md와 ADR로 프로젝트 도메인 모델 구축 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `improve-codebase-architecture` | 깊게 팔 만한 지점 스캔 → HTML 리포트 → 고른 항목 그릴링 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `resolving-merge-conflicts` | 진행 중인 git merge/rebase 충돌 해결 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `grilling` | 계획이나 결정이 깨지거나 버틸 때까지 압박 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `wait-what` | 멈춤. 직전 메시지가 안 통했으면 다시 제안 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `writing-for-agents` | 에이전트용 문서 작성: skills, AGENTS.md, CLAUDE.md | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `handoff` | 대화를 다음 에이전트용 인수인계 문서로 압축 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `teach` | 워크스페이스 내에서 기술·개념을 가르침 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `find-skills` | 새 에이전트 스킬 탐색/설치 | local |
| `gpt-image-2` | Codex CLI + ChatGPT 요금제로 이미지 생성 | local |
| `impeccable` | 프론트엔드 디자인 리뷰 및 다듬기 | [oddxinformatics/impeccable](https://github.com/oddxinformatics/impeccable) |
| `ego-browser` | 로그인 상태를 공유하는 에이전트 친화 브라우저 | [citrolabs/ego-lite](https://github.com/citrolabs/ego-lite) |
| `sdlc-kit` | 기록으로 남는 사람 승인, 새 컨텍스트 검토, 제한된 메모리를 갖춘 6단계 SDLC 루프 | [cskwork/sdlc-kit](https://github.com/cskwork/sdlc-kit) |

### 익스텐션

`pi install`로 설치된다 (`settings.json` 참고):

| 패키지 | 용도 |
|---|---|
| `npm:@gotgenes/pi-permission-system` | 패턴 기반 권한 관리 (아래 참고) |
| `npm:@narumitw/pi-goal` | 세션 목표를 주면 완료까지 계속 작업 |
| `npm:@narumitw/pi-usage` | 사용량/비용 추적 |
| `npm:pi-subagents` | 서브에이전트 오케스트레이션 |
| `npm:pi-lens` | 에이전트가 편집하는 동안 코드 피드백: LSP, 린터, 포매터, 타입 검사 |
| `npm:pi-background-tasks` | 이름 붙인 백그라운드 셸 작업 |
| `npm:context-mode` | 큰 도구 출력이 컨텍스트를 먹지 않게 함 |
| `npm:pi-memory` (`@samfp/`) | 학습된 선호를 영구 저장 |
| `npm:pi-oracle` | 한 번의 격리 브라우저 인증으로 ChatGPT Pro/Grok 웹 작업을 비동기 실행 |
| `npm:pi-mcp-adapter` | 컨텍스트 낭비 없는 MCP 서버 연결 |
| `npm:pi-web-access` | 웹 검색/페치 |
| `npm:pi-simplify` | 코드 단순화 |
| `npm:pi-markdown-preview` | 마크다운 렌더 미리보기 |
| `npm:pi-powerline-footer` | 상태 푸터 |
| `npm:@juicesharp/rpiv-todo` | 할 일 관리 |
| `npm:@juicesharp/rpiv-ask-user-question` | 구조화된 질문 |
| `npm:pi-ponytail` | 게으른 시니어 개발자 모드(YAGNI 사다리). coder/cleaner에 스킬 연결, 기본 `off`, `/ponytail`로 켜기 |
| `npm:pi-agent-browser-native` | agent-browser를 네이티브 `agent_browser` 도구로 노출. browser-qa 엔진 캐스케이드 1순위 (업스트림 `agent-browser` CLI 필요, install.sh가 설치) |

추가로 `extensions/`에 로컬 익스텐션이 있다: `dirty-repo-guard.ts`(세션 전환 시 미커밋 변경 가드), `herdr-agent-state.ts`. Bash 권한은 `@gotgenes/pi-permission-system`만 쓴다. 다른 곳에서는 건드리지 않는다.

### 서브에이전트 모델 프로필 (4)

프로필은 `profiles/pi-subagents/*.json`에 있다. 공용 에이전트 세트의 모델 라우팅을
통째로 교체한다. `/subagents-load-profile <codex-only|claude-only|mix|glm-max>`

| 게이트 | `codex-only` | `claude-only` | `mix` | `glm-max` |
|---|---|---|---|---|
| specifier | sol · high | sonnet-5 · high | opus-5 · high | glm-5.3 · max |
| coder | sol · medium | opus-5 · high | codex sol · high | glm-5.3 · max |
| cleaner | sol · medium | haiku-4-5 · high | sol · medium | glm-5.3 · max |
| sw-architect | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| hardender | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| qa | sol · medium | sonnet-5 · high | glm-5.3-flash · max | glm-5.3-flash · max |

hardender에는 항상 최상위 모델을 붙인다. 주어진 문서를 읽는 다른 게이트와 달리 검사 항목을 스스로 만들어야 하고, BLOCK 권한을 가지며, 실패하면 조용히 `PASS`를 내보내 이후 어떤 게이트도 이를 잡지 못한다.

**유틸리티 에이전트.** 모든 프로필은 게이트가 아닌 에이전트도 2단 티어로
배정한다. `planner`와 `security`는 해당 프로필의 상위 모델을 받는다. 남이 짠
계획을 실행하는 게 아니라 무엇을 만들지 판단하는 역할이기 때문이다.
`refactorer`·`doc-writer`·`git-ops`·`javascript-pro`·`typescript-pro`·
`delegate`·`scout`·`researcher`·`reviewer`·`worker`·`tester`·`debugger`는
저렴하고 빠른 쪽을 받는다.

**에이전트 frontmatter에 `model:`을 넣지 말 것.** pi-subagents는 frontmatter의
`model:`을 `agentOverrides`보다 **먼저** 해석한다. 따라서 `.md`에 모델을 박아둔
에이전트는 모든 프로필을 조용히 무시한다. 이 저장소의 `agents/*.md`에는
의도적으로 `model:` 줄이 없고, 라우팅은 프로필에서만 결정된다. 특정 에이전트가
프로필을 절대 따르면 안 될 때만 다시 넣는다.

외부 스킬이나 확장이 등록한 에이전트에도 같은 규칙이 적용된다. 시작할 때
`Unknown subagent model 'opus'`(또는 `sonnet`) 오류가 나면 외부 에이전트
프롬프트를 고친다. `model:` 줄을 제거하거나 정확한 provider/model ID를 쓴다.
frontmatter가 먼저 이기므로 settings override만으로는 이 핀을 고칠 수 없다.

### 기본 스킬 연결

모든 프로필이 `agentOverrides.<agent>.skills`를 설정해 호출마다 연결할 필요 없이 에이전트와 함께 스킬이 로드된다:

- **QA/브라우저.** `qa`, `qa-tester`, `qa-auditor`, `agent-browser`에 `browser-qa` (+ 필요한 곳에 `agent-browser`, `playwright-cli`)
- **페르소나.** `customer-agent`, `persona-product-tester`에 `browser-qa` + `agent-browser`
- **검증/TDD/디버깅.** `verify`, `tester`, `hardender`, `debugger`, `coder`에 검증/TDD/체계적 디버깅 스킬
- **도메인 데이터.** `specifier`, `hardender`, `qa`에 `db-intelligence` (코딩 전 도메인 데이터 확보, 무결성 프로브, 읽기 전용 DB 증거)
- **미니멀리즘.** `coder`에 `ponytail`, `cleaner`/`refactorer`에 `ponytail-review`
- **아키텍처.** `sw-architect`에 `api-and-interface-design` (`skills/`에 실물 복사본이 있어 새로 클론해도 동작한다). 에이전트 프롬프트는 *무엇을* 볼지 정하고, 스킬은 판단 근거를 제공한다: Hyrum의 법칙, 멱등키(idempotency key) 확보와 TOCTOU 함정, 에러 형태 일관성, 추가 전용 변경 규칙.

### 권한 정책 (기본값)

`configs/permissions.json`이 `extensions/pi-permission-system/config.json`으로 배치된다. 읽기, 파일 도구, 스킬, ctx 도구, 일반 셸 명령은 기본 pi와 똑같이 확인 없이 통과한다. 정책 전체는 이렇다:

- 비밀 가능성이 높은 파일(`.env*`, credentials, 개인키, application 설정, `~/.ssh/*`)은 모든 도구에서 차단
- 재귀 삭제, 권한 상승, 디스크 쓰기, 파괴적 Git 명령은 확인
- 파일시스템 루트 삭제와 디스크 포맷은 거부
- 일반 명령과 외부 디렉터리 접근은 허용

실제 사용 중인 설정은 **본인 것**이다. 이 저장소에서는 gitignore 처리되어 있고, pi 권한 모달로 수정한 내용은 로컬에만 남는다. 저장소 사본은 새로 설치하는 사람이 받는 기본값으로 유지한다.

## 구조

```
AGENTS.md            운영 지침 (~/.pi/agent로 심볼릭 링크)
settings.json        프로바이더 + 패키지
configs/             권한 기본값 (공개)
skills/              에이전트 스킬 30개
agents/              서브에이전트 역할 프롬프트
extensions/          로컬 TS 익스텐션
scripts/             check-docs.py: 문서/설정 불일치 CI 가드
                     pi-node-heap.sh/.ps1: Pi 전용 8 GiB 런처
                     pi-env.sh/.ps1: 프로바이더 자격증명 로더 + 키 이름 미러링
                     prune-sessions.sh: 세션 기록 보존 기간 정리
.env.example         ~/.pi-setup.env 템플릿 (실제 비밀 파일은 이 저장소
                     밖에 있고 절대 커밋되지 않는다)
tests/               셸·PowerShell 런처 회귀 검사
install.sh           macOS/Linux/Git Bash 부트스트랩
install.ps1          Windows PowerShell 네이티브 부트스트랩
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
