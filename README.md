# 🛡️ MikroTik RB-E60iUGS - Zero Trust & SD-WAN Architecture

Este repositório contém um script de configuração completo ("Manual de Ouro") para roteadores MikroTik baseados em ARM (focado na **RB-E60iUGS / hEX S**).

O projeto implementa uma arquitetura de segurança **Zero Trust**, segmentação de rede e redundância de acesso remoto.

## 🚀 Funcionalidades

* **Arquitetura Zero Trust:** Bloqueio padrão de todo o tráfego (Drop All), com permissões explícitas (Whitelist).
* **Segmentação de Rede (VLANs):**
    * LAN ADM (Gestão Segura)
    * LAN CASA (Uso Geral)
    * VLAN IoT (Isolada para dispositivos inteligentes)
* **Dual-VPN Access:**
    * **ZeroTier:** SD-WAN nativa para contornar CGNAT (Setup via CLI/Containers).
    * **WireGuard:** VPN Kernel-level para acesso rápido e backup.
* **Performance:** Regras de *FastTrack* otimizadas para hardware ARM.
* **SFP Ready:** Porta 2.5G pré-configurada.

## ⚠️ Pré-requisitos e Avisos

1.  **Hardware:** Testado na MikroTik RB-E60iUGS (ARM). Adaptável para outros modelos ARM/ARM64.
2.  **Reset:** O script foi desenhado para ser aplicado em um roteador "zerado" (`no-defaults=yes`).
3.  **ZeroTier:** Requer ativação física do `device-mode` (instruções incluídas no script).
4.  **Sanitização:** Lembre-se de inserir suas próprias Chaves Públicas e Network IDs antes de rodar.

## 🛠️ Como Usar

1.  Baixe o arquivo `.rsc` deste repositório.
2.  Edite o arquivo inserindo suas credenciais (WireGuard Keys / ZeroTier ID).
3.  Resete sua MikroTik sem configurações padrão.
4.  Importe o script via Terminal.

---
*Disclaimer: Este script é fornecido "como está". Revise todas as regras de firewall antes de aplicar em ambiente de produção.*
