#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
#set -o errexit

BTA=wholeGenome
#Set Script Name variable
SCRIPT=`basename ${BASH_SOURCE[0]}`
### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options BSW or HOL"
  echo "  where <string> valid options are BSW or HOL"
  echo "Usage: $SCRIPT -p <string>"
  echo "  where <string> specifies the parent to be checked"
  echo "  where <string> valid options are sire or dam"
  exit 1
}


### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:p: FLAG; do
  case $FLAG in
    b) # set option "b"
      breed=$(echo $OPTARG | tr a-z A-Z)
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ] || [ ${breed} == "ALL" ]; then
	  echo ${breed} > /dev/null
      else
	  usage 'Breed not correct, must be specified BSW or HOL or VMS using option -b <string>'
      fi
      ;;
    p) # set option "p"
      parent=$(echo $OPTARG | tr A-Z a-z)
      if [ ${parent} == "sire" ] || [ ${parent} == "dam" ]; then
	  echo ${parent} > /dev/null
      else
	  usage 'Parent not correct, must be specified SIRE or DAM using option -b <string>'
      fi
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'Breed not specified, must be specified using option -b <string>'	
fi
### # check that parent is not empty
if [ -z "${parent}" ]; then
    usage 'Parent name must be specified using option -p <string>'	
fi
set -o nounset

    #breed=$(echo "$1")
echo "running Fimpute PEDICHECK ${parent} BTA${BTA} for breed ${breed} im nohhup"
echo " "
echo "warte bis Kommentar auf Commandline dass parentage test fertig ist."


rm -f ${FIM_DIR}/${breed}_PEDICHECKout/*
rm -rf ${FIM_DIR}/${breed}_PEDICHECKout
mkdir ${FIM_DIR}/${breed}_PEDICHECKout

(echo "title=\"BTAX for ${breed} and ${parent}\";"
echo "genotype_file=\"${FIM_DIR}/DUMMY${parent}${breed}BTA${BTA}_FImpute.geno\";"
echo "snp_info_file=\"${FIM_DIR}/${breed}BTA${BTA}_FImpute.snpinfo\";"
echo "ped_file=\"${FIM_DIR}/DUMMY${parent}${breed}Fimpute.ped\";"
echo "parentage_test /ert_mm=0.02 /ert_m=0.01 /find_match_cnflt /remove_conflict;"
echo "output_folder=\"${FIM_DIR}/${breed}_PEDICHECKout\";"
echo "njob=${numberOfParallelMEHDIJobs};" ) > ${FIM_DIR}/${breed}_PEDICHECK.ctr
echo " "
echo "Parameters are as follows:"
cat ${FIM_DIR}/${breed}_PEDICHECK.ctr
echo " "

nohup $FRG_DIR/FImpute_Linux ${FIM_DIR}/${breed}_PEDICHECK.ctr -o > ${FIM_DIR}/Fimpute${breed}.log 2>&1 &	

date
sleep 60
date
    #endless LOOP to tell User when Parantage is ready


$BIN_DIR/countSecTillFileInARG2Exists.sh ${breed} $FIM_DIR/${breed}_PEDICHECKout/report.txt


t=0
while [ true ]; do
    if [ ${t} -lt 1 ]; then
	t=$(grep "Imputing... (No. jobs" $FIM_DIR/${breed}_PEDICHECKout/report.txt | wc -l | awk '{print $1}')
    else
	echo "Parentage for ${breed} done"
	echo "killing Fimpute jobs for pediCHECK"
	ps fax | grep -i FImpute_Linux | tr -s ' ' |awk -v gg=${MAIN_DIR} '{if($9 ~ gg || $5 ~ gg || $6 ~ gg) print $1}' | while read job; do   kill ${job} > /dev/null 2>&1  ; done
	exit 1
    fi
done


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

