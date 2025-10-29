#!/usr/bin/env zsh
set -euo pipefail

# Set directory of this file to SCRIPT_DIR
SCRIPT_DIR=${${(%):-%N}:A:h}

# Ensure base dirs exist
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/karabiner"
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.config/tmux"
mkdir -p "$HOME/.config/git"
mkdir -p "$HOME/.zsh"

echo "Restoring dotfiles and configs from repo to system…"

# tmuxrun -> ~/.local/bin
if [[ -f "$SCRIPT_DIR/scripts/tmuxrun" ]]; then
  cp "$SCRIPT_DIR/scripts/tmuxrun" "$HOME/.local/bin/tmuxrun"
  chmod +x "$HOME/.local/bin/tmuxrun" || true
  echo "✓ tmuxrun"
fi

# ghostty config -> ~/.config/ghostty/config
if [[ -f "$SCRIPT_DIR/ghostty/config" ]]; then
  cp "$SCRIPT_DIR/ghostty/config" "$HOME/.config/ghostty/config"
  echo "✓ ghostty/config"
fi

# karabiner -> ~/.config/karabiner/karabiner.json
if [[ -f "$SCRIPT_DIR/karabiner/karabiner.json" ]]; then
  cp "$SCRIPT_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
  echo "✓ karabiner.json"
fi

# .zshrc -> ~
if [[ -f "$SCRIPT_DIR/zsh/.zshrc" ]]; then
  cp "$SCRIPT_DIR/zsh/.zshrc" "$HOME/.zshrc"
  echo "✓ .zshrc"
fi

# nvim -> ~/.config/nvim
if [[ -d "$SCRIPT_DIR/nvim" ]]; then
  rsync -a --delete "$SCRIPT_DIR/nvim/" "$HOME/.config/nvim/"
  echo "✓ nvim"
fi

# tmux -> ~/.config/tmux
if [[ -d "$SCRIPT_DIR/tmux" ]]; then
  rsync -a --delete "$SCRIPT_DIR/tmux/" "$HOME/.config/tmux/"
  echo "✓ tmux"
fi

# gitignore -> ~/.config/git/ignore
if [[ -f "$SCRIPT_DIR/git/ignore" ]]; then
  cp "$SCRIPT_DIR/git/ignore" "$HOME/.config/git/ignore"
  echo "✓ git/ignore"
fi

# Rectangle settings (macOS) -> com.knollsoft.Rectangle
if [[ -f "$SCRIPT_DIR/rectangle/RectangleSettings.plist" ]]; then
  if command -v defaults >/dev/null 2>&1; then
    # Import plist into Rectangle's domain
    defaults import com.knollsoft.Rectangle "$SCRIPT_DIR/rectangle/RectangleSettings.plist" || true
    echo "✓ Rectangle settings imported"
  else
    echo "⚠︎ 'defaults' not found; skipping Rectangle import" >&2
  fi
fi

echo "All done ✅"
