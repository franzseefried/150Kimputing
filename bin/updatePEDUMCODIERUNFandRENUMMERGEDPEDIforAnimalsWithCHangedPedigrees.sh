#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "
##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

### # function for reporting on console
usage () {
	local l_MSG=$1
	echo "Usage Error: $l_MSG"
	echo "Usage: $SCRIPT -b <string>"
	echo "  where <string> specifies the breed with options BSW or HOL"
	exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -le 0 ]; then
	usage 'No command line arguments specified'
fi

while getopts ":b:" FLAG; do
	case $FLAG in
		b)
			impbreed=$(echo $OPTARG | awk '{print toupper($1)}')
			if [ ${impbreed} != "BSW" ] && [ ${impbreed} != "HOL" ] && [ ${impbreed} != "VMS" ] ; then
				usage 'Breed not correct, must be specified: BSW or HOL or VMS using option -b <string>'
			fi
		;;
		*) # invalid command line arguments
			usage "Invalid command line argument $OPTARG"
		;;
	esac
done
#shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
if [ -z "${impbreed}" ]; then
	usage 'IMPBREED not specified, must be specified using option -b <string>'
fi
set -o errexit
set -o nounset

for i in VATER MUTTER; do
	echo "Lese files aus der Pedigree-Plausi Imputation fuer ${impbreed} ${i}-Aenderungen"
	cut -d';' -f1,4 $ZOMLD_DIR/${impbreed}_Korrektueren${i}.csv | \
		sed -n '2,$p' | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${impbreed}.${i}.srt
done

echo " "
echo "Sammle Vater + Mutter Aederungen fuer ${impbreed}"
echo "Aufbau einer Liste in $TMP_DIR/${impbreed}.Korrekturen.summary"
echo "Format: Tier VaterSNP VaterMutter wenn SNPPlausi was liefert, '-' wenn keine Aenderung aus Imputation kommt."
(cut -d';' -f1 $ZOMLD_DIR/${impbreed}_KorrektuerenVATER.csv | sed -n '2,$p';
	cut -d';' -f1 $ZOMLD_DIR/${impbreed}_KorrektuerenMUTTER.csv | sed -n '2,$p') | awk '{print $1" k"}' |\
		sort -T ${SRT_DIR} -u |\
		sort -T ${SRT_DIR} -t' ' -k1,1 |\
		join -t' ' -o'1.1 2.2' -a 1 -e'-' -1 1 -2 1 - $TMP_DIR/${impbreed}.VATER.srt |\
		sort -T ${SRT_DIR} -t' ' -k1,1 |\
		join -t' ' -o'1.1 1.2 2.2' -a 1 -e'-' -1 1 -2 1 - $TMP_DIR/${impbreed}.MUTTER.srt > $TMP_DIR/${impbreed}.Korrekturen.summary

echo " "
echo "Hole fuer ${impbreed} die mit nur einem geaenderten Elter, den anderen Elter aus dem Imputing-pedigree"
#format: TVDtier idtier TVDsnpvater TVDsnpmutter
$BIN_DIR/awk_holeIDimputing ${WORK_DIR}/ped_umcodierung.txt.${impbreed} $TMP_DIR/${impbreed}.Korrekturen.summary > $TMP_DIR/${impbreed}.Korrekturen.summary.id
#format: TVDtier idtier TVDsnpvater pedivatID TVDsnpmutter pedimutID, dann alle "-"-Eltern die ersetzt werden koennen aus dem pedigree ersetzen
echo "Behalte fuer Rasseberechnung nur die mit 2 bekannten Eltern denn nur die haben auch die Imputation durchlaufen: Liste $TMP_DIR/${impbreed}.Korrekturen.final"
$BIN_DIR/awk_updateMissingElterFromImpPedi ${WORK_DIR}/ped_umcodierung.txt.${impbreed} $TMP_DIR/${impbreed}.Korrekturen.summary.id |\
	awk '{if($3 == "-" && $4 != 0) print $1,$2,$4,$5,$6 ; else print $1,$2,$3,$5,$6}' |\
	awk '{if($4 == "-" && $5 != 0) print $1,$2,$3,$5 ; else print $1,$2,$3,$4}' |\
	awk '{if($3 != "-" && $4 != "-") print $1,$2,$3,$4}'> $TMP_DIR/${impbreed}.Korrekturen.summary.idvatmut
