#!/usr/bin/env bash
set -euo pipefail

TOOLS_DIR="$HOME/.local/tools"
BIN_DIR="$HOME/.local/bin"
ENV_ZPROFILE="$HOME/.zprofile"
ZSHRC="$HOME/.zshrc"

# Remove Maven, Gradle, jq
rm -rf "$TOOLS_DIR/maven" "$TOOLS_DIR/gradle" "$TOOLS_DIR/jq"

# Remove shims
rm -f "$BIN_DIR/maven" "$BIN_DIR/gradle" "$BIN_DIR/jq"

# Remove PATH and JVM options block from profile files
remove_env_block() {
  local file="$1"
  if [[ -f "$file" ]]; then
    sed -i.bak '/export PATH="$HOME\/\.local\/bin:$PATH"/d' "$file"
    sed -i.bak '/export MAVEN_OPTS="-Xmx512m ${MAVEN_OPTS}"/d' "$file"
    sed -i.bak '/export GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx1g ${GRADLE_OPTS}"/d' "$file"
    # Remove backup if desired
    rm -f "$file.bak"
  fi
}

remove_env_block "$ENV_ZPROFILE"
remove_env_block "$ZSHRC"

echo "Ferramentas Maven, Gradle e jq removidas."
echo "Shims removidos de $BIN_DIR."
echo "Blocos de configuração removidos de ~/.zprofile e ~/.zshrc."
