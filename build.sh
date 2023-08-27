#!/bin/sh
options="src/ -out:build/odin-calc"

if [ -z "$1" ]; then
  eval "odin build ${options}"
elif [ $1 = "run" ]; then
  eval "odin run ${options}"
fi
