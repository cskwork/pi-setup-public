# pi-setup

[pi 코딩 에이전트](https://github.com/badlogic/pi-mono) 설정 모음 — 스킬, 익스텐션, 서브에이전트, 그리고 과하지 않은 권한 정책. 새 머신에서 명령 한 줄로 복원한다.

**랜딩 페이지:** https://cskwork.github.io/pi-setup/ · **English:** [README.md](README.md)

## 빠른 시작

```bash
git clone https://github.com/cskwork/pi-setup.git ~/pi-setup
~/pi-setup/install.sh
pi auth   # 사용하는 프로바이더에 로그인
# pi 재시작
```

`install.sh`는 `~/.pi/agent/{AGENTS.md, settings.json, extensions, agents, skills}`를 이 저장소로 심볼릭 링크하고, 아래 패키지를 전부 설치하고, 기본 권한 설정을 배치한다. 기존 파일은 백업되며 덮어쓰지 않는다.

이후 로컬에서 바뀐 내용은 `~/pi-setup/sync.sh`로 저장소에 반영한다.

## 구성

### 스킬 (12)

| 스킬 | 하는 일 | 출처 |
|---|---|---|
| `agent-browser` | 에이전트용 브라우저 자동화 CLI | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| `impeccable` | 프론트엔드 디자인 리뷰 및 다듬기 | [oddxinformatics/impeccable](https://github.com/oddxinformatics/impeccable) |
| `gpt-image-2` | Codex CLI + ChatGPT 요금제로 이미지 생성 | local |
| `improve-codebase-architecture` | 테스트를 통과시킨 채 탐색성 위주로 리팩터링 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `handoff` | 세션 인계 요약 | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `call-agent` | 작업을 가장 적합한 다른 AI CLI로 넘김 | [cskwork/call-agent](https://github.com/cskwork/call-agent) |
| `clean-code` | 동작을 바꾸지 않는 레거시 리팩터링 | [cskwork/clean-code](https://github.com/cskwork/clean-code) |
| `verify-skill` | 5단계 검증 — "빌드 통과 = 검증됨"을 거부한다 | [cskwork/verify-skill](https://github.com/cskwork/verify-skill) |
| `ego-browser` | 로그인 상태를 공유하는 에이전트 친화 브라우저 | [citrolabs/ego-lite](https://github.com/citrolabs/ego-lite) |
| `promptbox` | promptbox 컬렉션에 원샷으로 항목 추가 | [cskwork/promptbox](https://github.com/cskwork/promptbox) |
| `pi-sixpack` | SwarmForge 방식 6역할 게이트 파이프라인 (specifier→coder→cleaner→architect∥hardender→QA, 팩 2/4/6) | [cskwork/aidt-swarmforge-harness](https://github.com/cskwork/aidt-swarmforge-harness) 이식 |
| `browser-qa` | 어떤 사이트든 브라우저 QA — YAML DAG 시나리오, 엔진 선택, API 증적, `superqa` 런타임 | [cskwork/browser-qa](https://github.com/cskwork/browser-qa) |

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

추가로 `extensions/`에 로컬 익스텐션이 있다: `permission-gate.ts` (위험 명령 확인), `dirty-repo-guard.ts` (세션 전환 시 미커밋 변경 가드), `herdr-agent-state.ts`, `superset-hooks.ts`, `ai-memory-pi.ts`.

### 서브에이전트 모델 프로필 (6)

`profiles/pi-subagents/*.json` — 식스팩 파이프라인의 게이트별 모델을 통째로 교체한다.
`/subagents-load-profile <codex-only|claude-only|mix|glm-max>`

| 게이트 | `codex-only` | `claude-only` | `mix` | `glm-max` |
|---|---|---|---|---|
| specifier | sol · high | sonnet-5 · high | opus-5 · high | glm-5.3 · max |
| coder | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| cleaner | luna · xhigh · fast | haiku-4-5 · med | luna · xhigh · fast | glm-5.3 · max |
| sw-architect | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| hardender | sol · high | opus-5 · high | codex sol · high | glm-5.3 · max |
| qa | luna · xhigh · fast | sonnet-5 · med | glm-5.3 · med | glm-5.3 · max |

hardender에는 항상 최상위 모델을 붙인다. 주어진 문서를 읽는 다른 게이트와 달리 검사 항목 자체를 스스로 만들어내야 하고, 실패했을 때 조용히 `PASS`를 내보내 이후 어떤 게이트도 이를 잡지 못하며, BLOCK 권한을 가지기 때문이다.

**팩 프로필** — `two-pack`과 `four-pack`은 `glm-max` 모델을 해당 팩이 실제로
돌리는 게이트에만 고정한다 (two-pack: coder → qa; four-pack: specifier →
coder → refactorer → sw-architect → qa). 역할 순서는 업스트림 SwarmForge
브랜치를 따르며, pi 파이프라인의 독립 QA 게이트는 모든 팩에 유지된다.
팩이 이미 정해져 있다면 로드하면 된다. 유틸리티 에이전트의 스킬 목록은
그대로 남아 통째 로드해도 아무것도 벗겨지지 않는다. 팩 6은 모델 프로필을
그대로 쓴다.

### 권한 정책 (기본값)

`configs/permissions.json`이 `extensions/pi-permission-system/config.json`으로 배치된다. 체감은 기본 pi와 거의 같다 — 읽기, 파일 도구, 스킬, ctx 도구, 일반 셸 명령은 확인 없이 통과하고, 정말 필요한 곳에만 가드를 둔다:

- `.env*`와 `~/.ssh/*`는 모든 도구에서 읽기 차단 (`path` deny, 전역 적용)
- `rm -rf`는 거부, 그 외 `rm`/`sudo`는 확인
- 나머지는 허용

실제 사용 중인 설정은 **본인 것**이다. 이 저장소에서는 gitignore 처리되어 있고, pi 권한 모달로 수정한 내용은 로컬에만 남는다. 저장소 사본은 새로 설치하는 사람을 위한 깔끔한 기본값으로 유지한다.

## 구조

```
AGENTS.md            운영 지침 (~/.pi/agent로 심볼릭 링크)
settings.json        프로바이더 + 패키지
configs/             권한 기본값 (공개)
skills/              선별한 스킬 12개
agents/              서브에이전트 역할 프롬프트
extensions/          로컬 TS 익스텐션
install.sh           새 머신 부트스트랩
sync.sh              로컬 변경을 GitHub로 저장
```

## 백업

`sync.sh`가 로컬 변경을 커밋하고 푸시한다. 메모리와 세션 데이터는 의도적으로 이 저장소 바깥에 둔다.
