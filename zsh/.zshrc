# Directory for Zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if we don't already have it
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source Zinit
source "${ZINIT_HOME}/zinit.zsh"

function zvm_config() {
    # Use system clipboard
    ZVM_SYSTEM_CLIPBOARD_ENABLED=true
}

function zvm_after_lazy_keybindings() {
    # use system clipboard with paste
    bindkey -M vicmd 'p' zvm_paste_clipboard_after
    bindkey -M vicmd 'P' zvm_paste_clipboard_before
    bindkey -M visual 'p' zvm_visual_paste_clipboard
    bindkey -M visual 'P' zvm_visual_paste_clipboard
}

function zvm_after_init() {
    # Fuzzy find integration (must be loaded after zsh-vi-mode)
    eval "$(fzf --zsh)"

    # Ctrl+Y to accept autosuggestions (must be set after zsh-vi-mode loads)
    bindkey '^Y' autosuggest-accept
}

# Add Zinit plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light jeffreytse/zsh-vi-mode

# Init completion system
autoload -U compinit && compinit
zinit cdreplay -q

# fzf-tab must be AFTER compinit
zinit light Aloxaf/fzf-tab

# Catppuccin theme for zsh-syntax-highlighting
zinit ice depth=1 pick"themes/catppuccin_mocha-zsh-syntax-highlighting.zsh"
zinit light catppuccin/zsh-syntax-highlighting
zinit light zsh-users/zsh-syntax-highlighting

# Completion styling
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

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

# Set prompt
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
alias btd="bazel test //nodes/platform/decisionsystems/... --test_output=errors --test_tag_filters="
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

# Add go to path
export PATH=$PATH:/usr/local/go/bin:$HOME/.local/bin/

export PATH="$HOME/go/bin:$PATH"
