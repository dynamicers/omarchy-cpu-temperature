#!/bin/sh
# Optional root is useful for testing with a synthetic hwmon tree.
for h in "${1:-/sys/class/hwmon}"/hwmon*; do
  [ -r "$h/name" ] || continue
  read -r name < "$h/name" || continue
  case "$name" in
    coretemp|k10temp|zenpower) ;;
    *) continue ;;
  esac

  # Tctl can include a fan-control offset; prefer Tdie on the same device.
  has_tdie=0
  for label_file in "$h"/temp*_label; do
    [ -r "$label_file" ] || continue
    read -r label < "$label_file"
    if [ "$label" = Tdie ]; then
      has_tdie=1
      break
    fi
  done

  for input in "$h"/temp*_input; do
    [ -r "$input" ] || continue
    label=""
    label_file="${input%_input}_label"
    [ ! -r "$label_file" ] || read -r label < "$label_file"
    if [ -z "$label" ]; then
      label="${input##*/}"
      label="${label%_input}"
    fi
    [ "$has_tdie" = 1 ] && [ "$label" = Tctl ] && continue
    printf '%s\t%s\t%s\n' "$name" "$label" "$input"
  done
done
