# MiniBar 开发交接文档 (Handoff Document)

> **当前阶段**：Ticket 1–6 已全部构建完成并通过单元测试（47/47 tests passed）。Ticket 5 已推送，GitHub Issue #5 已关闭。Ticket 6 已提交到 `main`（见下方 SHA）。
> **下一阶段目标**：无更多 GitHub Ticket。剩余工作为实机验收（开机自启系统授权、常驻内存 < 30MB、Divider 退出恢复）。

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
  - 测试命令：`swift test` 或 `make test`
  - 构建并运行 `.app`：`make run`（或 `scripts/run.sh`）
  - 构建 Release：`swift build -c release` / `make app`
- **系统权限实测**：
  - `AXIsProcessTrusted()` (辅助功能 Accessibility)：**已开启 (True)**
  - `CGPreflightScreenCaptureAccess()` (屏幕录制 Screen Recording)：**已开启 (True)**
  - `SMAppService.mainApp`（开机自启）：**需在实机 `.app` 内勾选**，首次可能弹出「登录项」授权。
- **系统硬性限制（核心事实）**：
  - WindowServer 硬编码锁定系统时钟 `Clock` 与控制中心 `BentoBox`，**禁止移动或隐藏**（必须保留在顶栏最右侧，详见 `docs/adr/0004-immovable-system-items-boundary.md`）。
  - 第三方应用图标及系统 `Battery`、`WiFi` 支持通过 `⌘ + Drag` 跨越推挤分隔符进行收纳与隐藏。
  - 核心推挤机制：折叠时设置 `dividerItem.length = 10,000 pt`，展开重排时恢复 `8 pt`。

---

## 3. 核心架构与已实现模块
1. **推挤拓扑与控制项**：
   - `StatusItemCoordinator.swift` & `NSStatusBarInstaller.swift`：管理 MiniBar 的 Control Item 与 Divider Item（10,000pt 推挤）。
   - Control Item 点击时先展开 Divider（8pt）再 `show()`，以便 pin 分类对着真实布局扫描；Popover 关闭后再折叠。
   - `prepareForTermination()`：退出前将 Divider 恢复为 8pt，避免留下幽灵空隙。
2. **窗口扫描与高清截图**：
   - `MenuBarScanner.swift` & `StatusItemWindow.swift`：扫描 `layer == 25` 窗口，排除自身 PID，区分可移动项与时钟/控制中心不可移动项。
   - `scanOwnStatusWindows()` 用于定位 Divider Item（自身窗口中最左侧）。
   - `CGImage+AlphaTrim.swift`：基于 32 位 RGBA 像素矩阵遍历裁剪 Alpha > 12 的透明边框。
   - `SystemWindowImageCapturer`：通过 `dlsym` 绕过 macOS 15 SDK 对 `CGWindowListCreateImage` 的弃用限制，抓取 Retina 2x 高清位图，并配合 `IconCache` 内存缓存。
3. **SwiftUI Popover 浮层**：
   - `PopoverGridView.swift`：4 列磨砂玻璃网格，Tooltip、Arrange Mode 开关、蓝/灰 pin 徽标、拖拽 Loading、开机自启勾选、Quit。
   - `PopoverCoordinator.swift`：管理 `NSPopover` 瞬态生命周期；普通点击走 Click Proxy 并关闭；整理模式点击走 ItemArranger 并保持打开。
4. **双轨点击代理服务**：
   - `ClickProxyService.swift`：Track 1 Accessibility，Track 2 `MenuBarUpdateMask` + 瞬态 Divider 8pt + `0x33` CGEvent。
5. **整理模式与拖拽切换**：
   - `ItemLayout.swift`：pin 分类、拖拽目标 X、网格过滤纯函数。
   - `ItemArranger.swift`：合成 `⌘ + Drag` 穿越 Divider Item；0.3s 单操作防抖；`busyWindowID` Loading 状态。
   - 不可移动项（Clock / BentoBox）拒绝拖拽。
6. **开机自启与发布打磨**：
   - `LaunchAtLoginService.swift`：`LoginItemRegistering` 接缝 + `SMAppServiceLoginItem` 适配 `SMAppService.mainApp`。
   - `Makefile` / `scripts/run.sh`：打包 `.build/MiniBar.app`（Info.plist、`LSUIElement`、AppIcon、adhoc codesign）。
   - 无网络依赖；图标懒加载 + 内存缓存，避免频繁截屏告警。

---

## 4. 任务清单与当前进度 (Tickets Tracking)

所有任务已同步发布在 GitHub Issues：

| 编号 | 任务标题 | 状态 | 依赖 (Blocked By) | Commit / Issue |
| :--- | :--- | :--- | :--- | :--- |
| **#1** | **Ticket 1: App Scaffold, Status Items & Spacer Push** | ✅ **Done** | 无 | Commit `0631def` ([#1](https://github.com/hertzhzzz/minibar/issues/1)) |
| **#2** | **Ticket 2: Window Scanner & Retina Icon Capture** | ✅ **Done** | #1 | Commit `ae6fe0b` ([#2](https://github.com/hertzhzzz/minibar/issues/2)) |
| **#3** | **Ticket 3: SwiftUI Popover Grid & Lifecycle** | ✅ **Done** | #2 | Commit `5dd199a` ([#3](https://github.com/hertzhzzz/minibar/issues/3)) |
| **#4** | **Ticket 4: Double-Track Click Proxy Service** | ✅ **Done** | #3 | Commit `fbcfb4f` ([#4](https://github.com/hertzhzzz/minibar/issues/4)) |
| **#5** | **Ticket 5: Arrange Mode & Drag-to-Toggle** | ✅ **Done** | #4 | Commit `a5e4ff4` ([#5](https://github.com/hertzhzzz/minibar/issues/5)) |
| **#6** | **Ticket 6: Launch at Login & Release Polish** | ✅ **Done** | #5 | 见最新 `feat: ... (closes #6)` 提交 ([#6](https://github.com/hertzhzzz/minibar/issues/6)) |

---

## 5. 下一个会话执行指引 (Next Session Action Plan)

所有 Ticket 已完成。接手 Agent 应：
1. **实机验收（未在单测覆盖）**：
   - `make run` 启动 `.app` 后，在 Popover 勾选 Launch at Login；若状态为 `requiresApproval`，到「系统设置 → 通用 → 登录项」批准。
   - `SMAppService.mainApp` 只对签名后的 `.app` bundle 有效；`swift run` 裸二进制无法持久化登录项。
   - 勾选 Quit MiniBar，确认 Divider 恢复 8pt、菜单栏不留幽灵空隙。
   - Activity Monitor 确认常驻 RSS < 30MB；确认无网络连接。
   - Ticket 5 残留风险：合成 ⌘+Drag 目前是 down → 一次 dragged → up；CGEvent Y 轴可能偏移。
2. **不要提交** `.notes/`（本地项目记忆）。

---

## 6. Suggested Skills (建议调用的技能)
- **`handon`**：新会话启动或 `/clear` 后，自动重新加载本交接文档与上下文。
- **`code-review`**：若继续改动，合入前做 Standards / Spec 双轴审查。
