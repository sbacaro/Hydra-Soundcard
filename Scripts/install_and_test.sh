#!/bin/bash
# Hydra Audio — Build, Test and Install Helper Script
set -euo pipefail

# Change to the repository root directory
cd "$(dirname "${BASH_SOURCE[0]}")/.."

BOLD=$'\033[1m'
RESET=$'\033[0m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'
YELLOW=$'\033[33m'

log() {
    printf '\n%s=== %s ===%s\n' "$BOLD$CYAN" "$*" "$RESET"
}

# 1. Terminar processos antigos
log "Encerrando instâncias ativas do Hydra e desativando daemons conflitantes do Dante..."
killall Hydra 2>/dev/null || true
killall hydra-inferno-bridge 2>/dev/null || true
sudo launchctl unload /Library/LaunchDaemons/com.audinate.dante.ConMon.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchDaemons/com.audinate.dante.DanteVirtualSoundcard.plist 2>/dev/null || true

# 2. Executar testes unitários
log "Executando os testes unitários do Hydra..."
xcodebuild test -scheme HydraCore -destination "platform=macOS" -quiet
xcodebuild test -scheme HydraRTTests -destination "platform=macOS" -quiet
xcodebuild test -scheme HydraSurfaceTests -destination "platform=macOS" -quiet
echo -e "${GREEN}✓ Todos os testes passaram!${RESET}"

# 3. Compilar e gerar o pacote installer
log "Compilando o aplicativo e gerando o pacote .pkg..."
bash Packaging/build_pkg.sh

# 4. Instalar o pacote .pkg
log "Instalando o Hydra no macOS (será solicitada a senha sudo)..."
sudo installer -pkg dist/Hydra-2.1.4.pkg -target /

# 5. Abrir a versão atualizada
log "Iniciando a versão atualizada do Hydra..."
open /Applications/Hydra.app

echo -e "\n${BOLD}${GREEN}✓ Hydra instalado com sucesso em /Applications e iniciado!${RESET}\n"
