# <Service name>

<一句话说明这个仓库是什么、边界在哪。>

## Commands
- Build: `<cmd>`  (成功时输出包含 `<healthy output>`)
- Test: `<cmd>`   (全绿；集成测试用 `<cmd>`，需要 `<前置条件>`)
- Lint: `<cmd>`   (零告警；CI 也跑，推之前先修)
- Run: `<cmd>`

## Verifying your work
Run all three before reporting any task complete, and paste the output.
If a test fails, fix the code, not the test.

## Conventions
- <语言/框架版本与硬约束>
- <命名、目录、错误处理约定>
- <数值/时间/金额等易错类型的强制规则>

## Architecture
- `<dir>/` — <职责>
- <模块之间的依赖方向>
- <哪些是生成代码，绝对不要手改>

## Things Claude gets wrong
<同一个错误犯第二次就写到这里。这一节是活的，其他节是静的。>
- <具体错误 → 正确做法>

## SDLC
Change artifacts live in `sdlc/<id>/` (intent.md → spec.md → plan.md); the active
change id is in `.sdlc/current`. Commands: /sdlc:intent /sdlc:spec /sdlc:plan
/sdlc:build /sdlc:fix /sdlc:verify /sdlc:review /sdlc:done; /sdlc:status shows where a
change stands. Gates and drive mode: `.sdlc/config.json`.
