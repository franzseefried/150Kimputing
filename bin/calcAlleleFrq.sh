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
elif [ ${1} == "BSW" ]; then
	echo $1 > /dev/null
elif [ ${1} == "HOL" ]; then
	echo $1 > /dev/null
elif [ ${1} == "VMS" ]; then
        echo $1 > /dev/null
else
	echo " $1 != BSW / HOL / VMS, ich stoppe"
	exit 1
fi
breed=${1}
set -o nounset

#Zielmap enthaelt schon nur noch die LD-SNP die auch auf dem HD chip drauf sind
#Programm schreibt neue Map für sas Imputing, d.h. die map aus writeNewAimMap.sh wird hier uerberschrieben
#2 Chips hier
#######Funktionsdefinition
getColmnNrSemicl () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}
##########################

#get Info about SNP from Reftab
getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS} ; colITGX=$colNr_
getColmnNrSemicl QuagCode ${REFTAB_CHIPS} ; colQUG=$colNr_
#echo $colITGX $colQUG
ncONE=$(awk -v cc=${colQUG} -v dd=${colITGX} -v nc=${NewChip1} 'BEGIN{FS=";"}{if( $dd == nc ) print $cc }' ${REFTAB_CHIPS})
ncTWO=$(awk -v cc=${colQUG} -v dd=${colITGX} -v nc=${NewChip2} 'BEGIN{FS=";"}{if( $dd == nc ) print $cc }' ${REFTAB_CHIPS})


#Use intergenomics codes here!! > now in parameterfile
#ncONE=150KV1
#ncTWO=47KV1


#lese chip binary files und nicht das gemergte, da fuer doe allelfrq der chip und nicht die density entscheidend sind


echo "allelfrequenzen berechnen ausgehend von den tailpopulations"

#prep für GCTA, trennen nach Rasse und behalte nur LD-SNPs geregelt ueber callrate snp --geno 0.01
$BIN_DIR/awk_grepLDSNP $WORK_DIR/${breed}Typisierungsstatus${run}.txt <(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) | sed 's/ /\;/2') | tr ';' ' ' | awk '{print $2,$1,$3,$4,$5}'  > $TMP_DIR/obsianteil.${breed}.srt


#liste fuer die berechnung der allelfrequenzen
if [ ${breed} == "BSW" ]; then
   awk -v blood=${blutanteilsgrenze} '{if($3 >= blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/higher.animals.${breed}
   awk -v blood=${blutanteilsgrenze} '{if($4 >= blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/lower.animals.${breed}
fi
if [ ${breed} == "HOL" ]; then
   awk -v blood=${blutanteilsgrenze} '{if($3 >= blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/higher.animals.${breed}
   awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/lower.animals.${breed}
fi
if [ ${breed} == "VMS" ]; then
   awk -v blood=${blutanteilsgrenze} '{if($3 >= blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/higher.animals.${breed}
   awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/lower.animals.${breed}
fi
   
wc -l $TMP_DIR/higher.animals.${breed}
wc -l $TMP_DIR/lower.animals.${breed}   
echo " "

for chip in ${ncONE} ${ncTWO} ; do
   #reduktion auf SNPs im fixes Imputing System
   awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));GZW[$1]=$2;}} \
    else {sub("\015$","",$(NF));EBV=GZW[$2]; \
    if   (EBV != "") {print $2}}}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt $WORK_DIR/${breed}.${chip}.map > $TMP_DIR/${breed}.${chip}.keep
   $FRG_DIR/plink --bfile $BCP_DIR/${run}/binaryfiles/${breed}.${chip} --missing-genotype '0' --cow --nonfounders --noweb --extract $TMP_DIR/${breed}.${chip}.keep --make-bed --out $TMP_DIR/${breed}.${chip}.fuerALLELEFREQ1
   for aniset in higher lower; do
      $FRG_DIR/plink --bfile $TMP_DIR/${breed}.${chip}.fuerALLELEFREQ1 --missing-genotype '0' --cow --nonfounders --noweb --keep $TMP_DIR/${aniset}.animals.${breed} --freq --out $TMP_DIR/${breed}.${chip}.${aniset}.fuerALLELEFREQ2
   done
   wc -l $TMP_DIR/${breed}.${chip}.${aniset}.fuerALLELEFREQ2.frq 
