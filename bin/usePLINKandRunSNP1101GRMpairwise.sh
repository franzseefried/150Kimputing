#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

#############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit
set -o nounset


####ACHTUNG: es gibt probleme wenn zu viele Tiere drin sind in higher/lower.animals.${breed}!!!!!!
# Kommandozeilenargumenten einlesen und pruefen
if test -z $1; then
  echo "FEHLER: Kein Argument erhalten. Diesem Shell-Script muss ein Rassenkuerzel mitgegeben werden! --> PROGRAMMABBRUCH"
  exit 1
fi
breed=$(echo $1 | awk '{print toupper($1)}')

if [ ${breed} != "BSW" ] && [ ${breed} != "HOL" ] && [ ${breed} != "VMS" ]; then
  echo "FEHLER: Diesem shell-Script wurde ein unbekanntes Rassenkuerzel uebergeben! (BSW / HOL / VMS sind zulaessig) --> PROGRAMMABBRUCH"
  exit 1
fi

startfile=$WORK_DIR/${breed}Typisierungsstatus${run}.txt
#ausschluss z.b. von JER Tiere im BSW System
if [ ${breed} == "BSW" ]; then
(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed})) |\
   awk '{if(($3+$4+$5) > 0.5) print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.MVcoreanimals.txt
fi
if [ ${breed} == "HOL" ]; then
(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed})) |\
   awk '{if(($3+$5) > 0.5) print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.MVcoreanimals.txt
fi
if [ ${breed} == "VMS" ]; then
(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed})) |\
   awk '{if(($3+$5) > 0.5) print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.MVcoreanimals.txt
fi
cp $TMP_DIR/${breed}.MVcoreanimals.txt $TMP_DIR/${breed}.VVcoreanimals.txt

#prep für GCTA, trennen nach Rasse und behalte nur LD-SNPs geregelt ueber callrate snp --geno 0.01
$BIN_DIR/awk_grepLDSNP $WORK_DIR/${breed}Typisierungsstatus${run}.txt <(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) | sed 's/ /\;/2') | tr ';' ' ' | awk '{print $2,$1,$3,$4,$5}'  > $TMP_DIR/obsianteil.${breed}.srt

