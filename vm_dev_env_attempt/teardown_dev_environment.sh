#!/usr/bin/env bash

set -e

set -x
sudo rm -rf /usr/local/go
rm -rf $HOME/go
unset GOPATH
set +x