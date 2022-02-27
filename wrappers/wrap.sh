#!/usr/bin/env bash
crema "$1" --repo repo "${@:2}"
exit $?
