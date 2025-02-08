#!/bin/bash

OPT=$1

if [ "$OPT" == "clean" ]; then
   rm -rf build dist root
   rm -rf /opt/openssh 
elif [ "$OPT" == "create" ]; then
   build_dir=$(pwd)
   cd /opt/
   chown root:root -R openssh
   tar -czvf openssh.tgz openssh
   mv openssh.tgz "$build_dir/root"
else 
   echo "sudo $0 clean|create"
fi
