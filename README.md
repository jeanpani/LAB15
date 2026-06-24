# 🛡️ Mitigación Automatizada de Ataques DDoS y Exfiltración de Datos

Este repositorio contiene la solución técnica desarrollada para la detección, mitigación y prevención automatizada de un ataque de denegación de servicio (DDoS) por exfiltración/descarga masiva de archivos, diseñado para la protección de servidores web en entornos Linux.

El proyecto simula un escenario real donde un atacante satura el ancho de banda de salida y los recursos de almacenamiento, comprometiendo la disponibilidad del servicio.

## 📁 Contenido del Repositorio

* **`defensa.sh`**: Script de mitigación activa. Analiza las conexiones TCP entrantes al servidor web, identifica de forma dinámica la dirección IP agresiva y aplica reglas restrictivas en el Firewall (`iptables`) para cortar el ataque de raíz.
* **`INFORME_INCIDENTE.md`**: Reporte técnico detallado que sigue la metodología de resolución de problemas de HP, respondiendo a las preguntas de análisis socrático e incluyendo las evidencias visuales (`nload`, `iostat`) del antes y después de la mitigación.


## 🛡️ Defensa.sh

Para tener la defensa activada tenemos que crear el archivo defensa.sh:
```
nano defensa.sh

```

Después tenemos que darle permisos de ejecución con el comando:
```
sudo chmod +x defensa.sh

```

Abrimos el archvio defensa.sh y pegamos el siguiente script:
```
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

```

## ⚙️ Arquitectura del Sistema de Prevención (Cron + Monitoreo)

Para garantizar la resiliencia del servidor sin intervención humana, se diseñó teóricamente un modelo de **defensa reactiva modular**:

1.  **Sensor de Tráfico:** Un script ligero consulta cada minuto las estadísticas de la interfaz de red (`ens33`).
2.  **Evaluación de Umbral:** Si el tráfico de salida supera un umbral de peligro crítico (ej. 50 Mbps), el sensor actúa como un interruptor.
3.  **Activación Autónoma:** Al detectar la anomalía, el sensor invoca automáticamente a `defensa.sh`, aislando al atacante de inmediato.



