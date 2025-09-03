# dev-offline-kit (offline total, sem sudo)

Objetivo: instalar Maven, Gradle e utilitários (jq, yq) + plugins úteis do zsh em ambientes com proxy restritivo, sem Homebrew e sem rede. Basta baixar este repositório como ZIP, extrair e rodar os scripts locais.

## Requisitos
- macOS (arm64 ou x86_64) com bash + unzip (padrão do sistema).
- Sem internet; sem sudo.

## Instalação
1. Baixe este repositório como ZIP (Code → Download ZIP) e extraia.
2. No diretório extraído, rode:
   bash install.sh
   bash zsh/install-zsh-plugins.sh
3. Ative o PATH:
   source ~/.zprofile
4. Teste:
   mvn -v
   gradle -v
   jq --version
   yq --version

## Conteúdo instalado
- Maven: ~/.local/tools/maven/<versão>/apache-maven-<versão>
- Gradle: ~/.local/tools/gradle/<versão>/gradle-<versão>
- jq / yq: ~/.local/tools/*/portable/
- Shims: ~/.local/bin/{mvn,gradle,jq,yq}
- Plugins zsh: ~/.local/share/zsh-plugins/ (autosuggestions, syntax-highlighting, history-substring-search)

## Notas sobre dependências de build
Este kit só cobre as ferramentas. Se seu projeto precisar baixar dependências (Maven Central etc.), será necessário acesso a um mirror interno ou liberar os domínios no proxy.

## Desinstalar
- Remova ~/.local/tools/<tool>/...
- Remova shims em ~/.local/bin/...
- Remova o snippet do ~/.zshrc e as linhas do ~/.zprofile (PATH).

## Licenças
Inclua textos de licença dos projetos em /licenses conforme necessário.


dev-offline-kit/
├─ README.md
├─ install_offline.sh                  # não baixa nada: só copia e cria shims
├─ manifests/
│  ├─ tools-macos-arm64.json
│  └─ tools-macos-x86_64.json
├─ payloads/                           # TUDO que será instalado vem daqui
│  ├─ maven/
│  │  └─ 3.9.9/apache-maven-3.9.9/...
│  ├─ gradle/
│  │  └─ 8.10.2/gradle-8.10.2/...
│  ├─ jq/
│  │  ├─ darwin-arm64/jq
│  │  └─ darwin-x86_64/jq
│  └─ yq/
│     ├─ darwin-arm64/yq
│     └─ darwin-x86_64/yq
└─ zsh/
   ├─ install-zsh-plugins.sh
   ├─ snippets/zshrc.snippet
   └─ plugins/
      ├─ zsh-autosuggestions/...
      ├─ zsh-syntax-highlighting/...
      └─ zsh-history-substring-search/...
      # (opcional) fzf-tab/ e binário do fzf em payloads/fzf/...