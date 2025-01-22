#!/bin/bash

distro_determined=false

# get_custom_distro: Ask from user for base of distro
get_custom_distro() {
    # Prompt the user for a custom distribution name
    read -p "Unable to identify the distribution. Please specify base of your distribution (options: arch, debian, ubuntu, rhel, alpine):" custom_distro
    # Validate the input
    case "$custom_distro" in
    arch | debian | ubuntu | rhel | alpine)
        echo "$custom_distro" # Return the custom distro if valid
        distro=$custom_distro
        distro_determined=true
        return
        ;;
    *)
        echo "unknown"
        return
        ;;
    esac
}

# get_distro: Detects the Linux distribution of the system.
get_distro() {
    if [ "$distro_determined" = true ]; then
        echo $distro
        return
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release

        case "$ID" in
        rocky | Rocky | almalinux | Almalinux | centos | Centos)
            echo rhel
            return
            ;;
        ubuntu | Ubuntu | debian | Debian)
            echo "debian"
            return
            ;;
        alpine | Alpine)
            echo "alpine"
            return
            ;;
        arch | Arch | manjaro | Manjaro)
            echo "arch"
            return
            ;;
        *) ;;
        esac

    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
        return
    elif [ -f /etc/arch-release ]; then
        echo "arch"
        return
    elif [ -f /etc/alpine-release ]; then
        echo "alpine"
        return
    fi
    echo "other"
    return
}

dnsmasq_config() {
    if ! grep -q "iran-unbound" "/etc/dnsmasq.conf"; then
        echo "" >>/etc/dnsmasq.conf
        echo "# iran-unbound" >>/etc/dnsmasq.conf
        echo "listen-address=127.0.0.1" >>/etc/dnsmasq.conf
        echo "conf-dir=/etc/dnsmasq.d/,*.conf" >>/etc/dnsmasq.conf
        echo "conf-dir=/etc/dnsmasq.d/,*.conf" >>/etc/dnsmasq.conf
    fi

    # Create dnsmasq.d directory if not exists
    if [ ! -d "/etc/dnsmasq.d" ]; then
        mkdir /etc/dnsmasq.d/
    fi

    cp b-domains.conf /etc/dnsmasq.d/b-domains.conf

    if [[ "$distro" == "alpine" ]]; then
        echo "nameserver 127.0.0.1" >/etc/resolv.conf
        chattr +i /etc/resolv.conf
    fi
}

# dnsmasq_restart: Restart the servies of dnsmasq
dnsmasq_restart() {
    if [ ! -n "${distro}" ]; then
        echo "Error: Cannot find the distribution of your linux for restart the dnsmasq service"
        exit 1
    fi

    case "$distro" in
    arch | debian | ubuntu | rhel)

        systemctl disable systemd-resolved.service
        systemctl stop systemd-resolved.service

        systemctl enable dnsmasq.service
        systemctl restart dnsmasq.service

        # Check the service restarted suceessfully
        if systemctl is-active --quiet "dnsmasq"; then
            echo "Dnsmasq is restarted Successfully."
        else
            echo "Failed to restart Dnsmasq. Please check the service problem with:"
            echo "journalctl -xu dnsmasq.service"
        fi
        ;;
    alpine)
        rc-update add dnsmasq
        rc-service dnsmasq restart

        # Check the service restarted successfully
        if rc-service dnsmasq status | grep -q "running"; then
            echo "Dnsmasq is restarted Successfully."
        else
            echo "Failed to restart Dnsmasq. Please check the service problem with:"
            echo "rc-service dnsmasq status"
        fi
        ;;
    *)
        echo "Restart Failed."
        ;;
    esac
}

show_help() {
    echo "-----------------------"
    echo "|    IRAN UNBOUND     |"
    echo "|  IR-Boycott-Bypass  |"
    echo "-----------------------"
    echo "Options:"
    echo "--install   Install and config dnsmasq. use -y for install non-interactively"
    echo "--update    Update the boycotted domains list"
    echo "--dns			  Set an optional dns provider address. (default 178.22.122.100)"
    echo "--help			Show this message."
}

# EntryPoint

# Check script is running in sudo mod
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Get distribution name
distro=$(get_distro)

# If the distribution is another distribution give base distribution from user
if [[ "$distro" == "other" ]]; then
    distro=$(get_custom_distro)

    if [[ "$distro" == "unknown" ]]; then
        echo "Sorry, its not valid base distribution name."
        exit 1
    fi
fi

echo "Starting Installation for : $distro"

# Usage message
if [[ "$1" == "--help" || "$1" == "" ]]; then
    show_help
fi

# Check the config file is exists
if [ ! -f ./b-domains.conf ]; then
    printf "Error: \"b-domains.conf\" file is not exists. Please run:\n./iran-unbound.sh --update\n"
    exit 1
fi

# Check the os is linux
uname=$(uname)
if [[ "$uname" -ne "Linux" ]]; then
    echo "Sorry, this script is support linux based operating systems"
    exit 1
fi

# Set the dns provider
if [[ "$1" == "--dns" ]]; then
    if [[ "$2" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then # Check the ip is valid
        echo "The DNS Provider is $2"
    else
        echo "Warning: the ip address is not valid!"
    fi

    sed -i "s,178.22.122.100,$2,g" b-domains.conf
    cp b-domains.conf /etc/dnsmasq.d/b-domains.conf
    dnsmasq_restart
fi

# Pull the project (--udpate)
if [[ "$1" == "--update" ]]; then

    # Check git is installed
    if git --version &>/dev/null; then
        git remote add origin https://github.com/MohsenParandvar/iran-unbound.git &>/dev/null
        git pull origin main
        cp b-domains.conf /etc/dnsmasq.d/b-domains.conf
        dnsmasq_restart
    else
        echo "Please install \"Git\" before run update command."
        exit 1
    fi
fi

if [[ "$1" == "--install" ]]; then
    if [[ "$2" != "-y" ]]; then
        echo "Notice: This action will make important changes to your system, and there is a possibility it may impact your DNS services."
        echo -n "Are you sure you want to proceed? [Y/n]:"

        read -r confirmation

        if [[ "$confirmation" != "Y" && "$confirmation" != "y" ]]; then
            exit 0
        fi
    fi

    # Debian Based
    if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
        apt update
        apt install dnsmasq -y

        dnsmasq_config

        is_restarted=$(dnsmasq_restart)

        if [[ "$is_restarted" == "Dnsmasq is restarted Successfully." ]]; then
            echo "Installation successfully."
        fi
    fi

    # RHEL Based
    if [[ "$distro" == "rhel" ]]; then
        dnf update
        dnf install dnsmasq -y

        dnsmasq_config

        is_restarted=$(dnsmasq_restart)

        if [[ "$is_restarted" == "Dnsmasq is restarted Successfully." ]]; then
            echo "Installation successfully."
        fi
    fi

    # Arch Based
    if [[ "$distro" == "arch" ]]; then
        pacman -Syu
        pacman -S dnsmasq

        dnsmasq_config

        is_restarted=$(dnsmasq_restart)

        if [[ "$is_restarted" == "Dnsmasq is restarted Successfully." ]]; then
            echo "Installation successfully."
        fi
    fi

    # Alpine Based
    if [[ "$distro" == "alpine" ]]; then
        apk update
        apk add dnsmasq

        dnsmasq_config

        is_restarted=$(dnsmasq_restart)

        if [[ "$is_restarted" == "Dnsmasq is restarted Successfully." ]]; then
            echo "Installation successfully."
        fi
    fi
fi
