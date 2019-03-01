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

cat $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert_NGPsiredamkorrigiert | sed -n '2,$p' | awk '{print $1";"$2";"$3";"$4}' > $TMP_DIR/${breed}.pedi.tmp
#pedigree aufbau snp1101
MissingYoB=$(date +"%Y")
#update pedigree with YoB
awk '{print substr($0,1,10)";"substr($0,73,4)}' ${PEDI_DIR}/work/${pdfol}/UpdatedRenumMergedPedi_${datped}.txt | sed 's/ //g' > $TMP_DIR/${breed}.uppd.tmp
(echo "ID SireID DamID Gender YoB";
awk -v MYOB=${MissingYoB} 'BEGIN{FS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));bp[$1]=$2;}} \
    else {sub("\015$","",$(NF));bpS=bp[$1]; \
    if   (bpS != "" && bpS != 9999) {print $1" "$2" "$3" "$4" "bpS} \
    else             {print $1" "$2" "$3" "$4" "MYOB}}}' $TMP_DIR/${breed}.uppd.tmp $TMP_DIR/${breed}.pedi.tmp) | awk '{printf "%-10s%-10s%-10s%-10s%-10s\n", $1,$2,$3,$4,$5}' > $TMP_DIR/${breed}.pedi.dat

	

echo "Final statictics"
wc -l $TMP_DIR/${breed}.pedi.dat


rm -f $TMP_DIR/${breed}.pedi.tmp
rm -f $TMP_DIR/${breed}.uppd.tmp


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
