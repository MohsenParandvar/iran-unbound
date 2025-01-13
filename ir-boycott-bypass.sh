#!/bin/bash

if [[ "$1" -ne "--help" ]]; then
  echo "-----------------"	
  echo "IR-Boycott-Bypass"
  echo "-----------------"	
  echo "options:"
  echo "--help			Show this message."
  echo "--domain		Set an optional dns provider address. (default 178.22.122.100)"
  echo "--default-domain	Set the default dns provider; unbanned domains will use this domain. (default 8.8.8.8)"
fi

