#!/bin/bash

#
# GIT-FTP
# Forward call to submodule
#


# get all params
params=""
while test $# != 0
do
    params="${params} $1"
    shift
done

check_merge() {
    # check whether ftp-git branch has been merged
    diff_logs=`git log ftp ^master | wc -l`
    if [ $diff_logs -gt 0 ]; then
        echo ""
        echo "*****************************************************"
        echo "FATAL:"
        echo "  the branch ftp has not been merged onto master yet."
        echo "  please do so and try again."
        echo "*****************************************************"
        echo ""
        exit 1
    fi
}

check_merge


echo ""
echo "*****************"
echo "*               *"
echo "*  #1 DOWNLOAD  *"
echo "*               *"
echo "*****************"
echo ""

`dirname $0`/download.sh${params}

if [ $? -ne 0 ]; then
    exit 1
fi

check_merge


echo ""
echo ""
echo "***************"
echo "*             *"
echo "*  #2 UPLOAD  *"
echo "*             *"
echo "***************"
echo ""

# forward call (without --http)
cmd="`dirname $0`/git-ftp/git-ftp.sh${params}"
cmd=`echo "$cmd" | sed "s/\(.*\) --http [^ ]* \(.*\)/\1 \2/"`
$cmd

if [ $? -ne 0 ]; then
    exit 1
fi


echo ""
echo ""
echo "**************"
echo "*            *"
echo "*  #3 MERGE  *"
echo "*            *"
echo "**************"
echo ""

echo "# Checkout ftp"
git checkout ftp

echo ""
echo "# Merge master"
git merge master

echo ""
echo "# Get new list from FTP"
`dirname $0`/download.sh${params} --catchup

echo ""
echo "# Checkout master"
git checkout master
