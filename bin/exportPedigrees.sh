#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

#######################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
#######################################################
set -o errexit
set -o nounset

### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  exit 1
}
### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b: FLAG; do
  case $FLAG in
    b) # set option "b"
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
      else
          usage "ImputationSystem not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
## # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'IMPUTATIONSYSTEM not specified, must be specified using option -b <string>'   
fi






# The directory for the evaluation is the directory where this program is stored
#eval_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)  # https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
#cd $eval_dir



# Check locking of the process
#if test -f lock.txt; then
#    echo "Processes are locked. Script is stopped."
#    echo "  Relevant processes could be running on Argus"
#    echo "  In order to unlock delete $eval_dir/lock.txt"
#    exit 1
#fi
#echo "This file is to prevent multiple startings of sql-processes" > lock.txt


#fix vergeben da nur BRUNANET
if ! test -d ${DEUTZ_DIR}/sbzv/dsch/in ; then
    >&2 echo "Error: ${DEUTZ_DIR}/sbzv/dsch/in not found"
    exit 1
fi

if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}/
fi

 #schreiben der parameterfiles
#==================================================
if [ ${breed} == "BSW" ]; then
    #2 pedigrees bei BSW
    pedigrees="ExportPedigree.bvch.gs.par;ExportPedigree.jer.gs.par";
    #pedigrees="ExportPedigree.jer.gs.par";
    (echo "psFileName;pedigree_rrtdm_BVCH.dat";
     echo "pnExportBlood;1";
     echo "pnExportNameDame;1";
     echo "pnIdAnimal;";
     echo "pnIdGattung;";
     echo "psHbRasse;BV,BS,OB,ROB";
     echo "pnNoHbRInc;0";
     echo "pnNoNOk;0";
     echo "pnNoStillgelegt;1";
     echo "pnIgnoreOKCode;0";
     echo "pnIgnoreHbRInc;0";
     echo "pnOutSektion;0";
     echo "pnOutRasseCode;0";
     echo "pnGenmarker;0";) > ${DEUTZ_DIR}/sbzv/dsch/in/ExportPedigree.bvch.gs.par
     
     (echo "psFileName;pedigree_rrtdm_JER.dat";
     echo "pnExportBlood;1";
     echo "pnExportNameDame;1";
     echo "pnIdAnimal;";
     echo "pnIdGattung;";
     echo "psHbRasse;JE";
     echo "pnNoHbRInc;0";
     echo "pnNoNOk;0";
     echo "pnNoStillgelegt;1";
     echo "pnIgnoreOKCode;0";
     echo "pnIgnoreHbRInc;0";
     echo "pnOutSektion;0";
     echo "pnOutRasseCode;0";
     echo "pnGenmarker;0";) > ${DEUTZ_DIR}/sbzv/dsch/in/ExportPedigree.jer.gs.par
elif  [ ${breed} == "HOL" ]; then
    pedigrees="ExportPedigree.shb.gs.par";
    (echo "psFileName;pedigree_rrtdm_SHB.dat";
     echo "pnExportBlood;1";
     echo "pnExportNameDame;1";
     echo "pnIdAnimal;";
     echo "pnIdGattung;";
     echo "psHbRasse;HO,SF,MO,SI,NO,BF,PZ,EV";
     echo "pnNoHbRInc;0";
     echo "pnNoNOk;0";
     echo "pnNoStillgelegt;1";
     echo "pnIgnoreOKCode;0";
     echo "pnIgnoreHbRInc;0";
     echo "pnOutSektion;1";
     echo "pnOutRasseCode;1";
     echo "pnGenmarker;0";) > ${DEUTZ_DIR}/sbzv/dsch/in/ExportPedigree.shb.gs.par
elif  [ ${breed} == "VMS" ]; then
    pedigrees="ExportPedigree.vms.gs.par";
    (echo "psFileName;pedigree_rrtdm_VMS.dat";
     echo "pnExportBlood;1";
     echo "pnExportNameDame;1";
     echo "pnIdAnimal;";
     echo "pnIdGattung;";
     echo "psHbRasse;";
     echo "pnNoHbRInc;0";
     echo "pnNoNOk;0";
     #inkl stillgelegte damit kein sql noetig 
     echo "pnNoStillgelegt;0";
     echo "pnIgnoreOKCode;0";
     echo "pnIgnoreHbRInc;0";
     echo "pnOutSektion;0";
     echo "pnOutRasseCode;0";
     echo "pnGenmarker;0";) > ${DEUTZ_DIR}/sbzv/dsch/in/ExportPedigree.vms.gs.par
else
    >&2 echo "Error: Unknown breeding_association"
    usage
    exit 1
fi

#HOST=rapid.braunvieh.ch
HOST=$(echo ${dbsystem}.braunvieh.ch)
SERVICE=AR01.braunvieh.ch
USERNAME=gestho
PASSWORD=gestho
MANDANT=SBZV



# Prepare and run sql-program to purge the location data
#=======================================================
if ! test -s $BIN_DIR/exportPedigrees.sql; then
    >&2 echo "Error: $BIN_DIR/exportPedigrees.sql does not exist or is empty"
    exit 1
fi
cd ${DEUTZ_DIR}/sbzv/dsch/in
for pedipar in $(echo ${pedigrees} | tr ';' ' ' ); do
	echo "${breed} ${pedipar} started now"
	echo " ";
	echo "Parameterfile looks as follows:";
	cat ${pedipar};
	cd ${MAIN_DIR}
	
	$MAIN_DIR/bin/update_T_JOB_PARAM.sh ${pedipar}
	
	cd ${DEUTZ_DIR}/sbzv/dsch/in
	
	echo " "
	lJOB=$(awk '{ sub("\r$", ""); print }' ${DEUTZ_DIR}/sbzv/dsch/out/jobid.txt | awk '{print $1}')
    #using pedipackage directly
    #cat $BIN_DIR/exportPedigrees.sql | sed "s/XXXXXXXXXX/${pedipar}/g"  | sed "s/MANDANTTNADNAM/${MANDANT}/g" > exportPedigrees.doit.sql
	#using PA_OPERAT.callJobById
    cat $BIN_DIR/exportPedigrees.sql | sed "s/XXXXXXXXXX/${lJOB}/g"  | sed "s/YYYYYYYYYY/${MAILACCOUNT}/g" | sed "s/MANDANTTNADNAM/${MANDANT}/g" > exportPedigrees.doit.sql
    
    cat exportPedigrees.doit.sql
    echo ${USERNAME}/${PASSWORD}@//${HOST}:1521/${SERVICE}
    sql ${USERNAME}/${PASSWORD}@//${HOST}:1521/${SERVICE} @exportPedigrees.doit.sql
    sleep 10
done


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

