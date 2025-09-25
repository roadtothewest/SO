#!/bin/bash

forma_uso() {
    echo "Cantidad inadecuada de parámetros."
    echo "Uso: server_snitch.sh -s servidor -c cantidad"
    echo "                         servidor: ip o nombre"
    echo "                         cantidad: nro entero positivo"
    exit 1
}

servidor=""
cantidad=""

while getopts "s:c:h" opcion; do
    case "$opcion" in
        s) servidor=$OPTARG ;;
        c) cantidad=$OPTARG ;;
        h) forma_uso ;;
        *) forma_uso ;;
    esac
done

if [ -z "$servidor" ] || [ -z "$cantidad" ]; then
    forma_uso
fi

if ! echo "$cantidad" | grep -qE '^[1-9][0-9]*$'; then
    echo "Error: La cantidad debe ser un número entero positivo."
    forma_uso
fi

echo "Analizando servidor: $servidor"
echo "Cantidad de paquetes: $cantidad"
echo "----------------------------------------"

resultado=$(ping -c "$cantidad" "$servidor" 2>/dev/null)
codigo_salida=$?

if [ $codigo_salida -ne 0 ]; then
    echo "Error: No se pudo conectar al servidor $servidor"
    exit 1
fi

latencia=$(echo "$resultado" | grep -E 'rtt min/avg/max/mdev' | sed 's/.*= [0-9.]*\///' | sed 's/\/.*//')
perdida=$(echo "$resultado" | grep -oE '[0-9]+% packet loss' | grep -oE '[0-9]+%')

echo "Resultados:"
echo "  Latencia promedio: ${latencia} ms"
echo "  Tasa de pérdida: $perdida"

if [ -n "$latencia" ]; then
    if echo "$latencia" | awk '{exit !($1 < 50)}'; then
        echo "  ✓ Latencia excelente"
    elif echo "$latencia" | awk '{exit !($1 < 100)}'; then
        echo "  ○ Latencia buena"
    elif echo "$latencia" | awk '{exit !($1 < 200)}'; then
        echo "  △ Latencia aceptable"
    else
        echo "  ✗ Latencia pobre"
    fi
fi

if [ "$perdida" = "0%" ]; then
    echo "  ✓ Sin pérdida de paquetes"
else
    echo "  ✗ Pérdida de paquetes detectada: $perdida"
fi
