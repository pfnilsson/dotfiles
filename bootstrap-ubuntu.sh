#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/dotfiles"
DOTFILES_DIR="$(readlink -f "$DOTFILES_DIR")"
TS="$(date +%s)"

echo "=== Ubuntu Bootstrap ==="
echo "Dotfiles repo: $DOTFILES_DIR"
echo

copy_item() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    echo "Copied $src -> $dest"
}

# --- 1) Install Snap if missing ---
if ! command -v snap >/dev/null; then
    echo "Installing snapd..."
    sudo apt update
    sudo apt install -y snapd
fi

# --- 2) Install applications ---
echo "Installing Neovim, Ghostty, Tmux via Snap..."
sudo snap install nvim --classic
sudo snap install ghostty --classic
sudo snap install tmux --classic

echo "Installing clipboard tools..."
sudo apt update
sudo apt install -y xclip xsel

echo "Installing zsh-syntax-highlighting..."
sudo apt update
sudo apt install -y zsh-syntax-highlighting

echo "Installing fzf"
sudo apt update
sudo apt install fzf -y

echo "Installing ripgrep"
sudo apt update
sudo apt install ripgrep

# --- 3) Install Node.js + npm ---
if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
    echo "Installing Node.js and npm..."
    sudo apt update
    sudo apt install -y nodejs npm
fi

# --- 4) Install Go ---
if ! command -v go >/dev/null; then
    echo "Installing Go..."
    # Fetch latest Go version
    GO_LATEST_JSON=$(curl -s https://go.dev/dl/?mode=json)
    GO_VERSION=$(echo "$GO_LATEST_JSON" | jq -r '.[0].version' | sed 's/go//')
    
    echo "Latest Go version: $GO_VERSION"
    wget -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O "/tmp/go${GO_VERSION}.tar.gz"
    
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "/tmp/go${GO_VERSION}.tar.gz"
    rm "/tmp/go${GO_VERSION}.tar.gz"
fi

# --- 5) Install Lazygit ---
if ! command -v lazygit >/dev/null; then
    echo "Installing Lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": *"v\K[^"]*')

    curl -Lo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"

    tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit -D -t /usr/local/bin/
    rm /tmp/lazygit /tmp/lazygit.tar.gz
fi

# --- 6) Install python deps
sudo apt install -y python3-venv python3-pip

# --- 7) Copy dotfiles ---
echo "Copying dotfiles..."

copy_item "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"
cp -rf "$DOTFILES_DIR/nvim" "$HOME/.config"

mkdir -p "$HOME/.config/ghostty"
copy_item "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

cp -rf "$DOTFILES_DIR/tmux" "$HOME/.config"

copy_item "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

mkdir -p "$HOME/.zsh"
copy_item "$DOTFILES_DIR/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh" "$HOME/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh"
cp -rf "$DOTFILES_DIR/zsh/zsh-vi-mode" "$HOME/.zsh"

mkdir -p "$HOME/.local/bin"
for f in "$DOTFILES_DIR"/scripts/*; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    copy_item "$f" "$HOME/.local/bin/$base"
    chmod +x "$HOME/.local/bin/$base"
done

echo
echo "✅ Bootstrap complete!"
echo "Neovim, Ghostty installed via Snap; dotfiles copied"
echo "Log out and back in to apply shell changes and shortcuts."