#liste fuer die berechnung der allelfrequenzen
if [ ${breed} == "BSW" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($4 >= blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/lower.animals.${breed}
fi
if [ ${breed} == "HOL" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/lower.animals.${breed}
fi
if [ ${breed} == "VMS" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/lower.animals.${breed}
fi

#liste fuer die zuordnung der Tiere beim erstellen der GRM 
if [ ${breed} == "BSW" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($4 >= 0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.lower.animals.${breed}
fi
if [ ${breed} == "HOL" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($5 >= 0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.lower.animals.${breed}
fi
if [ ${breed} == "VMS" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($5 >= 0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.lower.animals.${breed}
fi


$FRG_DIR/plink --bfile $TMP_DIR/${breed}merged_ --cow --geno 0.01 --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --make-bed -out $TMP_DIR/${breed}.LDsnps.forSNP1101.LDsnp
$FRG_DIR/plink --bfile $TMP_DIR/${breed}.LDsnps.forSNP1101.LDsnp --cow --mind 0.5 --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $TMP_DIR/${breed}.LDsnps.forSNP1101


echo " "
echo "Baue Genotypenfile jetzt fuer ${1}"
(echo "ID Call..." ;
   sed 's/ /#/1' $TMP_DIR/${breed}.LDsnps.forSNP1101.raw | sed -n '2,$p' | sed 's/ /#/1' | sed 's/ /#/4' | cut -d'#' -f2,4 | sed 's/ //g' | sed 's/NA/5/g' | tr '#' ' ' | awk '{print $1,$2}') > $SMS_DIR/${breed}.SNP1101FImpute.geno
echo " "

echo "copy Pedfile von Fimpute"
cp $FIM_DIR/${breed}Fimpute.ped $SMS_DIR/${breed}.SNP1101FImpute.ped

echo " "
echo "make Mapfile"
(echo "SNPID Chr Pos";
awk '{if(NR == 1) print }' $TMP_DIR/${breed}.LDsnps.forSNP1101.raw | cut -d' ' -f7- | tr ' ' '\n' | cat -n | awk '{print $2,$1}' | sed 's/_B / /g' | sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 2.2 2.3' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo) | sort -T ${SRT_DIR} -t' ' -k2,2n | awk '{print $1,$3,$4}') > $SMS_DIR/${breed}.SNP1101FImpute.snplst



echo " "
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^run Allele frequency calculation for base population of ${breed}"
cd ${SMS_DIR}
cat $PAR_DIR/SNP1101_AFC.ctr | sed "s/WWWWWWWWWW/${breed}/g" > $SMS_DIR/${breed}.AFC.use
rm -rf $SMS_DIR/${breed}-AFC
mkdir -p $SMS_DIR/${breed}-AFC
$FRG_DIR/snp1101 $SMS_DIR/${breed}.AFC.use
echo " "
echo "remove header from allele frq file for ${breed}"
for i in lower higher; do
cp $SMS_DIR/${breed}-AFC/afreq_${i}.txt $SMS_DIR/${breed}-AFC/afreq_${i}.wiHeader
awk '{if(NR > 1) print}' $SMS_DIR/${breed}-AFC/afreq_${i}.wiHeader > $SMS_DIR/${breed}-AFC/afreq_${i}.txt
done
echo " "
cd $lokal
#block MV
awk '{ sub("\r$", ""); print }' $WORK_DIR/${breed}Typisierungsstatus${run}.txt |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 2.1 2.3' -1 1 -2 5 - <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
   sort -T ${SRT_DIR} -t' ' -k3,3 |\
   join -t' ' -o'1.1 1.2 2.2' -1 3 -2 1 -  <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
   sort -T ${SRT_DIR} -t' ' -k3,3 |\
   join -t' ' -o'1.1 1.2 2.5 1.3' -1 3 -2 1 -  <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 1.3 1.4' -1 1 -2 1 - $TMP_DIR/${breed}.MVcoreanimals.txt |\
   sort -T ${SRT_DIR} -t' ' -k3,3 > ${SMS_DIR}/${breed}.allTypi_TVDTier_mitTVDMUVA.txt
if test -s $SMS_DIR/${breed}.MVpairsInRows.toBechecked.out; then
  rm -f $SMS_DIR/${breed}.MVpairsInRows.toBechecked.out
fi
join -t' ' -o'1.1 1.2 1.3 1.4' -1 3 -2 1 <(sort -T ${SRT_DIR} -t' ' -k3,3 ${SMS_DIR}/${breed}.allTypi_TVDTier_mitTVDMUVA.txt) <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/${breed}Typisierungsstatus${run}.txt) |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
tee $SMS_DIR/${breed}.MVpairsInPairs.toBechecked | awk '{print $2,$4}' > $SMS_DIR/${breed}.MVpairsInRows.toBechecked

#block VV
awk '{ sub("\r$", ""); print }' $WORK_DIR/${breed}Typisierungsstatus${run}.txt |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 2.1 2.2' -1 1 -2 5 - <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
   sort -T ${SRT_DIR} -t' ' -k3,3 |\
   join -t' ' -o'1.1 1.2 2.2' -1 3 -2 1 -  <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
   sort -T ${SRT_DIR} -t' ' -k3,3 |\
   join -t' ' -o'1.1 1.2 2.5 1.3' -1 3 -2 1 -  <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 1.3 1.4' -1 1 -2 1 - $TMP_DIR/${breed}.VVcoreanimals.txt |\
   sort -T ${SRT_DIR} -t' ' -k3,3 > ${SMS_DIR}/${breed}.allTypi_TVDTier_mitTVDVAVA.txt
  if test -s $SMS_DIR/${breed}.VVpairsInRows.toBechecked.out; then
    rm -f $SMS_DIR/${breed}.VVpairsInRows.toBechecked.out
  fi
join -t' ' -o'1.1 1.2 1.3 1.4' -1 3 -2 1 <(sort -T ${SRT_DIR} -t' ' -k3,3 ${SMS_DIR}/${breed}.allTypi_TVDTier_mitTVDVAVA.txt) <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/${breed}Typisierungsstatus${run}.txt) |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
tee $SMS_DIR/${breed}.VVpairsInPairs.toBechecked | awk '{print $2,$4}' > $SMS_DIR/${breed}.VVpairsInRows.toBechecked


#reduktion auf tatsaechlich genotypisierte Tiere im Datensatz da oben mit dem Typistatus gearbeitet wurde
for gp in MV VV; do
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));G[$1]=substr($2,1,1);}} \
    else {sub("\015$","",$(NF));E=G[$1]; \
    if   (E != "") {print $0}}}' $SMS_DIR/${breed}.SNP1101FImpute.geno $SMS_DIR/${breed}.${gp}pairsInRows.toBechecked > $TMP_DIR/${breed}.${gp}pairsInRows.toBechecked
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));G[$1]=substr($2,1,1);}} \
    else {sub("\015$","",$(NF));E=G[$1]; \
    if   (E != "") {print $0}}}' $SMS_DIR/${breed}.SNP1101FImpute.geno $TMP_DIR/${breed}.${gp}pairsInRows.toBechecked > $SMS_DIR/${breed}.${gp}pairsInRows.toBechecked 
