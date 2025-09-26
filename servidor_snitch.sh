#!/bin/bash

# server_snitch.sh
# Script para medir latencia y perdida de paquetes hacia un servidor
# Uso: server_snitch.sh -s servidor -c cantidad

# Variables para almacenar los parametros
SERVER=""
COUNT=""

# Funcion para mostrar el uso del script
mostrar_uso() {
    echo "Cantidad inadecuada de parametros."
    echo "Uso: server_snitch.sh -s servidor -c cantidad"
    echo "                          servidor: ip o nombre"
    echo "                          cantidad: nro entero positivo"
}

# Verificar que se proporcionaron exactamente 4 parametros
if [ $# -ne 4 ]; then
    mostrar_uso
    exit 1
fi

# Procesar los parametros de linea de comandos
while getopts "s:c:" option; do
    case $option in
        s)
            SERVER="$OPTARG"
            ;;
        c)
            COUNT="$OPTARG"
            ;;
        *)
            mostrar_uso
            exit 1
            ;;
    esac
done

# Verificar que se proporcionaron tanto servidor como cantidad
if [ -z "$SERVER" ] || [ -z "$COUNT" ]; then
    mostrar_uso
    exit 1
fi

# Verificar que la cantidad sea un numero entero positivo
if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -le 0 ]; then
    echo "Error: La cantidad debe ser un numero entero positivo."
    mostrar_uso
    exit 1
fi

# Ejecutar ping y capturar la salida
echo "Midiendo latencia hacia $SERVER con $COUNT paquetes..."
echo "----------------------------------------"

PING_OUTPUT=$(ping -c "$COUNT" "$SERVER" 2>&1)
PING_EXIT_CODE=$?

# Verificar si ping fue exitoso
if [ $PING_EXIT_CODE -ne 0 ]; then
    echo "Error: No se pudo conectar al servidor $SERVER"
    echo "Salida de ping:"
    echo "$PING_OUTPUT"
    exit 1
fi

# Mostrar la salida completa del ping
echo "$PING_OUTPUT"
echo "----------------------------------------"

# Extraer estadisticas de la salida de ping
STATS_LINE=$(echo "$PING_OUTPUT" | grep "packet loss")
TIMING_LINE=$(echo "$PING_OUTPUT" | grep "rtt min/avg/max")

if [ -n "$STATS_LINE" ]; then
    # Extraer perdida de paquetes
    PACKET_LOSS=$(echo "$STATS_LINE" | sed 's/.*\([0-9]\+\)% packet loss.*/\1/')
    echo "Tasa de perdida de paquetes: $PACKET_LOSS%"
fi

if [ -n "$TIMING_LINE" ]; then
    # Extraer latencia promedio
    AVG_LATENCY=$(echo "$TIMING_LINE" | awk -F'/' '{print $5}')
    echo "Latencia promedio: $AVG_LATENCY ms"
    
    # Extraer latencia minima y maxima para informacion adicional
    MIN_LATENCY=$(echo "$TIMING_LINE" | awk -F'/' '{print $4}')
    MAX_LATENCY=$(echo "$TIMING_LINE" | awk -F'/' '{print $6}')
    echo "Latencia minima: $MIN_LATENCY ms"
    echo "Latencia maxima: $MAX_LATENCY ms"
fi

echo "----------------------------------------"
echo "Medicion completada."
