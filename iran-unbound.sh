#!/bin/bash

# get_distro: Detects the Linux distribution of the system.
get_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    echo "$DISTRIB_ID"
  elif [ -f /etc/redhat-release ]; then
    echo "rhel"
  elif [ -f /etc/arch-release ]; then
    echo "arch"
  elif [ -f /etc/alpine-release ]; then
    echo "alpine"
  else
    echo "other"
  fi
}

# Ask from user for base of distro
get_custom_distro() {
    # Prompt the user for a custom distribution name
    read -p "Unable to identify the distribution. Please specify a custom distribution (options: arch, debian, ubuntu, rhel, alpine): " custom_distro
    # Validate the input
    case "$custom_distro" in
    arch | debian | ubuntu | rhel | alpine)
      echo "$custom_distro" # Return the custom distro if valid
      ;;
    *)
      echo "Invalid input. Please enter one of: arch, debian, ubuntu, rhel, alpine."
      return 1
      ;;
    esac
}

# dnsmasq_restart: Restart the servies of dnsmasq
dnsmasq_restart() {
  distro=$(get_distro)

  if [[ "$distro" == "other" ]];then
    get_custom_distro
  fi

  case "$distro" in
  arch | debian | ubuntu | rhel)
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
    echo -n "Are you sure you want to proceed? [Y,n]:"

    read -r confirmation

    if [[ "$confirmation" != "Y" && "$confirmation" != "y" ]]; then
      exit 0
    fi
  fi

  distro=$(get_distro)

  if [[ "$distro" == "other" ]];then
    distro=$(get_custom_distro)
  fi

  # Debian Based
  if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
    apt update
    apt install dnsmasq -y

    systemctl disable systemd-resolved.service
    systemctl stop systemd-resolved.service

    cp b-domains.conf /etc/dnsmasq.d/b-domains.conf

    is_restarted=$(dnsmasq_restart)

    if [[ "$is_restarted" == "Dnsmasq is restarted Successfully." ]]; then
      echo "Installation successfully."
    fi
  fi

  # RHEL Based
  if [[ "$distro" == "rhel" ]]; then
    dnf update
    dnf install dnsmasq -y

    systemctl disable systemd-resolved.service
    systemctl stop systemd-resolved.service

    is_restarted=$(dnsmasq_restart)

    if [[ "$is_restarted" == "Dnsmasq is restarted Successfully." ]]; then
      echo "Installation successfully."
    fi
  fi

  # Arch Based
  if [[ "$distro" == "arch" ]]; then
    pacman -Syu
    pacman -S dnsmasq

    systemctl disable systemd-resolved.service
    systemctl stop systemd-resolved.service

    is_restarted=$(dnsmasq_restart)

    if [[ "$is_restarted" == "Dnsmasq is restarted Successfully." ]]; then
      echo "Installation successfully."
    fi
  fi
fi


