#!/bin/bash

set -eux

source ~/emsdk/emsdk_env.sh

export INSTALL_FLANG=false
export BUILD_XEUS=false
export BUILD_XEUS_LITE=false
export BUILD_R=false
export BUILD_XEUS_R=false
export BUILD_JUPYTER_LITE=false
export BUILD_EMBEDDED=true

export PREFIX="$PWD/host-env"
export BUILD_PREFIX=$MAMBA_ROOT_PREFIX/envs/xeus-r-lite
export EMPACK_PREFIX=$MAMBA_ROOT_PREFIX/envs/xeus-r-lite

export EMCC_DEBUG=0

#-------------------------------------------------------------------------------
if [ "$INSTALL_FLANG" = true ]; then
    # Using flang as a WASM cross-compiler
    # https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
    # https://github.com/conda-forge/flang-feedstock/pull/69
    micromamba install -p $BUILD_PREFIX \
        conda-forge/label/llvm_rc::libllvm19=19.1.0.rc2 \
        conda-forge/label/llvm_dev::flang=19.1.0.rc2 \
        -y --no-channel-priority
    rm $BUILD_PREFIX/bin/clang # links to clang19
    ln -s $BUILD_PREFIX/bin/clang-18 $BUILD_PREFIX/bin/clang # links to emsdk clang
fi

#-------------------------------------------------------------------------------
if [ "$BUILD_XEUS" = true ]; then
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
if [ "$BUILD_XEUS_LITE" = true ]; then
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
if [ "$BUILD_R" = true ]; then
    echo "😈😈😈 Building R"
    pushd r-source
        ./build.sh
    popd
    echo "😈😈😈 Done"
fi

#-------------------------------------------------------------------------------
if [ "$BUILD_XEUS_R" = true ]; then
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
if [ "$BUILD_JUPYTER_LITE" = true ]; then
    pushd jupyter-lite
        echo "🫐🫐🫐 Building jupyter-lite"
        rm -r _output .jupyterlite.doit.db || true
        jupyter lite build --XeusAddon.prefix=$PREFIX --XeusAddon.mounts=/home/ihuicatl/Repos/Xeus/xeus-r-lite/host-env:/
        cp ../host-env/lib/R/lib/libR*.so _output/extensions/@jupyterlite/xeus/static/

        echo "🪅🪅🪅 Setting up the host 🪅🪅🪅"
        ln -s ../host-env/lib/ lib

        echo "🪅🪅🪅 Serving 🪅🪅🪅"
        python -m http.server
    popd
fi

# jupyter lite serve --XeusAddon.prefix=/home/ihuicatl/Repos/Xeus/xeus-r-lite/host-env --XeusAddon.mounts=/home/ihuicatl/Repos/Xeus/xeus-r-lite/host-env:/

#-------------------------------------------------------------------------------
export WASM_FLAGS="-sMAIN_MODULE -sWASM_BIGINT -sALLOW_MEMORY_GROWTH=1 -sEXPORTED_RUNTIME_METHODS=callMain,FS,ENV,getEnvStrings,TTY -sFORCE_FILESYSTEM=1 -sINVOKE_RUN=0 -fsanitize=address -sERROR_ON_UNDEFINED_SYMBOLS=0"

#-lRblas -lFortranRuntime -lpcre2-8 -llzma -lbz2 -lz -lrt -ldl -lm -liconv
export LINK_LIBS="-Lembed-env/lib/R/lib -lR -Lembed-env/lib/ -lRblas -lpcre2-8 -llzma -lbz2 -lz -liconv -ldl -lm -lrt"

export HEADER_PATH="-I/home/ihuicatl/Repos/Xeus/xeus-r-lite/host-env/lib/R/include/"
# -I/home/ihuicatl/emsdk/upstream/emscripten/system/lib/libc/musl/include/"

export SHARED_LIBS=""

modules=(
    "grDevices"
    "graphics"
    "grid"
    "methods"
    "parallel"
    "splines"
    "stats"
    "tools"
    "utils"
    "cli"
    "rlang"
)

if [ "$BUILD_EMBEDDED" = true ]; then
    pushd embedded
        echo "💥💥💥 Clean up"
        rm *.so || true

        echo "💥💥💥 Setting up the host"
        # ln -s ../host-env/ embed-env
        for module in "${modules[@]}"
        do
            SHARED_LIBS="$SHARED_LIBS embed-env/lib/R/library/$module/libs/$module.so"
            cp embed-env/lib/R/library/$module/libs/$module.so $module.so
        done
        cp embed-env/lib/R/lib/libR*.so ./

        echo "💥💥💥 Building embedded"
        em++ $HEADER_PATH $LINK_LIBS $WASM_FLAGS \
            -o embedded.js main.cpp $SHARED_LIBS --pre-js pre.js

        echo "💥💥💥 Serving"
        python -m http.server
    popd
fi
