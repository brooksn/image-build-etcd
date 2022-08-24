#!/bin/sh

make ORG=bcibase TAG="v3.5.4-k3s1-build20220504" BUILD_META="-build20220504" image-build

make ORG=bcibase TAG="v3.5.3-k3s1-build20220413" BUILD_META="-build20220413" image-build
