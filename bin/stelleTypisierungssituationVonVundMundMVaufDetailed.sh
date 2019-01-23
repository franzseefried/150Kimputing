#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT} 
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit



if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS "
    exit 1
else 
set -o nounset
    breed=${1}
if [ ${1} == "BSW" ]; then
        zofol=$(echo "bvch")
        natpedi=${PEDI_DIR}/work/bv/${DatPEDIbvch}_pedigree_rrtdm_BVJE.dat
fi
if [ ${1} == "HOL" ]; then
        zofol=$(echo "shb")
        natpedi=${PED_DIR}/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat
fi
if [ ${1} == "VMS" ]; then
    zofol=$(echo "vms")
        natpedi=${PED_DIR}/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat
fi
echo "Typisierungsstuation wird ermittelt"
for dicht in LD HD; do
  colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ImputationDensityLD150K | awk '{print $1}')
  colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
  CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v densit=${dicht} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})


  for chip in ${CHIPS} ; do
    cd $SNP_DIR/dataWide${chip}/${zofol}
    linkarray=$(find -maxdepth 1 -type l -exec basename {} \;)
    echo ${linkarray} | grep "[0-9]" |  sed "s/\.lnk/\.${chip}/g" | tr ' ' '\n' 
  done | sort -T ${SRT_DIR} -u | tr '.' ' '
done > $TMP_DIR/${breed}.startanimallst.chips
lastani=0
sort -t' ' -k1,1 -k2,2nr $TMP_DIR/${breed}.startanimallst.chips |\
 while IFS=" "; read a h; do
      if [ ${lastani} != ${a} ]; then
         echo $a $h
      fi
   lastani=${a}
done | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.startanimallst.chips.max




    echo "Mache Uebericht fuer Rasse ${breed}"
#Aufbau von ani sire dam pgs pgd mgs mgd gpgs gpgd ITB TVD idanimal ITB19 breed
#pgs
cp $WRK_DIR/Run${run}.alleIDS_${breed}.txt $WRK_DIR/Run${run}.alleIDS_${breed}.txt2
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$2;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$2]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $WRK_DIR/Run${run}.alleIDS_${breed}.txt2 > $TMP_DIR/Run${run}.alleIDS_${breed}.txt
rm -f $WRK_DIR/Run${run}.alleIDS_${breed}.txt2
#pgd
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$3;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$2]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $TMP_DIR/Run${run}.alleIDS_${breed}.txt > $TMP_DIR/Run${run}.alleIDS_${breed}.txt2
mv $TMP_DIR/Run${run}.alleIDS_${breed}.txt2 $TMP_DIR/Run${run}.alleIDS_${breed}.txt
#ms
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$2;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$3]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $TMP_DIR/Run${run}.alleIDS_${breed}.txt > $TMP_DIR/Run${run}.alleIDS_${breed}.txt2
mv $TMP_DIR/Run${run}.alleIDS_${breed}.txt2 $TMP_DIR/Run${run}.alleIDS_${breed}.txt
#mgd
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$3;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$3]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $TMP_DIR/Run${run}.alleIDS_${breed}.txt > $TMP_DIR/Run${run}.alleIDS_${breed}.txt2
mv $TMP_DIR/Run${run}.alleIDS_${breed}.txt2 $TMP_DIR/Run${run}.alleIDS_${breed}.txt
#pggs
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$2;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$9]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $TMP_DIR/Run${run}.alleIDS_${breed}.txt > $TMP_DIR/Run${run}.alleIDS_${breed}.txt2
mv $TMP_DIR/Run${run}.alleIDS_${breed}.txt2 $TMP_DIR/Run${run}.alleIDS_${breed}.txt
#mggs
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$2;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$11]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $TMP_DIR/Run${run}.alleIDS_${breed}.txt > $TMP_DIR/Run${run}.alleIDS_${breed}.txt2
mv $TMP_DIR/Run${run}.alleIDS_${breed}.txt2 $TMP_DIR/Run${run}.alleIDS_${breed}.txt

#umformatieren
awk '{print $1,$2,$3,$9,$10,$11,$12,$13,$14,$4,$5,$6,$7,$8}' $TMP_DIR/Run${run}.alleIDS_${breed}.txt > $TMP_DIR/Run${run}.alleIDS_${breed}.txt2
mv $TMP_DIR/Run${run}.alleIDS_${breed}.txt2 $TMP_DIR/Run${run}.alleIDS_${breed}.txt



