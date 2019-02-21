#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "
echo "to do: plausi auf das Alter der gefundenen NK Elter Kombinationen"
##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
##########################################################################################
# Funktionsdefinition

# Funktion gibt Spaltennummer gemaess Spaltenueberschrift in csv-File zurueck.
# Es wird erwartet, dass das Trennzeichen das Semikolon (;) ist
getColmnNr () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}

##########################################################################################


if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'ALL' is here necessary"
    exit 1
else
set -o errexit
set -o nounset
breed=${1}

#get Info about SNP from Reftab
for i in BSW HOL VMS; do

getColmnNr VaterPedigree $ZOMLD_DIR/${i}_SammelLOG-${run}.csv ;   colVP=$colNr_
getColmnNr VaterSNP $ZOMLD_DIR/${i}_SammelLOG-${run}.csv ;        colVS=$colNr_
getColmnNr MutterPedigree $ZOMLD_DIR/${i}_SammelLOG-${run}.csv ;  colMP=$colNr_
getColmnNr MutterSNP $ZOMLD_DIR/${i}_SammelLOG-${run}.csv ;       colMS=$colNr_
getColmnNr OhneVATERmatch $ZOMLD_DIR/${i}_SammelLOG-${run}.csv ;  colOV=$colNr_
getColmnNr OhneMUTTERmatch $ZOMLD_DIR/${i}_SammelLOG-${run}.csv ; colOM=$colNr_



getColmnNr VaterPedigree $HIS_DIR/${i}_SumUpLOG.${run}.csv ;      cosVP=$colNr_
getColmnNr VaterSNP $HIS_DIR/${i}_SumUpLOG.${run}.csv ;           cosVS=$colNr_
getColmnNr MutterPedigree $HIS_DIR/${i}_SumUpLOG.${run}.csv ;     cosMP=$colNr_
getColmnNr MutterSNP $HIS_DIR/${i}_SumUpLOG.${run}.csv ;          cosMS=$colNr_
getColmnNr OhneVATERmatch $HIS_DIR/${i}_SumUpLOG.${run}.csv ;     cosOV=$colNr_
getColmnNr OhneMUTTERmatch $HIS_DIR/${i}_SumUpLOG.${run}.csv ;    cosOM=$colNr_


getColmnNr TVD $ZOMLD_DIR/${i}_SammelLOG-${run}.csv  ;            colTVD=$colNr_
getColmnNr TVD $HIS_DIR/${i}_SumUpLOG.${run}.csv ;                cosTVD=$colNr_
	
#nun muss die Spalt Pedigree Vater 0 gesetzt werden und in Spalte VateSNP der jeweiige Vater gesetzt werden sowie das Y von OhneVATERmathc geloescht werden
(head -1 $ZOMLD_DIR/${i}_SammelLOG-${run}.csv;
awk -v T=${colTVD} -v P=${colVP} -v S=${colVS} -v O=${colOV} 'BEGIN{FS=";";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));GG[$1]=$4;}} \
    else {sub("\015$","",$(NF));CG=GG[$T]; \
    if   (CG != "" && $O == "Y") {$P="0";$S=CG;$O="";print} \
    else                         {print $0}}}' $ZOMLD_DIR/ALL_KorrektuerenVATER.csv $ZOMLD_DIR/${i}_SammelLOG-${run}.csv | awk '{if(NR > 1)print}' ) > $TMP_DIR/${i}_SammelLOG-${run}.csv
mv $TMP_DIR/${i}_SammelLOG-${run}.csv $ZOMLD_DIR/${i}_SammelLOG-${run}.csvNEU 
#das selbe fuer die Mutter
(head -1 $ZOMLD_DIR/${i}_SammelLOG-${run}.csv;
awk -v T=${colTVD} -v P=${colMP} -v S=${colMS} -v O=${colOM} 'BEGIN{FS=";";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));GG[$1]=$4;}} \
    else {sub("\015$","",$(NF));CG=GG[$T]; \
    if   (CG != "" && $O == "Y") {$P="0";$S=CG;$O="";print} \
    else                         {print $0}}}' $ZOMLD_DIR/ALL_KorrektuerenMUTTER.csv $ZOMLD_DIR/${i}_SammelLOG-${run}.csvNEU | awk '{if(NR > 1)print}') > $TMP_DIR/${i}_SammelLOG-${run}.csv
mv $TMP_DIR/${i}_SammelLOG-${run}.csv $ZOMLD_DIR/${i}_SammelLOG-${run}.csvNEU     


#nur jene die in Spatle OhneVATERmatch ein "Y" haben
#nun muss die Spalt Pedigree Vater 0 gesetzt werden und in Spalte VateSNP der jeweiige Vater gesetzt werden sowie das Y von OhneVATERmathc geloescht werden
(head -1 $HIS_DIR/${i}_SumUpLOG.${run}.csv;
awk -v T=${cosTVD} -v P=${cosVP} -v S=${cosVS} -v O=${cosOV} 'BEGIN{FS=";";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));GG[$1]=$4;}} \
    else {sub("\015$","",$(NF));CG=GG[$T]; \
    if   (CG != "" && $O == "Y") {$P="0";$S=CG;$O="";print} \
    else                         {print $0}}}' $ZOMLD_DIR/ALL_KorrektuerenVATER.csv $HIS_DIR/${i}_SumUpLOG.${run}.csv | awk '{if(NR > 1)print}') > $TMP_DIR/${i}_SumUpLOG.${run}.csv
mv $TMP_DIR/${i}_SumUpLOG.${run}.csv $HIS_DIR/${i}_SumUpLOG.${run}.csvNEU 
#das selbe fuer die Mutter
(head -1 $HIS_DIR/${i}_SumUpLOG.${run}.csv;
awk -v T=${cosTVD} -v P=${cosMP} -v S=${cosMS} -v O=${cosOM} 'BEGIN{FS=";";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));GG[$1]=$4;}} \
    else {sub("\015$","",$(NF));CG=GG[$T]; \
    if   (CG != "" && $O == "Y") {$P="0";$S=CG;$O="";print} \
    else                         {print $0}}}' $ZOMLD_DIR/ALL_KorrektuerenMUTTER.csv $HIS_DIR/${i}_SumUpLOG.${run}.csvNEU | awk '{if(NR > 1)print}') > $TMP_DIR/${i}_SumUpLOG.${run}.csv
mv $TMP_DIR/${i}_SumUpLOG.${run}.csv $HIS_DIR/${i}_SumUpLOG.${run}.csvNEU    


done
fi



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
