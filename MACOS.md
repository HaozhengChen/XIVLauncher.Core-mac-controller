# XIVLauncher.Core macOS 分支说明

本分支（`mac`，基于 ottercorp `cn`）是在 macOS（Apple Silicon）上运行国服 FFXIV 的个人适配分支。游戏经 Rosetta 2 + wine（XIV on Mac 5.3.1）+ DXMT（D3D11→Metal）运行；Dalamud 换用 Soil 社区分发（无插件封禁）。

## 改动清单

### 主仓库（XIVLauncher.Core）

| 文件 | 改动 |
|---|---|
| `src/XIVLauncher.Core/Program.cs` | macOS 默认值修正：`DxmtEnabled` 默认开（原默认关会导致走 DXVK/MoltenVK 老路径）；`ESyncEnabled` 默认关（与 MSync 同开会造成数秒级同步原语停顿，见下）。`ShowWindow`/`HideWindow` 改为标志位编组到主线程执行——AppKit 要求窗口操作必须在主线程，原先后台线程直调导致"游戏启动后窗口不隐藏、不响应关闭" |
| `src/XIVLauncher.Core/Components/MainPage/MainPage.cs` | 接入超域旅行（DCTravel）本地 API 完整生命周期：登录成功后随机端口起 `DcTravelListener`（明文 JSON、绑 127.0.0.1）、经 `XL.DcTraveler=<port>` 游戏参数通知插件、游戏退出后停止；供 DCTravelerX 插件使用 |
| `src/XIVLauncher.Core/Resources/libsdl2.dylib` | 仓库自带的 2022 年旧版 SDL2 → 官方 SDL2 2.32.10 universal（x86_64+arm64）。旧版在 macOS 26 上窗口事件投递异常 |

### 子模块（lib/FFXIVQuickLauncher，本地 `mac` 分支）

| 文件 | 改动 |
|---|---|
| `Util/ServerAddress.cs` | 新增 Soil 静态分发地址常量（Dalamud、资产、runtimeInfo） |
| `Dalamud/DalamudUpdater.cs` | Dalamud 更新源从 OtterCorp aonyx API 换成 Soil 静态分发：`RELEASE` 版本号 → `{版本}/latest.7z` → `hashes.json` MD5 校验。删除 StgCode 校验、beta track 逻辑、运行时哈希端点（Soil 无对应物，退化为版本号+目录存在性判断） |
| `Dalamud/DalamudLauncher.cs` | 删除 `SupportedGameVer` 游戏版本强校验（`ReCheckVersion` 只查更新器状态）、`CanRunDalamud` 的联网检查、`REMOTE_BASE` 常量 |
| `Dalamud/AssetManager.cs` | Dalamud 资产（UIRes、字体等）换源到 Soil：`assets/RELEASE` + `assets/{版本}/assetCN.json` 清单 + `files/` 下载。注意清单内嵌版本号滞后，以 RELEASE 文本为准 |
| `Game/DcTraveler.cs` | `MigrationConfirmOrder` 补 `[HttpRpc]` 特性；新增 `SetSdoArea` RPC。其余 DTO 与插件协议本就匹配 |

### 环境（非代码，首次部署已完成）

- wine：XIV on Mac 5.3.1 包（启动器自动下载）；prefix：`~/.xlcore_cn/wineprefix`
- **注意**：存储根目录是 `~/.xlcore_cn`（`Storage.cs` 在非 Windows 用 `~/.{appName}`），不是 `~/.config`
- prefix 已配置：Noto Sans CJK 字体 + 常用中文字体替换（FontSubstitutes）；`LeftCommandIsCtrl=y`/`RightCommandIsCtrl=y`（Command 映射为 Ctrl）
- 手动在终端运行 wine 程序必须带全环境变量，否则 `Floating point exception: 8`：
  `WINEPREFIX=~/.xlcore_cn/wineprefix WINEDEBUG=-all LANG=en_US WINEESYNC=0 WINEMSYNC=1 WINEFSYNC=0`
- 已对 `game-data/` 和 `~/.xlcore_cn/` 关闭 Spotlight 索引（`.metadata_never_index`）

## 构建

```bash
export PATH="$HOME/.dotnet:$PATH"   # .NET SDK 10.0.x（brew 或官方脚本安装均可）
cd src/XIVLauncher.Core
dotnet publish -r osx-arm64 --sc -c Release -o ./dist/osx-arm64
./dist/osx-arm64/XIVLauncher.Core
```

`osx-arm64` 为当前日常构建（原生运行）；`osx-x64` 亦可编译（经 Rosetta）。

## 已知问题与决策记录

- **IME**：游戏本体输入框正常；**Dalamud 窗口内双重上屏**——winemac 发送 IME 消息顺序为 END 先于 RESULT（与真 Windows 相反），击中 Dalamud 内置 IME 状态机（`DalamudIme.cs`）。IME 激活时字母键被转成 `VK_PROCESSKEY` 导致快捷键失灵——解法：用非输入法键盘源（ABC）玩游戏。修复 DalamudIme 需本地构建 Dalamud 托管部分，未做
- **同步原语**：ESync 与 MSync 不可同开（本分支已改默认值）。证据与排查过程见工作区根目录 `../NOTES.md`
- **Dalamud 来源**：Soil 静态分发（`dalamud-dis.atmoomen.top`），版本随 Soil 更新；无 `SupportedGameVer` 校验
- **性能**：Rosetta 翻译税 + 跑图资源加载卡顿属固有成本；内存紧张时 macOS 压缩/换出会造成 1~2s 停顿，游戏时建议关闭浏览器等大内存应用

## 同步上游

```bash
git fetch origin && git merge origin/cn   # 主仓库
cd lib/FFXIVQuickLauncher && git fetch origin && git merge origin/CN   # 子模块（注意大写 CN）
```

合并后重点复查：`Program.cs` 默认值段、`MainPage.cs` 登录流程、子模块 Dalamud 三个文件。
