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
  fi
}

# dnsmasq_restart: Restart the servies of dnsmasq
dnsmasq_restart() {
  distro=$(get_distro)
  case "$distro" in
  arch | debian | ubuntu | rhel)
    systemctl restart dnsmasq.service
    if systemctl is-active --quiet "dnsmasq"; then
      echo "DnsMasq is restarted Successfully."
    else
      echo "Failed to restart DnsMasq. Please check the service problem with:"
      echo "journalctl -xu dnsmasq.service"
    fi
    ;;
  *)
    echo "Restart Failed."
    ;;
  esac
}

# Usage message
if [[ "$1" == "--help" ]]; then
  echo "-----------------------"
  echo "|    IRAN UNBOUND     |"
  echo "|  IR-Boycott-Bypass  |"
  echo "-----------------------"
  echo "Options:"
  echo "--install   Install and config dnsmasq"
  echo "--update    Update the boycotted domains list"
  echo "--dns			  Set an optional dns provider address. (default 178.22.122.100)"
  echo "--help			Show this message."
fi

# Check the config file is exists
if [ ! -f ./ir-domains.conf ]; then
  printf "Error: \"ir-domains.conf\" file is not exists. Please run:\n./iran-unbound.sh --update\n"
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

  sed -i "s,178.22.122.100,$2,g" ir-domains.conf
fi

# Pull the project (--udpate)
if [[ "$1" == "--update" ]]; then
  if git --version &>/dev/null; then
    git remote add origin https://github.com/MohsenParandvar/iran-unbound.git &>/dev/null
    git pull origin main
    cp ir-domains.conf /etc/dnsmasq.d/ir-domains.conf
  else
    echo "Please install \"Git\" before run update command."
    exit 1
  fi
fi
