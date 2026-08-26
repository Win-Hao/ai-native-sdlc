---
id: <NNNN-slug>
stage: build
status: draft              # draft | approved | implemented
from_spec: ./spec.md
approved_by: <name>
created: <YYYY-MM-DD>
---

# Plan: <标题> (from spec.md <YYYY-MM-DD>)

## Files that change
<逐个列出路径，标注 new / modify / delete。不要写"相关文件"。>

- `path/to/file.ts` (new) — <职责>
- `path/to/other.py` (modify) — <改什么>

## Order of work
1. <第一步。每步是一个竖切片：单独可演示，一个会话能做完。>
2. <第二步。>
3. <第三步。>

## Risks
<这个改动可能弄坏什么。哪一步风险最大。>

## Alternatives not taken
<考虑过但没选的方案，以及否决理由。审问计划时这一节最容易暴露问题。>

## Proof
<怎么证明做对了，从 spec.md 的 Testing decisions 写下来：约定接缝上的测试文件名、命令、期望输出、截图对比对象。>

- `tests/test_x.py` 覆盖 <哪些情况>
- `make test` 全绿
- 截图与 `design/mock-x.png` 一致

## Deviations
<实现过程中偏离计划时，在同一个 commit 里回填这里。为空表示未偏离。>
