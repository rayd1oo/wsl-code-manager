# WSL Code Manager

`wsl-code-manager` (`wcm`) 是一个给 VS Code 系 Windows 编辑器生成 WSL 侧启动 wrapper 的终端工具。

它会探测常见编辑器的 Windows 安装、Remote WSL 插件、WSL server CLI、WSL wrapper 和 helper 状态，然后可选择性安装 wrapper 到 `~/.local/bin`。

## 使用

### APT 安装

```bash
curl -fsSL https://rayd1oo.github.io/wsl-code-manager/wsl-code-manager-archive-keyring.gpg \
  | sudo tee /usr/share/keyrings/wsl-code-manager.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/wsl-code-manager.gpg] https://rayd1oo.github.io/wsl-code-manager stable main" \
  | sudo tee /etc/apt/sources.list.d/wsl-code-manager.list >/dev/null

sudo apt update
sudo apt install wsl-code-manager
```

### 命令

```bash
wcm
wcm --list
wcm --refresh
wcm --install qoder
wcm --reinstall cursor
wcm --uninstall cursor
wcm --restore cursor
wcm --remove-wrapper cursor
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

TUI 首页的 `View list` 会先展示上一次保存的静态列表，再用终端内刷新动画更新本地状态。安装、卸载、恢复和 `Upgrade installed wrappers` 这类耗时动作会先进入任务页，显示 spinner，完成后展示结果。

`--upgrade-installed` 只重写 WCM installed wrapper/helper，不覆盖自定义脚本。它用于 WCM 模板升级后，把已安装的 wrapper 更新到新版逻辑。

如果某个编辑器当前显示为 `custom`，TUI 里选中它会提供：

- 覆盖安装：先把 custom wrapper/helper 备份为 `.bak.<timestamp>`，再安装 WCM wrapper。
- 删除回官方：先备份 custom wrapper/helper，再移除本地入口，让 PATH 回落到 Windows 官方 launcher。
- 恢复备份：把最近一次 `.bak.<timestamp>` 恢复回来；当前文件会先再次备份。

CLI 对应命令：

```bash
wcm --reinstall qoder       # 显式覆盖安装，custom 会先备份
wcm --uninstall qoder       # 卸载 WCM installed 文件，并优先恢复最近备份
wcm --restore qoder         # 手动恢复最近备份
wcm --remove-wrapper qoder  # 备份并移除本地 wrapper/helper，回到官方 launcher
```

## 安装入口

本地 checkout 可直接安装到 `~/.local/bin`：

```bash
/home/ray/dev/linkong/wsl-code-manager/install.sh
```

安装脚本只创建/更新：

```text
~/.local/bin/wsl-code-manager
~/.local/bin/wcm
```

不会修改 Windows 程序目录，也不会修改 Windows PATH。

APT 包会安装到：

```text
/usr/bin/wsl-code-manager
/usr/bin/wcm
```

Cursor 会按它自己的 `extensionReplacementMapForImports` 检测 `anysphere.remote-wsl`，不会误用其他编辑器的 Remote WSL 扩展。

Windsurf 已按官方更名处理为 Devin Desktop。WCM 会继续把 `Windsurf` 当作 legacy alias 搜索，但默认生成的 WSL 命令是 `devin-desktop`，避免覆盖 Devin CLI 的 `devin` 命令。

WCM installed wrapper 每次启动都会重新读取真实 Windows launcher 里的 `COMMIT`、`APP_NAME`、`NAME`、`SERVERDATAFOLDER` 和 `VERSIONFOLDER`。如果旧 launcher 路径失效，新版 wrapper 会继续尝试 PATH 和 Windows 注册表来重新定位编辑器。

首次启动某个编辑器的 WSL 窗口时，如果对应 server 还没安装，wrapper 会交给该编辑器自己的 Remote WSL 脚本下载 server，并在后台等待 `remote-cli/code` 出现后补齐 `remote-cli/<applicationName>` symlink。

对 CodeArts Agent、Trae 这类复用 Microsoft Remote WSL 扩展但自身 commit 不在 VS Code 官方下载源的编辑器，installed wrapper 会使用本机 VS Code server commit 作为兼容 server commit，避免下载 404。

Qoder / QoderCN 如果命中 `ms-vscode-remote.remote-wsl`，也会走相同兼容逻辑，避免编辑器自身 commit 在 `update.code.visualstudio.com` 上不存在时首启失败。

首次下载兼容 server 后，如果 Remote WSL 脚本立刻调用 `remote-cli/<applicationName>` 而 symlink 还没生成，wrapper 会立即补链并自动重试一次。

## 版本

当前版本见 `VERSION`，脚本 splash 中也会显示版本号。

## 发布 APT 仓库

发版由 GitHub Actions 的 `Publish APT repository` workflow 完成：

1. 创建 APT signing key：

```bash
gpg --batch --quick-generate-key "WSL Code Manager APT <rayd1oo@users.noreply.github.com>" rsa4096 sign 2y
gpg --list-secret-keys --keyid-format=long "WSL Code Manager APT"
```

2. 导出私钥，把输出内容保存到 GitHub repository secret `APT_GPG_PRIVATE_KEY`：

```bash
gpg --armor --export-secret-keys "WSL Code Manager APT"
```

3. 如果私钥有密码，也添加 secret `APT_GPG_PASSPHRASE`。
4. 可选添加 secret `APT_GPG_KEY_ID` 指定签名 key fingerprint；不填会使用导入后的第一个 secret key。
5. 确认 `VERSION` 是目标版本，例如 `1.0`。
6. 打 tag 并推送：

```bash
git tag v1.0
git push origin main v1.0
```

workflow 会构建 `dist/wsl-code-manager_1.0_all.deb`，发布 GitHub Release，并把签名 APT 仓库部署到 GitHub Pages。
