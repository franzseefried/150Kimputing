#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


#run one anial against all genotyped animals to search closest SNP-relatives
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

(echo $RIGHT_NOW Start ${SCRIPT};
echo " ";
echo "#BlockA #A find samples with changes in Pedigree checks for ${breed}"
join -t';' -1 2 -2 2 -o'1.2 1.1 1.3 1.4 1.5 1.6 1.7 1.8 1.9 1.10 1.11 2.4 2.5 2.6 2.7 2.8 2.9 2.10 2.11' <(awk 'BEGIN{FS=";";OFS=";"}{print $1,$2,$3,$8,$9,$10,$11,$12,$13,$14,$15}' ${HIS_DIR}/${breed}_SumUpLOG.${oldrun}.csv | sort -T ${SRT_DIR} -t';' -k2,2) <(awk 'BEGIN{FS=";";OFS=";"}{print $1,$2,$3,$8,$9,$10,$11,$12,$13,$14,$15}' ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv |sort -T ${SRT_DIR} -t';' -k2,2) | awk 'BEGIN{FS=";"}{if($4 != $12 || $5 != $13 || $6 != $14 || $7 != $15 || $8 != $16 || $9 != $17 || $10 != $18 || $11 != $19) print}' | sed 's/\;/ /3' | sed 's/\;/ /10'  | awk '{print "#A",$1,$2,$3,$4}'
echo " ";
echo " ";
echo "#BlockB #B find samples with changes in SNPrelationships ${breed}"
join -t';' -o'1.2 1.1 1.3 1.4 1.5 1.6 1.7 1.20 1.21 1.23 2.20 2.21 2.23 1.11' -1 2 -2 2 <(awk '{if(NR >= 1) print}' ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv | sort -T ${SRT_DIR} -t';' -k2,2 ) <(awk '{if(NR >= 1) print}' ${HIS_DIR}/${breed}_SumUpLOG.${oldrun}.csv | sort -T ${SRT_DIR} -t';' -k2,2) | awk 'BEGIN{FS=";";OFS=";"}{if($14 != NULL) print}' | awk 'BEGIN{FS=";"}{if(($8 != $11) || ($9 != $12) ) print "#B",$0}'
echo " ";
echo " ";
echo "#BlockC #C find samples that lost their imputation result ${breed}"
join -t' ' -1 1 -2 1 -v1 -o'1.1 1.2' -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 ${HIS_DIR}/${breed}.RUN${oldrun}.IMPresult.tierlis) <(sort -T ${SRT_DIR} -t' ' -k1,1 ${HIS_DIR}/${breed}.RUN${run}.IMPresult.tierlis) | awk '{print "#C",$0}'
echo " ";
echo " ";
echo "#BlockD #D find samples that have been SNPdensity-downgraded in their imputation result ${breed}"
join -t' ' -1 1 -2 1 -o'1.1 1.2 2.2' -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 ${HIS_DIR}/${breed}.RUN${oldrun}.IMPresult.tierlis) <(sort -T ${SRT_DIR} -t' ' -k1,1 ${HIS_DIR}/${breed}.RUN${run}.IMPresult.tierlis) | awk '{if(($2 == 1 && $3 == 2) || ($2 == 2 && $3 == 0)) print "#D",$0}'
echo " ";
echo " ";
echo "#BlockE #E find samples with changes in their pedigrees SNPdensity ${breed}"
join -t';' -o'1.2 1.1 1.3 1.4 1.5 1.6 1.7 2.4 2.5 2.6 2.7' -1 2 -2 2 <(awk 'BEGIN{FS=";";OFS=";"}{print $1,$2,$3,$16,$17,$18,$19}' ${HIS_DIR}/${breed}_SumUpLOG.${oldrun}.csv | sort -T ${SRT_DIR} -t';' -k2,2) <(awk 'BEGIN{FS=";";OFS=";"}{print $1,$2,$3,$16,$17,$18,$19}' ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv | sort -T ${SRT_DIR} -t';' -k2,2 ) | awk 'BEGIN{FS=";"}{if($4 != $8 || $5 != $9 || $6 != $10 || $7 != $11) print}' | sed 's/\;/ /3' | sed 's/\;/ /6'  | awk '{print "#E",$1,$2,$3,$4}' | grep -v " ;;; "
echo " ";
echo " ";
echo "#BlockF #F find historic samples which have now genotyped parents in the dataset ${breed} while historic samples are suspicious againt newly genotyped parents"
join -t';' -o'1.2 1.1 1.3 1.4 1.5 1.6 1.7 2.4 2.5 2.6 2.7' -1 2 -2 2 <(awk 'BEGIN{FS=";";OFS=";"}{print $1,$2,$3,$16,$17,$18,$19}' ${HIS_DIR}/${breed}_SumUpLOG.${oldrun}.csv | sort -T ${SRT_DIR} -t';' -k2,2) <(awk 'BEGIN{FS=";";OFS=";"}{print $1,$2,$3,$16,$17,$18,$19}' ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv | sort -T ${SRT_DIR} -t';' -k2,2 ) | awk 'BEGIN{FS=";"}{if(($9 != "" && $9 != "-" && $5 == "-" &&  $5 != $9) || ($10 != "" && $10 != "-" && $6 == "-" && $6 != $10)) print $1}' > $TMP_DIR/${breed}.samplesWiGPar
awk 'BEGIN{FS=";";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));NP[$1]=$1}} \
    else {sub("\015$","",$(NF));ECD="0";ECD=NP[$2]; \
    if (ECD != "") {print "#F",$0}}}' $TMP_DIR/${breed}.samplesWiGPar ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv | awk 'BEGIN{FS=";"}{if($9 != "" || $10 != "" || $11 != "" || $12 != "" || $13 != "" || $14 != "" || $15 != "" || $16 != "") print}' | sed 's/\;/ /g'