done


(cat $SMS_DIR/${breed}.MVpairsInRows.toBechecked ;
 cat $SMS_DIR/${breed}.VVpairsInRows.toBechecked ) > $SMS_DIR/${breed}.GPpairsInRows.toBechecked


cd ${SMS_DIR}
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^run pairwise GRM calculation for ${breed}"
cat $PAR_DIR/SNP1101_GRMpair.ctr | sed "s/WWWWWWWWWW/${breed}/g" > $SMS_DIR/${breed}.GRM.use
rm -rf $SMS_DIR/${breed}-GRM-pair
mkdir -p $SMS_DIR/${breed}-GRM-pair

$FRG_DIR/snp1101 $SMS_DIR/${breed}.GRM.use 2>&1 > $LOG_DIR/${breed}.GRM.SMP1101.log

echo "pairwise Relationship-coefficients are ready now:"
ls -trl $SMS_DIR/${breed}-GRM-pair/pair_rsh.txt

cd ${lokal}
echo " "
echo "write files like it was before for MV / VV separately"
#achtung $4 = Prelship $5 = Grelship in snp1101 outfile
cat $SMS_DIR/${breed}-GRM-pair/pair_rsh.txt | tr '\t' ' ' > $SMS_DIR/${breed}-GRM-pair/pair_rsh.tmp
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));G[$1]=$5;}} \
    else {sub("\015$","",$(NF));E=G[$1];F=G[$2]; \
    if   (E != "" && F != "") {print E,$1,F,$2,$4}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $SMS_DIR/${breed}-GRM-pair/pair_rsh.tmp > $SMS_DIR/${breed}-GRM-pair/pair_rsh.tvd
join -t' ' -o'1.1 1.2 1.3 1.4 1.5' -1 6 -2 5 <(awk '{print $1,$2,$3,$4,$5,$2"_"$4}' $SMS_DIR/${breed}-GRM-pair/pair_rsh.tvd | sort -T ${SRT_DIR} -t' ' -k6,6) <(awk '{print $1,$2,$3,$4,$2"_"$4}' ${SMS_DIR}/${breed}.allTypi_TVDTier_mitTVDVAVA.txt | sort -T ${SRT_DIR} -t' ' -k5,5) > ${RES_DIR}/${breed}.out.AnimalVV.snp1101.${run}.txt
join -t' ' -o'1.1 1.2 1.3 1.4 1.5' -1 6 -2 5 <(awk '{print $1,$2,$3,$4,$5,$2"_"$4}' $SMS_DIR/${breed}-GRM-pair/pair_rsh.tvd | sort -T ${SRT_DIR} -t' ' -k6,6) <(awk '{print $1,$2,$3,$4,$2"_"$4}' ${SMS_DIR}/${breed}.allTypi_TVDTier_mitTVDMUVA.txt | sort -T ${SRT_DIR} -t' ' -k5,5) > ${RES_DIR}/${breed}.out.AnimalMV.snp1101.${run}.txt

rm -f $TMP_DIR/${breed}.MVcoreanimals.txt
rm -f $TMP_DIR/${breed}.VVcoreanimals.txt
rm -f $TMP_DIR/obsianteil.${breed}.srt
rm -f $SMS_DIR/lower.animals.${breed}
rm -f $SMS_DIR/higher.animals.${breed}
rm -f $SMS_DIR/grm.lower.animals.${breed}
rm -f $SMS_DIR/grm.higher.animals.${breed}
rm -f $SMS_DIR/${breed}.SNP1101FImpute.geno
rm -f $SMS_DIR/${breed}.SNP1101FImpute.snplst

echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
