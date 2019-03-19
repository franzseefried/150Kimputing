#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

###############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit

if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS "
    exit 1
fi 
set -o nounset
    
BREED=$(echo "$1")
echo "running runFimpute GPsearch for breed ${BREED}:"

cd $FIM_DIR
#write parameterfile
(echo "title=\"GPsearch\";"
echo "genotype_file=\"${BREED}.GPsearch_FImpute.geno\";"
echo "snp_info_file=\"${BREED}.GPsearch_FImpute.snpinfo\";"
echo "ped_file=\"${BREED}.GPsearch_Fimpute.ped\";"
echo "parentage_test /ert_mm=0.02 /ert_m=0.01 /find_match_cnflt /remove_conflict;"
echo "add_ungen /min_fsize=4 /output_min_fsize=4 /output_min_call_rate=0.95;"
echo "output_folder=\"${BREED}.GPsearch.out\";"
echo "njob=${numberOfParallelMEHDIJobs};") > ${BREED}.GPsearch.haplos.ctr

echo "Parameters are as follows:"
cat ${BREED}.GPsearch.haplos.ctr
echo " "
$FRG_DIR/FImpute_Linux  ${BREED}.GPsearch.haplos.ctr -o

rm -f ${BREED}.GPsearch.haplos.ctr
cd $lokal




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
