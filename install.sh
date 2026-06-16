#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
bin_dir="${WCM_INSTALL_DIR:-$HOME/.local/bin}"
target="$repo_dir/bin/wsl-code-manager"

if [ ! -x "$target" ]; then
    chmod +x "$target"
fi

mkdir -p "$bin_dir"
ln -sf "$target" "$bin_dir/wsl-code-manager"
ln -sf "$target" "$bin_dir/wcm"

echo "Installed wsl-code-manager:"
echo "  $bin_dir/wsl-code-manager -> $target"
echo "  $bin_dir/wcm -> $target"
