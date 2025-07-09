# ─────────────────────────────────────────────────────────────
# 0) Define cursor styles for vi modes
# ─────────────────────────────────────────────────────────────
CURSOR_BLOCK=$'\e[2 q'
CURSOR_BAR=$'\e[6 q'

# ─────────────────────────────────────────────────────────────
# 1) make Esc → normal-mode timeout razor-sharp
# ─────────────────────────────────────────────────────────────
# wait only 10 ms for any bytes after ESC
KEYTIMEOUT=1

# ─────────────────────────────────────────────────────────────
# 2) enable vi-mode
# ─────────────────────────────────────────────────────────────
bindkey -v

# ─────────────────────────────────────────────────────────────
# 3) explicit arrow-keys in insert-mode for history/cursor
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
# 4) remap Enter/CR in insert-mode to newline, use Ctrl-J to accept
# ─────────────────────────────────────────────────────────────

bindkey -M viins $'\C-j' self-insert   # Ctrl-J inserts a literal newline
bindkey -M viins $'\r'   accept-line   # Enter submits the buffer

# ─────────────────────────────────────────────────────────────
# 5) bindings in command (normal) mode
# ─────────────────────────────────────────────────────────────
# jump to first non-blank
bindkey -M vicmd '"' vi-first-non-blank
# end of line
bindkey -M vicmd '€' vi-end-of-line
# yank to end of line
bindkey -M vicmd 'Y' vi-yank-eol
# delete whole line under cursor (like dd in Vim)
zle_dd_to_clipboard() {
  zle kill-whole-line            # kill the line into CUTBUFFER
  print -rn -- "$CUTBUFFER" | $CLIP_IN
}
zle -N zle_dd_to_clipboard

# Now bind 'dd' in normal mode to our new widget:
bindkey -M vicmd 'dd' zle_dd_to_clipboard
# visual to end of line (V)
function vi-visual-to-eol() {
  zle visual-mode
  zle vi-end-of-line
}
zle -N vi-visual-to-eol
bindkey -M vicmd 'V' vi-visual-to-eol
# visual select current line (vv)
function vi-visual-whole-line() {
  zle vi-beginning-of-line
  zle visual-mode
  zle vi-end-of-line
}
zle -N vi-visual-whole-line
bindkey -M vicmd 'vv' vi-visual-whole-line

# ─────────────────────────────────────────────────────────────
# 6) clipboard integration (xclip, xsel, or pbcopy/pbpaste)
# ─────────────────────────────────────────────────────────────
if   command -v xclip >/dev/null 2>&1; then
  CLIP_IN='xclip -in -selection clipboard'
  CLIP_OUT='xclip -out -selection clipboard'
elif command -v xsel >/dev/null 2>&1; then
  CLIP_IN='xsel --clipboard --input'
  CLIP_OUT='xsel --clipboard --output'
elif command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
  CLIP_IN='pbcopy'
  CLIP_OUT='pbpaste'
else
  echo "⚠️ No clipboard tool found. Install xclip, xsel, or pbcopy/pbpaste." >&2
fi

# Paste before cursor (P)
zle_paste_before() {
  local head=${BUFFER[1,CURSOR]}
  local tail=${BUFFER[CURSOR+1,-1]}
  local paste=$($CLIP_OUT)
  BUFFER=$head$paste$tail
  CURSOR=$(( CURSOR + ${#paste} - 1 ))
  zle reset-prompt
}
zle -N zle_paste_before
bindkey -M vicmd 'P' zle_paste_before

# paste after cursor (p)
zle_paste_after() {
  local head=${BUFFER[1,CURSOR+1]}
  local tail=${BUFFER[CURSOR+2,-1]}
  local paste=$($CLIP_OUT)
  BUFFER=$head$paste$tail
  CURSOR=$(( CURSOR + ${#paste} ))
  zle reset-prompt
}
zle -N zle_paste_after
bindkey -M vicmd 'p' zle_paste_after

# yank line (yy)
zle_yank_line() {
  print -rn -- "$BUFFER" | $CLIP_IN
  zle reset-prompt
}
zle -N zle_yank_line
bindkey -M vicmd 'yy' zle_yank_line

# ─────────────────────────────────────────────────────────────
# 7) dynamic cursor shape based on keymap
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

if [[ -o interactive ]]; then
  zle_keymap_select() {
    if [[ $KEYMAP == vicmd ]]; then
      printf '%s' "$CURSOR_BLOCK" > /dev/tty
    else
      printf '%s' "$CURSOR_BAR"   > /dev/tty
    fi
  }

  zle -N zle-keymap-select zle_keymap_select
  zle -N zle-line-init     zle_keymap_select
fi

# enable backspace in insert mode
bindkey -M viins '^?' backward-delete-char

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
  local socket="/tmp/nvim-$(echo "$PWD" | tr '/' '_').sock"
  command nvim --listen "$socket" "$@"
}

# Start nvim with remote
export NVIM_LISTEN_ADDRESS="/tmp/nvim.sock"

# Languge specific grep shorthands
alias grepy="grep -rn --include='*.py' --exclude-dir='*venv'"
alias grepgo="grep -rn --include='*.go'"

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
eval "$(jenv init -)"

# gazelle utility function including restarting gopls 
function gazelle() {
  if bazel run //:gazelle -- "$@"; then
    local socket="/tmp/nvim-$(echo "$PWD" | tr '/' '_').sock"
    # Check if Neovim is running on that socket
    if nvr --servername "$socket" --nostart --remote-expr "v:true" &>/dev/null; then
      # Invoke your custom :GoplsRestart in the remote Neovim
      nvr --servername "$socket" --nostart -c "GoplsRestart" || true
      echo "✅ gopls restarted via :GoplsRestart"
    else
      echo "⚠️ Neovim isn’t running or listening at $socket"
    fi
  else
    echo "❌ gazelle failed"
  fi
}

# Bazel aliases
alias brg="gazelle"
alias btd="bazel test //nodes/decisionsystems/... --test_output=errors --test_tag_filters="
alias bmt="bazel run //:go -- mod tidy -e"

# Colorize ls
alias ls="ls --color=auto"

# Source pretzel
source /Users/fredrik/.pretzel/pretzel.zsh

# Use neovim as default editor
export EDITOR="nvim"
export VISUAL="nvim"

# Excplicitly bind Ctrl-R to reverse search because tmux sometimes breaks it
bindkey '^R' history-incremental-search-backward

# Syntax highlighting
source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
