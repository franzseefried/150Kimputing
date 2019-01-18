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
getColmnNrSemicl QuagCode ${REFTAB_CHIPS} ; colQUG=$colNr__
#echo $colITGX $colQUG
ncONE=$(awk -v cc=${colQUG} -v dd=${colITGX} -v nc=${NewChip1} 'BEGIN{FS=";"}{if( $dd == nc ) print $cc }' ${REFTAB_CHIPS})
ncTWO=$(awk -v cc=${colQUG} -v dd=${colITGX} -v nc=${NewChip2} 'BEGIN{FS=";"}{if( $dd == nc ) print $cc }' ${REFTAB_CHIPS})


#Use intergenomics codes here!! > now in parameterfile
#ncONE=150KV1
#ncTWO=47KV1


#lese chip binary files und nicht das gemergte, da fuer doe allelfrq der chip und nicht die density entscheidend sind


echo "allelfrequenzen berechnen ausgehend von den tailpopulations"

#prep für GCTA, trennen nach Rasse und behalte nur LD-SNPs geregelt ueber callrate snp --geno 0.01
$BIN_DIR/awk_grepLDSNP $WORK_DIR/${breed}Typisierungsstatus${run}.txt <(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) | sed 's/ /\;/2') | tr ';' ' ' | awk '{print $2,$1,$3,$4,$5}'  > $TMP_DIR/obsianteil.${breed}.srt

#liste fuer die berechnung der allelfrequenzen
if [ ${breed} == "BSW" ]; then
   awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/higher.animals.${breed}
   awk -v blood=${blutanteilsgrenze} '{if($4 >= blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/lower.animals.${breed}
fi
if [ ${breed} == "HOL" ]; then
   awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/higher.animals.${breed}
   awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/lower.animals.${breed}
fi
if [ ${breed} == "VMS" ]; then
   awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/higher.animals.${breed}
   awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print "1",$1}' $TMP_DIR/obsianteil.${breed}.srt > $TMP_DIR/lower.animals.${breed}
fi
   
wc -l $TMP_DIR/higher.animals.${breed}
wc -l $TMP_DIR/lower.animals.${breed}   


for chip in ${ncONE} ${ncTWO} ; do
   #reduktion auf gut gecallte Tiere, darf eigentlich keine grosse rolle spielen: --geno _> per variant / --mind _> per sample
   $FRG_DIR/plink --bfile $TMP_DIR/${breed}.${chip} --missing-genotype '0' --cow --nonfounders --noweb --mind 0.05 --geno 0.01 --make-bed --out $TMP_DIR/${breed}.${chip}.fuerALLELEFREQ1
   for aniset in higher lower; do
      $FRG_DIR/plink --bfile $TMP_DIR/${breed}.${chip}.fuerALLELEFREQ1 --missing-genotype '0' --cow --nonfounders --noweb --keep $TMP_DIR/${aniset}.animals.${breed} --freq --out $TMP_DIR/${breed}.${chip}.${aniset}.fuerALLELEFREQ2
   done
   #inkl. reduce to autosomal snps: ueberschreiben der SNPmap im HIS_DIR, vorher wurde eine neue overallmap erstellt
   #to do regionen besser abdecken von mirjam???
   (awk '{if($5 > 0.009)print $2}' $TMP_DIR/${breed}.${chip}.higher.fuerALLELEFREQ2.frq ;
    awk '{if($5 > 0.009)print $2}' $TMP_DIR/${breed}.${chip}.lower.fuerALLELEFREQ2.frq ;) | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -u | awk '{print $1,$1}' > $WORK_DIR/${breed}.${chip}.MAFkeptSNP.txt
   #copy to HIS_DIR if MAF threshold is used in Gensel
   cp $TMP_DIR/${breed}.${chip}.higher.fuerALLELEFREQ2.frq ${HIS_DIR}/.
done

#Ausschluss von LDSNPs die zwar drin wären aber nicht auf dem HDChip sind -> geht nicht wg phasing probleme
join -t' ' -a1 -e'-' -o'1.1 2.1' -1 1 -2 1 <(sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/${breed}.${ncONE}.MAFkeptSNP.txt ) <(sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/${breed}.${ncTWO}.MAFkeptSNP.txt ) > $WORK_DIR/${breed}.MAFkeptSNP.txt

echo "overview of selected SNPs:"
awk '{if($2 == "-") print "HD -"; else print "HD LD"}' $WORK_DIR/${breed}.MAFkeptSNP.txt | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} | uniq -c | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -k1,1nr

awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));SNP[$1]=$2;}} \
    else {sub("\015$","",$(NF));MARKER=SNP[$1]; \
    if   (MARKER != "") {print $0}}}' $WORK_DIR/${breed}.MAFkeptSNP.txt $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt > $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.frqthrdl.txt
cp $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.1.txt
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));SNP[$1]=$2;}} \
    else {sub("\015$","",$(NF));MARKER=SNP[$1]; \
    if   (MARKER != "") {print $0}}}' $WORK_DIR/${breed}.MAFkeptSNP.txt $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.autosomal.txt > $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.autosomal.frqthrdl.txt
cp $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.autosomal.txt $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.autosomal.1.txt

#schreiben der finalen datei
awk '{if($4 != "0" ) print $0}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.frqthrdl.txt | awk '{print $1,$2,$3,NR}' > $TMP_DIR/${breed}.HD.newmap.txt
awk '{if($5 != "0" ) print $0}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.frqthrdl.txt | awk '{print $1,NR}'       > $TMP_DIR/${breed}.LD.newmap.txt
(echo "SNPID Chr BPPos chip_1 chip_2";
join -t' ' -o'1.1 1.2 1.3 1.4 2.2' -a1 -e'0' -1 1 -2 1 <(sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.HD.newmap.txt) <(sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.LD.newmap.txt) | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k4,4n) |\
  awk '{printf "%-53s%+6s%+10s%+15s%+10s\n", $1,$2,$3,$4,$5}' > $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.gonosomalMitochondrial.txt

awk '{if($4 != "0" ) print $0}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.autosomal.frqthrdl.txt | awk '{print $1,$2,$3,NR}' > $TMP_DIR/${breed}.HD.newmap.txt
awk '{if($5 != "0" ) print $0}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.autosomal.frqthrdl.txt | awk '{print $1,NR}' > $TMP_DIR/${breed}.LD.newmap.txt
(echo "SNPID Chr BPPos chip_1 chip_2";
join -t' ' -o'1.1 1.2 1.3 1.4 2.2' -a1 -e'0' -1 1 -2 1 <(sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.HD.newmap.txt) <(sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.LD.newmap.txt) | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k4,4n) |\
  awk '{printf "%-53s%+6s%+10s%+15s%+10s\n", $1,$2,$3,$4,$5}' > $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt

wc -l $HIS_DIR/*.txt



echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW Ende ${SCRIPT}
