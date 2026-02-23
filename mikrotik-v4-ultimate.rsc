# =======================================================================
# 🏆 MIKROTIK EXPERT - V4.0 (ARM EDITION - RB-E60iUGS)
# Arquitetura Zero Trust | Dual-VPN | SFP Ready
# =======================================================================

# -----------------------------------------------------------------------
# ✅ MÓDULO 1 — INTERFACES FÍSICAS E LÓGICAS (ZEROTIER INCLUÍDO)
# -----------------------------------------------------------------------
/interface ethernet
set [find default-name=ether1] name=WAN
set [find default-name=ether2] name=LAN-CASA
set [find default-name=ether5] name=LAN-ADM
set [find default-name=sfp1] name=SFP-2.5G comment="Porta SFP Livre para Link/Switch 2.5G"

/interface vlan
add name=VLAN-IOT vlan-id=30 interface=LAN-CASA comment="VLAN 30 (IoT) na porta da Casa"

/interface wireguard
add name=wg0 listen-port=51820 comment="Servidor VPN WireGuard (Acesso Backup)"

/zerotier interface
add network="SEU_NETWORK_ID_AQUI" instance=zt1 name=zerotier1 disabled=no comment="Túnel Principal SD-WAN ZeroTier"

# -----------------------------------------------------------------------
# ✅ MÓDULO 2 — ENDEREÇAMENTO (GATEWAYS)
# -----------------------------------------------------------------------
/ip address
add address=10.10.10.1/24 interface=LAN-ADM comment="Gateway ADM"
add address=10.20.20.1/24 interface=LAN-CASA comment="Gateway CASA"
add address=10.30.30.1/24 interface=VLAN-IOT comment="Gateway IoT"
add address=10.99.99.1/24 interface=wg0 comment="Gateway WireGuard"
# (O ZeroTier recebe o IP automaticamente da nuvem, não precisa adicionar aqui)

# -----------------------------------------------------------------------
# ✅ MÓDULO 3 — DHCP SERVERS, POOLS E REDES
# -----------------------------------------------------------------------
/ip pool
add name=pool-adm ranges=10.10.10.10-10.10.10.50
add name=pool-casa ranges=10.20.20.10-10.20.20.200
add name=pool-iot ranges=10.30.30.10-10.30.30.200

/ip dhcp-server
add name=dhcp-adm interface=LAN-ADM address-pool=pool-adm lease-time=12h disabled=no
add name=dhcp-casa interface=LAN-CASA address-pool=pool-casa lease-time=12h disabled=no
add name=dhcp-iot interface=VLAN-IOT address-pool=pool-iot lease-time=12h disabled=no

/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1 dns-server=10.10.10.1
add address=10.20.20.0/24 gateway=10.20.20.1 dns-server=10.20.20.1
add address=10.30.30.0/24 gateway=10.30.30.1 dns-server=10.30.30.1

# -----------------------------------------------------------------------
# ✅ MÓDULO 4 — WAN (INTERNET) E DNS ROOT
# -----------------------------------------------------------------------
/ip dhcp-client
add interface=WAN disabled=no use-peer-dns=no add-default-route=yes comment="Recebe IP da ONU"

/ip dns
set servers=1.1.1.1,8.8.8.8 allow-remote-requests=yes cache-size=4096KiB

# -----------------------------------------------------------------------
# ✅ MÓDULO 5 — NAT UNIVERSAL
# -----------------------------------------------------------------------
/ip firewall nat
add chain=srcnat out-interface=WAN action=masquerade comment="NAT-INTERNET-GLOBAL"

# -----------------------------------------------------------------------
# 🔥 MÓDULO 6 — FIREWALL PROFISSIONAL (ZERO TRUST DUPLO)
# -----------------------------------------------------------------------
/ip firewall filter

# --- CHAIN INPUT (Proteção do Roteador) ---
add chain=input connection-state=established,related action=accept comment="1. ACCEPT ESTABLISHED/RELATED"
add chain=input connection-state=invalid action=drop comment="2. DROP INVALID"

