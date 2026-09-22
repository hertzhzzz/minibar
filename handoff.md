# MiniBar 开发交接文档 (Handoff Document)

> **当前阶段**：Ticket 1 已完成构建、测试并通过双轴审查，代码已合并并推送到 main 分支。
> **下一阶段目标**：启动 **Ticket 2 (Issue #2): Window Scanner & Retina Icon Capture**。

---

## 1. 项目基础信息与仓库
- **项目名称**：MiniBar
- **代码仓库**：[https://github.com/hertzhzzz/minibar](https://github.com/hertzhzzz/minibar)
- **本地项目绝对路径**：`/Users/mark/projects/minibar`
- **产品定位**：原生极简、低资源占用、无缝兼容 macOS 15 刘海屏的菜单栏图标整合与访问工具（类 iBar 浮层模式）。

---

## 2. 运行环境与实机实测基准
- **操作系统**：macOS 15.6.2 (Sequoia Darwin 25.6.0 arm64)
- **硬件环境**：Apple Silicon M2 MacBook Air (1470×956 Retina)，带物理刘海（Notch 占据 X: 646 ~ 825 pt）。
- **工具链配置**：
  - Apple Swift 6.4 (CommandLineTools)。
  - **重要提醒**：由于 Xcode 许可证未手动同意，运行 Swift 命令时需前缀或使用环境变量：
    ```bash
    DEVELOPER_DIR=/Library/Developer/CommandLineTools swift <command>
    ```
- **系统权限实测**：
  - `AXIsProcessTrusted()` (辅助功能 Accessibility)：**已开启 (True)**
  - `CGPreflightScreenCaptureAccess()` (屏幕录制 Screen Recording)：**已开启 (True)**
- **系统硬性限制（核心事实）**：
  - WindowServer 硬编码锁定系统时钟 `Clock` 与控制中心 `BentoBox`，**禁止移动或隐藏**（必须保留在顶栏最右侧）。
  - 第三方应用图标及系统 `Battery`、`WiFi` 支持通过 `⌘ + Drag` 跨越推挤分隔符进行收纳与隐藏。
  - 核心推挤机制：折叠时设置 `dividerItem.length = 10,000 pt`，展开重排时恢复 `8 pt`。

---

## 3. 项目文档索引
- **领域词汇表与概念模型**：`CONTEXT.md`
- **架构设计决策记录 (ADRs)**：`docs/adr/`
  - `0001-spacer-push-for-icon-hiding.md`
  - `0002-popover-grid-interface.md`
  - `0003-double-track-click-proxy.md`
  - `0004-immovable-system-items-boundary.md`
- **底层架构与技术调研**：`plan/research/RESEARCH.md`
- **系统产品功能规格书**：`plan/research/SPEC.md`

---

## 4. 任务清单与当前进度 (Tickets Tracking)

所有任务已同步发布为 GitHub Issues：

| 编号 | 任务标题 | 状态 | 依赖 (Blocked By) | Issue 链接 |
| :--- | :--- | :--- | :--- | :--- |
| **#1** | **Ticket 1: App Scaffold, Status Items & Spacer Push** | ✅ **Done (Commit `0631def`)** | 无 | [#1](https://github.com/hertzhzzz/minibar/issues/1) |
| **#2** | **Ticket 2: Window Scanner & Retina Icon Capture** | 🚀 **Ready for Agent (当前前沿)** | #1 (已解封) | [#2](https://github.com/hertzhzzz/minibar/issues/2) |
| **#3** | **Ticket 3: SwiftUI Popover Grid & Lifecycle** | 🔒 Blocked | #2 | [#3](https://github.com/hertzhzzz/minibar/issues/3) |
| **#4** | **Ticket 4: Double-Track Click Proxy Service** | 🔒 Blocked | #3 | [#4](https://github.com/hertzhzzz/minibar/issues/4) |
| **#5** | **Ticket 5: Arrange Mode & Drag-to-Toggle** | 🔒 Blocked | #4 | [#5](https://github.com/hertzhzzz/minibar/issues/5) |
| **#6** | **Ticket 6: Launch at Login & Release Polish** | 🔒 Blocked | #5 | [#6](https://github.com/hertzhzzz/minibar/issues/6) |

---

## 5. 下一个会话执行指引 (Next Session Action Plan)

接手本项目的 Agent 应执行以下步骤：
1. **领取前沿任务**：针对 [Issue #2](https://github.com/hertzhzzz/minibar/issues/2) (Window Scanner & Retina Icon Capture) 开展工作。
2. **实现范围**：
   - 编写 `MenuBarScanner` 获取 `layer == 25` 的状态栏窗口列表。
   - 过滤系统硬性锁定的不可移动项（Clock, BentoBox），保留第三方及可移动系统项（Battery, Wi-Fi）。
   - 编写纯函数 Alpha 边界裁切算法（RGBA 像素遍历，裁切掉透明边距），通过单元测试覆盖。
   - 使用 `CGWindowListCreateImage` 捕获 64×66 Retina 2x 图标。
3. **验证测试**：
   - 运行 `DYLD_LIBRARY_PATH=/Library/Developer/CommandLineTools/usr/lib/swift/host DEVELOPER_DIR=/Library/Developer/CommandLineTools swift test` 确保测试全部通过。
4. **代码审查与提交**：
   - 运行双轴审查并提交代码，关闭 Issue #2。

---

## 6. Suggested Skills (建议调用的技能)
- **`implement`**：用于抓取 Issue #1 并在干净的上下文窗口中驱动全流程实现。
- **`tdd`**：用于为状态栏推挤逻辑编写自动化测试用例。
- **`code-review`**：在代码合入前，对实现的 Diff 按照 Spec 规范和 macOS 原生标准进行代码审查。
