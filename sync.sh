#!/bin/bash

#
# GIT-FTP
# Forward call to submodule
#


# get all params
params=$*


#
# SYNC SUBMODULES
#

# get submodules
submodules=`git submodule | grep -o "[^ ]*$"`

# make sure, url is first argument
if [ "${params:0:1}" == "-" ]; then
    echo ""
    echo "ERROR: Please pass URL first"
    echo "Submodules not synced"
    exit 1;
fi

root_dir=`pwd`
for submodule in $submodules; do
    
    echo ""
    echo ""
    echo ""
    echo ""
    echo "#"
    echo "# ----------------------------------------------------------------------------"
    echo "# sync submodule $submodule"
    echo "# ----------------------------------------------------------------------------"
    echo "#"
    echo ""
    
    # escape slashes in submodule path
    submodule_escaped=`echo $submodule | sed 's:/:\\\/:g'`
    
    # add submodule to ftp url
    subparams=`echo $params | sed "s/\([^ ]*\)/\1${submodule_escaped}/"`
    
    # add submodule to http url
    subparams=`echo $subparams | sed "s/--http \([^ ]*\)/--http \1${submodule_escaped}/"`
    subparams=`echo $subparams | sed "s/--w \([^ ]*\)/--w \1${submodule_escaped}/"`
    
    # go to submodule and do sync
    cd $submodule
    $0 $subparams
    
    if [ $? -ne 0 ]; then
        cd $root_dir
        exit 1
    fi
    
    cd $root_dir
done

if [ `echo $submodule | wc -w` -gt 0 ]; then
    echo ""
    echo ""
    echo ""
    echo ""
    echo "#"
    echo "# ----------------------------------------------------------------------------"
    echo "# sync superproject"
    echo "# ----------------------------------------------------------------------------"
    echo "#"
    echo ""
fi


#
# SYNC MAIN
#

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

`dirname $0`/download.sh $params

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
cmd="`dirname $0`/git-ftp/git-ftp.sh ${params}"
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
`dirname $0`/download.sh ${params} --catchup

echo ""
echo "# Checkout master"
git checkout master


