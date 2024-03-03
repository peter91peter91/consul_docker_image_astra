#!/bin/sh


docker run -it --workdir=/app --entrypoint=bash -v="$(pwd):/app" registry.astralinux.ru/library/alse:1.7.3