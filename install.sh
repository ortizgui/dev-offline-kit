#!/usr/bin/env bash
set -euo pipefail

ARCH="$(uname -m)"                 # arm64 ou x86_64
OS="macos"

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
JQ_SRC="${ROOT}/payloads/jq/darwin-${ARCH}/jq"
JQ_DST_DIR="${TOOLS_DIR}/jq/portable"
mkdir -p "$JQ_DST_DIR"
cp "$JQ_SRC" "${JQ_DST_DIR}/jq"
chmod +x "${JQ_DST_DIR}/jq"
make_shim "jq" "portable" "jq"

# 4) yq (binário único)
YQ_SRC="${ROOT}/payloads/yq/darwin-${ARCH}/yq"
YQ_DST_DIR="${TOOLS_DIR}/yq/portable"
mkdir -p "$YQ_DST_DIR"
cp "$YQ_SRC" "${YQ_DST_DIR}/yq"
chmod +x "${YQ_DST_DIR}/yq"
make_shim "yq" "portable" "yq"

# PATH + ajustes de JVM (opcional)
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$ENV_ZPROFILE" 2>/dev/null; then
  {
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo 'export MAVEN_OPTS="-Xmx512m ${MAVEN_OPTS}"'
    echo 'export GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx1g ${GRADLE_OPTS}"'
  } >> "$ENV_ZPROFILE"
  ADDED_PATH=1
fi

echo "Ferramentas instaladas em: $TOOLS_DIR"
echo "Shims criados em: $BIN_DIR"
[[ "${ADDED_PATH:-0}" == "1" ]] && echo '>> Adicionado PATH em ~/.zprofile (rode: source ~/.zprofile)'
echo "Teste: mvn -v | gradle -v | jq --version | yq --version"