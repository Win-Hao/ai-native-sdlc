# AI-Native SDLC for Claude Code

中文 · [English](README.en.md)

把 [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) 的六个阶段做成
Claude Code 插件：**14 条命令、3 个 agent、一套产物模板**。命令随时打，打了就把产物写进
`sdlc/<id>/`；闸门（hook）和自动驱动都是可选项，默认关。

## 安装

```bash
claude plugin marketplace add Win-Hao/ai-native-sdlc
claude plugin install sdlc@ai-native-sdlc
```

依赖 `jq`（macOS 15+ 自带；其他系统 `brew install jq` / `apt install jq`）。

## 快速开始

```
cd <你的项目> && claude
/sdlc:init
```

`/sdlc:init` 会问四件事，每题带推荐答案：模板语言（英文 / 中文）、闸门级别（推荐 `minimal`）、
是否让 agent 自动推进阶段（推荐 `off`）、允许它写哪些文件。配置先预览再落地。
不跑 init 也能直接用命令（默认 `sdlc/` 目录 + 插件模板）。

### 做一个新功能

```
/sdlc:intent   采访你，写 intent.md；你说"接受"即通过
/sdlc:spec     读 intent，加载组织 skills，先和你确认测试接缝；flagged concerns 由你拍板
/sdlc:plan     进 plan mode 起草，critic agent 审问，展示给你；接受即批准
/sdlc:build    按 plan 实现（加 tdd 则每个切片先红后绿）
/sdlc:verify   跑 build/test/lint，逐条对照 Proof，独立 agent 复核
/sdlc:review   bugs / security / compliance 三遍 findings；你 merge
/sdlc:done     关闭变更
```

小项目可以跳过 spec；也可以直接 `/sdlc:plan` 从对话起草，它会自己分配 id。

### 修一个 bug

```
/sdlc:fix      造能变红的反馈闭环 → 最小化 → 假设 → 失败测试单独提交 → 锁测试 → 修 → 清扫
```

或者直接说"这里坏了"，agent 会自己用这套做法。不需要 intent 和 plan。

### 小改动

直接说，agent 直接改。除非碰到 `rm -rf /`、force push、生产部署这类闸门，没有任何东西拦你。

## 命令参考

| 命令 | 读什么 | 产出 |
|---|---|---|
| `/sdlc:init` | 仓库现状 | `.sdlc/config.json`、`CLAUDE.md` 里的 `## SDLC` 指针块、`REVIEW.md` |
| `/sdlc:intent` | 你的话；工单/告警来的先验证主张，再查 `sdlc/` 里有无同类变更 | `intent.md`：问题、期望结果、影响面、约束、open questions、out of scope |
| `/sdlc:spec` | `intent.md`（没有就综合对话）+ `.claude/skills/` 政策 + `CONTEXT.md` / ADR | `spec.md`：需求表（带验收）、设计决策（不写路径）、测试接缝、政策应用、flagged concerns |
| `/sdlc:plan` | `spec.md` 或 `intent.md`，加真实代码 | `plan.md`：改哪些文件、顺序、风险、否决的方案、Proof |
| `/sdlc:build [tdd]` | `plan.md` | diff；偏离计划时同一提交回填 Deviations；`tdd` = 每片红测试单独提交 → 锁 → 绿 |
| `/sdlc:fix` | 你描述的症状 | 失败测试（提交在修复之前）+ 修复 |
| `/sdlc:verify` | `plan.md` 的 Proof | 原始 build/test/lint 输出、逐条 Proof、`sdlc-verifier` 复核 |
| `/sdlc:review` | `REVIEW.md` + spec + plan + 以前的 `findings.md` | `findings.md`：三遍 findings、每条带 class、同类第几次出现；第 2 次写进 CLAUDE.md，第 3 次起提议 hook 或 skill |
| `/sdlc:done` | — | `intent.md` 记 `closed:` / `outcome:`，清空 `.sdlc/current` |
| `/sdlc:status` | `sdlc/<id>/` | 这个变更走到哪、通常下一步 |
| `/sdlc:gate` | `.sdlc/config.json` | 审计 / 加闸门 / 证明闸门会响 |
| `/sdlc:evals` | 真实任务、事故 | `evals/*.json` + CI 门槛 |
| `/sdlc:watch` | 生产指标 | `bands.yaml`；越界自动写回新 `intent.md` |
| `/sdlc:customize` | — | 改 pipeline、覆盖模板 |

