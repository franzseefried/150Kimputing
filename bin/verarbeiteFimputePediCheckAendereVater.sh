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
	
	TUMMY1=$(cat $WORK_DIR/DUMMYsire.${breed} | cut -d' ' -f1)


	#mache Liste mit unplausiblen VAETERN loesche Tiere mit unbekanntem Elte aus Genotypenfile, OHNE die vorher dummyelter bekommen haben
	grep "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt | sed 's/No match/No_Match/g' |\
            awk -v T1=${TUMMY1} '{if($2 != T1) print}' |\
            awk '{if($4 == "Sire") print $1,$2,$4,$10}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 |\
            join -t' ' -o'1.1 1.2 1.3 1.4' -1 1 -2 1 -v1 - $TMP_DIR/${breed}.TiereMitUnbekanntemVater.srt > $TMP_DIR/${breed}.TiereMitVATERPROBLEM_undOHNEsurrogateSIRE.srt


#anhaengen der Tiere bei denen der surrogate sire zu jung ist, geht einfach via idimputing > idimputing surrogate sire, da renumeriertes pedigree
        grep -v "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt | sed 's/No match/No_Match/g' |\
            awk -v T1=${TUMMY1} '{if($2 != T1 || $3 != T1) print}' |\
            awk '{if($4 == "Sire" && $1 < $10) print $1,$2,$4,$10}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 | awk '{print $1,$2,"Sire No_Match"}'  >> $TMP_DIR/${breed}.TiereMitVATERPROBLEM_undOHNEsurrogateSIRE.srt

#inkl plausi auf gebdat via idimputing tier > idimputing sire
	grep -v "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt | sed 's/No match/No_Match/g' |\
            awk -v T1=${TUMMY1} '{if($2 != T1 || $3 != T1) print}' |\
            awk '{if($4 == "Sire" && $1 > $10) print $1,$2,$4,$10}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt

#wieder loeschen aus OHNEsurrogate wenn einer gefunden wurde
join -t' ' -o'1.1 1.2 1.3 1.4' -v1 -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitVATERPROBLEM_undOHNEsurrogateSIRE.srt) <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt) > $TMP_DIR/${breed}.TiereMitVATERPROBLEM_undOHNEsurrogateSIRE.srt.pruned
mv $TMP_DIR/${breed}.TiereMitVATERPROBLEM_undOHNEsurrogateSIRE.srt.pruned $TMP_DIR/${breed}.TiereMitVATERPROBLEM_undOHNEsurrogateSIRE.srt


#eliminate Tiere mit mehreren Matches
	if test -s $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt; then
	    z1=$(cut -d' ' -f1 $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt | sort -T ${SRT_DIR} | uniq -c | awk '{print $1}' | sort -T ${SRT_DIR} -u | wc -l | awk '{print $1}')
		if [ ${z1} == 1 ]; then
	    	    echo "Alles ok, habe kein Tier mit Multi-Matching Sires"
		    echo "2 X" | sort -T ${SRT_DIR} -t' ' -k1,1 >  $TMP_DIR/${breed}.MULTImatchingsire.animals
	    	    cp $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt.uniq
		else
	    	    echo "ACHTUNG, habe Tier(e) mit Multi-Matching Sires, check file $TMP_DIR/${breed}.MULTImatchingsire.animals, Tiere werden aus Imputation ausgeschlossen "
	    	    cut -d' ' -f1 $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt | sort -T ${SRT_DIR} | uniq -c | awk '{if($1 != 1)print $2,$1}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.MULTImatchingsire.animals
	    	    sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt |\
                    join -t' ' -o'1.1 1.2 1.3 1.4' -1 1 -2 1 -v1 -  $TMP_DIR/${breed}.MULTImatchingsire.animals >  $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt.uniq
		fi
	else
	    echo "Alles ok, habe kein Tier mit Multi-Matching Sires"
    	    echo "2 X" | sort -T ${SRT_DIR} -t' ' -k1,1 >  $TMP_DIR/${breed}.MULTImatchingsire.animals
    	    cp $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt.uniq
	fi

	echo aendere Pedigree Vater
	if test -s $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt.uniq ; then
	    echo "awking sire(s)"
	    $BIN_DIR/awk_sedSIRE $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt.uniq $FIM_DIR/${breed}Fimpute.ped >  $FIM_DIR/${breed}Fimpute.ped_sirekorrigiert
	
	    

	echo mache Liste VATER an Verbaende
	(echo Tier VaterALT flag VaterNEU ;
	    sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitVATERPROBLEM_ABERsurrogateSIRE.srt.uniq | join -t' ' -o'2.5 1.2 1.3 1.4' -1 1 -2 1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt |\
              sort -T ${SRT_DIR} -t' ' -k2,2 | join -t' ' -o'1.1 2.5 1.3 1.4' -e'0' -1 2 -2 1 -a1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt |\
              sort -T ${SRT_DIR} -t' ' -k4,4 | join -t' ' -o'1.1 1.2 1.3 2.5' -e'0' -1 4 -2 1 -a1 -  $TMP_DIR/ped_umcodierung.txt.${breed}.srt) | tr ' ' ';'  > $ZOMLD_DIR/${breed}_KorrektuerenVATER.csv

	(echo Tier Grund;
	    join -t' ' -o'2.5 1.1' -1 1 -2 1 $TMP_DIR/${breed}.TiereMitVATERPROBLEM_undOHNEsurrogateSIRE.srt $TMP_DIR/ped_umcodierung.txt.${breed}.srt | awk '{print $1,$2,"OhneMatch"}';
	    join -t' ' -o'2.5 1.1' -1 1 -2 1 $TMP_DIR/${breed}.MULTImatchingsire.animals $TMP_DIR/ped_umcodierung.txt.${breed}.srt | awk '{print $1,$2,"MultiMatch"}') > $ZOMLD_DIR/${breed}_VATERproblem-OHNEoderMULTImatch_daherKEINimputing.csv

    else
	    echo "cp .ped zu .ped_sirekorrigiert"
	    cp $FIM_DIR/${breed}Fimpute.ped $FIM_DIR/${breed}Fimpute.ped_sirekorrigiert
	    touch $ZOMLD_DIR/${breed}_KorrektuerenVATER.csv
	fi
	echo "run Parentage fuer Muetter"

	echo "Tiere mit Vaterproblem od. Mutterproblem und OHNE alternativ Elter werden aus den SNPs gelöscht. NO IMPUTATION."
	echo "Tiere mit Vaterproblem od. Mutterproblem und MIT alternativ Elter  wird das Pedigree geaendert.  IMPUTATION RUNNING."

	echo "Info geht im Gesammelten Logfile an ZO per Mail"
rm -f $TMP_DIR/ped_umcodierung.txt.${breed}.srt


fi


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

