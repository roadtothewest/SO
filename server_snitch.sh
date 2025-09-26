#!/bin/bash
SERVER=""
COUNT=""
mostrar_uso() {
    echo "Cantidad inadecuada de parametros."
    echo "Uso: server_snitch.sh -s servidor -c cantidad"
    echo "                          servidor: ip o nombre"
    echo "                          cantidad: nro entero positivo"
}
if [ $# -ne 4 ]; then
    mostrar_uso
    exit 1
fi
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
if [ -z "$SERVER" ] || [ -z "$COUNT" ]; then
    mostrar_uso
    exit 1
fi
if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -le 0 ]; then
    echo "Error: La cantidad debe ser un numero entero positivo."
    mostrar_uso
    exit 1
fi
echo "Midiendo latencia hacia $SERVER con $COUNT paquetes..."
echo "----------------------------------------"

PING_OUTPUT=$(ping -c "$COUNT" "$SERVER" 2>&1)
PING_EXIT_CODE=$?
if [ $PING_EXIT_CODE -ne 0 ]; then
    echo "Error: No se pudo conectar al servidor $SERVER"
    echo "Salida de ping:"
    echo "$PING_OUTPUT"
    exit 1
fi
echo "$PING_OUTPUT"
echo "----------------------------------------"
STATS_LINE=$(echo "$PING_OUTPUT" | grep "packet loss")
TIMING_LINE=$(echo "$PING_OUTPUT" | grep "rtt min/avg/max")

if [ -n "$STATS_LINE" ]; then
    PACKET_LOSS=$(echo "$STATS_LINE" | sed 's/.*\([0-9]\+\)% packet loss.*/\1/')
    echo "Tasa de perdida de paquetes: $PACKET_LOSS%"
fi

if [ -n "$TIMING_LINE" ]; then
    AVG_LATENCY=$(echo "$TIMING_LINE" | awk -F'/' '{print $5}')
    echo "Latencia promedio: $AVG_LATENCY ms"
    MIN_LATENCY=$(echo "$TIMING_LINE" | awk -F'/' '{print $4}')
    MAX_LATENCY=$(echo "$TIMING_LINE" | awk -F'/' '{print $6}')
    echo "Latencia minima: $MIN_LATENCY ms"
    echo "Latencia maxima: $MAX_LATENCY ms"
fi
echo "----------------------------------------"
echo "Medicion completada."
