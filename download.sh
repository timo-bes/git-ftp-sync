#!/bin/bash

#
# FTP-GIT
# Forward call to submodule
#

# get all params
params=""
while test $# != 0
do
    params="${params} $1"
    shift
done

# forward call and add --sha1 option
`dirname $0`/ftp-git/ftp-git.sh${params} --sha1=.git-ftp.log

if [ $? -ne 0 ]; then
    exit 1
fi