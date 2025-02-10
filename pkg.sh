#!/bin/bash

OPT="$1"
MESSAGE="Uso: sudo $0 clean|create"

if [ -z "$OPT" ]; then
    echo "$MESSAGE"
    exit 1
fi


if [ "$OPT" == "clean" ]; then
    echo "Limpiando archivos..."
    rm -rf build dist root
    [ -d /opt/openssh ] && rm -rf /opt/openssh
    echo "Limpieza completada."

elif [ "$OPT" == "create" ]; then
    build_dir=$(pwd)
    
    if [ ! -d /opt/openssh ]; then
        echo "Error: El directorio /opt/openssh no existe."
        exit 1
    fi

    cd /opt/ || exit 1
    chown -R root:root openssh

    tar -czvf openssh.tgz openssh
    mkdir -p "$build_dir/root"
    mv openssh.tgz "$build_dir/root/"
    
    echo "Archivo comprimido movido a $build_dir/root/"

else
    echo "$MESSAGE"
    exit 1
fi
