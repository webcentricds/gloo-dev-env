#!/usr/bin/env bash

set -e

set -x
TEMP_DIR=`mktemp -d`
pushd $TEMP_DIR

#==============================================================================
# Install go  https://dl.google.com/go/go1.11.linux-amd64.tar.gz
#==============================================================================
curl -O https://dl.google.com/go/go1.11.linux-amd64.tar.gz
# Verify the checksum
CHKSUM=`sha256sum go1.11.linux-amd64.tar.gz | sed 's/ .*//'`
CHKSUM_SHOULD_BE="b3fcf280ff86558e0559e185b601c9eade0fd24c900b4c63cd14d1d38613e499"
if [ "$CHKSUM" != "$CHKSUM_SHOULD_BE" ] ; then
    echo "Checksum does not match"
    exit 9
fi

tar xvf go1.11.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv go /usr/local
PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

#==============================================================================
# Create GOPATH Location
#==============================================================================
mkdir -p $HOME/go
export GOPATH=$HOME/go:/usr/local/go

#==============================================================================
# Setup described here: https://gloo.solo.io/dev/README/
#==============================================================================
# Dep
go get -u github.com/golang/dep/cmd/dep

# Proto dependencies
set +e
curl -OL https://github.com/google/protobuf/releases/download/v3.3.0/protoc-3.3.0-linux-x86_64.zip && \
    unzip protoc-3.3.0-linux-x86_64.zip -d protoc3 && \
    sudo mv protoc3/bin/* /usr/local/bin/ && \
    sudo mv protoc3/include/* /usr/local/include/
set -e

git clone https://github.com/googleapis/googleapis "$HOME/go/googleapis"

go get -v github.com/golang/protobuf/...

go get -v github.com/gogo/protobuf/...

# Other tools used for code generation
go get github.com/paulvollmer/2gobytes

mkdir -p $HOME/go/src/k8s.io && \
    git clone https://github.com/kubernetes/code-generator $HOME/go/src/k8s.io/code-generator

git clone https://github.com/kubernetes/apimachinery $HOME/go/src/k8s.io/apimachinery

go get -v github.com/go-swagger/go-swagger/cmd/swagger

go get -d github.com/lyft/protoc-gen-validate

go get -u -f github.com/pkg/errors
go get -u -f github.com/go-openapi/runtime
go get -u -f golang.org/x/net/context/ctxhttp

#==============================================================================
# Now, go get gloo and glooctl (as make expects it to be in adjacent directory
#==============================================================================
pushd $HOME/go
mkdir -p $HOME/go/src/github.com/solo-io
git clone  --recurse-submodules -j8 https://github.com/solo-io/gloo $HOME/go/src/github.com/solo-io/gloo
git clone  --recurse-submodules -j8 https://github.com/solo-io/glooctl
pushd $HOME/go/src/github.com/solo-io/gloo
set +x
echo "+-----------------------------------------------------------------------"
echo "| GOPATH : $GOPATH"
echo "+-----------------------------------------------------------------------"
set -x
make localgloo
#go build -o gloo cmd/localgloo/main.go
popd
popd

set +x