add chain=input src-address=10.10.10.0/24 action=accept comment="3. ADM-ACCESS-FULL (Cabo Local)"
add chain=input protocol=udp dst-port=53 src-address=10.20.20.0/24 action=accept comment="4. ALLOW-DNS-CASA"
add chain=input protocol=tcp dst-port=53 src-address=10.20.20.0/24 action=accept
add chain=input protocol=udp dst-port=53 src-address=10.30.30.0/24 action=accept comment="5. ALLOW-DNS-IOT"
add chain=input protocol=tcp dst-port=53 src-address=10.30.30.0/24 action=accept
add chain=input protocol=udp dst-port=51820 action=accept comment="6. ALLOW-WIREGUARD-TUNNEL"
add chain=input protocol=icmp action=accept comment="7. ALLOW-PING"

# Liberação das VPNs para gerência do equipamento
add chain=input in-interface=zerotier1 action=accept comment="8. ALLOW-ZEROTIER-ADMIN"
add chain=input src-address=10.99.99.0/24 action=accept comment="9. ALLOW-WG-ADMIN"

add chain=input action=drop comment="10. DROP-ALL-OTHER-INPUT"


# --- CHAIN FORWARD (Bloqueio entre Redes) ---
add chain=forward action=fasttrack-connection connection-state=established,related comment="11. FASTTRACK-GLOBAL (Acelera hardware ARM)"
add chain=forward connection-state=established,related action=accept comment="12. ACCEPT-ESTABLISHED-FWD"
add chain=forward connection-state=invalid action=drop comment="13. DROP-INVALID-FWD"

add chain=forward src-address=10.10.10.0/24 action=accept comment="14. ADM-CAN-GO-ANYWHERE"
add chain=forward src-address=10.20.20.0/24 out-interface=WAN action=accept comment="15. CASA-TO-INTERNET"
add chain=forward src-address=10.30.30.0/24 out-interface=WAN action=accept comment="16. IOT-TO-INTERNET"
add chain=forward src-address=10.99.99.0/24 out-interface=WAN action=accept comment="17. WG-TO-INTERNET"

# Liberação das VPNs para acessar apenas a rede de ADM remota
add chain=forward in-interface=zerotier1 dst-address=10.10.10.0/24 action=accept comment="18. ZT-TO-ADM-ONLY"
add chain=forward src-interface=wg0 dst-address=10.10.10.0/24 action=accept comment="19. WG-TO-ADM-ONLY"

add chain=forward connection-state=new action=drop comment="20. DROP-ALL-NEW-FWD (Implicit Deny)"

# -----------------------------------------------------------------------
# 🔐 MÓDULO 7 — WIREGUARD PEERS (CLIENTES)
# -----------------------------------------------------------------------
/interface wireguard peers
add interface=wg0 public-key="COLOQUE_A_CHAVE_DO_CELULAR_AQUI" allowed-address=10.99.99.2/32 comment="Smartphone ADM (Backup)"

# -----------------------------------------------------------------------
# 🛡️ MÓDULO 8 — HARDENING FINAL
# -----------------------------------------------------------------------
/ip service
disable telnet,ftp,www,api,api-ssl
set winbox address=""
set ssh address=""

/system identity set name="RB-E60iUGS-Core"

# =======================================================================
# 🚨 ANEXO A — DESBLOQUEIO FÍSICO DO ZEROTIER (OBRIGATÓRIO)
# Como o ZeroTier roda no Kernel, a MikroTik exige prova de acesso físico.
# =======================================================================

# PASSO 1: Solicitar o desbloqueio ao sistema
# Abra o 'New Terminal' no Winbox e rode o comando abaixo:
/system device-mode update zerotier=yes

# PASSO 2: A Confirmação Física (Janela de 5 Minutos)
# O terminal ficará aguardando ("waiting for confirmation"). 
# Vá até a sua RB-E60iUGS e faça UMA destas duas coisas:
# Opção A (Mais Segura): Puxe o cabo de energia, espere 3 segundos e ligue novamente.
# Opção B: Pressione o botão físico de "Reset" na placa (um clique rápido, NÃO segure).

# PASSO 3: Conferir se o desbloqueio funcionou
# Após o roteador reiniciar, abra o terminal e rode:
/system device-mode print

# 🟢 VERIFICAÇÃO DE SUCESSO:
# Na lista que aparecer, a linha do ZeroTier deve estar assim:
# zerotier: yes
#
# Se estiver "yes", a interface ZT1 do script acima sairá do status 
# "inactivated" e conectará automaticamente à nuvem.
# =======================================================================
# FIM DO MANUAL DE OURO V4.0
# =======================================================================
