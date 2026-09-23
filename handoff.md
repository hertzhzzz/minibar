# MiniBar 开发交接文档 (Handoff Document)

> **当前阶段**：Ticket 1、Ticket 2、Ticket 3 与 Ticket 4 已全部构建完成并通过单元测试（19/19 tests passed），代码已全部合并并推送到 `main` 分支。
> **下一阶段目标**：启动 **Ticket 5 (Issue #5): Arrange Mode & Drag-to-Toggle**。

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
2. **窗口扫描与高清截图**：
   - `MenuBarScanner.swift` & `StatusItemWindow.swift`：扫描 `layer == 25` 窗口，排除自身 PID，区分可移动项与时钟/控制中心不可移动项。
   - `CGImage+AlphaTrim.swift`：基于 32 位 RGBA 像素矩阵遍历裁剪 Alpha > 12 的透明边框。
   - `SystemWindowImageCapturer`：通过 `dlsym` 绕过 macOS 15 SDK 对 `CGWindowListCreateImage` 的弃用限制，抓取 Retina 2x 高清位图，并配合 `IconCache` 内存缓存。
3. **SwiftUI Popover 浮层**：
   - `PopoverGridView.swift`：4 列磨砂玻璃网格，支持 Tooltip 悬停显示 App 名称与点击回调。
   - `PopoverCoordinator.swift`：管理 `NSPopover` 瞬态生命周期，锚定在 Control Item 下方，点击外部或 `Esc` 自动消失。
4. **双轨点击代理服务**：
   - `ClickProxyService.swift`：
     - **Track 1**：优先调用 `SystemAccessibilityPerformer`（`kAXPressAction` / `AXShowMenu`），零光标位移唤起微信、Amphetamine 等原生菜单。
     - **Track 2**：针对非标项保底使用 `MenuBarUpdateMask`（全屏无感一帧遮罩防闪烁）+ 瞬态恢复 Divider 8pt + 合成带 `0x33` 标记的 `CGEvent` 鼠标点击。
     - 点击触发后自动退出 Popover。

---

## 4. 任务清单与当前进度 (Tickets Tracking)

所有任务已同步发布在 GitHub Issues：

| 编号 | 任务标题 | 状态 | 依赖 (Blocked By) | Commit / Issue |
| :--- | :--- | :--- | :--- | :--- |
| **#1** | **Ticket 1: App Scaffold, Status Items & Spacer Push** | ✅ **Done** | 无 | Commit `0631def` ([#1](https://github.com/hertzhzzz/minibar/issues/1)) |
| **#2** | **Ticket 2: Window Scanner & Retina Icon Capture** | ✅ **Done** | #1 | Commit `ae6fe0b` ([#2](https://github.com/hertzhzzz/minibar/issues/2)) |
| **#3** | **Ticket 3: SwiftUI Popover Grid & Lifecycle** | ✅ **Done** | #2 | Commit `5dd199a` ([#3](https://github.com/hertzhzzz/minibar/issues/3)) |
| **#4** | **Ticket 4: Double-Track Click Proxy Service** | ✅ **Done** | #3 | Commit `fbcfb4f` ([#4](https://github.com/hertzhzzz/minibar/issues/4)) |
| **#5** | **Ticket 5: Arrange Mode & Drag-to-Toggle** | 🚀 **Ready for Agent (当前前沿)** | #4 (已解封) | [#5](https://github.com/hertzhzzz/minibar/issues/5) |
| **#6** | **Ticket 6: Launch at Login & Release Polish** | 🔒 Blocked | #5 | [#6](https://github.com/hertzhzzz/minibar/issues/6) |

---

## 5. 下一个会话执行指引 (Next Session Action Plan)

接手本项目的 Agent 应执行以下步骤：
1. **领取前沿任务**：针对 [Issue #5](https://github.com/hertzhzzz/minibar/issues/5) (Arrange Mode & Drag-to-Toggle) 开展工作。
2. **实现范围**：
   - 在 `PopoverGridView` 中加入“整理模式 (Arrange Mode)”切换开关。
   - 图标增加状态徽标指示（蓝点：常驻顶栏 Pinned；灰点：收纳抽屉 Unpinned）。
   - 实现 `ItemArranger`：点击图标时根据目标状态计算目标 X 坐标，通过 `CGEvent` 合成 `⌘ + Drag` 拖拽穿越 Divider Item 进行收纳/常驻切换。
   - 加入 0.3s 防抖保护与拖拽过程中的 Loading 反馈。
3. **验证测试**：
   - 运行 `swift test` 确保已有 19 个用例及新用例全部通过。
4. **代码审查与提交**：
   - 提交代码并关闭 Issue #5。

---

## 6. Suggested Skills (建议调用的技能)
- **`handon`**：新会话启动或 `/clear` 后，自动重新加载本交接文档与上下文。
- **`context-mode`**：在执行任何大输出命令、测试或构建时，使用 `ctx_batch_execute` / `ctx_execute` 保护上下文。
- **`code-review`**：在合入前对 Ticket 5 的拖拽算法与 UI 状态逻辑进行双轴审查。
