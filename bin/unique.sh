#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "
set -o errexit
#https://stackoverflow.com/questions/22492978/bash-tell-if-duplicate-lines-exist-y-n

if [ -z ${1} ]; then

exit 1

else

awk 'a[$0]++{exit 1}' ${1}

fi
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
