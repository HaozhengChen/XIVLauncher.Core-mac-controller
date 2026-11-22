# XIVLauncher.Core for macOS

> **本分支新增：macOS 手柄（Controller）支持**，见 [CONTROLLER.md](CONTROLLER.md)。

这是面向 **macOS Apple Silicon** 的《最终幻想 XIV》国服启动器分支，基于 [ottercorp/XIVLauncher.Core](https://github.com/ottercorp/XIVLauncher.Core) 的 `cn` 分支维护。它不是上游的通用 Linux/Steam Deck 发行版，也不提供 Windows 支持。

当前维护分支为 [`mac`](https://github.com/rika-ffxiv/XIVLauncher.Core/tree/mac)。发行版从 GitHub Releases 获取，构建目标为自包含的 `osx-arm64`。

## 运行环境

- Apple Silicon macOS；游戏 Windows 客户端通过 Rosetta 2 运行。
- 使用 Homebrew 安装 `aria2`（`brew install aria2`），用于下载游戏补丁。
- 启动器自动安装并使用本项目构建的 **Wine 11**，安装目录为 `~/.xlcore_cn/compatibilitytool/beta/wine-11.0/`。
- 图形路径默认使用与 Wine 11 配套的 **DXMT v0.72**（Direct3D 11 到 Metal），安装目录为 `~/.xlcore_cn/compatibilitytool/dxmt/dxmt-wine11-v0.72/`。
- 默认关闭 ESync、启用 MSync；两者同时启用会造成明显的同步停顿。

Wine 与 DXMT 的预构建包由启动器从项目的 R2 分发地址下载。已有 `wine-11.0` 本地缓存不会因服务端替换同名包而自动更新。

## 此分支的主要修改

- 修正 macOS 的窗口生命周期：所有 AppKit 窗口操作回到主线程执行，避免游戏启动后启动器无法正确隐藏或关闭。
- 更新仓库内 SDL2 至 2.32.10 universal，修复新版 macOS 的窗口事件问题。
- 将 managed Wine 从旧版 XOM 5.3.1 迁移至 Wine 11，并将 DXMT 升级至匹配的 v0.72；已在实际游戏启动中验证中文输入法可用。
- 将 Dalamud、运行时信息和资产的下载切换到 Soil 静态分发；移除上游游戏版本门槛，保留下载完整性校验。
- 接入 DCTravel 本地 RPC 生命周期，供兼容的 DCTraveler 插件在游戏启动期间使用。
- 随附的 Wine 增加 `FlashWindowEx` 到 macOS Dock attention 的映射：Dalamud 等 Windows 程序请求任务栏闪烁时，Dock 会请求提醒；停止闪烁会取消提醒。

完整的技术细节、构建命令、发布流程和已知问题见 [MACOS.md](MACOS.md)。

## 安装与启动

1. 从本仓库的 [Releases](https://github.com/rika-ffxiv/XIVLauncher.Core/releases) 下载 `XIVLauncher.Core-osx-arm64.tar.gz` 并解压。
2. 在终端运行 `XIVLauncher.Core`。首次启动时在 macOS 的“隐私与安全性”设置中按需允许该未签名应用。
3. 在启动器中选择游戏目录并登录；首次运行会下载 Wine 与 DXMT。

配置、日志和 Wine prefix 位于 `~/.xlcore_cn/`；日志位于 `~/.xlcore_cn/logs/`。

## 构建

需要 .NET SDK 10 与 macOS 构建环境。克隆时须带上子模块：

```sh
git clone --recurse-submodules --branch mac https://github.com/rika-ffxiv/XIVLauncher.Core.git
cd XIVLauncher.Core/src/XIVLauncher.Core
dotnet publish -r osx-arm64 --self-contained -c Release -o ./dist/osx-arm64
```

`lib/FFXIVQuickLauncher` 子模块固定在本组织维护的 `mac` 分支；其中包含 Dalamud/资产分发与 DCTravel 的配套修改。

## 免责声明

本项目是非官方的社区维护分支，与 SQUARE ENIX、XIVLauncher 上游和 Dalamud 上游均无隶属关系。使用第三方启动器和插件存在风险，请自行判断并承担责任。