$BIN_DIR/awk_holeIDvatMutimputing ${WORK_DIR}/ped_umcodierung.txt.${impbreed} $TMP_DIR/${impbreed}.Korrekturen.summary.idvatmut |\
	awk 'BEGIN{FS=";"}{if ($4 != "") print $1";"$4";"$5";"$6; else print $1";"$3";"$5";"$6}' |\
	awk 'BEGIN{FS=";"}{if ($4 != "") print $1";"$2";"$4; else print $1";"$2";"$3}' > $TMP_DIR/${impbreed}.Korrekturen.final

echo " "
echo "preparing update der Blutanteile im Fall einer Eltermutation"
awk 'BEGIN{FS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));bp[$2]=substr($0,33,150)}} \
    else {sub("\015$","",$(NF));bpS=bp[$2];bpD=bp[$3]; \
    if   (bpS != "" && bpD != "") {print $0";"bpS";"bpD} else {print $0}}}' $TMP_DIR/${impbreed}.Blutanteile.txt $TMP_DIR/${impbreed}.Korrekturen.final |\
    awk 'BEGIN{FS=";";OFS=";"}{print $1,$2,$3,($4*0.5)+($7*0.5),($5*0.5)+($8*0.5),($6*0.5)+($9*0.5)}' > $TMP_DIR/${impbreed}.Blutanteile.ForUpdate

echo " "
echo "update Blutanteilfile"
#ACHTUNG: je nachdem wo im Ablauf dann Blutantile gelesen werden ist es richtig das entweder roiginale oder modifizierte Blutanteile gelesen werden
awk 'BEGIN{FS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));bp[$1]=$4;cp[$1]=$5;dp[$1]=$6}} \
    else {sub("\015$","",$(NF));bpT=bp[$2];cpT=cp[$2];dpT=dp[$2]; \
    if   (bpT != "") {print $1";"$2";"bpT";"cpT";"dpT} else {print $0}}}' $TMP_DIR/${impbreed}.Blutanteile.ForUpdate $TMP_DIR/${impbreed}.Blutanteile.txt > $TMP_DIR/${impbreed}.Blutanteile.mod
#grep CH120135290724 $TMP_DIR/${impbreed}.Blutanteile.mod $TMP_DIR/${impbreed}.Blutanteile.txt $TMP_DIR/${impbreed}.Blutanteile.ForUpdate


echo " "
echo "Rasseupdate fuer die Tiere mit geaenderter Abstammung fuer ${impbreed} beginnt jetzt, inkl umformatieren auf 100er format, Logik siehe Mail USN 02.04.15"
#Format Blutanteile.txt: Tier OB% BV% BS%"
#Format Blutanteile.txt: Tier SI% MO% HO%"
#Format Blutanteile.txt: Tier LI% CH% DR%" ergaenzt 13.4.2017
#endformat: Tier Vater Mutter BreedTier
if [ ${impbreed} == "BSW" ]; then
	pedbreed=bv;
	d1=$(echo ${DatPEDIbvch});
    $BIN_DIR/awk_grep3Blutanteile $TMP_DIR/${impbreed}.Blutanteile.mod $TMP_DIR/${impbreed}.Korrekturen.final |\
	awk '{print $1,$2,$6,100*(($3+$7)/2),100*(($4+$8)/2),100*(($5+$9)/2),$10}' |\
	awk '{if(($4 + $5 + $6) < 87.5) print $1,$2,$3,"KR"; else if ($4 == 100) print $1,$2,$3,"OB"; else if ($4 >87.5 && $7 == "F") print $1,$2,$3,"ROB"; else print $1,$2,$3,"BV"}' > $WORK_DIR/${impbreed}.sedBreed
