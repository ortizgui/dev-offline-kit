
# dev-offline-kit

Ferramentas de desenvolvimento totalmente offline, sem necessidade de sudo, Homebrew ou acesso à internet.  
Ideal para ambientes restritos (proxy, rede fechada, máquinas corporativas).

## Objetivo

Instalar Maven, Gradle, utilitários (jq) e plugins úteis do Zsh em sistemas macOS (Apple Silicon) e Linux(x86_64), usando apenas scripts locais e arquivos já incluídos no repositório.

## Principais recursos

- Instalação offline de Maven, Gradle e jq.
- Instalação de plugins Zsh populares: autosuggestions, syntax-highlighting, history-substring-search.
- Scripts adaptados para detectar automaticamente o sistema operacional e arquitetura (macOS Apple Silicon/x86_64, Linux ARM/x86_64).
- Não requer permissões administrativas (sudo) nem acesso à internet.
- Fácil remoção/desinstalação.

## Requisitos

- macOS (arm64 ou x86_64) ou Linux (arm64 ou x86_64).
- Bash e unzip instalados (padrão do sistema).
- Sem internet; sem sudo.

## Instalação

1. Baixe este repositório como ZIP e extraia.
2. No diretório extraído, rode:
   ```sh
   bash install.sh
   bash zsh/install-zsh-plugins.sh
   ```
3. Ative o PATH:
   ```sh
   source ~/.zprofile
   ```
4. Teste as ferramentas:
   ```sh
   mvn -v
   gradle -v
   jq --version
   ```

## Estrutura instalada

- Ferramentas: `~/.local/tools/<tool>/<versão>/`
- Binários (shims): `~/.local/bin/{mvn,gradle,jq,yq}`
- Plugins Zsh: `~/.local/share/zsh-plugins/`
- Manifests e payloads organizados por sistema/arquitetura.

## Observações

- O kit instala apenas as ferramentas. Para baixar dependências de projetos (ex: Maven Central), é necessário acesso à rede ou a um mirror interno.
- Para desinstalar, remova os diretórios em `~/.local/tools/`, os shims em `~/.local/bin/` e as linhas adicionadas ao `~/.zprofile`.

## Licenças

Consulte os textos de licença dos projetos em `/licenses` conforme necessário.