echo " ";
echo " ";
echo "#BlockG #G find newly added samples which fit based on SNPs as parent to samples that have been genotypes in the past while pedigree would not expect parent - offspring relationship"
join -t' ' -o'2.1' -1 1 -2 5 <(sort -T ${SRT_DIR} -t' ' -k1,1 $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WRK_DIR/Run${run}.alleIDS_${breed}.txt ) > $TMP_DIR/${breed}.samplesNGPlook
#hole pedigree-nachkommen des neuen tieres
#Vater:
(join -t' ' -o'2.5' -1 1 -2 2 <(sort $TMP_DIR/${breed}.samplesNGPlook ) <(sort -T ${SRT_DIR} -t' ' -k2,2 $WRK_DIR/Run${run}.alleIDS_${breed}.txt )
#Mutter:
join -t' ' -o'2.5' -1 1 -2 3 <(sort $TMP_DIR/${breed}.samplesNGPlook ) <(sort -T ${SRT_DIR} -t' ' -k3,3 $WRK_DIR/Run${run}.alleIDS_${breed}.txt )) | sort -T ${SRT_DIR} -u > $TMP_DIR/${breed}.samplesNGPlook.pedigreeOffspring
#suche wo neues Tier als SNPVater / Mutter in Frage kommt Col 13 || Col 15 -> && unter ausschluss der NK des neuen Tieres
sed 's/ /\;/g' $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt > $TMP_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt
awk 'BEGIN{FS=";";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));NP[$1]=$1}} \
    if(FILENAME==ARGV[2]){if(NR>0){sub("\015$","",$(NF));OP[$1]=$1}} \
    else {sub("\015$","",$(NF));ECS=NP[$13];ECD=NP[$15]; OCD=OP[$2];\
    if ((ECS != "" || ECD != "") && $12 != 0 && $14 != 0 && OCD == "") {print "#G",$0}}}' $TMP_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt $TMP_DIR/${breed}.samplesNGPlook.pedigreeOffspring ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv
echo "NOTE: ^^^^^^^You should report this information to the corresponding breeding organisation since SNP-order of the offspring sample has been closed during a previous run"
echo " ";
echo " ";
#echo "#BlockH #H find newly added samples which have suspicous high / low SNP-relationships against samples that have been genotypes in the past"
#echo "This option is ot ready yet. I'm sorry."
#to do: suche nach proben die SNP-basiert um mehr als z.b. 0.2 im SNP-relship coefficient abweichen. Idee zeilenweise G und A einlesen und nach Elementen suchen die </> 0.2 abweichen
#echo " ";
#echo " ";	
RIGHT_NOW=$(date );
echo $RIGHT_NOW Ende ${SCRIPT};
echo " ") > $LOG_DIR/${breed}.SumUpComparison.log
echo " ";
echo " ";

echo "ATTENTION: .... check files with comparison against last run: $LOG_DIR/${breed}.SumUpComparison.log"
echo " ";
echo " ";
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
