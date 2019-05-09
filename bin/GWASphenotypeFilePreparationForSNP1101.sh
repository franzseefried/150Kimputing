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

echo "not phenotype file does not have to fit with genotype file in terms of no of records"
#phenotypefile aufbau
if [ ${GWASPHEN} == "BINARY" ]; then
if [ ${DEFCNTRGRP} ==  "N" ]; then
   echo " I take alle genotyped animals beyond cases as controls"
   #prepare phenotype file, achtung cases mit 2 kodiert. Ziel = 1 /2 . alle anderen ausser die cases werden 1 codiert. +  Dummy reliability und alle Tiere als referneztiere setzen
   (echo "ID Group Obs Rel" | awk '{printf "%-10s%-10s%-12s%-10s\n", $1,$2,$3,$4}';
     awk '{if($2 != "") print $1,$1}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis | sort -T ${SRT_DIR} -t' ' -k1,1 -T $SRT_DIR |\
     join -t' ' -o'1.1 2.2' -a1 -e'1' -1 1 -2 1 - <(awk '{print substr($1,1,14),"2"}' $GWAS_DIR/${breed}_${GWAStrait}_affectedAnimals.txt | sort -T ${SRT_DIR} -t' ' -k1,1) |\
     sort  -t' ' -k1,1 -T $SRT_DIR |\
     join -t' ' -o'2.1 1.2 2.5' -1 1 -2 5 - <(sort -T ${SRT_DIR} -t' ' -k5,5 -T $SRT_DIR $WORK_DIR/ped_umcodierung.txt.${breed}) |\
     awk '{printf "%-10s%-10s%-12s%-10s\n", $1,"1",$2,"99"}') > $TMP_DIR/${breed}.phenotypes.dat 
fi
if [ ${DEFCNTRGRP} ==  "Y" ]; then
   #test if cases and controls are separated correctly
   nCommonSamples=$(join -t' ' -o'1.1' -1 1 -2 1 <(awk '{print substr($0,1,14),"2"}' $GWAS_DIR/${breed}_${GWAStrait}_affectedAnimals.txt | sort -T ${SRT_DIR} -t' ' -k1,1) <(awk '{print substr($0,1,14),"0"}' $GWAS_DIR/${breed}_${GWAStrait}_controlAnimals.txt | sort -T ${SRT_DIR} -t' ' -k1,1) |wc -l | awk '{print $1}')
   if [ ${nCommonSamples} -gt 0 ]; then echo "contro and cases have ; ${nCommonSamples} ; common samples -> ERROR"; exit 1; fi 
   echo " I take alle defined control group animals"
   #prepare phenotype file, achtung cases mit 2 kodiert. Ziel = 1 /2 . alle anderen ausser die cases werden 1 codiert. +  Dummy reliability und alle Tiere als referneztiere setzen
   (echo "ID Group Obs Rel" | awk '{printf "%-10s%-10s%-12s%-10s\n", $1,$2,$3,$4}';
     awk '{if($2 != "") print $1,$1}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis | sort -T ${SRT_DIR} -t' ' -k1,1 -T $SRT_DIR |\
     join -t' ' -o'1.1 2.2' -1 1 -2 1 - <((awk '{print substr($0,1,14),"2"}' $GWAS_DIR/${breed}_${GWAStrait}_affectedAnimals.txt | sort -T ${SRT_DIR} -t' ' -k1,1;awk '{print substr($0,1,14),"1"}' $GWAS_DIR/${breed}_${GWAStrait}_controlAnimals.txt | sort -T ${SRT_DIR} -t' ' -k1,1)|sort -t' ' -k1,1) |\
     sort  -t' ' -k1,1 -T $SRT_DIR |\
     join -t' ' -o'2.1 1.2 2.5' -1 1 -2 5 - <(sort -T ${SRT_DIR} -t' ' -k5,5 -T $SRT_DIR $WORK_DIR/ped_umcodierung.txt.${breed}) |\
     awk '{printf "%-10s%-10s%-12s%-10s\n", $1,"1",$2,"99"}') > $TMP_DIR/${breed}.phenotypes.dat 
fi
echo "distribution of case control phenotype:"
awk '{print $3}' $TMP_DIR/${breed}.phenotypes.dat |sort|uniq -c
fi


if [ ${GWASPHEN} == "QUANTITATIVE" ]; then
#behalte nur die die phaenotype haben. Hier sind ja alle in einem Phaenotypenfile drin
   (echo "ID Group Obs Rel" | awk '{printf "%-10s%-10s%-12s%-10s\n", $1,$2,$3,$4}';
     join -t' ' -1 1 -2 5 -o'2.1 1.2' <(sort -t' ' -k1,1 $GWAS_DIR/${breed}_${GWAStrait}_inputPhenotypes.txt) <(sort -T ${SRT_DIR} -t' ' -k5,5 -T $SRT_DIR $WORK_DIR/ped_umcodierung.txt.${breed}) |\
     awk '{printf "%-10s%-10s%-12s%-10s\n", $1,"1",$2,"99"}') > $TMP_DIR/${breed}.phenotypes.dat 
fi

wc -l $TMP_DIR/${breed}.phenotypes.dat

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
