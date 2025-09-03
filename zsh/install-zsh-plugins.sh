#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="${HOME}/.local/share/zsh-plugins"
mkdir -p "$DEST"

rsync -a "${ROOT}/plugins/" "$DEST/"

SNIPPET="${HOME}/.zshrc"
if ! grep -q "dev-offline-kit zsh plugins" "$SNIPPET" 2>/dev/null; then
  cat >> "$SNIPPET" <<'EOF'

# --- dev-offline-kit zsh plugins ---
source $HOME/.local/share/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/.local/share/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/.local/share/zsh-plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# Bindings úteis (busca no histórico por substring)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Ajustes de histórico
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
# ----------------------------------
EOF
  echo "Snippet adicionado ao ~/.zshrc"
fi

echo "Plugins do zsh instalados em $DEST. Reinicie o terminal."