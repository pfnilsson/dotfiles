# Use vi mode
bindkey -v

# Pretty json output from curl
curljq() {
  output=$(curl -sS "$@")
  if echo "$output" | jq . >/dev/null 2>&1; then
    echo "$output" | jq
  else
    echo "$output"
  fi
}

# Start devbox shell
dbu() {
  local input="$1"
  devbox up "$input" --ide=none && devbox shell "$input"
}

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

# Bazel aliases
alias brg="bazel run //:gazelle"
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
