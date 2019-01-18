#!/bin/bash
RIGHT_NOW=$(date)
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
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
else
breed=${1}
BTA=wholeGenome
##################################################

head -1 $WORK_DIR/${breed}FIFTYK_routine_BTAwholeGenome.raw | cut -d' ' -f7- | tr ' ' '\n' | cat -n | awk '{print $2,$1}' | sed 's/_B / /g' > $TMP_DIR/${breed}.FIFTYK.map.lst
head -1 $WORK_DIR/${breed}LD_routine_BTAwholeGenome.raw | cut -d' ' -f7- | tr ' ' '\n' | cat -n | awk '{print $2,$1}' | sed 's/_B / /g' > $TMP_DIR/${breed}.LD.map.lst

join -t' ' -o'1.1 1.2 2.2' -e'#' -a1 -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.FIFTYK.map.lst) <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.LD.map.lst) | awk '{if($3 == "#") print $1,$2,"0"; else print $1,$2,$3}' > $TMP_DIR/${breed}.fimpute.tmp.map.lst

awk '{print $1" "$2" "$3" "$4 }' $WORK_DIR/${breed}merged_.map | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}merged.sortedmap
(echo "SNP_ID Chr Pos Chip1 Chip2" ;
join -t' ' -o'1.1 2.1 2.4 1.2 1.3' -1 1 -2 2 <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.fimpute.tmp.map.lst ) $TMP_DIR/${breed}merged.sortedmap |\
   sort -T ${SRT_DIR} -t' ' -k4,4n) > $FIM_DIR/${breed}BTA${BTA}_FImpute.snpinfo
wc -l ${FIM_DIR}/${breed}BTA${BTA}_FImpute.snpinfo
rm -f $WORK_DIR/${breed}FIFTYK_routine_BTAwholeGenome.raw
rm -f $WORK_DIR/${breed}LD_routine_BTAwholeGenome.raw
#check if snpstrat=F with oldmap
sed "s/ \{1,\}/ /g" ${HIS_DIR}/${breed}.RUN${fixSNPdatum}snp_info.txt | sed -n '2,$p' > $TMP_DIR/${breed}.${oldrun}.mapfilecheck
cat $FIM_DIR/${breed}BTAwholeGenome_FImpute.snpinfo | sed -n '2,$p' > $TMP_DIR/${breed}.${run}.mapfilecheck
if false; then
if [ ${snpstrat} == "F" ]; then
mc=$(diff -q $TMP_DIR/${breed}.${run}.mapfilecheck $TMP_DIR/${breed}.${oldrun}.mapfilecheck | sed 's/ //g' )
if [ ! -z ${mc} ]; then
  echo " "
  echo "...ooops you have choosen fixed SNPstratagey but current SNPfiles differs with previous one"
  echo " please check, I have to stop due to serious data problems"
  echo " "
  exit 1
fi
fi
fi
rm -f $TMP_DIR/${breed}.FIFTYK.map.lst
rm -f $TMP_DIR/${breed}.LD.map.lst
rm -f $TMP_DIR/${breed}.fimpute.tmp.map.lst
rm -f $TMP_DIR/${breed}merged.sortedmap
rm -f $TMP_DIR/${breed}.${oldrun}.mapfilecheck
rm -f $TMP_DIR/${breed}.${run}.mapfilecheck

fi
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
