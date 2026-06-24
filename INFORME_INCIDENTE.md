# Informe de Mitigación de Incidente: Ataque DoS por Extracción de Datos

**Fecha del Incidente:** 24 de Junio de 2026  
**Servidor Afectado:** webserver (IP: 10.160.10.200 / Interfaz: ens33)  
**Analista de Seguridad:** [Tu Nombre/Código de Alumno]  

---

## FASE 1 y 2: Diagnóstico y Detección de la Anomalía

### 1. ¿Cómo se detectó la anomalía y qué recursos afectaba?
El incidente se detectó tras una degradación crítica en el tiempo de respuesta del servidor web. Al realizar el análisis forense de recursos en tiempo real, se identificaron dos cuellos de botella masivos:
* **Red (Ancho de Banda):** El tráfico de salida (**Outgoing/TX**) se encontraba completamente saturado en el orden de los Gigabits por segundo, causado por la transferencia forzada de un archivo de gran tamaño hacia un host externo.
* **Almacenamiento (Disco):** El comando `iostat` reflejó que el dispositivo de bloques principal (`sda` y `dm-0`) operaba de forma sostenida a un **100% de utilización (%util)**, debido a la tasa de lectura constante (`r/s` y `rkB/s`) requerida para despachar el archivo a la red.

---

## FASE 3 y 4: Estrategia de Mitigación

### 1. ¿Qué estrategia se utilizó para frenar el ataque sin tirar el servicio legítimo?
Se optó por una **mitigación selectiva en la capa de red (Firewall)**. En lugar de apagar el servicio web (Apache/Nginx) o reiniciar la máquina (lo que provocaría una denegación de servicio autoinducida), el procedimiento consistió en:
1.  Identificar la dirección IP del atacante mediante herramientas de socket (`ss -ntu` o `netstat`), buscando conexiones persistentes al puerto 80 con un volumen inusual de datos.
2.  Ejecutar el script desarrollado `defensa.sh`, el cual automatiza el aislamiento aplicando una regla de descarte en el firewall del kernel (`iptables -A INPUT -s [IP_ATACANTE] -j DROP`).
3.  Esto cortó inmediatamente el flujo TCP establecido por el atacante, liberando el socket y deteniendo la lectura en disco sin afectar a los usuarios legítimos.

---

## FASE 5: Problema Resuelto (Validación de Parámetros)

### 1. Evidencia de Retorno a la Normalidad
Tras la ejecución del script de defensa, se volvieron a auditar las herramientas de monitoreo para validar la efectividad de las contramedidas.

#### Monitoreo de Red (`nload`)
El tráfico de salida colapsó de inmediato drásticamente, estabilizándose en niveles mínimos de operación normal.
* **Tráfico Saliente Actual (TX):** ~7.79 kBit/s.
* **Estado:** Exitoso. El canal de comunicación del ataque quedó completamente clausurado.

#### Monitoreo de Almacenamiento (`iostat -x 1`)
Al cancelarse las peticiones de lectura del archivo malicioso, el estrés sobre el hardware desapareció.
* **Porcentaje de Utilización (`%util`):** Cayó a **0.03%** y posteriormente a **0.00%** en las lecturas consecutivas.
* **Lecturas por segundo (`r/s`):** Regresó a 0.00.
* **Estado:** Exitoso. El disco duro recuperó su total disponibilidad operativa.

---

## FASE 6: Medidas Preventivas y Automatización

### 1. ¿Cómo convertir el script de defensa en una tarea automatizada reactiva?
Para evitar la dependencia de la intervención humana, se diseñó e implementó un esquema de **defensa perimetral autónoma** basado en un modelo de monitoreo por umbrales:

1.  **Script Sensor:** Se implementó un script en `/usr/local/bin/check_ddos.sh` que mide de forma automatizada las estadísticas de bytes salientes directamente de `/sys/class/net/ens33/statistics/tx_bytes`.
2.  **Control de Umbral:** El script evalúa cada segundo si el tráfico supera un límite seguro de peligro (ej. 50 Mbps). Si el tráfico es normal, el script finaliza en paz.
3.  **Activación por Cron:** Este script sensor se programó en el sistema mediante **Cron** (`sudo crontab -e`) para ejecutarse en segundo plano con una frecuencia de **cada minuto** (`* * * * *`). 
4.  **Respuesta Reactiva:** Si el sensor detecta que el tráfico supera el umbral, actúa como un disparador e invoca de inmediato en segundo plano a `defensa.sh`, mitigando futuros ataques en menos de 60 segundos desde su inicio.
5.  **Hardening del Kernel:** Adicionalmente, se modificó el archivo `/etc/sysctl.conf` para activar las `tcp_syncookies` y mitigar de forma nativa los ataques por inundación de tablas de conexión.