fi
#endformat: Tier Vater Mutter BreedTier
if [ ${impbreed} == "HOL" ]; then
	pedbreed=rh;
	d1=$(echo ${DatPEDIshb});
	$BIN_DIR/awk_grep3Blutanteile $TMP_DIR/${impbreed}.Blutanteile.mod $TMP_DIR/${impbreed}.Korrekturen.final |\
	awk '{print $1,$2,$6,100*(($3+$7)/2),100*(($4+$8)/2),100*(($5+$9)/2),$10}' |\
	awk '{if(($4 + $5 + $6) < 87.5) print $1,$2,$3,"KR"; else if ($6 > 87.5 ) print $1,$2,$3,"HO"; else if ($5 > 50) print $1,$2,$3,"MO";else if ($4 + $5 > 87.5) print $1,$2,$3,"SI"; else print $1,$2,$3,"SF"}' > $WORK_DIR/${impbreed}.sedBreed
#decipher RH from HOL. hole Sektionscodes der eltern aus der originalen ped umkodierung
#achtung: einzig die paarung RF X RH / RF x RF kann so nicht aufgeschluesselt werden. man muesste die Imutation des Farbgens lesen. Wird hier noch nicht gemacht, da noch kein Farbgen imputiert wird
    awk 'BEGIN{FS=" "}{ \
       if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$5]=$6}} \
       else {sub("\015$","",$(NF));bpT=sp[$2];dpT=sp[$3]; \
       if      (bpT != "" && dpT != "" && bpT == "RH"  && dpT == "RH") print $1,$2,$3,"RH";
       else if (bpT != "" && dpT != "" && bpT == "RH"  && dpT == "HO") print $1,$2,$3,"RF";
       else if (bpT != "" && dpT != "" && bpT == "HO"  && dpT == "RH") print $1,$2,$3,"RF";
       else if (bpT != "" && dpT != "" && bpT == "RH"  && dpT == "HOL")print $1,$2,$3,"RF";
       else if (bpT != "" && dpT != "" && bpT == "HOL" && dpT == "RH") print $1,$2,$3,"RF";
       else if (bpT != "" && dpT != "" && bpT == "RH"  && dpT == "HO") print $1,$2,$3,"RF";
       else if (bpT != "" && dpT != "" && bpT == "HO"  && dpT == "RH") print $1,$2,$3,"RF";
       else                                                             print $0}}' ${WORK_DIR}/ped_umcodierung.txt.${impbreed} $WORK_DIR/${impbreed}.sedBreed > $WORK_DIR/${impbreed}.sedBreed.sektionscodeUpdate
    mv $WORK_DIR/${impbreed}.sedBreed.sektionscodeUpdate $WORK_DIR/${impbreed}.sedBreed
fi
#endformat: Tier Vater Mutter BreedTier
if [ ${impbreed} == "VMS" ]; then
	pedbreed=vms;
	d1=$(echo ${DatPEDIvms});
    $BIN_DIR/awk_grep3Blutanteile $TMP_DIR/${impbreed}.Blutanteile.mod $TMP_DIR/${impbreed}.Korrekturen.final |\
	awk '{print $1,$2,$6,100*(($3+$7)/2),100*(($4+$8)/2),100*(($5+$9)/2),$10}' |\
	awk '{if(($4 + $5 + $6) < 87.5) print $1,$2,$3,"KR"; else if ($4 > 50) print $1,$2,$3,"LM"; else if ($5 > 50) print $1,$2,$3,"CH"; else if ($6 > 50) print $1,$2,$3,"DR" ;else print $1,$2,$3,"KR"}' > $WORK_DIR/${impbreed}.sedBreed
fi



#itb rasse wird nicht upgedates, dies erfolgt 5 Zeilen weiter unten an Hand des Rassecodes
echo "Update Breed in $WORK_DIR/ped_umcodierung.txt.${impbreed} now und setze flag 'U' fuer Updates an der Rasse"
$BIN_DIR/awk_sedBREED $WORK_DIR/${impbreed}.sedBreed ${WORK_DIR}/ped_umcodierung.txt.${impbreed} > $TMP_DIR/ped_umcodierung.txt.${impbreed}.updated

