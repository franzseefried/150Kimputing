#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
export lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit

### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -f <string>"
  echo "  where <string> specifies the file to be uploaded"
  #echo "  where <string> valid options are BSW or HOL"
  echo "Usage: $SCRIPT -o <string>"
  echo "  where <string> specifies the folder where file -f is"
  echo "Usage: $SCRIPT -z <string>"
  echo "  where <string> specifies the Folder where the file should be uploaded to"
  #echo "  where <string> valid options are 0, 1 or 2"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
  exit 1
fi

while getopts ":o:f:z:" FLAG; do
  case $FLAG in
    o) # set option "z"
      localfolder=$(echo $OPTARG )
      if [ ! -z ${localfolder} ] ; then
          echo ${localfolder} > /dev/null
      else
          usage 'Parameter for local Folder where the files exists is NULL, must be specified: using option -o <string>'
          exit 1
      fi
      ;;
    f) # set option "f"
      upf=$(echo $OPTARG )
      if [ ! -z ${upf} ] ; then
          echo ${upf} > /dev/null
      else
          usage 'Parameter for file to be tranferred is NULL, must be specified usinf -f <string> option '
          exit 1
      fi
      ;;   
    z) # set option "z"
      putfolder=$(echo $OPTARG )
      if [ ! -z ${putfolder} ] ; then
          echo ${putfolder} > /dev/null
      else
          usage 'Parameter for Folder on ftpServer where to put the file is NULL, must be specified: using option -z <string>'
          exit 1
      fi
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
if test -s ${localfolder}/${upf} ; then
   echo ${upf} > /dev/null
else
   echo "file to be transferred ${localfolder}/${upf} does not exist of has size zero"
   exit 1
fi

#echo $upf $putfolder

cd ${localfolder}
echo "file tp be uploaded:"
ls -trl ${upf}
echo " "
echo "connecting ftp now"

HOST='ftp.elvadata.ch'
USER='qualitas'
PASSWD='DPiv35$!'
#datei='USAM000000022235_D.pdf'
#echo $datei
ftp -n $HOST <<end_skript
quote USER $USER
quote PASS $PASSWD
cd ${putfolder}
binary
put ${upf}
dir ${upf}
quit
end_skript


echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}
