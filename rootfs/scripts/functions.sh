#!/bin/bash

ask() { local q="$1"; local d=${2:-"n"}
  read -p "$q [$d]: " r; r=${r:-"$d"}
  while true; do
    case $r in
      y|Y|yes|Yes|yES|YES )
        return 0
        ;;
      n|N|no|No|nO )
        return 1
        ;;
      * )
        read -p "Not a valid answer. Try 'y' or 'n': " r
        continue
        ;;
    esac
  done
}
