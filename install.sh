#!/usr/bin/env bash
set -euo pipefail


ARCH="$(uname -m)"                 # arm64 ou x86_64
UNAME_S="$(uname -s)"

if [[ "$UNAME_S" == "Darwin" ]]; then
  OS="macos"
  JQ_OS="darwin"
elif [[ "$UNAME_S" == "Linux" ]]; then
  OS="linux"
  JQ_OS="linux"
else
  echo "Sistema operacional não suportado: $UNAME_S"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="${HOME}/.local/tools"
BIN_DIR="${HOME}/.local/bin"
ENV_ZPROFILE="${HOME}/.zprofile"

mkdir -p "$TOOLS_DIR" "$BIN_DIR"

# Utilitário: cria shim
make_shim() {
  local tool="$1" version="$2" binrel="$3"
  local shim="${BIN_DIR}/${tool}"
  cat > "$shim" <<EOF
#!/usr/bin/env bash
exec "${TOOLS_DIR}/${tool}/${version}/${binrel}" "\$@"
EOF
  chmod +x "$shim"
}

# Lê valor do manifest (usando python nativo do macOS)
json_get() {
  /usr/bin/python3 - "$1" "$2" << 'PY'
import json,sys
data=json.load(open(sys.argv[1]))
key=sys.argv[2]
print(data[key])
PY
}

MANIFEST="${ROOT}/manifests/tools-${OS}-${ARCH}.json"
if [[ ! -f "$MANIFEST" ]]; then
  echo "Manifesto não encontrado: $MANIFEST"
  exit 1
fi

# 1) Maven (copia diretório já extraído)
MAVEN_VERSION="$(json_get "$MANIFEST" maven_version)"
MAVEN_SRC="${ROOT}/payloads/maven/${MAVEN_VERSION}"
MAVEN_DST="${TOOLS_DIR}/maven/${MAVEN_VERSION}"
if [[ ! -d "$MAVEN_SRC/apache-maven-${MAVEN_VERSION}" ]]; then
  echo "Maven não encontrado em ${MAVEN_SRC}"
  exit 1
fi
mkdir -p "$MAVEN_DST"
rsync -a "${MAVEN_SRC}/" "$MAVEN_DST/"
make_shim "maven" "$MAVEN_VERSION" "apache-maven-${MAVEN_VERSION}/bin/mvn"

# 2) Gradle
GRADLE_VERSION="$(json_get "$MANIFEST" gradle_version)"
GRADLE_SRC="${ROOT}/payloads/gradle/${GRADLE_VERSION}"
GRADLE_DST="${TOOLS_DIR}/gradle/${GRADLE_VERSION}"
if [[ ! -d "$GRADLE_SRC/gradle-${GRADLE_VERSION}" ]]; then
  echo "Gradle não encontrado em ${GRADLE_SRC}"
  exit 1
fi
mkdir -p "$GRADLE_DST"
rsync -a "${GRADLE_SRC}/" "$GRADLE_DST/"
make_shim "gradle" "$GRADLE_VERSION" "gradle-${GRADLE_VERSION}/bin/gradle"


# 3) jq (binário único)
JQ_SRC="${ROOT}/payloads/jq/${JQ_OS}-${ARCH}/jq"
JQ_DST_DIR="${TOOLS_DIR}/jq/portable"
mkdir -p "$JQ_DST_DIR"
cp "$JQ_SRC" "${JQ_DST_DIR}/jq"
chmod +x "${JQ_DST_DIR}/jq"
make_shim "jq" "portable" "jq"


# 4) JDKs (descompacta e organiza por arquitetura/versão)
JDKS=(8 17 21)
JAVA_DIR="${TOOLS_DIR}/java/${OS}-${ARCH}"
JDK_SRC_DIR="${ROOT}/payloads/java/${OS}-${ARCH}"
mkdir -p "$JAVA_DIR"
for ver in "${JDKS[@]}"; do
  JDK_TAR="${JDK_SRC_DIR}/jdk-${ver}.tar.gz"
  JDK_DST="${JAVA_DIR}/${ver}"
  if [[ -f "$JDK_TAR" ]]; then
    mkdir -p "$JDK_DST"
    tar -xzf "$JDK_TAR" -C "$JDK_DST" --strip-components=1
    echo "JDK ${ver} instalado em $JDK_DST"
  else
    echo "JDK ${ver} não encontrado em $JDK_TAR (ignorado)"
  fi
done

# Cria shim para java-switch
JAVA_SWITCH_SHIM="${BIN_DIR}/java-switch"
cat > "$JAVA_SWITCH_SHIM" <<'EOF'
#!/usr/bin/env bash
ver="$1"
if [[ -z "$ver" ]]; then
  echo "Uso: java-switch <versao>" >&2
  exit 1
fi
JAVA_DIR="$HOME/.local/tools/java/${OS}-${ARCH}/$ver"
if [[ ! -d "$JAVA_DIR" ]]; then
  echo "JDK $ver não encontrado em $JAVA_DIR" >&2
  exit 2
fi
JAVA_HOME="$JAVA_DIR"
JAVA_BIN="$JAVA_HOME/bin"
PROFILE="$HOME/.zprofile"
ZSHRC="$HOME/.zshrc"
for file in "$PROFILE" "$ZSHRC"; do
  if [[ -f "$file" ]]; then
    # Remove JAVA_HOME e PATH anteriores
    sed -i.bak '/export JAVA_HOME=/d' "$file"
    sed -i.bak '/export PATH="$JAVA_HOME\/bin:$PATH"/d' "$file"
    rm -f "$file.bak"
    # Adiciona novos
    echo "export JAVA_HOME=\"$JAVA_HOME\"" >> "$file"
    echo "export PATH=\"$JAVA_BIN:$PATH\"" >> "$file"
  fi
done
echo "JAVA_HOME atualizado para $JAVA_HOME. Rode: source ~/.zprofile"
EOF
chmod +x "$JAVA_SWITCH_SHIM"


# Função para adicionar bloco ao arquivo de perfil se não existir
add_env_block() {
  local file="$1"
  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$file" 2>/dev/null; then
    {
      echo 'export PATH="$HOME/.local/bin:$PATH"'
      echo 'export MAVEN_OPTS="-Xmx512m ${MAVEN_OPTS}"'
      echo 'export GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx1g ${GRADLE_OPTS}"'
    } >> "$file"
    return 0
  fi
  return 1
}

ADDED_PATH=0
add_env_block "$ENV_ZPROFILE" && ADDED_PATH=1
add_env_block "$HOME/.zshrc" && ADDED_PATH=1

echo "Ferramentas instaladas em: $TOOLS_DIR"
echo "Shims criados em: $BIN_DIR"
[[ "${ADDED_PATH:-0}" == "1" ]] && echo '>> Adicionado PATH em ~/.zprofile (rode: source ~/.zprofile)'
echo "JDKs instalados em: $JAVA_DIR"
echo "Use: java-switch <versao> para alternar JAVA_HOME (ex: java-switch 17)"
echo "Teste: mvn -v | gradle -v | jq --version | java -version"
