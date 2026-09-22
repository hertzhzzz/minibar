# 关于构建 `handon` 技能的可行性与生态调研报告

> **调研目标**：针对当前 AI 编程智能体生态（以 `mattpocock/skills`、Claude Code 插件生态及 Pi Harness 为主要来源），考察“会话交接（Handoff）”与“冷启动接手（Handon / Resume）”的行业一手实现，评估是否应该制作一个独立的 `handon` 技能以支撑快速启动任务。
> **调研归档路径**：`plan/research/HANDON-SKILL-RESEARCH.md`

---

## 一、调研对象与第一手来源（Primary Sources）

1. **`mattpocock/skills` 官方仓库**：
   - 生产环境技能：[`skills/productivity/handoff/SKILL.md`](https://github.com/mattpocock/skills/blob/main/skills/productivity/handoff/SKILL.md)
   - 试验中技能：[`skills/in-progress/claude-handoff/SKILL.md`](https://github.com/mattpocock/skills/blob/main/skills/in-progress/claude-handoff/SKILL.md)
   - 编排规范：`skills/engineering/ask-matt/SKILL.md` 及 `PHASE-BOUNDARIES.md`
2. **社区与生产级 Claude Code / Agent 技能实践**：
   - `haacked/dotfiles` (`ai/skills/handoff/SKILL.md`)
   - `ostikwhy-blip/claude-code-handoff-skill`
   - `florianbuetow/claude-code/plugins/onboarding`
   - `frohsinnllc/claude-code-onboard-repo`

---

## 二、一手来源事实分析（Key Findings）

### 1. Matt Pocock 官方体系中的断层与不对称性
- **事实 1**：在 `mattpocock/skills` 仓库的 `engineering`、`productivity` 与 `in-progress` 分类中，**完全没有名为 `handon` 或 `pickup` 的技能**。
- **事实 2**：现有的 `handoff` 技能仅负责单向的**“导出（Export）”**：
  > *"Compact the current conversation into a handoff document for another agent to pick up."*
  它定义了如何写入临时文件、建议后续技能、规避重复，但**未定义新 Agent 如何自动化读取和启动**。
- **事实 3**：Matt 在实验分支中开发了 `claude-handoff`（`skills/in-progress/claude-handoff/SKILL.md`），其实质是通过 CLI 管道直接启动后台子 Agent：
  ```bash
  claude --bg --name "<descriptive name>" "<handoff summary>"
  ```
  该方案受限于特定的 Claude Code 原生命令，无法跨 Harness（如在 Pi 或通用终端中），且无法在断点重启（如用户第二天重新打开终端）时使用。

### 2. 开源 Agent 生态中的两大成熟演进流派

在更广泛的 Agent 开发者生态中，解决会话断点和接班问题主要演化为两种架构模式：

| 模式 | 代表方案 | 机制与工作流 | 适用场景与优劣 |
| :--- | :--- | :--- | :--- |
| **模式 A：单技能双向模式（Unified Handoff）** | `haacked/dotfiles` | 同一个 `/handoff` 技能通过参数分支：<br>1. 无参：生成交接文档 `handoff.md`<br>2. `/handoff resume`：读取并核对 Git 状态后接手 | **优点**：只有一个技能名称。<br>**缺点**：语义上 `handoff` 意为“交出”，用“交出”来表达“接手（Pick up）”存在认知违和。 |
| **模式 B：对称成对模式（Handoff & Handon / Onboarding）** | `claude-code-onboard-repo` | 明确拆分为两个对等动作：<br>1. 会话结束前调用 `/handoff`<br>2. 新会话启动时输入 `/handon` 或 `/onboard` | **优点**：符合人类工程团队的“交班（Handoff）- 接班（Handon）”心智模型；冷启动时只需 1 个斜杠命令，零输入摩擦。<br>**缺点**：需要额外维护一个技能文件。 |

---

## 三、`handon` 技能的必要性与核心价值（Why We Should Build It）

对于在同一机器、多会话（跨天、跨 Ticket、执行 `/clear` 之后）上运作的工程项目，构建 `handon` 技能具有压倒性的优势：

### 1. 解决人类“胶水提示词”的疲劳与遗漏
- **现状**：每次进入新会话，人类用户必须手动拼凑：`@handoff.md 请先阅读这个，再读取 CONTEXT.md，检查 git status，然后领取 Issue #1 开始开发……`
- **引入 `handon` 后的体验**：用户只需敲入 `/handon`，Agent 即刻执行固化的预检脚本（Pre-flight Checklist）。

### 2. 实现状态与物理事实对齐（Snapshot vs Reality Reconciliation）
参考生产级接手技能，优秀的接班不仅是“读一段 Markdown”，而是**拿文档中的快照去验证当前代码库的真实状态**：
- 检查当前 Git 分支是否正确。
- 检查 HEAD Commit 是否与交接时一致（若不一致，提示用户有外部改动）。
- 检查工作区是否有未暂存脏文件。
- 验证本地特定的工具链与环境变量（如 macOS 上的 `DEVELOPER_DIR`）。

### 3. 自动化任务前沿计算（Automated Frontier Detection）
`handon` 可以通过本地 `gh issue list` 或扫描 Ticket 文件，自动识别所有依赖已就绪（All blockers resolved）的下一个 Ticket，无需人类查阅后再告知。

---

## 四、`handon` 技能的推荐规格与设计蓝图

基于本次调研提炼的最佳实践，建议在项目中构建如下轻量规范的 `handon/SKILL.md`：

```yaml
---
name: handon
description: Pick up an in-progress project from handoff.md, verify local environment and git status, and queue the next frontier ticket.
disable-model-invocation: true
---

# Handon (Agent Onboarding & Task Pickup)

Use this skill when starting a fresh session in an ongoing project to restore context without human prompting.

## Execution Steps

1. **Read Core Context & Handoff**:
   - Read `<project-root>/handoff.md` for in-flight state, recent decisions, and blockers.
   - Silently ingest `<project-root>/CONTEXT.md` (domain glossary) and any active ADRs in `docs/adr/`.
2. **Reconcile with Git Reality**:
   - Run `git status` and `git log -1 --oneline`.
   - Verify working tree cleanliness. If dirty or diverged from handoff, alert the user before proceeding.
3. **Verify Environment Prerequisites**:
   - Check critical project toolchains, SDK paths, and required environment variables (e.g. `DEVELOPER_DIR` for Swift).
4. **Detect the Frontier Ticket**:
   - Query the issue tracker (e.g. `gh issue list --state open` or local ticket files) to locate the highest-priority ticket whose blockers are resolved (`ready-for-agent`).
5. **Present the Onboarding Brief**:
   - Output a concise, 10-second readable brief:
     - **Project**: [Name & Status]
     - **Git State**: [Branch & commit]
     - **Frontier Task**: [Ticket # & Title]
   - Offer a single confirmation gate: *"Ready to invoke `/implement` on [Ticket #]. Proceed?"*
```

---

## 五、结论与行动建议

1. **明确结论**：**应当制作 `handon` 技能**。它是连接 `handoff` 与 `implement` 之间缺失的闭环齿轮。
2. **落地路径**：
   - 在 `/Users/mark/Projects/.agents/skills/handon/SKILL.md` 创建定义。
   - 在 `/Users/mark/Projects/.pi/skills/handon` 建立软链接，使其对所有项目生效。
   - 在 `ask-matt/SKILL.md` 的流程图谱中，将其标注为在 `/clear` 或跨会话时接入 `/implement` 的标准入口。
