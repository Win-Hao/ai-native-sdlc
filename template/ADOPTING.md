# 把 AI-native SDLC 套到一个仓库上

## 30 秒版本

```bash
claude plugin marketplace add ./
claude plugin install sdlc@ai-native-sdlc
cd <你的项目> && claude
/sdlc:init          # 模板语言、闸门级别、drive（默认 off）、CLAUDE.md 指针块；写之前预览
/sdlc:intent        # 开始第一个变更
```

前提：`jq` 在 PATH 上（macOS 15+ 自带；否则 `brew install jq` / `apt install jq`）。
缺了它闸门会拒绝一切编辑并提示安装，不会静默放行。

`/sdlc:init` 之后 `/sdlc:init doctor` 会告诉你哪些闸门是空的（匹配不到任何文件的 glob
等于没有闸门）。**不要跳过这一步**——套用别人的配置最常见的死法就是 glob 不匹配，
于是闸门拦错东西，然后所有人把它关掉。

## 不用 Claude Code 也能用的部分

`template/` 里的文件是纯文本，跟工具无关，直接拷进你的仓库：

```bash
cp -r template/. /path/to/your-repo/    # 注意是 `.` 不是 `*`，要带上 .sdlc/ .github/
```

| 文件 | 作用 |
|---|---|
| `CLAUDE.md` | 骨架。**填完必须砍到一页以内** |
| `REVIEW.md` | review 政策，三遍 passes + 什么算 Important |
| `.sdlc/config.json` | 闸门配置（generic preset，需要按仓库改） |
| `.sdlc/templates/` | **中文占位版**产物模板（intent / spec / plan / CLAUDE.md / bands.yaml）。插件本身是英文的，有这个目录就优先用中文版；要英文就删掉它 |
| `sdlc/0000-example-claims-status/` | 完整走通的产物链范例：intent → spec → plan |
| `evals/` | eval 格式 + 一个能跑的 checker |
| `.github/workflows/agent-evals.yml` | 配置变更的回归门槛 |

那个 example 目录是这套模板里最该先读的东西——它把三份产物之间的引用关系
（requirement 引 intent、plan 的 Proof 对应 spec 的 acceptance、flagged concern 怎么被
resolve）写完整了。看一遍比读十页说明有用。跑通之后删掉它。

## 采纳顺序：不要一次全开

原文的说法是"从 clay play 开始"——没有任何前置依赖的那几个。按这个顺序：

### 第 1 周（三件事，都无前置依赖）——闸门 `minimal`，`drive: off`，命令自己打
1. **`CLAUDE.md`** — `/init` 生成，砍到一页，逐条验证命令真的能跑
2. **反馈闭环** — 收敛成一条命令，写进 `CLAUDE.md` 并附健康输出样例
3. **`intent.md`** — `/sdlc:intent`，哪怕只有你一个人

这三件做完，agent 的输出质量已经变了，后面的都是在这个基础上加约束。

### 第 2–4 周——升到 `standard`
4. **plan mode 成为默认起手式** — `/sdlc:plan`，任何非平凡改动先出 plan.md
5. **打开 test_lock + protected_paths 闸门** — 升到级别 `standard`，`/sdlc:gate audit` 看现状
6. **`REVIEW.md` + `/sdlc:review`** — 三遍 passes

### 第 2 个月起——闸门 `full`，`drive: suggest` 或 `auto`
7. **skills** — 每条反复要求却总被忘记的规范写一个
8. **hooks 作为审批闸门** — `/sdlc:gate add`，把组织自己的审批（变更单、迁移）表达成闸门；`plan_sync` 也在这一步开
9. **evals** — 攒够 20 个真实任务再进 CI，不然门槛是噪音
10. **`/sdlc:watch`** — 挑一个指标闭环，rollback 路径先演练过再开 3σ
11. **`drive: auto`** — 命令用顺了、闸门都在，再让 agent 自己推阶段；这是原文的 end state，不是起点

### 判断该不该往下走
每一步只在**上一步的产物开始被真正使用**之后才加。plan.md 没人看就上 plan_sync 闸门，
只会得到一个每次 commit 都被绕过的提示框。

## 三个最容易做错的地方

**1. `CLAUDE.md` 写成填空题然后原样提交。**
模板给的是骨架不是内容。一份 200 行的 `CLAUDE.md` 每次会话全量读入，里面 180 行是
你没删的占位符。硬性标准：一页以内，每条命令都实际跑过，"Things Claude gets wrong"
一节留空——它应该由真实错误长出来，不是预先编出来。

**2. 闸门配置照抄不校验。**
`.sdlc/config.json` 的 preset 是猜的。你的测试目录可能不叫 `tests/`，你的生成代码可能
不在 `generated/`。跑 `/sdlc:init doctor`，把 WARN 清干净。

**3. 把 intent 和 spec 混着写。**
`/sdlc:intent` 阶段不讨论实现是硬规则。一旦在 intent 里写了"用 Redis 缓存"，后面
spec 就不再是设计，而是给既定实现补理由。这两份文件分开的全部价值就在这里。

## 一个人用需要减配吗

不需要。六个阶段在个人项目上都成立，减掉的只是组织协作的部分：

| 原文的东西 | 一个人时 |
|---|---|
| product owner 审 intent、tech lead 审 plan | 都是你，但**仍然分两次看**——写完隔一会儿再审 |
| policy owner 拍板 flagged concerns | 你自己拍，但要写下结论和理由 |
| 分支保护 + code owner 审批 | 至少保留生产闸门和不可逆动作闸门 |
| managed settings / MDM / 合规 API | 跳过 |

真正不能省的是**产物链**和**闸门**。省掉产物链，六个阶段就退化成一次长对话；
省掉闸门，agent 就能改测试、改生成代码、直接部署。
