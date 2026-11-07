# 🛠️ Guia de Operações e Manutenção (Runbook)

Este documento reúne os comandos essenciais para administração diária, monitoramento de recursos, gerenciamento do console, backups e atualização do servidor dedicado na instância **Ubuntu ARM64 (Oracle Cloud)**.

---

## 1. Gerenciamento do Serviço 24/7 (`systemd`)

O servidor Bedrock é gerenciado nativamente pelo `systemd` através do serviço `bedrock.service`, configurado com reinicialização automática (`Restart=always`) e desligamento seguro (`graceful stop`).

* **Verificar se o servidor está rodando (Status):**
  ```bash
  sudo systemctl status bedrock.service
  ```
  *(Pressione a tecla `q` para sair da tela de status).*

* **Reiniciar o servidor (Salva o mundo automaticamente antes de reiniciar):**
  ```bash
  sudo systemctl restart bedrock.service
  ```

* **Parar o servidor com segurança (Salva o mundo e encerra o processo):**
  ```bash
  sudo systemctl stop bedrock.service
  ```

* **Iniciar o servidor manualmente (Caso esteja parado):**
  ```bash
  sudo systemctl start bedrock.service
  ```

* **Acompanhar os logs de sistema em tempo real:**
  ```bash
  sudo journalctl -u bedrock.service -f
  ```
  *(Pressione `Ctrl + C` para sair da visualização de logs sem desligar o servidor).*

---

## 2. Acesso ao Console do Jogo (`GNU Screen`)

O processo do servidor roda em segundo plano dentro de uma sessão dedicada chamada `bedrock` no `GNU Screen`.

* **Entrar no console ao vivo do servidor:**
  ```bash
  screen -r bedrock
  ```
  > ⚠️ **IMPORTANTE:** Para sair dessa tela e voltar ao terminal normal **sem desligar o servidor**, segure **`Ctrl`**, aperte **`A`**, solte as teclas e aperte **`D`** (*Detach*). **Nunca** aperte `Ctrl + C` dentro do console, pois isso encerrará o servidor.

* **Injetar comandos no jogo sem precisar abrir o console:**
  * Enviar mensagem no chat global:
    ```bash
    screen -S bedrock -p 0 -X stuff "say Aviso: Manutencao programada em 5 minutos!$(printf \\r)"
    ```
  * Enviar alerta em destaque no meio da tela de todos os jogadores:
    ```bash
    screen -S bedrock -p 0 -X stuff "title @a title Servidor Atualizado!$(printf \\r)"
    ```
  * Ativar coordenadas na tela (sem ativar Cheats / mantendo conquistas):
    ```bash
    screen -S bedrock -p 0 -X stuff "gamerule showcoordinates true$(printf \\r)"
    ```
  * Alterar a dificuldade do mundo:
    ```bash
    screen -S bedrock -p 0 -X stuff "difficulty hard$(printf \\r)"
    ```

---

## 3. Monitoramento de Saúde da Máquina (CPU, RAM e Disco)

* **Painel interativo em tempo real (4 núcleos ARM64 e 24 GB de RAM):**
  ```bash
  htop
  ```
  *(Pressione `q` ou `F10` para sair).*

* **Monitorar exclusivamente o processo do servidor Bedrock:**
  ```bash
  top -c -p $(pgrep -d',' -f bedrock_atual)
  ```

* **Verificar espaço livre e ocupado no disco (SSD da instância):**
  ```bash
  df -h
  ```

* **Verificar resumo de consumo de memória RAM e Swap:**
  ```bash
  free -h
  ```

---

## 4. Rotinas de Backup do Mundo (`LevelDB`)

* **Executar o script automatizado de backup compactado (`.tar.gz`) com retenção de 7 dias:**
  ```bash
  bash /home/ubuntu/bedrock_server/scripts/backup-world.sh
  ```

* **Fazer uma cópia manual rápida antes de testes ou atualizações:**
  ```bash
  cp -r /home/ubuntu/bedrock_server/dados/worlds/EpocaNova /home/ubuntu/backup_EpocaNova_$(date +%F)
  ```

* **Listar backups existentes e seus tamanhos:**
  ```bash
  ls -lh /home/ubuntu/backups/bedrock/
  ```

---

## 5. Procedimento de Atualização de Versão (Arquitetura Híbrida)

Quando o Minecraft Bedrock lançar uma nova versão oficial, o contêiner Docker é utilizado para baixar e extrair a atualização automaticamente, enquanto o `systemd` atualiza o link simbólico (`bedrock_atual`) na inicialização:

```bash
# 1. Para o servidor atual salvando o mundo com segurança
sudo systemctl stop bedrock.service

# 2. Inicia o Docker Compose brevemente para baixar e extrair a release mais recente (LATEST)
cd /home/ubuntu/bedrock_server
sudo docker compose up -d
sleep 25
sudo docker compose down

# 3. Inicia o serviço nativo (o ExecStartPre apontará automaticamente para o novo binário)
sudo systemctl start bedrock.service

# 4. Confirma se o servidor subiu na versão nova
sudo systemctl status bedrock.service
```

---

## 6. Diagnóstico de Rede e Firewall (`iptables`)

* **Verificar se o servidor está escutando nas portas UDP 19132 e 19133:**
  ```bash
  sudo ss -ulnp | grep 1913
  ```

* **Listar regras ativas para portas UDP no firewall do Ubuntu:**
  ```bash
  sudo iptables -L INPUT -v -n | grep udp
  ```

* **Liberar uma nova porta UDP permanentemente (caso necessário no futuro):**
  ```bash
  sudo iptables -I INPUT -m state --state NEW -p udp --dport PORTA_AQUI -j ACCEPT
  sudo netfilter-persistent save
  ```