# WSL Code Manager

`wsl-code-manager` (`wcm`) 是一个给 VS Code 系 Windows 编辑器生成 WSL 侧启动 wrapper 的终端工具。

它会探测常见编辑器的 Windows 安装、Remote WSL 插件、WSL server CLI、WSL wrapper 和 helper 状态，然后可选择性安装 wrapper 到 `~/.local/bin`。

## 使用

```bash
wcm
wcm --list
wcm --refresh
wcm --install qoder
wcm --reinstall cursor
wcm --uninstall cursor
wcm --install-all
wcm --upgrade-installed
```

普通 `--list` 只读取本地缓存：

```text
~/.cache/wsl-code-manager/editors.tsv
```

需要重新扫描 Windows 程序目录时，使用：

```bash
wcm --refresh
```

查看列表不会联网；只有安装缺失的 Remote Development / Remote WSL 扩展时，才可能调用 Marketplace 下载 VSIX 作为 fallback。

刷新时会优先查询 Windows 注册表的 Uninstall 项来定位编辑器安装目录，然后只检查少量固定的 `product.json` 路径；找不到时才回退到候选目录扫描。

TUI 首页的 `View list` 会先展示上一次保存的静态列表，再用终端内刷新动画更新本地状态。

`--upgrade-installed` 只重写 WCM installed wrapper/helper，不覆盖自定义脚本。它用于 WCM 模板升级后，把已安装的 wrapper 更新到新版逻辑。

## 安装入口

```bash
/home/ray/dev/linkong/wsl-code-manager/install.sh
```

安装脚本只创建/更新：

```text
~/.local/bin/wsl-code-manager
~/.local/bin/wcm
```

不会修改 Windows 程序目录，也不会修改 Windows PATH。

Cursor 会按它自己的 `extensionReplacementMapForImports` 检测 `anysphere.remote-wsl`，不会误用其他编辑器的 Remote WSL 扩展。

Windsurf 已按官方更名处理为 Devin Desktop。WCM 会继续把 `Windsurf` 当作 legacy alias 搜索，但默认生成的 WSL 命令是 `devin-desktop`，避免覆盖 Devin CLI 的 `devin` 命令。

WCM installed wrapper 每次启动都会重新读取真实 Windows launcher 里的 `COMMIT`、`APP_NAME`、`NAME`、`SERVERDATAFOLDER` 和 `VERSIONFOLDER`。如果旧 launcher 路径失效，新版 wrapper 会继续尝试 PATH 和 Windows 注册表来重新定位编辑器。

首次启动某个编辑器的 WSL 窗口时，如果对应 server 还没安装，wrapper 会交给该编辑器自己的 Remote WSL 脚本下载 server，并在后台等待 `remote-cli/code` 出现后补齐 `remote-cli/<applicationName>` symlink。

对 CodeArts Agent、Trae 这类复用 Microsoft Remote WSL 扩展但自身 commit 不在 VS Code 官方下载源的编辑器，installed wrapper 会使用本机 VS Code server commit 作为兼容 server commit，避免下载 404。

## 版本

当前版本见 `VERSION`，脚本 splash 中也会显示版本号。