agent（由命令调用）：`sdlc-plan-critic` 审问 plan、`sdlc-verifier` 在干净上下文里跑一遍、`sdlc-reviewer` 三遍 review。

## 产物与状态

```
sdlc/0001-claims-status/
  intent.md    status: draft → accepted | rejected
  spec.md      status: draft → accepted
  plan.md      status: draft → approved → implemented
  findings.md  review 结果 + tally；同类 finding 跨变更计数
.sdlc/current  当前变更 id
```

- `status:` 是你的决定：直接改文件，或在对话里说一句，agent 替你改
- 每个阶段以一次提交结束（`intent(0001): …`、`spec(0001): …`、`plan(0001): …`），git 历史就是审计轨迹
- 目录不删不归档；`/sdlc:done` 写回 `closed:`，之后 `/sdlc:intent` 会查历史避免重复
- `template/sdlc/0000-example-claims-status/` 是一份完整的范例产物链

## 闸门（可选）

| 级别 | 开着的闸门 |
|---|---|
| `minimal` | 不可逆命令（`rm -rf /`、force push 等）问一句；生产部署需要 `SDLC_RELEASE_APPROVAL=<谁批的>` |
| `standard` | + 修 bug 期间测试文件只读（`.sdlc/lock-tests` 存在时）；生成代码、迁移、CI 配置禁止 agent 改 |
| `full` | + 提交里有 plan 没写的文件就问一句（`CLAUDE.md`、`REVIEW.md`、`evals/`、`.claude/` 除外） |

`/sdlc:init` 时选，`/sdlc:gate` 随时升。没跑过 init 的仓库不受影响。

## 自动驱动（可选）

`.sdlc/config.json` → `drive`：

| 值 | 行为 |
|---|---|
| `off`（默认） | agent 只响应命令 |
| `suggest` | 你提新需求时它提一句"可以 `/sdlc:intent` 记一下"，然后照你说的做 |
| `auto` | agent 自己进 intent、提议下一阶段、没批准的 plan 不写代码、在每道闸门停下等你。流程由 `pipeline` 定：`full` / `lean` / `regulated` / `tdd`，可加自定义阶段 |

## 自定义

| 改什么 | 放哪 |
|---|---|
| 产物模板 | `.sdlc/templates/*.md`（覆盖插件的；init 可装中文版） |
| 组织政策（安全、品牌、API 规范） | `.claude/skills/<name>/SKILL.md`，spec 阶段作为约束加载 |
| 阶段流程（drive 用） | `.sdlc/config.json` → `pipeline` |
| 闸门 | `.sdlc/config.json` → `gates` |

加自定义阶段 = 一个 skill + 一条 pipeline 配置 + 一个模板，见 `/sdlc:customize`。

## 不用 Claude Code

`cp -r template/. your-repo/` 拿到 `CLAUDE.md`、`REVIEW.md`、闸门配置、eval 框架、中文模板和范例产物链。
详见 [ADOPTING.md](template/ADOPTING.md)。

## 目录

```
.claude-plugin/marketplace.json   分发入口
sdlc/                             插件：skills / agents / hooks / scripts / templates / presets / pipelines
template/                         纯文件层
docs/                             playbook 原文存档
```

## 参考

[The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)；spec、采访、修 bug、TDD 的做法参考了
[mattpocock/skills](https://github.com/mattpocock/skills)。
