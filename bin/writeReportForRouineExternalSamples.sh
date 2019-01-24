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
getColmnNr CHIPADRESSE $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv ; col21=$colNr_

	
if [[ $(awk -v f=${col1} -v e=${col21} 'BEGIN{FS=";";OFS=";"}{if($e != "")print $2,$e}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv | wc -l) -ge 1 ]]; then

for provider in $(awk -v e=${col21} 'BEGIN{FS=";";OFS=";"}{if(NR > 1 && $e != "")print $e}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv | sort -T ${SRT_DIR} -u); do

(echo "sampleID;CHEID;ITBID;ChipID;SYS;Name;NationalBreed;Shipment;IMPresultOLD;IMPresultNEW;Callrate;Heterozygotie;GCScore;Pedigree;MultiSIREmatch;MultiDAMmatch;WithoutSIREmatch;WithoutDAMmatch;SirePedigree;SireSNP;DamPedigree;DamSNP;ChipCurrentIMPSample;ChipCurrentIMPSirePedigree;ChipCurrentIMPDamPedigree;ChipCurrentIMPMGSPedigree;MGSsuspicious;ExternalSNP;PedigreeImputation;SNPTwin;SexSuspicious;CHIPADRESSE;PGSsuspicious;SAK_BGA;"
awk -v f=${col1} -v e=${col21} -v p=${provider} 'BEGIN{FS=";";OFS=";"}{if(NR > 1 && $e != "")print $0}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv | sed "s/\;NEU\;/\;NEW\;/g") > $GEDE_DIR/zomld/${provider}_${breed}_SummaryLOG-${run}.csv

done
else

echo "No ${breed} External Samples to be reported"

fi


RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
