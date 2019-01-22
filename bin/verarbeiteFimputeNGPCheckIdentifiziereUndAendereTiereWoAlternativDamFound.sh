#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
else
set -o errexit
set -o nounset

breed=${1}
    ps fax | grep -i "FImpute_Linux"  | tr -s ' ' | awk -v gg=${MAIN_DIR} '{if($9 ~ gg || $5 ~ gg || $6 ~ gg) print $1}' | while read job; do  kill -9 ${job} > /dev/null 2>&1; done
	sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/ped_umcodierung.txt.${breed}.srt
	
	PHUMMY1=$(cat $WORK_DIR/PHUMMYdam.${breed} | cut -d' ' -f2)

#selektiere die wo ein moeglicher Mutter gefuden, geht einfach ueber die idimputing, da idimputingTier > idImputingSire
	#mache Liste mit unplausiblen MUETTERN loesche Tiere mit unbekanntem Elte aus Genotypenfile, OHNE die vorher dummyelter bekommen haben
	grep -v "No match" ${FIM_DIR}/${breed}_NGPCout/parentage_test.txt | sed 's/No match/No_Match/g' |\
            awk -v PH1=${PHUMMY1} '{if($3 == PH1) print}' |\
            awk '{if($4 == "Dam" && $1 > $10) print $1,$3,$4,$10}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt


#eliminate Tiere mit mehreren Matches
	if test -s $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt; then
	    z1=$(cut -d' ' -f1 $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt | sort -T ${SRT_DIR} | uniq -c | awk '{print $1}' | sort -T ${SRT_DIR} -u | wc -l | awk '{print $1}')
		if [ ${z1} == 1 ]; then
	    	    echo "Alles ok, habe kein Tier im NGPCHECK mit Multi-Matching Dams"
		    touch  $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals; sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals -o $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals;
	    	    cp $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt.uniq
		else
	    	    echo "ACHTUNG, habe Tier(e) im NGPCHECK mit Multi-Matching Dams, check file $TMP_DIR/${breed}.MULTImatchingsire.animals, Tiere werden aus Imputation ausgeschlossen "
	    	    cut -d' ' -f1 $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt | sort -T ${SRT_DIR} | uniq -c | awk '{if($1 != 1)print $2,$1}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals
	    	    sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt |\
                    join -t' ' -o'1.1 1.2 1.3 1.4' -1 1 -2 1 -v1 -  $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals >  $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt.uniq
		fi
	else
	    echo "Alles ok, habe kein Tier im NGPCHECK mit Multi-Matching Dams"
    	touch  $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals; sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals -o $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals;
    	cp $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt.uniq
	fi

	echo aendere Pedigree Mutter NGPCHECK
	if test -s $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt.uniq ; then
	    echo "awking dam(s)"
	    $BIN_DIR/awk_sedDAM $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt.uniq $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert_NGPsirekorrigiert >  $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert_NGPsiredamkorrigiert
		    

	    echo mache Liste MUTTER NGPCHECK an Verbaende
        #	(echo Tier MutterALT flag MutterNEU ;
	    sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt.uniq | join -t' ' -o'1.1 2.3 1.3 1.4' -1 1 -2 1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt |\
              sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'2.5 1.2 1.3 1.4' -1 1 -2 1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt |\
              sort -T ${SRT_DIR} -t' ' -k2,2 | join -t' ' -o'1.1 2.5 1.3 1.4' -e'0' -1 2 -2 1 -a1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt |\
              sort -T ${SRT_DIR} -t' ' -k4,4 | join -t' ' -o'1.1 1.2 1.3 2.5' -e'0' -1 4 -2 1 -a1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt | tr ' ' ';'  >> $ZOMLD_DIR/${breed}_KorrektuerenMUTTER.csv
       

       #	(echo Tier Grund;
	    join -t' ' -o'2.5 1.1' -1 1 -2 1 $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals $TMP_DIR/ped_umcodierung.txt.${breed}.srt | awk '{print $1,$2,"MultiMatch"}' >> $ZOMLD_DIR/${breed}_MUTTERproblem-OHNEoderMULTImatch_daherKEINimputing.csv

	else
	    echo "cp .ped zu .ped_sirekorrigiert"
	    cp $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert_NGPsirekorrigiert $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert_NGPsiredamkorrigiert
	fi


	echo "Info aus NGPCMUTTERCHECK geht im Gesammelten Logfile an ZO per Mail"
rm -f $TMP_DIR/ped_umcodierung.txt.${breed}.srt
rm -f $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt
rm -f $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals
rm -f $TMP_DIR/${breed}.TiereMitNGPMUTTER_ABERsurrogateDAM.srt.uniq


fi


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

