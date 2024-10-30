#!/bin/bash

export HOST_NAME="./host-env"
export FILE_NAME="filefile.js"

echo "let fffiles = \`" > $FILE_NAME

echo "🐸 BIN"
find $HOST_NAME/bin -type f >> $FILE_NAME

echo "🐸 INCLUDE"
find $HOST_NAME/include -type f >> $FILE_NAME

echo "🐸 LIB"
find $HOST_NAME/lib -type f >> $FILE_NAME

echo "🐸 SHARE"
find $HOST_NAME/share -type f >> $FILE_NAME

echo "🐸 TOOLS"
find $HOST_NAME/tools -type f >> $FILE_NAME

echo "\`" >> $FILE_NAME