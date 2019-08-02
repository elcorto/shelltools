#!/bin/sh

fmt="{{.Repository}}:{{.Tag}}"
[ "$1" = "-v" ] && fmt="{{.Repository}}:{{.Tag}} {{.ID}} {{.CreatedSince}} {{.Size}}"

docker image ls --format "$fmt" | column -t
