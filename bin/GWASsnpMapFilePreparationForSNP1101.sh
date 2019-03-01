#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
#define function to chek when parallel jobs are ready

PRLLRUNcheck () {
#echo ${1};
existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${1}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
fi
done


echo "file to check  ${1}  exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${1} )
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 120 ]; then
    shotresult=same
    echo "${1} is ready now ${RIGHT_NOW}"
 fi
done

}

if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
fi
if [ -z $2 ]; then
    echo "brauche den Code ob Genotypen oder phased genotypes gelesen werden sollen: .out fuer Genotypen / .haplos fuer phased genotypes"
    exit 1
fi
set -o errexit
set -o nounset
if [ ${1} == "BSW" ]; then
pdfol=bv
datped=${DatPEDIbvch}
fi
if [ ${1} == "HOL" ]; then
pdfol=rh
datped=${DatPEDIshb}
fi
if [ ${1} == "VMS" ]; then
pdfol=vms
datped=${DatPEDIvms}
fi


if [ ${2} == "GENOTYPES" ]; then
    foldername="out"
elif [ ${2} == "HAPLOTYPES" ]; then
    foldername="haplos"
else
    echo "${2} is not correct, GENOTYPES or HAPLOTYPES are allowed"
    exit 1
fi


breed=$(echo "$1")



if [ ${HFTSNPSET} == "HD" ]; then
(echo "SNPID Chr Pos";
   cat $FIM_DIR/${breed}BTAwholeGenome.${foldername}/snp_info.txt | sed -n '2,$p') | awk '{printf "%-50s%-5s%-10s\n", $1,$2,$3}' > $TMP_DIR/${breed}.snpinfo.dat
fi
if [ ${HFTSNPSET} == "LD" ]; then
(echo "SNPID Chr Pos";
   awk '{if($5 != 0)print}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/snp_info.txt | sed -n '2,$p') | awk '{printf "%-50s%-5s%-10s\n", $1,$2,$3}' > $TMP_DIR/${breed}.snpinfo.dat
fi
 
echo "Final statictics"
wc -l $TMP_DIR/${breed}.snpinfo.dat



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
