#!/usr/bin/env bash
# Script de backup automatizado com retenção para o banco de dados LevelDB do mundo

set -euo pipefail

WORLD_NAME="EpocaNova"
SERVER_DIR="/home/ubuntu/bedrock_server/dados"
BACKUP_DIR="/home/ubuntu/backups/bedrock"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

mkdir -p "$BACKUP_DIR"

echo "[INFO] Iniciando backup do mundo: $WORLD_NAME ($TIMESTAMP)..."
cp -r "$SERVER_DIR/worlds/$WORLD_NAME" "$BACKUP_DIR/${WORLD_NAME}_${TIMESTAMP}"

echo "[INFO] Compactando arquivos..."
tar -czf "$BACKUP_DIR/${WORLD_NAME}_${TIMESTAMP}.tar.gz" -C "$BACKUP_DIR" "${WORLD_NAME}_${TIMESTAMP}"
rm -rf "$BACKUP_DIR/${WORLD_NAME}_${TIMESTAMP}"

# Mantém apenas os últimos 7 backups para preservar a cota de armazenamento da instância
ls -1t "$BACKUP_DIR"/*.tar.gz | tail -n +8 | xargs -r rm --

echo "[OK] Backup concluído com sucesso em: $BACKUP_DIR/${WORLD_NAME}_${TIMESTAMP}.tar.gz"