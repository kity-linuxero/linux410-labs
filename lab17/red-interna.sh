#!/bin/bash
# red-interna.sh: arma la red interna "redcurso" del Laboratorio 17.
#
# Uso:  sudo bash red-interna.sh           (configura)
#       sudo bash red-interna.sh quitar    (deshace todo)
#
# En Debian agrega 192.168.50.10/24 a enp0s8 con "ip" (temporal: se pierde al reiniciar).
# En Rocky crea la conexión "redcurso" de NetworkManager con 192.168.50.20/24.
# En las dos agrega "debian" y "rocky" a /etc/hosts, con la marca "# lab17".

IFACE=enp0s8
IP_DEBIAN=192.168.50.10
IP_ROCKY=192.168.50.20
MASCARA=24
MARCA="# lab17"

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script necesita permisos de root. Ejecutalo así: sudo bash $0 $*"
    exit 1
fi

ACCION=${1:-configurar}
if [ "$ACCION" != "configurar" ] && [ "$ACCION" != "quitar" ]; then
    echo "Uso: sudo bash $0 [quitar]"
    exit 1
fi

# Distribución: /etc/os-release trae el campo ID.
if [ ! -r /etc/os-release ]; then
    echo "No encuentro /etc/os-release, no puedo saber qué distribución es."
    exit 1
fi
. /etc/os-release
case "$ID" in
    debian)
        DISTRO=debian
        MI_IP=$IP_DEBIAN
        ;;
    rocky | rhel | centos | almalinux)
        DISTRO=rocky
        MI_IP=$IP_ROCKY
        ;;
    *)
        echo "Distribución no prevista: $ID. Este script es para Debian y Rocky."
        exit 1
        ;;
esac
echo "Distribución: $DISTRO. Segunda placa: $IFACE, dirección $MI_IP/$MASCARA."

tiene_placa() {
    ip link show "$IFACE" > /dev/null 2>&1
}

tiene_direccion() {
    ip -4 addr show dev "$IFACE" 2> /dev/null | grep -q "inet $MI_IP/"
}

# --- /etc/hosts ---

agregar_hosts() {
    # Si el archivo no termina en salto de línea, lo agregamos para no pegar líneas.
    if [ -n "$(tail -c1 /etc/hosts)" ]; then
        echo >> /etc/hosts
    fi
    for linea in "$IP_DEBIAN debian" "$IP_ROCKY rocky"; do
        if grep -q "^$linea $MARCA\$" /etc/hosts; then
            echo "/etc/hosts ya tiene: $linea"
        else
            echo "$linea $MARCA" >> /etc/hosts
            echo "Agregado a /etc/hosts: $linea"
        fi
    done
}

quitar_hosts() {
    if grep -q " $MARCA\$" /etc/hosts; then
        sed -i "/ $MARCA\$/d" /etc/hosts
        echo "Quitadas de /etc/hosts las líneas marcadas con $MARCA."
    else
        echo "/etc/hosts no tiene líneas marcadas con $MARCA."
    fi
}

# --- Debian: ip ---

configurar_debian() {
    if tiene_direccion; then
        echo "$IFACE ya tiene $MI_IP/$MASCARA. Sigo."
    else
        ip addr add "$MI_IP/$MASCARA" dev "$IFACE"
        echo "Agregada la dirección $MI_IP/$MASCARA a $IFACE."
    fi
    ip link set "$IFACE" up
}

quitar_debian() {
    if tiene_placa && tiene_direccion; then
        ip addr del "$MI_IP/$MASCARA" dev "$IFACE"
        echo "Quitada la dirección $MI_IP/$MASCARA de $IFACE."
    else
        echo "$IFACE no tiene la dirección $MI_IP/$MASCARA."
    fi
}

# --- Rocky: NetworkManager ---

hay_conexion() {
    nmcli -g NAME connection show | grep -qx redcurso
}

configurar_rocky() {
    if ! command -v nmcli > /dev/null; then
        echo "No encuentro nmcli: NetworkManager no está instalado."
        exit 1
    fi
    if hay_conexion; then
        echo "La conexión redcurso ya existe. Sigo."
    elif tiene_direccion; then
        echo "$IFACE ya tiene $MI_IP/$MASCARA (¿viene del Laboratorio 16?). No creo otra conexión."
        return
    else
        nmcli connection add type ethernet ifname "$IFACE" con-name redcurso \
            ipv4.method manual ipv4.addresses "$MI_IP/$MASCARA" ipv6.method disabled
    fi
    nmcli connection up redcurso
}

quitar_rocky() {
    if hay_conexion; then
        nmcli connection delete redcurso
    else
        echo "No existe la conexión redcurso."
    fi
}

# --- Programa principal ---

if [ "$ACCION" = "configurar" ]; then
    if ! tiene_placa; then
        echo "No existe la interfaz $IFACE. Falta el Adaptador 2 de VirtualBox."
        echo "Apagá la VM, habilitalo en Configuración > Red > Adaptador 2 (Red interna, nombre redcurso) y encendela de nuevo."
        exit 1
    fi
    if [ "$DISTRO" = "debian" ]; then
        configurar_debian
    else
        configurar_rocky
    fi
    agregar_hosts
    echo
    ip -br -4 addr show dev "$IFACE"
else
    if [ "$DISTRO" = "debian" ]; then
        quitar_debian
    else
        quitar_rocky
    fi
    quitar_hosts
    # NetworkManager tarda un instante en soltar la dirección al borrar la conexión.
    for _ in 1 2 3 4 5; do
        tiene_direccion || break
        sleep 1
    done
    echo
    if ip -br -4 addr show dev "$IFACE" 2> /dev/null | grep -q .; then
        ip -br -4 addr show dev "$IFACE"
    else
        echo "$IFACE sin dirección IPv4."
    fi
fi
