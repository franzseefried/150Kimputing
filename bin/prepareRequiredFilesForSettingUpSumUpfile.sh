#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 



##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
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
if [ ${breed} == "BSW" ]; then outzo=SBZV; fi
if [ ${breed} == "HOL" ]; then outzo=SHSF; fi
if [ ${breed} == "VMS" ]; then outzo=VMS; fi



for i in $TMP_DIR/smpg${breed} $TMP_DIR/chcks${breed}; do if test -d ${i} ; then rm -rf ${i} ; fi; done
mkdir -p $TMP_DIR/smpg${breed}
mkdir -p $TMP_DIR/chcks${breed}


rm -f $TMP_DIR/TiereMitGenotypOhnePedigree${run}.srt


for ffile in $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${run}.csv $ZOMLD_DIR/${breed}_*problem-OHNEoderMULTImatch_daherKEINimputing.csv $ZOMLD_DIR/${breed}_Korrektueren*.csv $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv $ZOMLD_DIR/${breed}_suspiciousVVs.${run}.csv; do
  if ! test -s ${ffile}; then
    touch ${ffile}
  fi
done
#defintion eines zaehlers damit hinter her im LOOPJoin sortiert werde kann. Achtung so wie gejoint wird muessen sie hier sortiert sein && nur 2 spalten, wenn also mehr als 2 Spalten benoetigt werden muessen mehrere files ausgelesen werden
#ausserdem wird hier definiert war wie es im Logfile codiert ist. z.B. "Y"
counter=1
#Imputationsergebnis
awk '{if($2 > 0) print $1,"+"}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis > $TMP_DIR/smpg${breed}/#${counter}#${breed}impres.${oldrun}
counter=$(echo $counter | awk '{print $1+1}')
awk '{if($2 > 0) print $1,"+"}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis  > $TMP_DIR/smpg${breed}/#${counter}#${breed}impres.${run}
counter=$(echo $counter | awk '{print $1+1}')
#ohne pedigree
awk 'BEGIN{FS=";"}{if( $2 == "NoPedigreeRecord") print $1,"-"}' $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${run}.csv > $TMP_DIR/smpg${breed}/#${counter}#.${breed}TiereMitGenotypOhnePedigree${run}.srt
counter=$(echo $counter | awk '{print $1+1}')
#MultiMatch
for i in VATER MUTTER; do
    cat $ZOMLD_DIR/${breed}_${i}problem-OHNEoderMULTImatch_daherKEINimputing.csv | awk '{if($3 == "MultiMatch") print $1,"Y"}' >  $TMP_DIR/smpg${breed}/#${counter}#${breed}${i}MULTI.srt
    counter=$(echo $counter | awk '{print $1+1}')
done
#OhneMatch
for i in VATER MUTTER; do
    if [ ${i} == "VATER" ]; then
    flg="Vater"
    fi
    if [ ${i} == "MUTTER" ]; then
    flg="Dam"
    fi
    (cat $ZOMLD_DIR/${breed}_${i}problem-OHNEoderMULTImatch_daherKEINimputing.csv | awk '{if($3 == "OhneMatch") print $1,"Y"}';
    awk -v ff=${flg} 'BEGIN{FS=";"}{if($3 == ff) print $1,"Y"}' $ZOMLD_DIR/${breed}.TiereMitUnbekanntemElter_KEINEimputation.csv ) | sort -T ${SRT_DIR} -u >  $TMP_DIR/smpg${breed}/#${counter}#${breed}UnbekElter${i}.srt
    counter=$(echo $counter | awk '{print $1+1}')
done
#Vater & Mutterkorrekturen 2x benoetigt
for i in VATER MUTTER; do
j=2;
for j in 2 4; do
	cat $ZOMLD_DIR/${breed}_Korrektueren${i}.csv | tr ';' ' ' | cut -d' ' -f1,${j} > $TMP_DIR/smpg${breed}/#${counter}#${breed}${i}korrekturen${j}.srt
	counter=$(echo $counter | awk '{print $1+1}')
done
done
#Typisierungssituation 4x benoetigt
j=2
for j in 2 4 6 8; do
	cat $RES_DIR/${breed}TypiSituationVMMV_${run}.txt | sed 's/UUUUUUUUUUUUUU/-/g' | cut -d' ' -f1,${j} > $TMP_DIR/smpg${breed}/#${counter}#${breed}Typi${j}.stat
	counter=$(echo $counter | awk '{print $1+1}')
done
#VVcheck
awk '{print $1,"Y"}' $ZOMLD_DIR/${breed}_suspiciousVVs.${run}.csv > $TMP_DIR/smpg${breed}/#${counter}#${breed}suspiciousVVs.${run}.csv
counter=$(echo $counter | awk '{print $1+1}')
#MVcheck
awk '{print $1,"Y"}' $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv  > $TMP_DIR/smpg${breed}/#${counter}#${breed}suspiciousMVs.${run}.csv
counter=$(echo $counter | awk '{print $1+1}')
#externe SNPauftraege
(awk '{print $1,$2}' $TMP_DIR/${breed}.externeSNPLD.lst;
awk '{print $1,$2}' $TMP_DIR/${breed}.externeSNPHD.lst;) | sort -T ${SRT_DIR} -u > $TMP_DIR/smpg${breed}/#${counter}#${breed}EXETERNESNP.lst
counter=$(echo $counter | awk '{print $1+1}')
#snpTwincheck files doppelt lesen da twin1 twin2 im readfile sind
(awk '{print $1,$2}' $RES_DIR/${breed}.SNPtwins.${run}.txt
  awk '{print $2,$1}' $RES_DIR/${breed}.SNPtwins.${run}.txt) > $TMP_DIR/smpg${breed}/#${counter}#${breed}snptwins.${run}.txt
counter=$(echo $counter | awk '{print $1+1}')
awk '{print $1,$3}' $RES_DIR/${breed}.GenomicFcoefficient.${run}.txt | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/smpg${breed}/#${counter}#${breed}.${run}.genF
counter=$(echo $counter | awk '{print $1+1}')
awk '{print $1,$3}' $RES_DIR/${breed}.PedigreeFcoefficient.${run}.txt | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/smpg${breed}/#${counter}#${breed}.${run}.genP



echo " "
RIGHT_END=$(date +"%x %r %Z")
echo $RIGHT_END Ende ${SCRIPT}
