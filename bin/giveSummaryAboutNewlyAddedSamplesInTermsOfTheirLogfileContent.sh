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


getColmnNr IMPresultNEU $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col1=$colNr_
getColmnNr Pedigree $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col2=$colNr_
getColmnNr MultiVATERmatch $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col3=$colNr_
getColmnNr MultiMUTTERmatch $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col4=$colNr_
getColmnNr OhneVATERmatch $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col5=$colNr_
getColmnNr OhneMUTTERmatch $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col6=$colNr_
getColmnNr VaterPedigree $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col7=$colNr_
getColmnNr VaterSNP $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col8=$colNr_
getColmnNr MutterPedigree $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col9=$colNr_
getColmnNr MutterSNP $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col10=$colNr_
getColmnNr ChipCurrentIMPTier $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col12=$colNr_
getColmnNr ChipCurrentIMPVaterPedigree $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col13=$colNr_
getColmnNr ChipCurrentIMPMutterPedigree $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col14=$colNr_
getColmnNr ChipCurrentIMPMVPedigree $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col15=$colNr_
getColmnNr MVsuspekt $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col16=$colNr_
getColmnNr SNPTwin $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col17=$colNr_
getColmnNr SuspektSex $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col18=$colNr_
getColmnNr VVsuspekt $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col19=$colNr_
getColmnNr SAK_BGA $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col20=$colNr_

nA=$(wc -l $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt )
(echo $RIGHT_NOW Start ${SCRIPT};
echo " "
echo "you are analyzing a sum of ${nA} Samples"
echo " "
echo " ";
echo "#Block #A ImpResNeu"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col1} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #B PedigreeRecord"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col2} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #C MultiVATERmatch"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col3} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #D MultiMUTTERmatch"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col4} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #E OhneVaterMatch"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col5} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #F OhneMutterMatch"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col6} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #G VaterPedigree"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col7} -v ff=${col8} 'BEGIN{FS=";";OFS=";"}{if($f != "0" && $ff != "" && $f != "") print $2,"unexpectedSireMutation"}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #H MutterPedigree"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col9} -v ff=${col10} 'BEGIN{FS=";";OFS=";"}{if($f != "0" && $ff != "" && $f != "") print $2,"unexpectedDamMutation"}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #I VVsuspekt"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col19} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #J MVsuspekt"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col16} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #K SuspektSex"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col18} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #L SNPTwin"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col17} 'BEGIN{FS=";";OFS=";"}{if($f != "") print $2,"SNPTwinFound"}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
echo "#Block #M SAK_BGA"
join -t';' -o '2.2' -1 1 -2 1 <(sed 's/ /\;/g'  $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt |sort -T ${SRT_DIR} -t';' -k1,1) <(awk -v f=${col20} 'BEGIN{FS=";";OFS=";"}{print $2,$f}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv |sort -T ${SRT_DIR} -t';' -k1,1)|sort|uniq -c
echo " ";
echo " ";
RIGHT_NOW=$(date );
echo $RIGHT_NOW Ende ${SCRIPT};
echo " ") > $LOG_DIR/${breed}.NewSampleSummary.log
echo " ";
echo " ";

echo "ATTENTION: .... check files with comparison against last run: $LOG_DIR/${breed}.NewSampleSummary.log"
echo " ";
echo " ";
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
