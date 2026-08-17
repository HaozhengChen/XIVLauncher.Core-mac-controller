# AGENTS.md

本仓库是 ottercorp/XIVLauncher.Core 的个人 fork，工作分支为 `mac`（macOS 适配，详见 `MACOS.md`）。

## ⚠️ 最高优先级：保护未提交的工作

本分支的**全部适配改动当前都是未提交的工作区状态**，分布在两处：

- 主仓库：`src/XIVLauncher.Core/`（Program.cs、MainPage.cs、Resources/libsdl2.dylib）
- 子模块 `lib/FFXIVQuickLauncher`（本地 `mac` 分支上的工作区改动：Dalamud 更新器/资产换源、DcTraveler、ServerAddress）

**绝对不要**执行 `git checkout .`、`git reset --hard`、`git submodule update`（会按主仓库记录的指针重置子模块 HEAD）等命令，除非用户明确要求。做任何 git 变更前先 `git status` 两边都查一遍。

## 构建与验证

```bash
export PATH="$HOME/.dotnet:$PATH"   # .NET SDK 10.0.x
cd src/XIVLauncher.Core
dotnet build -c Release                                              # 快速验证编译
dotnet publish -r osx-arm64 --sc -c Release -o ./dist/osx-arm64      # 出可运行产物
```

- 改动后必须 `dotnet build` 零 error 才算完成；警告不用管（上游自带 600+）
- 产物是 `dist/osx-arm64/XIVLauncher.Core`（自包含，运行不需要 SDK）
- 没有测试套件可跑；验证方式就是编译 + 实际启动

## 平台约定（改 macOS 相关代码时必须遵守）

- **窗口操作必须在主线程**：AppKit 要求。后台线程要操作窗口时，走 `Program.cs` 里的 `windowShowRequested`/`windowHideRequested` 标志位模式，主循环消费。不要从别的线程直接碰 `window.Visible`
- **ESync/MSync 互斥**：macOS 上 `ESyncEnabled` 必须为 false（MSync 是原生路径；同开导致数秒级同步停顿）。改默认值的代码在 `Program.cs`，带注释
- **DXMT 是 macOS 的渲染路径**（默认开）；DXVK/MoltenVK 路径仅作回退
- 子模块的 `DalamudUpdater`/`AssetManager` 走 Soil 静态分发，不要恢复对 `aonyx.ffxiv.wang` 的引用；`ServerAddress.cs` 里 OtterCorp 地址仍被 wine/DXMT 下载使用（个人自用，保留）

## 运行时事实（排查问题时需要）

- 存储根目录：`~/.xlcore_cn/`（不是 `~/.config`）
- 手动运行 prefix 里的 wine 程序必须带全 env（WINEESYNC=0 WINEMSYNC=1 等），完整清单见 `MACOS.md`
- 日志：`~/.xlcore_cn/logs/`
- 工作区根目录（本仓库上一级）有 `NOTES.md`：历次疑难问题（IME、卡顿、字体）的完整排查记录
