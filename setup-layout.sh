#!/bin/bash -e

set -ue

sleep 1

zellij action go-to-tab-name watch
zellij action write-chars "just watch"
zellij action write 13

zellij action go-to-tab-name setup
zellij action close-tab

zellij action go-to-tab-name root
