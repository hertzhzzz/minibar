# MiniBar 开发交接文档 (Handoff Document)

> **当前阶段**：Ticket 1–5 已全部构建完成并通过单元测试（33/33 tests passed）。Ticket 5 已提交到本地 `main`（`a5e4ff4`），**尚未推送到 origin**，因此 GitHub Issue #5 仍为 Open。
> **下一阶段目标**：启动 **Ticket 6 (Issue #6): Launch at Login & Release Polish**。

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
  - Apple Swift 6.4 (Xcode 27.0)。
  - 测试命令：`swift test`
  - 构建 Release：`swift build -c release`
- **系统权限实测**：
  - `AXIsProcessTrusted()` (辅助功能 Accessibility)：**已开启 (True)**
  - `CGPreflightScreenCaptureAccess()` (屏幕录制 Screen Recording)：**已开启 (True)**
- **系统硬性限制（核心事实）**：
  - WindowServer 硬编码锁定系统时钟 `Clock` 与控制中心 `BentoBox`，**禁止移动或隐藏**（必须保留在顶栏最右侧，详见 `docs/adr/0004-immovable-system-items-boundary.md`）。
  - 第三方应用图标及系统 `Battery`、`WiFi` 支持通过 `⌘ + Drag` 跨越推挤分隔符进行收纳与隐藏。
  - 核心推挤机制：折叠时设置 `dividerItem.length = 10,000 pt`，展开重排时恢复 `8 pt`。

---

## 3. 核心架构与已实现模块
1. **推挤拓扑与控制项**：
   - `StatusItemCoordinator.swift` & `NSStatusBarInstaller.swift`：管理 MiniBar 的 Control Item 与 Divider Item（10,000pt 推挤）。
   - Control Item 点击时先展开 Divider（8pt）再 `show()`，以便 pin 分类对着真实布局扫描；Popover 关闭后再折叠。
2. **窗口扫描与高清截图**：
   - `MenuBarScanner.swift` & `StatusItemWindow.swift`：扫描 `layer == 25` 窗口，排除自身 PID，区分可移动项与时钟/控制中心不可移动项。
   - `scanOwnStatusWindows()` 用于定位 Divider Item（自身窗口中最左侧）。
   - `CGImage+AlphaTrim.swift`：基于 32 位 RGBA 像素矩阵遍历裁剪 Alpha > 12 的透明边框。
   - `SystemWindowImageCapturer`：通过 `dlsym` 绕过 macOS 15 SDK 对 `CGWindowListCreateImage` 的弃用限制，抓取 Retina 2x 高清位图，并配合 `IconCache` 内存缓存。
3. **SwiftUI Popover 浮层**：
   - `PopoverGridView.swift`：4 列磨砂玻璃网格，Tooltip、Arrange Mode 开关、蓝/灰 pin 徽标、拖拽 Loading。
   - `PopoverCoordinator.swift`：管理 `NSPopover` 瞬态生命周期；普通点击走 Click Proxy 并关闭；整理模式点击走 ItemArranger 并保持打开。
4. **双轨点击代理服务**：
   - `ClickProxyService.swift`：Track 1 Accessibility，Track 2 `MenuBarUpdateMask` + 瞬态 Divider 8pt + `0x33` CGEvent。
5. **整理模式与拖拽切换**：
   - `ItemLayout.swift`：pin 分类、拖拽目标 X、网格过滤纯函数。
   - `ItemArranger.swift`：合成 `⌘ + Drag` 穿越 Divider Item；0.3s 单操作防抖；`busyWindowID` Loading 状态。
   - 不可移动项（Clock / BentoBox）拒绝拖拽。

---

## 4. 任务清单与当前进度 (Tickets Tracking)

所有任务已同步发布在 GitHub Issues：

| 编号 | 任务标题 | 状态 | 依赖 (Blocked By) | Commit / Issue |
| :--- | :--- | :--- | :--- | :--- |
| **#1** | **Ticket 1: App Scaffold, Status Items & Spacer Push** | ✅ **Done** | 无 | Commit `0631def` ([#1](https://github.com/hertzhzzz/minibar/issues/1)) |
| **#2** | **Ticket 2: Window Scanner & Retina Icon Capture** | ✅ **Done** | #1 | Commit `ae6fe0b` ([#2](https://github.com/hertzhzzz/minibar/issues/2)) |
| **#3** | **Ticket 3: SwiftUI Popover Grid & Lifecycle** | ✅ **Done** | #2 | Commit `5dd199a` ([#3](https://github.com/hertzhzzz/minibar/issues/3)) |
| **#4** | **Ticket 4: Double-Track Click Proxy Service** | ✅ **Done** | #3 | Commit `fbcfb4f` ([#4](https://github.com/hertzhzzz/minibar/issues/4)) |
| **#5** | **Ticket 5: Arrange Mode & Drag-to-Toggle** | ✅ **Done（本地未推送）** | #4 | Commit `a5e4ff4` ([#5](https://github.com/hertzhzzz/minibar/issues/5)) |
| **#6** | **Ticket 6: Launch at Login & Release Polish** | 🚀 **Ready for Agent (当前前沿)** | #5 (已解封，待 push 后 GitHub 关闭 #5) | [#6](https://github.com/hertzhzzz/minibar/issues/6) |

---

## 5. 下一个会话执行指引 (Next Session Action Plan)

接手本项目的 Agent 应执行以下步骤：
1. **先确认是否 push**：本地 `main` 比 `origin/main` 超前 1 个提交（`a5e4ff4`）。用户确认后 `git push`，GitHub 才会因 `closes #5` 关闭 Issue。
2. **领取前沿任务**：针对 [Issue #6](https://github.com/hertzhzzz/minibar/issues/6) (Launch at Login & Release Polish) 开展工作。
3. **Ticket 5 实机风险（未在单测覆盖）**：
   - 合成 ⌘+Drag 目前是 down → 一次 dragged → up，真实菜单栏重排可能需要连续路径。
   - `CGWindow` 原点在左上，`CGEvent` 在左下；与 Ticket 4 Click Proxy 一致，实机可能偏 Y。
   - 展开后立刻扫描时，WindowServer 可能尚未把 Divider 写成 8pt。
4. **不要提交** `.notes/`（本地项目记忆）。

---

## 6. Suggested Skills (建议调用的技能)
- **`handon`**：新会话启动或 `/clear` 后，自动重新加载本交接文档与上下文。
- **`implement`**：领取 Ticket 6 后按 TDD 实现开机自启与发布打磨。
- **`code-review`**：合入前对 Ticket 6 的 `SMAppService` 与发布配置做双轴审查。
