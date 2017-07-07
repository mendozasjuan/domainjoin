#!/bin/bash

# Configuración de colores
resaltado="\033[43m\033[30m"
verde="\033[33m"
normal="\033[40m\033[37m"


# Escribir el título en colores
function write_title() {
    echo " "
    echo -e "$resaltado $1 $normal"
    say_continue
}


# Mostrar mensaje "Done."
function say_done() {
    echo " "
    echo -e "$verde Done. $normal"
    say_continue
}


# Preguntar para continuar
function say_continue() {
    echo -n " Para SALIR, pulse la tecla x; sino, pulse ENTER para continuar..."
    read acc
    if [ "$acc" == "x" ]; then
        exit
    fi
    echo " "
}


# Obtener la IP del Equipo
function __get_ip() {
    linea=`ifconfig eth0 | grep -e "inet\ addr:"`
    serverip=`python scripts/get_ip.py $linea`
    echo $serverip
}

function __get_desktop(){
    linea=`env | grep -e "DESKTOP_SESSION="`
    desktop=`python scripts/get_desktop.py $linea`
    echo $desktop
}