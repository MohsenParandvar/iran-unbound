#!/bin/bash

distro_determined=false

# get_custom_distro: Ask from user for base of distro
get_custom_distro() {
    # Prompt the user for a custom distribution name
    read -p "Unable to identify the distribution. Please specify base of your distribution (options: arch, debian, ubuntu, rhel):" custom_distro
    # Validate the input
    case "$custom_distro" in
    arch | debian | ubuntu | rhel)
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
    *)
        echo "Restart Failed."
        ;;
    esac
}

# dnsmasq_disable: disable the servies of dnsmasq
dnsmasq_disable() {
    if [ ! -n "${distro}" ]; then
        echo "Error: Cannot find the distribution of your linux for disable the dnsmasq service"
        exit 1
    fi

    systemctl disable dnsmasq.service
    systemctl stop dnsmasq.service

    # Check the service disabled suceessfully
    if ! systemctl is-active --quiet "dnsmasq"; then
        echo "success"
    else
        echo "failed"
    fi
}

# resolved_enable: enable the servies of resolved
resolved_enable() {
    if [ ! -n "${distro}" ]; then
        echo "Error: Cannot find the distribution of your linux for disable the systemd-resolved service"
        exit 1
    fi

    systemctl enable systemd-resolved.service
    systemctl restart systemd-resolved.service

    # Check the service disabled suceessfully
    if systemctl is-active --quiet "systemd-resolved"; then
        echo "success"
    else
        echo "failed"
    fi
}

show_help() {
    echo "-------------------------"
    echo "|      IRAN UNBOUND      |"
    echo "|   IR-Boycott-Bypass    |"
    echo "-------------------------"
    echo "Options:"
    echo "  --install       Install and configure dnsmasq. Use '-y' for non-interactive installation."
    echo "  --update        Update the list of boycotted domains."
    echo "  --dns <address> Set an optional DNS provider address. (Default: 178.22.122.100)"
    echo "  --enable        Enable Iran-Unbound on the system."
    echo "  --disable       Disable Iran-Unbound and revert to system defaults. Re-enable with --enable."
    echo "  --uninstall     Uninstall Iran-Unbound and restore system defaults."
    echo "  --help          Display this help message."
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
        current_dns_resolver=$(awk -F'/' '{print $3}' "b-domains.conf" | uniq | tr -d '\n')

        echo "Your current DNS Provier is : $current_dns_resolver"
        echo "will change to : $2"

        sed -i "s,$current_dns_resolver,$2,g" b-domains.conf
        cp b-domains.conf /etc/dnsmasq.d/b-domains.conf
        dnsmasq_restart
    else
        echo "Warning: the ip address is not valid!"
    fi

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

# Installation
if [[ "$1" == "--install" ]]; then
    if [[ "$2" != "-y" ]]; then
        echo "Notice: This action will make important changes to your system, and there is a possibility it may impact your DNS services."
        echo -n "Are you sure you want to proceed? [Y/n]:"

        read -r confirmation

        if [[ "$confirmation" != "Y" && "$confirmation" != "y" ]]; then
            exit 0
        fi
    fi

    echo "Starting Installation for : $distro"

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
fi

# Disable
if [[ "$1" == "--disable" ]]; then
    echo -n "Are you sure you want to disable? [Y/n]:"

    read -r confirmation

    if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
        echo "Disabling Dnsmasq service..."

        dnsmasq_disabled=$(dnsmasq_disable)
        if [[ "$dnsmasq_disabled" == "success" ]]; then
            echo "Restarting systemd-resolved service..."
            resolved_enabled=$(resolved_enable)

            if [[ "$resolved_enabled" == "success" ]]; then
                echo "Done..."
            else
                echo "[Warning]: an error happend while enabling systemd-resolved services"
                echo -n "Do you want to revert actions? [Y/n]:"

                read -r confirmation

                if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
                    dnsmasq_restart
                else
                    echo "Okay, you might not have internet access because your DNS server is inactive."
                fi
            fi
        fi
    fi
fi

# Enable
if [[ "$1" == "--enable" ]]; then
    echo "Enabling Dnsmasq service..."

    dnsmasq_restart
fi

# Uninstall
if [[ "$1" == "--uninstall" ]]; then
    echo -n "Are you sure you want to uninstall? [Y/n]:"

    read -r confirmation

    if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
        echo "Disabling Dnsmasq service..."

        dnsmasq_disabled=$(dnsmasq_disable)
        if [[ "$dnsmasq_disabled" == "success" ]]; then
            echo "Restarting systemd-resolved service..."
            resolved_enabled=$(resolved_enable)

            if [[ "$resolved_enabled" == "success" ]]; then
                if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
                    apt remove dnsmasq
                fi

                if [[ "$distro" == "rhel" ]]; then
                    dnf remove dnsmasq
                fi

                if [[ "$distro" == "arch" ]]; then
                    pacman -R firefox
                fi

                echo "Done..."
                echo "For install it again , you can use --install flag."
            else
                echo "[Warning]: an error happend while enabling systemd-resolved services"
                echo -n "Do you want to revert actions? [Y/n]:"

                read -r confirmation

                if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
                    dnsmasq_restart
                else
                    echo "Okay, you might not have internet access because your DNS server is inactive."
                fi
            fi
        fi
    fi
fi