echo "Update Sire und Dam in $WORK_DIR/ped_umcodierung.txt.${impbreed} using Sire Dam from Imputation"
$BIN_DIR/awk_sedSireDamInPedUmkodierung $FIM_DIR/${impbreed}Fimpute.ped_siredamkorrigiert_NGPsiredamkorrigiert $TMP_DIR/ped_umcodierung.txt.${impbreed}.updated > $WORK_DIR/ped_umcodierung.txt.${impbreed}.updated

echo "Update Sire, Breed, Dam in Renumbered Pedigree + in $WORK_DIR/ped_umcodierung.txt.${impbreed} using Sire Dam from Imputation"
if [ ${impbreed} == "BSW" ]; then
awk '{if(($6 ~ "OB")||($6 ~ "BV")||($6 ~ "BS")) printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","BSW";
else if (($6 ~ "JE")) printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","JER";
else printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","XXX"}' $WORK_DIR/ped_umcodierung.txt.${impbreed}.updated > $TMP_DIR/${impbreed}.pd.upd.umcd.srt
fi
if [ ${impbreed} == "HOL" ]; then
awk '{if(($6 ~ "60")||($6 ~ "70")||($6 ~ "SF")||($6 ~ "SI")) printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","SIM";
else if (($6 ~ "HO")||($6 ~ "RF")) printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","HOL";
else if (($6 ~ "RH")) printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","RED";
else if (($6 ~ "MO")) printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","MON";
else printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","XXX"}' $WORK_DIR/ped_umcodierung.txt.${impbreed}.updated > $TMP_DIR/${impbreed}.pd.upd.umcd.srt
fi
if [ ${impbreed} == "VMS" ]; then
awk '{if(($6 ~ "LM")) printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","LIM";
else if (($6 ~ "DR")) printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","DXT";
else if (($6 ~ "CH")) printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","CHA";
else printf "%+10s%+11s%+11s%+5s%+19s%+15s%+9s%+4s%+2s%+2s%+4s\n",$1,$2,$3,"XXXX",$4,$5,"XXXXXXXX",$6,$7,"X","XXX"}' $WORK_DIR/ped_umcodierung.txt.${impbreed}.updated > $TMP_DIR/${impbreed}.pd.upd.umcd.srt
fi
echo " "
#echo "ACHTUNG change in May from MergedPedi to RenumMergedPedi"
#$BIN_DIR/awk_UpdateRenumPed $TMP_DIR/${impbreed}.pd.upd.umcd.srt ${PEDWORK_DIR}/${pedbreed}/mergedPedi_${d1}.txt > ${PEDWORK_DIR}/${pedbreed}/UpdatedRenumMergedPedi_${d1}.txt
#hier Plausi auf die IDs zwischen Tier und Eltern
$BIN_DIR/awk_UpdateRenumPed_${impbreed} $TMP_DIR/${impbreed}.pd.upd.umcd.srt ${PEDI_DIR}/work/${pedbreed}/RenumMergedPedi_${d1}.txt | sed 's/\;//g' > ${PEDI_DIR}/work/${pedbreed}/UpdatedRenumMergedPedi_${d1}.txt
rm -f $TMP_DIR/${impbreed}.[A-Z][A-Z][A-Z]*.srt
rm -f $TMP_DIR/${impbreed}.Korrekturen.summary
rm -f $TMP_DIR/${impbreed}.Korrekturen.summary.id
rm -f $TMP_DIR/${impbreed}.Korrekturen.summary.idvatmut
rm -f $TMP_DIR/${impbreed}.Korrekturen.final
rm -f $TMP_DIR/${impbreed}.Blutanteile.ForUpdate
rm -f $WORK_DIR/${impbreed}.sedBreed
rm -f $WORK_DIR/${impbreed}.sedBreed.sektionscodeUpdate
rm -f $TMP_DIR/ped_umcodierung.txt.${impbreed}.updated
rm -f $TMP_DIR/${impbreed}.pd.upd.umcd.srt

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
