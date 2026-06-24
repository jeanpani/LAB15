# 🛡️ Mitigación Automatizada de Ataques DDoS y Exfiltración de Datos

Este repositorio contiene la solución técnica desarrollada para la detección, mitigación y prevención automatizada de un ataque de denegación de servicio (DDoS) por exfiltración/descarga masiva de archivos, diseñado para la protección de servidores web en entornos Linux.

El proyecto simula un escenario real donde un atacante satura el ancho de banda de salida (**TX**) y los recursos de almacenamiento (**%util** del disco), comprometiendo la disponibilidad del servicio.

## 📁 Contenido del Repositorio

* **`defensa.sh`**: Script de mitigación activa. Analiza las conexiones TCP entrantes al servidor web, identifica de forma dinámica la dirección IP agresiva y aplica reglas restrictivas en el Firewall (`iptables`) para cortar el ataque de raíz.
* **`reset_lab.sh`**: Script de restauración del entorno. Limpia las reglas del firewall y restablece los contadores de red para devolver el laboratorio a su estado inicial seguro.
* **`INFORME_INCIDENTE.md`**: Reporte técnico detallado que sigue la metodología de resolución de problemas de HP, respondiendo a las preguntas de análisis socrático e incluyendo las evidencias visuales (`nload`, `iostat`) del antes y después de la mitigación.

## ⚙️ Arquitectura del Sistema de Prevención (Cron + Monitoreo)

Para garantizar la resiliencia del servidor sin intervención humana, se diseñó teóricamente un modelo de **defensa reactiva modular**:

1.  **Sensor de Tráfico:** Un script ligero consulta cada minuto las estadísticas de la interfaz de red (`/sys/class/net/ens33/statistics/tx_bytes`).
2.  **Evaluación de Umbral:** Si el tráfico de salida supera un umbral de peligro crítico (ej. 50 Mbps), el sensor actúa como un interruptor.
3.  **Activación Autónoma:** Al detectar la anomalía, el sensor invoca automáticamente a `defensa.sh`, aislando al atacante de inmediato.

---
*Desarrollado como entregable final para la validación de competencias en seguridad de sistemas operativos y defensa de redes (2026).*
