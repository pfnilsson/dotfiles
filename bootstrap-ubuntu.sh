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

# --- 6) Install uv (standalone) ---
if ! command -v uv >/dev/null; then
    echo "Installing uv (standalone)..."
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi

# Ensure ~/.local/bin is on PATH for zsh (so uv/uvx are found)
if ! grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

# --- 7) Install python deps
sudo apt install -y python3-venv python3-pip

# --- 8) Copy dotfiles ---
echo "Copying dotfiles..."

copy_item "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"
cp -rf "$DOTFILES_DIR/nvim" "$HOME/.config"

mkdir -p "$HOME/.config/ghostty"
copy_item "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

cp -rf "$DOTFILES_DIR/tmux" "$HOME/.config"

copy_item "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

mkdir -p "$HOME/.local/bin"
for f in "$DOTFILES_DIR"/scripts/*; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    copy_item "$f" "$HOME/.local/bin/$base"
    chmod +x "$HOME/.local/bin/$base"
done

# --- GitHub auth via Git Credential Manager (Ubuntu) ---
setup_gcm() {
  set -euo pipefail

  # You can force a store via env: GCM_STORE=secretservice|gpg
  : "${GCM_STORE:=auto}"

  sudo apt-get update -y
  sudo apt-get install -y git ca-certificates curl

  # Install jq for release discovery if needed
  if ! command -v jq >/dev/null 2>&1; then
    sudo apt-get install -y jq
  fi

  # 1) Install GCM if missing
  if ! command -v git-credential-manager >/dev/null 2>&1; then
    ARCH="$(dpkg --print-architecture)"  # amd64/arm64/etc.
    echo "[GCM] Installing for arch: $ARCH"
    url="$(curl -fsSL https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest \
      | jq -r --arg arch "$ARCH" '.assets[] | select(.name | test("gcm-linux_"+$arch+".*\\.deb$")) | .browser_download_url' \
      | head -n1)"
    if [ -z "${url:-}" ]; then
      echo "[GCM] No .deb asset found for $ARCH" >&2
      return 1
    fi
    tmpdeb="$(mktemp /tmp/gcm.XXXXXX.deb)"
    curl -fsSL "$url" -o "$tmpdeb"
    # apt handles dependencies better than dpkg -i
    sudo apt-get install -y "$tmpdeb"
    rm -f "$tmpdeb"
  fi

  # 2) Wire GCM into Git (safe if already done)
  git-credential-manager configure || true

  # 3) Pick/store credentials (desktop keyring vs headless)
  pick_store() {
    case "$GCM_STORE" in
      secretservice)
        sudo apt-get install -y gnome-keyring libsecret-1-0
        git config --global credential.credentialStore secretservice
        ;;
      gpg)
        sudo apt-get install -y gnupg pass
        # Ensure we have a GPG key for pass
        if ! gpg --list-secret-keys --with-colons 2>/dev/null | grep -q '^sec:'; then
          gpg --quick-generate-key "gcm-$(whoami)@$(hostname)" default default 2y
        fi
        KEYID="$(gpg --list-secret-keys --with-colons | awk -F: '/^sec:/ {print $5; exit}')"
        pass init "$KEYID" >/dev/null 2>&1 || true
        git config --global credential.credentialStore gpg
        ;;
      auto|*)
        # Detect desktop session; treat WSL as headless
        if grep -qi microsoft /proc/version 2>/dev/null; then
          GCM_STORE="gpg"
          pick_store gpg
        elif [ -n "${XDG_CURRENT_DESKTOP-}" ] || [ -n "${DESKTOP_SESSION-}" ] \
             || [ "${XDG_SESSION_TYPE-}" = "x11" ] || [ "${XDG_SESSION_TYPE-}" = "wayland" ]; then
          GCM_STORE="secretservice"
          pick_store secretservice
        else
          GCM_STORE="gpg"
          pick_store gpg
        fi
        ;;
    esac
  }
  pick_store

  # 4) Make GCM the ONLY helper in global scope (cleans duplicates)
  git config --global --unset-all credential.helper 2>/dev/null || true
  # Clean legacy names if present
  git config --global --unset-all credential.helper manager-core 2>/dev/null || true
  # Set the current helper
  git config --global --add credential.helper manager

  # (Optional) scrub system/local helpers if you want zero surprises:
  # sudo git config --system --unset-all credential.helper 2>/dev/null || true
  # git config --local --unset-all credential.helper 2>/dev/null || true

  echo "[GCM] $(git-credential-manager --version)"
  echo "[GCM] helper(s): $(git config --global --get-all credential.helper | paste -sd ',')"
  echo "[GCM] store:     $(git config --global credential.credentialStore)"
}

setup_gcm

echo
echo "✅ Bootstrap complete!"
echo "Neovim, Ghostty installed via Snap; dotfiles copied"
echo "Log out and back in to apply shell changes and shortcuts."