#maxchip
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$2;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$12]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $TMP_DIR/${breed}.startanimallst.chips.max $TMP_DIR/Run${run}.alleIDS_${breed}.txt > $TMP_DIR/Run${run}.${breed}.chipmax
#Vaterchip
cp $TMP_DIR/Run${run}.${breed}.chipmax $TMP_DIR/Run${run}.${breed}.chipmax3
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$15;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$2]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $TMP_DIR/Run${run}.${breed}.chipmax $TMP_DIR/Run${run}.${breed}.chipmax3 > $TMP_DIR/Run${run}.${breed}.chipmax2
mv $TMP_DIR/Run${run}.${breed}.chipmax2 $TMP_DIR/Run${run}.${breed}.chipmax3
#damchip
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$15;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$3]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $TMP_DIR/Run${run}.${breed}.chipmax $TMP_DIR/Run${run}.${breed}.chipmax3 > $TMP_DIR/Run${run}.${breed}.chipmax2
mv $TMP_DIR/Run${run}.${breed}.chipmax2 $TMP_DIR/Run${run}.${breed}.chipmax3 
#pgschip
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$15;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$4]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $TMP_DIR/Run${run}.${breed}.chipmax $TMP_DIR/Run${run}.${breed}.chipmax3 > $TMP_DIR/Run${run}.${breed}.chipmax2
mv $TMP_DIR/Run${run}.${breed}.chipmax2 $TMP_DIR/Run${run}.${breed}.chipmax3
#pgdchip
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$15;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$5]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $TMP_DIR/Run${run}.${breed}.chipmax $TMP_DIR/Run${run}.${breed}.chipmax3 > $TMP_DIR/Run${run}.${breed}.chipmax2
mv $TMP_DIR/Run${run}.${breed}.chipmax2 $TMP_DIR/Run${run}.${breed}.chipmax3
#mgschip
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$15;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$6]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $TMP_DIR/Run${run}.${breed}.chipmax $TMP_DIR/Run${run}.${breed}.chipmax3 > $TMP_DIR/Run${run}.${breed}.chipmax2
mv $TMP_DIR/Run${run}.${breed}.chipmax2 $TMP_DIR/Run${run}.${breed}.chipmax3
#mgdchip
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$15;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$7]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $TMP_DIR/Run${run}.${breed}.chipmax $TMP_DIR/Run${run}.${breed}.chipmax3 > $TMP_DIR/Run${run}.${breed}.chipmax2
mv $TMP_DIR/Run${run}.${breed}.chipmax2 $TMP_DIR/Run${run}.${breed}.chipmax3
#gpgdchip
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$15;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$8]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $TMP_DIR/Run${run}.${breed}.chipmax $TMP_DIR/Run${run}.${breed}.chipmax3 > $TMP_DIR/Run${run}.${breed}.chipmax2
mv $TMP_DIR/Run${run}.${breed}.chipmax2 $TMP_DIR/Run${run}.${breed}.chipmax3
#gmgsdamchip
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));cid[$1]=$15;}} \
    else {sub("\015$","",$(NF));STAT="0";idd=cid[$9]; \
    if   (idd != "") {print $0,idd} \
    else             {print $0,"-"}}}' $TMP_DIR/Run${run}.${breed}.chipmax $TMP_DIR/Run${run}.${breed}.chipmax3 > $TMP_DIR/Run${run}.${breed}.chipmax2
mv $TMP_DIR/Run${run}.${breed}.chipmax2 $TMP_DIR/Run${run}.${breed}.chipmax3
mv $TMP_DIR/Run${run}.${breed}.chipmax3 $RES_DIR/${breed}TypiSituationDetail_${run}.txt

echo "#write summary only on sires"
(echo "n Breed ChipTier ChipV ChipPGS ChipMGS ChipGPGS chipGMGS"
	cut -d' ' -f14,15,16,18,20,22,23 $RES_DIR/${breed}TypiSituationDetail_${run}.txt | sort -T ${SRT_DIR} | uniq -c | awk '{if($3 != "-")print $1,$2,$3,$4,$5,$6,$7,$8}' | grep -v "\- \- \- \- \- \-"| sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1nr )| awk '{printf "%+10s%+10s%+10s%+10s%+10s%+10s%+10s%+10s\n", $1,$2,$3,$4,$5,$6,$7,$8}' 
(echo "n Breed ChipTier ChipV ChipPGS ChipMGS ChipGPGS chipGMGS"
        cut -d' ' -f14,15,16,18,20,22,23 $RES_DIR/${breed}TypiSituationDetail_${run}.txt | sort -T ${SRT_DIR} | uniq -c | awk '{if($3 != "-")print $1,$2,$3,$4,$5,$6,$7,$8}' | grep -v "\- \- \- \- \- \-"| sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1nr ) | tr ' ' ';' > $RES_DIR/${breed}_ChipStatus.SiresummaryDetail${run}.csv
echo " "
echo " "

echo "write summary complete"
(echo "n Breed ChipTier ChipV ChipM ChipPGS ChipPGD ChipMGS ChipMGD ChipGPGS chipGMGS"
        cut -d' ' -f14- $RES_DIR/${breed}TypiSituationDetail_${run}.txt | sort -T ${SRT_DIR} | uniq -c | awk '{if($3 != "-")print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}'  | grep -v "\- \- \- \- \- \- \- \- \-"| sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1nr )| awk '{printf "%+10s%+10s%+10s%+10s%+10s%+10s%+10s%+10s%+10s%+10s%+10s\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}'
(echo "n Breed ChipTier ChipV ChipM ChipPGS ChipPGD ChipMGS ChipMGD ChipGPGS chipGMGS"
        cut -d' ' -f14- $RES_DIR/${breed}TypiSituationDetail_${run}.txt | sort -T ${SRT_DIR} | uniq -c | awk '{if($3 != "-")print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}' | grep -v "\- \- \- \- \- \- \- \- \-" | sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1nr )| tr ' ' ';'  > $RES_DIR/${breed}_ChipStatus.CompleteSummaryDetail${run}.csv



rm -f $TMP_DIR/${breed}.startanimallst.chips
rm -f $TMP_DIR/Run${run}.${breed}.chipmax
rm -f $TMP_DIR/Run${run}.alleIDS_${breed}.txt
fi





echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