done




#add snps that are in the system but which are , delete den chip1 von oben
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ${IMPUTATIONFLAG} | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} 'BEGIN{FS=";"}{if( $cc == "HD" ) print $dd }' ${REFTAB_CHIPS} | sed "s/${ncONE}//g")
lgtC=$(echo ${CHIPS} | wc -w | awk '{print $1}')
if [ ${lgtC} -eq 0 ]; then
  echo "keie Chips angegeben in ${REFTAB_CHIPS} in Kolonne ${IMPUTATIONFLAG} "
  exit 1
fi
echo $CHIPS
for chip in ${CHIPS}; do
#reduktion auf SNPs im fixes Imputing System
   if [ -s $BCP_DIR/${run}/binaryfiles/${breed}.${chip}.bed ];then
   awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));GZW[$1]=$2;}} \
    else {sub("\015$","",$(NF));EBV=GZW[$2]; \
    if   (EBV != "") {print $2}}}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt $WORK_DIR/${breed}.${chip}.map > $TMP_DIR/${breed}.${chip}.keep
   $FRG_DIR/plink --bfile $BCP_DIR/${run}/binaryfiles/${breed}.${chip} --missing-genotype '0' --cow --nonfounders --noweb --extract $TMP_DIR/${breed}.${chip}.keep --make-bed --out $TMP_DIR/${breed}.${chip}.fuerALLELEFREQ1
   for aniset in higher lower; do
      $FRG_DIR/plink --bfile $TMP_DIR/${breed}.${chip}.fuerALLELEFREQ1 --missing-genotype '0' --cow --nonfounders --noweb --keep $TMP_DIR/${aniset}.animals.${breed} --freq --out $TMP_DIR/${breed}.${chip}.${aniset}.fuerALLELEFREQ2
   #copy to HIS_DIR if MAF threshold is used in Gensel
   #cp  $TMP_DIR/${breed}.${chip}.${aniset}.fuerALLELEFREQ2.frq ${HIS_DIR}/${breed}.${chip}.${aniset}.${run}.fuerALLELEFREQ2.frq
   done
   fi
done
#anhaengen an das ncONE allelefrq file
n1=$(wc -l $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt |awk '{print $1}')
n2=$(join -t' ' -o'1.1' -v1 -1 1 -2 2 <(awk '{if(NR > 1) print $1,$2}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt |sort -t' ' -k1,1)  <(sort -t' ' -k2,2 $WORK_DIR/${breed}.${ncONE}.map) | wc -l | awk '{print $1}' )
echo $n1 $n2
#nur wenn es noetig ist
if [ ${n2} -gt 0 ]; then
   for i in $(join -t' ' -o'1.1' -v1 -1 1 -2 2 <(awk '{if(NR > 1) print $1,$2}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt |sort -t' ' -k1,1)  <(sort -t' ' -k2,2 $WORK_DIR/${breed}.${ncONE}.map));do
   echo $i
      for aniset in higher lower; do
         for chip in ${CHIPS} ;do
            if [ -s $TMP_DIR/${breed}.${chip}.${aniset}.fuerALLELEFREQ2.frq ]; then
              awk -v j=${i} '{if($2 == j) print }' $TMP_DIR/${breed}.${chip}.${aniset}.fuerALLELEFREQ2.frq | sort -k6,6nr | head -1 |awk -v h=${aniset} -v g=${chip} '{printf "%+4s%+40s%+5s%+5s%+13s%+9s\n", $1,$2,$3,$4,$5,$6}' >> $TMP_DIR/${breed}.${ncONE}.${aniset}.fuerALLELEFREQ2.frq 
            fi
         done
      done
   done
fi




#copy to HIS_DIR if MAF threshold is used in Gensel
for aniset in higher lower; do
  wc -l $TMP_DIR/${breed}.${ncONE}.${aniset}.fuerALLELEFREQ2.frq 
  cp  $TMP_DIR/${breed}.${ncONE}.${aniset}.fuerALLELEFREQ2.frq ${HIS_DIR}/${breed}.${ncONE}.${aniset}.${run}.fuerALLELEFREQ2.frq
done




echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW Ende ${SCRIPT}
