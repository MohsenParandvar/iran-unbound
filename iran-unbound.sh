#!/bin/bash

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
  exit
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
  if git --version &> /dev/null; then
    git remote add origin https://github.com/MohsenParandvar/iran-unbound.git
    git pull
  else
    echo "Please install \"Git\" before run update command."
    exit
  fi
fi

