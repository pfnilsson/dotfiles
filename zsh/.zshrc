# ─────────────────────────────────────────────────────────────
# Better vi mode
# ─────────────────────────────────────────────────────────────
function zvm_config() {
    # Use system clipboard
    ZVM_SYSTEM_CLIPBOARD_ENABLED=true
}

# use system clipboard with paste
function zvm_after_lazy_keybindings() {
    bindkey -M vicmd 'p' zvm_paste_clipboard_after
    bindkey -M vicmd 'P' zvm_paste_clipboard_before
    bindkey -M visual 'p' zvm_visual_paste_clipboard
    bindkey -M visual 'P' zvm_visual_paste_clipboard
}

# source the plugin
source ~/.zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# ─────────────────────────────────────────────────────────────
# explicit arrow-keys in insert-mode for history/cursor
# ─────────────────────────────────────────────────────────────
# CSI-style
bindkey -M viins '^[[A' up-line-or-history
bindkey -M viins '^[[B' down-line-or-history
bindkey -M viins '^[[C' forward-char
bindkey -M viins '^[[D' backward-char
# SS3-style (some terminals send these in application mode)
bindkey -M viins '^[OA' up-line-or-history
bindkey -M viins '^[OB' down-line-or-history
bindkey -M viins '^[OC' forward-char
bindkey -M viins '^[OD' backward-char

# ─────────────────────────────────────────────────────────────
# remap Enter/CR in insert-mode to newline, use Ctrl-J to accept
# ─────────────────────────────────────────────────────────────

bindkey -M viins $'\C-j' self-insert   # Ctrl-J inserts a literal newline
bindkey -M viins $'\r'   accept-line   # Enter submits the buffer

# ─────────────────────────────────────────────────────────────
# bindings in command (normal) mode
# ─────────────────────────────────────────────────────────────
# jump to first non-blank
bindkey -M vicmd '"' vi-first-non-blank
# end of line
bindkey -M vicmd '€' vi-end-of-line
bindkey -M vicmd '¤' vi-end-of-line
# yank to end of line
bindkey -M vicmd 'Y' vi-yank-eol

# ─────────────────────────────────────────────────────────────
# get the real arrow‐key sequences from terminfo
local KU="${terminfo[kcuu1]}"   # Up
local KD="${terminfo[kcud1]}"   # Down
local KL="${terminfo[kcub1]}"   # Left
local KR="${terminfo[kcuf1]}"   # Right

# in insert mode, use arrows for history and cursor movements
bindkey -M viins "$KU" up-line-or-history
bindkey -M viins "$KD" down-line-or-history
bindkey -M viins "$KL" backward-char
bindkey -M viins "$KR" forward-char

# enable backspace in insert mode
bindkey -M viins '^?' backward-delete-char

# set prompt
PROMPT='%n@%m %1~ %% '

# Pretty json output from curl
curljq() {
  output=$(curl -sS "$@")
  if echo "$output" | jq . >/dev/null 2>&1; then
    echo "$output" | jq
  else
    echo "$output"
  fi
}

# Start nvim with a socket name per cwd
nvim() {
  local base="/tmp/nvim-$(tr '/' '_' <<<"$PWD").sock"
  local socket="$base"

  # If a socket file exists, check if a Neovim server is actually alive on it.
  if [ -S "$base" ]; then
    if command nvim --server "$base" --remote-expr 1 >/dev/null 2>&1; then
      # Alive: pick a random-suffix socket name, keeping the first deterministic.
      local base_noext="${base%.sock}" suffix
      while :; do
        suffix="$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
        socket="${base_noext}-${suffix}.sock"
        [ ! -e "$socket" ] && break
      done
    else
      # Stale socket: remove it so we can reuse the deterministic name.
      rm -f -- "$base"
      socket="$base"
    fi
  fi

  command nvim --listen "$socket" "$@"
}

# Start nvim with remote
export NVIM_LISTEN_ADDRESS="/tmp/nvim.sock"

# Enable advanced tab-completion features in zsh
autoload -Uz compinit && compinit

# Source rust env
. "$HOME/.cargo/env"

# Python version aliases to use uv as python installer
alias python3.9="~/.local/share/uv/python/cpython-3.9.20-macos-aarch64-none/bin/python3.9"
alias python3.10="~/.local/share/uv/python/cpython-3.10.15-macos-aarch64-none/bin/python3.10"
alias python3.11="~/.local/share/uv/python/cpython-3.11.10-macos-aarch64-none/bin/python3.11"
alias python3.12="~/.local/share/uv/python/cpython-3.12.7-macos-aarch64-none/bin/python3.12"

# Java env init
if command -v jenv >/dev/null 2>&1; then
    eval "$(jenv init -)"
fi

# gazelle utility function including restarting gopls 
function gazelle() {
  if bazel run //:gazelle -- "$@"; then
    local socket="/tmp/nvim-$(echo "$PWD" | tr '/' '_').sock"
    if nvr --servername "$socket" --nostart --remote-expr "v:true" &>/dev/null; then
      nvr --servername "$socket" --nostart -c 'LspRestart gopls' || true
      echo "✅ gopls restarted"
    else
      echo "⚠️ Neovim isn’t running or listening at $socket"
    fi
  else
    echo "❌ gazelle failed"
  fi
}
# Bazel aliases
alias brg="gazelle"
alias btd="bazel test //nodes/foundations/decisionsystems/... --test_output=errors --test_tag_filters="
alias bmt="bazel run //:go -- mod tidy -e"
alias bf="bazel run :gofmt --"

bt() {
  local dir=${1:h}
  command bazel test "//$dir/..." --test_output=errors --test_tag_filters= "$@"
}

# Colorize ls
alias ls="ls --color=auto"

# Source pretzel
PRETZEL_FILE="$HOME/.pretzel/pretzel.zsh"
if [[ -f "$PRETZEL_FILE" ]]; then
    source "$PRETZEL_FILE"
fi


# Use neovim as default editor
export EDITOR="nvim"
export VISUAL="nvim"

# Excplicitly bind Ctrl-R to reverse search because tmux sometimes breaks it
bindkey '^R' history-incremental-search-backward

# Syntax highlighting
source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh
if [[ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Add go to path
export PATH=$PATH:/usr/local/go/bin:$HOME/.local/bin/

