ARG BCI_IMAGE=registry.suse.com/bci/bci-base:latest
ARG GO_IMAGE=rancher/hardened-build-base:v1.16.10b7
FROM ${BCI_IMAGE} as bci
FROM ${GO_IMAGE} as builder
# setup required packages
RUN zypper update -y && \
    zypper --non-interactive install \
        unzip \
        libselinux-devel \
        libseccomp-devel
# setup the build
ARG PKG=go.etcd.io/etcd
ARG SRC=github.com/k3s-io/etcd
ARG TAG="v3.5.0-k3s2"
ARG ARCH="amd64"
RUN git clone --depth=1 https://${SRC}.git $GOPATH/src/${PKG}
WORKDIR $GOPATH/src/${PKG}
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
ENV CC=/usr/local/musl/bin/musl-gcc
# build and assert statically linked executable(s)
RUN go mod vendor && \
    export GO_LDFLAGS="-linkmode=external -X ${PKG}/version.GitSHA=$(git rev-parse --short HEAD)" && \
    if echo ${TAG} | grep -qE '^v3\.4\.'; then \
    go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o bin/etcd . && \
    go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o bin/etcdctl ./etcdctl; \
    else \
    cd $GOPATH/src/${PKG}/server  && go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o ../bin/etcd . && \
    cd $GOPATH/src/${PKG}/etcdctl && go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o ../bin/etcdctl .; \
    fi

RUN go-assert-static.sh bin/*
ARG ETCD_UNSUPPORTED_ARCH
ENV ETCD_UNSUPPORTED_ARCH=$ETCD_UNSUPPORTED_ARCH
RUN if [ "${ARCH}" != "s390x" ]; then \
    go-assert-boring.sh bin/*; \
    fi
RUN install -s bin/* /usr/local/bin
RUN etcd --version

FROM bci
RUN zypper update -y && \
    zypper clean --all
ARG ETCD_UNSUPPORTED_ARCH
ENV ETCD_UNSUPPORTED_ARCH=$ETCD_UNSUPPORTED_ARCH
COPY --from=builder /usr/local/bin/ /usr/local/bin/
