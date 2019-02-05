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
    	sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/ped_umcodierung.txt.${breed}.srt
	

	TUMMY2=$(cat $WORK_DIR/DUMMYdam.${breed} | cut -d' ' -f2)
        TUMMY1=$(cat $WORK_DIR/DUMMYdam.${breed} | cut -d' ' -f1)


#MUETTER.
	#mache Liste mit unplausiblen MUETTERN loesche Tiere mit unbekanntem Elte aus Genotypenfile, OHNE die vorher dummyelter bekommen haben
	grep "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt | sed 's/No match/No_Match/g' |\
            awk -v T1=${TUMMY1} -v T2=${TUMMY2} '{if($2 != T1 || $3 != T2 || $2 != T2 || $3 != T2) print}' |\
            awk '{if($4 == "Dam") print $1,$3,$4,$10}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 |\
            join -t' ' -o'1.1 1.2 1.3 1.4' -1 1 -2 1 -v1 - $TMP_DIR/${breed}.TiereMitUnbekannterMutter.srt > $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_undOHNEsurrogateDAM.srt

#anhaengen der Tiere bei denen der surrogate sire zu jung ist, geht einfach via idimputing > idimputing surrogate dam, da renumeriertes pedigree
#grep -v "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt | sed 's/No match/No_Match/g' |\
#            awk -v T1=${TUMMY1} -v T2=${TUMMY2} '{if($2 != T1 || $3 != T1 || $2 != T2 || $3 != T2) print}' |\
#            awk '{if($4 == "Dam" && $1 < $10) print $1,$3,$4,$10}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 >> $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_undOHNEsurrogateDAM.srt


#inkl plausi auf gebdat via idimputing tier > idimputing dam
	grep -v "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt | sed 's/No match/No_Match/g' |\
            awk -v T1=${TUMMY1} -v T2=${TUMMY2} '{if($2 != T1 || $3 != T1 || $2 != T2 || $3 != T2) print}' |\
            awk '{if($4 == "Dam" ) print $1,$3,$4,$10}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt

#wieder loeschen aus OHNEsurrogate wenn einer gefunden wurde
join -t' ' -o'1.1 1.2 1.3 1.4' -v1 -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_undOHNEsurrogateDAM.srt) <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt) > $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_undOHNEsurrogateDAM.srt.pruned
mv $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_undOHNEsurrogateDAM.srt.pruned $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_undOHNEsurrogateDAM.srt

#eliminate Tiere mit mehreren Matches
	if test -s $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt; then
	     z1=$(cut -d' ' -f1 $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt | sort -T ${SRT_DIR} | uniq -c | awk '{print $1}' | sort -T ${SRT_DIR} -u | wc -l | awk '{print $1}')
	     if [ ${z1} == 1 ]; then
	    	echo "Alles ok, habe kein Tier mit Multi-Matching Dams"
		echo "2 X" | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.MULTImatchingdam.animals
	    	cp $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt.uniq
	     else
	    	 echo "ACHTUNG, habe Tier(e) mit Multi-Matching Dams, check file $TMP_DIR/${breed}.MULTImatchingdams.animals, Tiere werden aus Imputation ausgeschlossen "
	    	 cut -d' ' -f1 $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt | sort -T ${SRT_DIR} | uniq -c | awk '{if($1 != 1)print $2,$1}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.MULTImatchingdam.animals
	    	 sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt |\
                        join -t' ' -o'1.1 1.2 1.3 1.4' -1 1 -2 1 -v1 -  $TMP_DIR/${breed}.MULTImatchingdam.animals >  $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt.uniq
	     fi
	else
	    echo "Alles ok, habe kein Tier mit Multi-Matching Dams"
	    echo "2 X" | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.MULTImatchingdam.animals
    	    cp $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt.uniq
	fi

	echo aendere im Pedigree Mutter
	if test -s $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt.uniq ; then
	    echo "awking dam(s)"
	    $BIN_DIR/awk_sedDAM $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt.uniq $FIM_DIR/${breed}Fimpute.ped_sirekorrigiert >  $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert
	


	echo mache Liste MUETTER an Verbaende
	(echo Tier MutterALT flag MutterNEU ;
	    sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_ABERsurrogateDAM.srt.uniq | join -t' ' -o'2.5 1.2 1.3 1.4' -1 1 -2 1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt |\
              sort -T ${SRT_DIR} -t' ' -k2,2 | join -t' ' -o'1.1 2.5 1.3 1.4' -e'0' -1 2 -2 1 -a1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt |\
              sort -T ${SRT_DIR} -t' ' -k4,4 | join -t' ' -o'1.1 1.2 1.3 2.5' -e'0' -1 4 -2 1 -a1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt) | tr ' ' ';'  > $ZOMLD_DIR/${breed}_KorrektuerenMUTTER.csv


	(echo Tier Grund;
	    join -t' ' -o'2.5 1.1' -1 1 -2 1 $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_undOHNEsurrogateDAM.srt $TMP_DIR/ped_umcodierung.txt.${breed}.srt | awk '{print $1,$2,"OhneMatch"}' ;
	    join -t' ' -o'2.5 1.1' -1 1 -2 1 $TMP_DIR/${breed}.MULTImatchingdam.animals $TMP_DIR/ped_umcodierung.txt.${breed}.srt | awk '{print $1,$2,"MultiMatch"}') > $ZOMLD_DIR/${breed}_MUTTERproblem-OHNEoderMULTImatch_daherKEINimputing.csv


    else
	    echo "cp ped_sirekorrigiert zu .ped_siredamkorrigiert"
	    cp $FIM_DIR/${breed}Fimpute.ped_sirekorrigiert $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert
	    touch $ZOMLD_DIR/${breed}_KorrektuerenMUTTER.csv
	fi

	echo "Tiere mit Vaterproblem od. Mutterproblem und OHNE alternativ Elter werden aus den SNPs gelöscht. NO IMPUTATION."
	echo "Tiere mit Vaterproblem od. Mutterproblem und MIT alternativ Elter  wird das Pedigree geaendert.  IMPUTATION RUNNING."

	echo "Info geht im Gesammelten Logfile an ZO per Mail"
rm -f $TMP_DIR/ped_umcodierung.txt.${breed}.srt


fi


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
