# AI-Native SDLC

把 [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
做成一套 Claude Code 工具：**14 条命令、3 个 agent、一套产物模板，外加可选的闸门和可选的闭环驱动**。
命令随时打，打了就把产物写进 `sdlc/<id>/`；中间怎么开发不管。要 playbook 里"闭环自己跑"的
end state，拧一个开关。

```
.claude-plugin/marketplace.json   分发入口
sdlc/                             Claude Code 插件（skills / agents / hooks / templates / presets）
template/                         纯文件层，不依赖 Claude Code，直接拷进仓库
docs/                             原文存档（md + html）
```

## 装

```bash
claude plugin marketplace add ./            # 本地路径必须以 ./ 开头
# 或： claude plugin marketplace add Win-Hao/ai-native-sdlc
claude plugin install sdlc@ai-native-sdlc
```

依赖 `jq`（macOS 15+ 自带；其他系统 `brew install jq` / `apt install jq`）。缺了它闸门会
**拒绝一切编辑并提示安装**，而不是静默放行。

## 用

```
cd <你的项目> && claude
/sdlc:init          # 一次：模板语言、闸门级别、drive（默认 off）、CLAUDE.md 里的指针块
/sdlc:intent        # 采访 → sdlc/0001-xxx/intent.md
/sdlc:spec          # 有 intent 读 intent，没有就综合当前对话 → spec.md
/sdlc:plan          # plan mode 起草，接受即批准 → plan.md
/sdlc:build [tdd]   # 按 plan 实现；tdd = 每个切片先红后绿
/sdlc:fix           # 修 bug：反馈闭环 → 红测试 → 锁 → 修
/sdlc:verify        # 跑 build/test/lint，对照 Proof，独立 agent 复核
/sdlc:review        # REVIEW.md 三遍 findings
/sdlc:done          # 关闭变更
/sdlc:status        # 这个变更走到哪了
```

不跑 `/sdlc:init` 也能用（默认 `sdlc/` + 插件模板）；init 是给闸门、模板和驱动做配置。

| 命令 | 读什么 | 产出 |
|---|---|---|
| `/sdlc:intent` | 你的话；工单/告警来的先验证主张，再查 `sdlc/` 里有没有同类变更 | `intent.md`：问题、期望结果、影响面、约束、open questions、out of scope |
| `/sdlc:spec` | `intent.md`（没有就综合对话）+ 组织 skills + `CONTEXT.md` / ADR | `spec.md`：需求表（带验收）、设计决策（不写路径）、测试接缝、政策应用、**flagged concerns** |
| `/sdlc:plan` | `spec.md` 或 `intent.md`，加真实代码 | `plan.md`：改哪些文件、顺序（竖切片）、风险、否决的方案、Proof |
| `/sdlc:build [tdd]` | `plan.md` | diff；偏离计划时同一提交回填 Deviations；`tdd` = 每个切片红测试单独提交 → 锁 → 绿 |
| `/sdlc:fix` | 你说的症状 | 能变红的反馈闭环 → 最小化 → 假设 → 失败测试单独提交 → 锁 → 修 → 清扫 |
| `/sdlc:verify` | `plan.md` 的 Proof | 原始 build/test/lint 输出、逐条 Proof、`sdlc-verifier` 独立复核 |
| `/sdlc:review` | `REVIEW.md` + spec + plan | bugs / security / compliance 三遍 findings + 机器可读 tally |
| `/sdlc:done` | — | `intent.md` 记 `closed:` / `outcome:`，清空 `.sdlc/current` |
| `/sdlc:gate` | `.sdlc/config.json` | 审计 / 加闸门 / 证明闸门会响 |
| `/sdlc:evals` | 真实任务、事故 | `evals/*.json` + CI 门槛 |
| `/sdlc:watch` | 生产指标 | `bands.yaml`；越界自动写回新 `intent.md` |
| `/sdlc:customize` | — | 改 pipeline、覆盖模板 |

三个 agent 由命令调用：`sdlc-plan-critic`（审问 plan）、`sdlc-verifier`（干净上下文里跑一遍）、
`sdlc-reviewer`（三遍 review）。

## 产物怎么管

```
sdlc/0001-claims-status/intent.md   status: draft → accepted | rejected
                        spec.md     status: draft → accepted
                        plan.md     status: draft → approved → implemented
.sdlc/current                       当前变更 id
```

- 状态在 frontmatter 的 `status:` 里，是**你的决定**：直接改文件，或在对话里说一句"接受"，agent 替你改
- 每个阶段以一次提交结束（`intent(0001): …` / `spec(0001): …` / `plan(0001): …`），git 历史就是审计轨迹
- 目录不删不归档；`/sdlc:done` 写回 `closed:`，之后 `/sdlc:intent` 会查历史，避免同一需求反复开
- 模板：插件默认英文；`/sdlc:init` 可装中文占位版到 `.sdlc/templates/`（它覆盖插件的）。标题和 `status:` 值保持英文，脚本只认它们
- `template/sdlc/0000-example-claims-status/` 是一份完整走通的范例，先读它

## 闸门（可选，hook 实现）

| level | 开着的 | 什么时候升 |
|---|---|---|
| `minimal` | irreversible（`rm -rf /`、force push 等，问一句）、production_gate（生产部署需 `SDLC_RELEASE_APPROVAL`） | 第 1 周 |
| `standard` | + test_lock（修 bug 期间测试文件只读）、protected_paths（生成代码、迁移、CI 配置） | plan.md 和测试先行真的在用之后 |
| `full` | + plan_sync（提交里有 plan 没写的文件就问一句） | 每次实现前都有人读 plan.md 之后 |

`/sdlc:init` 时选，`/sdlc:gate` 随时升。没跑过 init 的仓库不受影响——所有 hook 直接 exit 0。
`scripts/selftest.sh` 是闸门自己的测试。

## 驱动（可选）

`.sdlc/config.json` → `drive`：

| 值 | 行为 |
|---|---|
| `off`（默认） | agent 只响应命令；CLAUDE.md 里的 `## SDLC` 指针块告诉它产物和命令在哪 |
| `suggest` | 你提新需求时它说一句"这个可以 `/sdlc:intent` 记一下"，然后照你说的做；产物落地后提一句通常的下一步 |
| `auto` | playbook 的 end state：agent 自己进 intent、自己提议下一阶段、没批准的 plan 不写代码、在每道闸门停下等你。流程由 `pipeline` 定（`full` / `lean` / `regulated`、`tdd` = build 跑 `/sdlc:build tdd`，可加自定义阶段） |

原文的话："First, you prompt each step by hand, with the end state being a loop in which each accepted
artifact fires the next gate." `off` 是 by hand，`auto` 是 end state，同一套东西。

## 改成自己的

| 改什么 | 放哪 | 覆盖谁 |
|---|---|---|
| 产物模板 | `.sdlc/templates/*.md` | 插件的 `templates/` |
| 组织政策（安全、品牌、API 规范） | `.claude/skills/<name>/SKILL.md` | 无——spec 阶段作为约束加载 |
| 阶段流程（仅 drive 用） | `.sdlc/config.json` → `pipeline` | 内置四种 |
| 闸门 | `.sdlc/config.json` → `gates` | preset |

加一个自定义阶段 = 写一个 skill + 加一条 pipeline 配置 + 一个模板，见 `/sdlc:customize`。

## 不用 Claude Code

`cp -r template/. your-repo/` 拿到 `CLAUDE.md`、`REVIEW.md`、闸门配置、eval 框架、中文模板和范例产物链。
详见 [ADOPTING.md](template/ADOPTING.md)。

## 设计上的一句话

流程走 skills，硬约束走 hooks，独立检查走 agents，仓库常识走 CLAUDE.md——文章的判据是
"skill 让违规罕见，hook 让违规几乎不可能"。闸门和驱动是两件事：闸门只对具体危险动作说不，
驱动才是推着你走阶段；所以闸门可以开着而驱动关着。

几条规则借自 [mattpocock/skills](https://github.com/mattpocock/skills)：spec 先定测试接缝、只写决策不写路径
（`to-spec`）；采访按"前沿"一轮轮问、每题附推荐答案（`grilling`）；难 bug 先造 tight 的反馈闭环再提假设
（`diagnosing-bugs`）；红绿循环一次一个切片、不横切（`tdd`）；耐久决策写 ADR（`domain-modeling`）；
政策所有者不在场时生成问卷（`to-questionnaire`）；告警和工单先验证主张、被拒的留档（`triage`）；
命令是工具箱、产物落文件、流程不管（整个仓库的形态）。
