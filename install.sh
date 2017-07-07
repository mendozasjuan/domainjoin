#!/bin/bash
# @author       Juan Mendoza <mendozajuan007@gmail.com>


source helpers.sh

# Variables Generales
arquitectura=`uname -m`
greeter=`ls /usr/share/lightdm/lightdm.conf.d/ | grep 50-unity-greeter`

# 0. Verificar si es usuario root o no 
function is_root_user() {
    if [ "$USER" != "root" ]; then
        echo "Permiso denegado."
        echo "Este programa solo puede ser ejecutado por el usuario root"
        exit
    else
        clear
        cat templates/texts/welcome
    fi
}


# 1. Configurar zona horaria
function set_hour() {
    write_title "1. Configuración de la zona horaria"
    dpkg-reconfigure tzdata
    say_done
}

# 2. Instalacion de CNTLM
function install_cntlm()
{
    write_title "2. Instalacion de CNTLM"
    if [ "$arquitectura" == "i686" ]; then
        dpkg -i ejecutables/32bits/cntlm_0.92.3_i386.deb
    else 
        dpkg -i ejecutables/64bits/cntlm_0.92.3_amd64.deb
    fi
    mv /etc/cntlm.conf /etc/cntlm.conf.old
    cp templates/cntlm /etc/cntlm.conf
    echo -n " Indique el Usuario de Dominio: "; read usernameDomain
    echo -n " Indique el Dominio: "; read domain_name
    echo -n " Indique la Direccion del Proxy: "; read proxy
    echo "Username   $usernameDomain" >> /etc/cntlm.conf
    echo "Domain     $domain_name" >> /etc/cntlm.conf
    echo "Proxy     $proxy" >> /etc/cntlm.conf
    echo " Ingrese el Password: "
    cntlm -H | tail -3 >> /etc/cntlm.conf 
    /etc/init.d/cntlm restart
    cp scripts/proxy_si /usr/local/bin/
    chmod +x /usr/local/bin/proxy_si
    cp scripts/proxy_no /usr/local/bin/
    chmod +x /usr/local/bin/proxy_no
    proxy_si

}


# 3. Actualizar el sistema
function sysupdate() {
    write_title "3. Actualización del sistema"
    echo -n " ¿Desea Actualizar el Sistema? (y/n): "; read update_system
    if [ "$update_system" == "y" ]; then
        apt-get update
        apt-get upgrade -y
    fi
    say_done
}

# 4. Unir el Equipo al dominio
function unir_dominio(){
    write_title "4. Unir el Equipo al Dominio $domain_name"
    echo -n " ¿Desea Unir este Equipo al Dominio? (y/n): "; read unir_dominio
    if [ "$unir_dominio" == "y" ]; then
       if [ "$arquitectura" == "i686" ]; then
            chmod +x ejecutables/32bits/pbis-open-8.5.3.293.linux.x86.deb.sh
            ./ejecutables/32bits/pbis-open-8.5.3.293.linux.x86.deb.sh
        else 
            chmod +x ejecutables/64bits/pbis-open-8.5.3.293.linux.x86_64.deb.sh
            ./ejecutables/64bits/pbis-open-8.5.3.293.linux.x86_64.deb.sh
        fi
    fi
    domainjoin-cli join --disable ssh $domain_name $usernameDomain
    /opt/pbis/bin/config LoginShellTemplate /bin/bash
    /opt/pbis/bin/config HomeDirTemplate %H/%D/%U
    mv /etc/pam.d/common-session /etc/pam.d/common-session.old
    cp templates/common-session /etc/pam.d/common-session
    if [ "$greeter" == "50-unity-greeter.conf" ]; then
        echo "allow-guest=false" >> /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf
        echo "greeter-show-manual-login=true" >> /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf
    else
        echo "allow-guest=false" >> /usr/share/lightdm/lightdm.conf.d/60-lightdm-gtk-greeter.conf
        echo "greeter-show-manual-login=true" >> /usr/share/lightdm/lightdm.conf.d/60-lightdm-gtk-greeter.conf
    fi
}

# 5. Instalar Paquetes de Uso General
#function install_general(){
#    write_title "4. Instalacion de  Paquetes de Uso General"
#     echo -n " ¿Desea Instalar los Paquetes de Uso General? (y/n): "; read paquetes_general
#    if [ "$paquetes_general" == "y" ]; then
#        apt-get --assume-yes install unrar p7zip-full unace unzip ubuntu-restricted-addons ubuntu-restricted-extras nautilus-share samba smbclient libreoffice libreoffice-help-es libreoffice-l10n-es xclip ssh curl git imagemagick gimp gimp-help-es inkscape k3b myspell-es libreoffice-java-common libdvdread4 dvdstyler dvdstyler-data filezilla gnome-disk-utility system-config-printer-gnome firefox-locale-es && gnome-language-selector
#    fi
#    say_done
#}


# 6. Instalar HPLIP
function install_hplip(){
    write_title "5. Instalacion de HPLIP"
     echo -n " ¿Desea Instalar HPLIP? (y/n): "; read hplip
    if [ "$hplip" == "y" ]; then
        chmod +x ./ejecutables/hplip-3.16.11.run
    	echo -n "Indique un Usuario Local Para Ejecutar hplip: "; read username
    	su $username -c 'http_proxy=http://127.0.0.1:3128 ./ejecutables/hplip-3.16.11.run'
    fi
    
    say_done
}


# 7. Reiniciar el Equipo
function final_step() {
    write_title "6. Finalizar Instalacion"
    cat templates/texts/bye
    echo -n " ¿Desea Reiniciar el Equipo? (y/n) "
    read respuesta
    if [ "$respuesta" == "y" ]; then
         reboot
    else
        echo "El Equipo NO será reiniciado y su conexión permanecerá abierta."
        echo "Bye."
    fi
}


is_root_user                    #  0. Verificar si es usuario root o no
set_hour                        #  1. Configurar zona horaria
install_cntlm                   #  2. Instalacion de CNTLM
sysupdate                       #  3. Actualizar el sistema
unir_dominio                    #  4. Unir Equipo al Dominio
#install_general                 #  5. Instalar Paquetes de Uso General
install_hplip                   #  6. Instalar HPLIP 
final_step                      #  7. Reiniciar el Equipo