#!/bin/bash

set -eux

export BUILD_XEUS=true
export BUILD_XEUS_LITE=true
export BUILD_XEUS_R=true

export PREFIX="$PWD/host-env"
export EMPACK_PREFIX=$MAMBA_ROOT_PREFIX/envs/xeus-r-lite

export EMCC_DEBUG=1

#-------------------------------------------------------------------------------
if BUILD_XEUS; then
    echo "🍅🍅🍅 Building xeus"
    pushd xeus
        rm -r _build || true
        mkdir _build
        cd _build
        echo "🍅🍅🍅 CMaking"
        emcmake cmake .. \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_PREFIX_PATH=$PREFIX \
            -DCMAKE_INSTALL_PREFIX=$PREFIX \
            -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
            -DXEUS_EMSCRIPTEN_WASM_BUILD=ON \
            -Dnlohmann_json_DIR=$PREFIX/share/cmake/nlohmann_json \
            -DCMAKE_VERBOSE_MAKEFILE=ON
        echo "🍅🍅🍅 Making"
        emmake make -j4 VERBOSE=1
        echo "🍅🍅🍅 Installing"
        emmake make install
        echo "🍅🍅🍅 Done"
    popd
fi

#-------------------------------------------------------------------------------
if BUILD_XEUS_LITE; then
    echo "⭐⭐⭐ Building xeus-lite"
    pushd xeus-lite
        rm -r _build || true
        mkdir _build
        cd _build
        echo "⭐⭐⭐ CMaking"
        emcmake cmake  .. \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_PREFIX_PATH=$PREFIX \
            -DCMAKE_INSTALL_PREFIX=$PREFIX \
            -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
            -Dnlohmann_json_DIR=$PREFIX/share/cmake/nlohmann_json \
            -Dxeus_DIR=$PREFIX/lib/cmake/xeus \
            -DXEUS_LITE_BUILD_BROWSER_TEST_KERNEL=OFF \
            -DXEUS_LITE_BUILD_NODE_TESTS=OFF \
            -DCMAKE_VERBOSE_MAKEFILE=ON
        echo "⭐⭐⭐ Making"
        emmake make -j4 VERBOSE=1
        echo "⭐⭐⭐ Installing"
        emmake make install
        echo "⭐⭐⭐ Done"
    popd
fi

#-------------------------------------------------------------------------------
if BUILD_XEUS_R; then
    echo "🫘🫘🫘 Building xeus-r"
    pushd xeus-r
        rm -r _build || true
        mkdir _build
        cd _build
        echo "🫘🫘🫘 CMaking"
        emcmake cmake .. \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_PREFIX_PATH=$PREFIX \
            -DCMAKE_INSTALL_PREFIX=$PREFIX \
            -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
            -DXEUS_R_EMSCRIPTEN_WASM_BUILD=ON \
            -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
            -DCMAKE_VERBOSE_MAKEFILE=ON
        echo "🫘🫘🫘 Making"
        emmake make -j4 VERBOSE=1
        echo "🫘🫘🫘 Installing"
        emmake make install
        echo "🫘🫘🫘 Done"
    popd
fi

echo "🍌🍌🍌 All done packaging 🍌🍌🍌"

#-------------------------------------------------------------------------------
pushd jupyter-lite
    echo "🫐🫐🫐 Building jupyter-lite"
    rm -r _output || true
    jupyter lite build --XeusAddon.prefix=$PREFIX
popd