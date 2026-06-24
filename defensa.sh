#!/bin/bash

# SCRIPT 

echo "Iniciando la defensa..."

# 1. LIMPIEZA
# Borra todas las reglas previas en las tablas INPUT y FORWARD

iptables -F INPUT
iptables -F FORWARD

# 2. MITIGACIÓN CAPA 7 (Bloqueo de la descarga de db.sql)
# Inspecciona los paquetes HTTP entrantes buscando la cadena "db.sql"

echo "[+] Aplicando mitigación Capa 7 para db.sql..."
iptables -A INPUT -p tcp --dport 80 -m string --string "db.sql" --algo bm -j DROP

# 3. MITIGACIÓN CAPA 4 (Control de SYN Flood)
# Limita la cantidad de conexiones SYN entrantes por IP para evitar la saturación del backlog

echo "[+] Aplicando mitigación Capa 4 contra SYN Flood..."
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# 4. POLÍTICA DE SEGURIDAD (Opcional, según requerimiento de tu guía)
# Permite tráfico local (loopback) y conexiones ya establecidas para no perder tu acceso SSH

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "Defensa desplegada exitosamente. Servidor protegido."

# 5. OPTIMIZACIÓN DEL KERNEL (Limpia conexiones colgadas inmediatamente)
# Reduce la cantidad de reintentos SYN-ACK para borrar conexiones fantasmas rápido

echo "[+] Optimizando tiempos de espera del Kernel..."
sysctl -w net.ipv4.tcp_synack_retries=1
sysctl -w net.ipv4.tcp_max_syn_backlog=2048

# 6. EXPULSIÓN DE CONEXIONES EXISTENTES
# Corta de raíz cualquier conexión TCP establecida previamente en el puerto 80

echo "[+] Reseteando conexiones previas del atacante..."
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate ESTABLISHED -j REJECT --reject-with tcp-reset
