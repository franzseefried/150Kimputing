#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit
if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
elif [ ${1} == "BSW" ]; then
        echo $1 > /dev/null
elif [ ${1} == "HOL" ]; then
        echo $1 > /dev/null
elif [ ${1} == "VMS" ]; then
        echo $1 > /dev/null
else
        echo " $1 != HOL BSW oder VMS, ich stoppe"
        exit 1
fi
breed=${1}


(echo "run n sex chip" ;
for i in $(ls $WRK_DIR/${breed}Typisierungsstatus*); do
ilename=$(basename ${i})
runStamp=$(echo $ilename | cut -d'.' -f1 | cut -d'K' -f2)
#echo $ilename $runStamp
join -t' ' -o'2.3 1.2' -1 1 -2 2 <(sort -T ${SRT_DIR} -t' ' -k1,1 ${i}) <(awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1-3 | sed 's/ //g' | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2)|\
awk '{print substr($1,7,1),$2}'|sort | uniq -c | awk -v g=${runStamp} '{print substr(g,1,2),substr(g,3,2),$1,$2,$3}'
done | awk '{if($1 != 77) print $1+0,$2,$3,$4,$5}' | sort -T ${SRT_DIR} -t' ' -k2,2n -k1,1n -k5,5 -k4,4 | sed 's/ //1' ) > $TMP_DIR/snp.trend.${breed}

cat $BIN_DIR/barplotSNPtrend.R | sed "s/XXXXXXXXXX/${breed}/g" > $TMP_DIR/bplt.${breed}.R
chmod 777 $TMP_DIR/bplt.${breed}.R
Rscript $TMP_DIR/bplt.${breed}.R


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
