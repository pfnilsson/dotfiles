# Use vi mode
bindkey -v

# Binds shift-2 to first non blank
bindkey -M vicmd '"' vi-first-non-blank

# binds shift-4 to end of line
bindkey -M vicmd '€' vi-end-of-line

# binds Y to yank to end of line
bindkey -M vicmd 'Y' vi-yank-eol

# binds V to visual to end of line
function vi-visual-to-eol() {
  zle visual-mode
  zle vi-end-of-line
}
zle -N vi-visual-to-eol
bindkey -M vicmd 'V' vi-visual-to-eol

# bind vv to visual select current line 
function vi-visual-whole-line() {
  zle vi-beginning-of-line
  zle visual-mode
  zle vi-end-of-line
}
zle -N vi-visual-whole-line
bindkey -M vicmd 'vv' vi-visual-whole-line

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
    # Check if Neovim is running and listening at the computed socket.
    if nvr --servername "$socket" --nostart --remote-expr "v:true" &>/dev/null; then
      # Restart gopls if it's running inside the found Neovim instance.
      nvr --servername "$socket" --nostart -c \
        "lua for _,c in pairs(vim.lsp.get_clients()) do if c.name=='gopls' then vim.cmd('LspRestart gopls') break end end" \
        || true
      echo "✅ gopls restarted via Neovim remote"
    else
      echo "⚠️ Neovim is not running or not listening at $socket"
    fi
  else
    echo "❌ gazelle failed"
  fi
}

# Bazel aliases
alias brg="gazelle"
alias btd="bazel test //nodes/decision-systems/... --test_output=errors"
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
