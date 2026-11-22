# macOS 手柄（Controller）支持

在 macOS 上使用 XIVLauncher.Core（国服）时，让 DualSense / Xbox 等手柄在 FFXIV 里可用，同时保留 DXMT 渲染。

## 问题

| Wine | DXMT（`winemetal`） | 手柄（SDL 后端） |
|---|---|---|
| 启动器托管 Wine 11（Managed） | 有 | 无，游戏内设备列表为空 |
| Gcenx Wine Stable 11.0_1 | 无，游戏进程起不来 | 有 |
| Gcenx + DXVK（MoltenVK） | — | 有，但新场景会因着色器编译出现模型延迟加载 |

## 方案

复制一份 Managed Wine，只换入 Gcenx 版的手柄模块：`winebus.so`、`winebus.sys`、`libSDL2-2.0.0.dylib`、`libinotify.0.dylib`。渲染仍走 DXMT，手柄走 SDL。

## 使用

1. 先用 Managed Wine 启动一次游戏，让启动器下载 Wine 与 DXMT。
2. 退出启动器，运行：

   ```bash
   scripts/build-controller-wine.sh
   ```

   脚本会下载 Gcenx Wine Stable 11.0_1（校验 SHA-256），默认输出到 `~/.xlcore_cn/controller-wine`。
3. 加 `--configure` 可自动写好启动器设置（需先退出启动器）；也可手动：设置 → Wine，版本选 Custom，路径填 `~/.xlcore_cn/controller-wine/bin`（绝对路径），DXMT 保持开启。
4. 连接手柄后再启动游戏。

## 已验证环境

MacBook Pro（Apple Silicon）、macOS 27、Rosetta 2、DualSense（蓝牙）。游戏内手柄可用，加载表现与 Managed 一致。其他手柄和系统版本未测试。

## 注意

- 混合版不会随启动器更新；启动器更换 Managed Wine 版本后，需删除输出目录并重新运行脚本。
- 两个 Wine 并非同一分支，混用属于经验性方案，不保证所有版本组合可用。
- Wine 为 LGPL，Gcenx 构建来自 <https://github.com/Gcenx/macOS_Wine_builds>；本仓库不分发任何二进制。
- 本仓库基于 [rika-ffxiv/XIVLauncher.Core](https://github.com/rika-ffxiv/XIVLauncher.Core) `mac` 分支，许可证 GPL-3.0。

## 附：Dalamud 资源下载修复（Brotli）

上游 `HttpClientWithProgress` 只开启了 GZip 自动解压，却声明 `accept-encoding: gzip, deflate, br`。Cloudflare 因此返回 Brotli 压缩内容，启动器未解压就存盘，导致 Dalamud 的字体资源（`UIRes/*.otf|ttf`）哈希不符、字体损坏，游戏弹出 `Failed to initialize Dalamud base fonts`。

修复补丁在 `patches/`，构建前执行：

```bash
git submodule update --init
scripts/apply-patches.sh
```

已经下载坏的资源，可用 `brotli -d` 解压并核对启动器日志中的远端 SHA-1。

上游跟进：
- Brotli 修复 PR：<https://github.com/rika-ffxiv/FFXIVQuickLauncher/pull/1>
- 手柄支持讨论：<https://github.com/rika-ffxiv/XIVLauncher.Core/issues/1>
