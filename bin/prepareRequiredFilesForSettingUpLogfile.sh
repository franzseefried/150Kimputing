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
if [ ${breed} == "BSW" ]; then
sct=SBZV
fi
if [ ${breed} == "HOL" ]; then
sct="SHSF;SFSH"
fi
if [ ${breed} == "VMS" ]; then
sct="VMS"
fi


if [ ${breed} == "BSW" ]; then outzo=SBZV; fi
if [ ${breed} == "HOL" ]; then outzo=SHSF; fi
if [ ${breed} == "VMS" ]; then outzo=VMS; fi


if ! test -s $WORK_DIR/allExternSamples_forAdding.${run}.txt; then
touch $WORK_DIR/allExternSamples_forAdding.${run}.txt
fi

#LD
for ff in $(ls $WRK_DIR/previousSamplesheets/*.txt); do
awk '{ sub("\r$", ""); print }' ${ff} |\
	sed -n '2,$p' |\
	awk 'BEGIN{FS=";"}{ for(i = 1; i <= NF; i++) { if($i == "") printf "%s%s", "&",";"; else printf "%s%s", $i,";" }printf "\n"}' |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{ if($4 != "&") print $1,$4,$15,$16,$17,$19}' |\
    awk 'BEGIN{FS=";"}{ if($4 == "&") print $1";"$3";"$2";OTHER;"$5";"$6; else print $1";"$3";"$2";"$4";"$5";"$6}' |\
    sort -T ${SRT_DIR} -u |\
    sed 's/ /#/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{if(length($1) != 19 && $19 !~ "[A-Z]") print $0}' |\
    awk 'BEGIN{FS=";"}{print $1,$2,"3228",$4,$5,$6,"ALT"}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1 
done > $TMP_DIR/${breed}LDcrossrefOLD.collecttrack.srt 
awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
    sed -n '2,$p' |\
   	awk 'BEGIN{FS=";"}{ for(i = 1; i <= NF; i++) { if($i == "") printf "%s%s", "&",";"; else printf "%s%s", $i,";" }printf "\n"}' |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{ if($4 != "&") print $1,$4,$15,$16,$17,$19}' |\
    awk 'BEGIN{FS=";"}{ if($4 == "&") print $1";"$3";"$2";OTHER;"$5";"$6; else print $1";"$3";"$2";"$4";"$5";"$6}' |\
    sort -T ${SRT_DIR} -u |\
    sed 's/ /#/g' |\
    awk 'BEGIN{FS=";"}{print $1,$2,"3228",$4,$5,$6,"NEU"}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}LDcrossref.collecttrack.srt

#50K
for ff in $(ls $WRK_DIR/previousSamplesheets/*.txt); do
awk '{ sub("\r$", ""); print }' ${ff} |\
    sed -n '2,$p' |\
   	awk 'BEGIN{FS=";"}{ for(i = 1; i <= NF; i++) { if($i == "") printf "%s%s", "&",";"; else printf "%s%s", $i,";" }printf "\n"}' |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{ if($2 != "&") print $1,$2,$15,$16,$17,$19}' |\
    awk 'BEGIN{FS=";"}{ if($4 == "&") print $1";"$3";"$2";OTHER;"$5";"$6; else print $1";"$3";"$2";"$4";"$5";"$6}' |\
    sort -T ${SRT_DIR} -u |\
    sed 's/ /#/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{if(length($1) != 19 && $19 !~ "[A-Z]") print $0}' |\
    awk 'BEGIN{FS=";"}{print $1,$2,"4024",$4,$5,$6,"ALT"}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1
done > $TMP_DIR/${breed}HDcrossrefOLD.collecttrack.srt 
awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
    sed -n '2,$p' |\
	awk 'BEGIN{FS=";"}{ for(i = 1; i <= NF; i++) { if($i == "") printf "%s%s", "&",";"; else printf "%s%s", $i,";" }printf "\n"}' |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{ if($2 != "&") print $1,$2,$15,$16,$17,$19}' |\
    awk 'BEGIN{FS=";"}{ if($4 == "&") print $1";"$3";"$2";OTHER;"$5";"$6; else print $1";"$3";"$2";"$4";"$5";"$6}' |\
    sort -T ${SRT_DIR} -u |\
    sed 's/ /#/g' |\
    awk 'BEGIN{FS=";"}{print $1,$2,"4024",$4,$5,$6,"NEU"}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1  > $TMP_DIR/${breed}HDcrossref.collecttrack.srt
#F250K
for ff in $(ls $WRK_DIR/previousSamplesheets/*.txt); do
awk '{ sub("\r$", ""); print }' ${ff} |\
    sed -n '2,$p' |\
   	awk 'BEGIN{FS=";"}{ for(i = 1; i <= NF; i++) { if($i == "") printf "%s%s", "&",";"; else printf "%s%s", $i,";" }printf "\n"}' |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{ if($6 != "&") print $1,$6,$15,$16,$17,$19}' |\
    awk 'BEGIN{FS=";"}{ if($4 == "&") print $1";"$3";"$2";OTHER;"$5";"$6; else print $1";"$3";"$2";"$4";"$5";"$6}' |\
    sort -T ${SRT_DIR} -u |\
    sed 's/ /#/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{if(length($1) != 19 && $19 !~ "[A-Z]") print $0}' |\
    awk 'BEGIN{FS=";"}{print $1,$2,"4282",$4,$5,$6,"ALT"}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1 
done > $TMP_DIR/${breed}F250KcrossrefOLD.collecttrack.srt 
awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
    sed -n '2,$p' |\
	awk 'BEGIN{FS=";"}{ for(i = 1; i <= NF; i++) { if($i == "") printf "%s%s", "&",";"; else printf "%s%s", $i,";" }printf "\n"}' |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{ if($6 != "&") print $1,$6,$15,$16,$17,$19}' |\
    awk 'BEGIN{FS=";"}{ if($4 == "&") print $1";"$3";"$2";OTHER;"$5";"$6; else print $1";"$3";"$2";"$4";"$5";"$6}' |\
    sort -T ${SRT_DIR} -u |\
    sed 's/ /#/g' |\
    awk 'BEGIN{FS=";"}{print $1,$2,"4282",$4,$5,$6,"NEU"}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1  > $TMP_DIR/${breed}F250Kcrossref.collecttrack.srt
#777K
for ff in $(ls $WRK_DIR/previousSamplesheets/*.txt); do
awk '{ sub("\r$", ""); print }' ${ff} |\
    sed -n '2,$p' |\
   	awk 'BEGIN{FS=";"}{ for(i = 1; i <= NF; i++) { if($i == "") printf "%s%s", "&",";"; else printf "%s%s", $i,";" }printf "\n"}' |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{ if($3 != "&") print $1,$3,$15,$16,$17,$19}' |\
    awk 'BEGIN{FS=";"}{ if($4 == "&") print $1";"$3";"$2";OTHER;"$5";"$6; else print $1";"$3";"$2";"$4";"$5";"$6}' |\
    sort -T ${SRT_DIR} -u |\
    sed 's/ /#/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{if(length($1) != 19 && $19 !~ "[A-Z]") print $0}' |\
    awk 'BEGIN{FS=";"}{print $1,$2,"3229",$4,$5,$6,"ALT"}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1 
done > $TMP_DIR/${breed}777KcrossrefOLD.collecttrack.srt 
awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
    sed -n '2,$p' |\
	awk 'BEGIN{FS=";"}{ for(i = 1; i <= NF; i++) { if($i == "") printf "%s%s", "&",";"; else printf "%s%s", $i,";" }printf "\n"}' |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' |\
    awk 'BEGIN{FS=";";OFS=";"}{ if($3 != "&") print $1,$3,$15,$16,$17,$19}' |\
    awk 'BEGIN{FS=";"}{ if($4 == "&") print $1";"$3";"$2";OTHER;"$5";"$6; else print $1";"$3";"$2";"$4";"$5";"$6}' |\
    sort -T ${SRT_DIR} -u |\
    sed 's/ /#/g' |\
    awk 'BEGIN{FS=";"}{print $1,$2,"3229",$4,$5,$6,"NEU"}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1  > $TMP_DIR/${breed}777Kcrossref.collecttrack.srt

#AuftragsID SNP-basierte Abstammungskontrolle
for ff in $(ls $WRK_DIR/previousSamplesheets/*.txt); do
awk '{ sub("\r$", ""); print }' ${ff} |\
    sed -n '2,$p' |\
    awk 'BEGIN{FS=";"}{print $1,$24}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1
done > $TMP_DIR/${breed}_SNP_BGA_ID.srt 
awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
    sed -n '2,$p' |\
    awk 'BEGIN{FS=";"}{print $1,$24}' |\
    tr ';' ' ' |\
    sort -T ${SRT_DIR} -t' ' -k1,1  >> $TMP_DIR/${breed}_SNP_BGA_ID.srt 


#ShortcutRunOfDataEntry also das Kuerzel fuer den RUN in dem die probe ins System gekommen ist
awk 'BEGIN{FS=";"}{print FILENAME";"$0}' /qualstore03/data_archiv/SNP/samplemaps/* | tr -s ' ' | tr -s '\t' | tr '\t' ';' > $TMP_DIR/${breed}.samplemaps.smry
for ff in $(ls $WRK_DIR/previousSamplesheets/*.txt); do
awk '{ sub("\r$", ""); print }' ${ff} | awk -v zo=${sct} 'BEGIN{FS=";"}{if(NR > 1 && zo ~ $16) print $1";"}' | sort -T ${SRT_DIR} -t';' -k1,1 | join -t';' -1 1 -2 3 -o'1.1 2.1' - <(sort -T ${SRT_DIR} -t';' -k3,3 $TMP_DIR/${breed}.samplemaps.smry) |\
  while IFS=";"; read sampleID ffile; do
  if ! test -z ${ffile} ;then
    dateiname=$(basename ${ffile} | sed 's/_Sample_Map.txt//g'); 
    rShortcut=$(ls /qualstore03/data_archiv/SNP/checks/*/callingrate.check.${dateiname}* | cut -d'/' -f6 | sort -T ${SRT_DIR} -n | awk '{if(NR == 1) print $1}'); 
    echo $sampleID $rShortcut; 
  fi
done
done > $TMP_DIR/${breed}_ShortcutRunOfDataEntry.txt
awk '{ sub("\r$", ""); print }' $WRK_DIR/currentSamplesheet/$crossreffile | awk 'BEGIN{FS=";"}{if(NR > 1 && zo ~ $16) print $1";"}' | sort -T ${SRT_DIR} -t';' -k1,1 | join -t';' -1 1 -2 3 -o'1.1 2.1' - <(sort -T ${SRT_DIR} -t';' -k3,3 $TMP_DIR/${breed}.samplemaps.smry) |\
  while IFS=";"; read sampleID ffile; do
  ffile=$(awk -v ssIIdd=${sampleID} 'BEGIN{FS=";"}{if($0 ~ ssIIdd) print FILENAME}' /qualstore03/data_archiv/SNP/samplemaps/*)
  if ! test -z ${ffile} ;then
     dateiname=$(basename ${ffile} | sed 's/_Sample_Map.txt//g'); 
     rShortcut=$(ls /qualstore03/data_archiv/SNP/checks/*/callingrate.check.${dateiname}* | cut -d'/' -f6 | sort -T ${SRT_DIR} -n | awk '{if(NR == 1) print $1}'); 
     echo $sampleID $rShortcut; 
  fi
done >> $TMP_DIR/${breed}_ShortcutRunOfDataEntry.txt



for i in $TMP_DIR/smllg${breed} $TMP_DIR/chcks${breed}; do if test -d ${i} ; then rm -rf ${i} ; fi; done
mkdir -p $TMP_DIR/smllg${breed}
mkdir -p $TMP_DIR/chcks${breed}
#sampleID fuer Probentracking , achtung wenn uerbelappung der selben tvd auf alter und neuer versand laeuft das hier nicht richtig
(awk '{ sub("\r$", ""); print }' $WRK_DIR/previousSamplesheets/*.txt |\
        sed -n '2,$p' |\
    cut -d';' -f1,15 ;
awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
    sed -n '2,$p' |\
cut -d';' -f1,15) | sed 's/ /#/g' | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}probentrackingID.srt


rm -f $TMP_DIR/TiereMitGenotypOhnePedigree${run}.srt


for ffile in $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${run}.csv $ZOMLD_DIR/${breed}_MUTTERproblem-OHNEoderMULTImatch_daherKEINimputing.csv $ZOMLD_DIR/${breed}_VATERproblem-OHNEoderMULTImatch_daherKEINimputing.csv $ZOMLD_DIR/${breed}_KorrektuerenVATER.csv $ZOMLD_DIR/${breed}_KorrektuerenMUTTER.csv $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv $ZOMLD_DIR/${breed}_suspiciousVVs.${run}.csv; do
  if ! test -s ${ffile}; then
    touch ${ffile}
  fi
done
#defintion eines zaehlers damit hinter her im LOOPJoin sortiert werde kann. Achtung so wie gejoint wird muessen sie hier sortiert sein && nur 2 spalten, wenn also mehr als 2 Spalten benoetigt werden muessen mehrere files ausgelesen werden
#ausserdem wird hier definiert war wie es im Logfile codiert ist. z.B. "Y"
counter=1
#Imputationsergebnis
awk '{if($2 > 0) print $1,"+"}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis > $TMP_DIR/smllg${breed}/#${counter}#${breed}impres.${oldrun}
counter=$(echo $counter | awk '{print $1+1}')
awk '{if($2 > 0) print $1,"+"}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis  > $TMP_DIR/smllg${breed}/#${counter}#${breed}impres.${run}
counter=$(echo $counter | awk '{print $1+1}')
#ohne pedigree
awk 'BEGIN{FS=";"}{if( $2 == "NoPedigreeRecord") print $1,"-"}' $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${run}.csv > $TMP_DIR/smllg${breed}/#${counter}#${breed}TiereMitGenotypOhnePedigree${run}.srt
counter=$(echo $counter | awk '{print $1+1}')
#MultiMatch
for i in VATER MUTTER; do
    cat $ZOMLD_DIR/${breed}_${i}problem-OHNEoderMULTImatch_daherKEINimputing.csv | awk '{if($3 == "MultiMatch") print $1,"Y"}' >  $TMP_DIR/smllg${breed}/#${counter}#${breed}${i}MULTI.srt
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
    (cat $ZOMLD_DIR/${breed}_${i}problem-OHNEoderMULTImatch_daherKEINimputing.csv | awk '{if($3 == "OhneMatch") print $1,"Y"}' 
    awk -v ff=${flg} 'BEGIN{FS=";"}{if($3 == ff) print $1,"Y"}' $ZOMLD_DIR/${breed}.TiereMitUnbekanntemElter_KEINEimputation.csv ) | sort -T ${SRT_DIR} -u >  $TMP_DIR/smllg${breed}/#${counter}#${breed}UnbekElter${i}.srt
    counter=$(echo $counter | awk '{print $1+1}')
done
#Vater & Mutterkorrekturen 2x benoetigt
for i in VATER MUTTER; do
j=2;
for j in 2 4; do
	cat $ZOMLD_DIR/${breed}_Korrektueren${i}.csv | tr ';' ' ' | cut -d' ' -f1,${j} > $TMP_DIR/smllg${breed}/#${counter}#${breed}${i}korrekturen${j}.srt
	counter=$(echo $counter | awk '{print $1+1}')
done
done
#Typisierungssituation 4x benoetigt
j=2
for j in 2 4 6 8; do
	cat $RES_DIR/${breed}TypiSituationVMMV_${run}.txt | sed 's/UUUUUUUUUUUUUU/-/g' | cut -d' ' -f1,${j} > $TMP_DIR/smllg${breed}/#${counter}#${breed}Typi${j}.stat
	counter=$(echo $counter | awk '{print $1+1}')
done
#MVcheck
awk '{print $1,"Y"}' $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv  > $TMP_DIR/smllg${breed}/#${counter}#${breed}suspiciousMVs.${run}.csv
counter=$(echo $counter | awk '{print $1+1}')
#private externe SNPauftraege ACHTUNG Bug korrigiert 27.09.2017 und filename geaendert von externeSNPLD.lst zu externeSNP.lst
awk -v outo=${outzo} 'BEGIN{FS=";"}{if($16 == outo && $4 == "X") print $15,"3228";if($16 == outo && $2 == "X") print $15,"4024";if($16 == outo && $3 == "X") print $15,"3229";if($16 == outo && $6 == "X") print $15,"4282"}' $WRK_DIR/allExternSamples_forAdding.${run}.txt > $TMP_DIR/smllg${breed}/#${counter}#${breed}private.externeSNP.lst
counter=$(echo $counter | awk '{print $1+1}')
join -t' ' -o'1.1 1.2' -v1 -1 1 -2 1 <(awk '{if($2 == 0) print $1,"Y"}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis | sort -T ${SRT_DIR} -t' ' -k1,1 ) <(awk '{if($2 == 0) print $1,"Y"}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis | sort -T ${SRT_DIR} -t' ' -k1,1) > $TMP_DIR/smllg${breed}/#${counter}#${breed}pedigreeImputiert.lst
counter=$(echo $counter | awk '{print $1+1}')
#snpTwincheck files doppelt lesen da twin1 twin2 im readfile sind
(awk '{print $1,$2}' $RES_DIR/${breed}.SNPtwins.${run}.txt
  awk '{print $2,$1}' $RES_DIR/${breed}.SNPtwins.${run}.txt) > $TMP_DIR/smllg${breed}/#${counter}#${breed}snptwins.${run}.txt
counter=$(echo $counter | awk '{print $1+1}')
for srun in ${run} ${oldrun} ${old2run} ${old3run} ${old4run} ${old5run} ${old6run} ${old7run} ${old8run} ${old9run}; do
sed 's/\;/ /g' ${ZOMLD_DIR}/${srun}.BADsexCheck.lst ;
done | awk '{print $1,$7}' > $TMP_DIR/smllg${breed}/#${counter}#${breed}all.badsex.lst 
counter=$(echo $counter | awk '{print $1+1}')
(awk '{print $1,$2}' $TMP_DIR/${breed}.NEWexterneSNPHD.${run}.lst;
awk '{print $1,$2}' $TMP_DIR/${breed}.NEWexterneSNPLD.${run}.lst) > $TMP_DIR/smllg${breed}/#${counter}#${breed}routinekaneleExterneSNP.lst
counter=$(echo $counter | awk '{print $1+1}')
#VVcheck
awk '{print $1,"Y"}' $ZOMLD_DIR/${breed}_suspiciousVVs.${run}.csv > $TMP_DIR/smllg${breed}/#${counter}#${breed}suspiciousVVs.${run}.csv





#qualichecks eigene Proben Geneseek lese an anderen Ort aus da sie anderst gejoint werden muessen
for i in gcscore callingrate heterorate; do 
j=$(echo $i | cut -b1-3);
k=$(echo $j | awk '{print "_-"$1}')

for srun in ${run} ${oldrun} ${old2run} ${old3run} ${old4run} ${old5run} ${old6run} ${old7run} ${old8run} ${old9run}; do
awk '{if($3 == "") print $1,$2,"+",FILENAME; else print $0,FILENAME}' $CHCK_DIR/${srun}/${i}.check.* ;
done | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/smllg${breed}/${breed}${i}.check.srt

#hole geneseek haarkartennummer join via TVD;GeneSeekFile
awk '{print $4}' $TMP_DIR/smllg${breed}/${breed}${i}.check.srt | sort -T ${SRT_DIR} -u | while read filename; do basename ${filename} | cut -d'.' -f3 | sed 's/_FinalReport//g' ; done > $TMP_DIR/smllg${breed}/${breed}${j}.lst

while read fname; do if test -s ${SMP_DIR}/${fname}_Sample_Map.txt; then awk -v ff=${fname} '{print $1,$2,$3,$4,$5,$6,$7,ff}' ${SMP_DIR}/${fname}_Sample_Map.txt ; fi ; done < $TMP_DIR/smllg${breed}/${breed}${j}.lst | sort -T ${SRT_DIR} -t' ' -k2,2 |\

join -t' ' -o'1.2 2.2 1.8' -1 2 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}probentrackingID.srt) | sed 's/ /\;/2' > $TMP_DIR/smllg${breed}/${breed}${k}.lst

awk '{l=split($4,a,".")} {print $1";"a[3],$2,$3}' $TMP_DIR/smllg${breed}/${breed}${i}.check.srt | sed 's/_FinalReport//g' |sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'2.1 1.1 1.2 1.3' -1 1 -2 2 - <(sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/smllg${breed}/${breed}${k}.lst )| awk '{l=split($2,a,";")} {print $1";"a[1],$3,$4}' | tr ';' ' ' | sed 's/OOOPS/NOT\-OK/g' > $TMP_DIR/chcks${breed}/${breed}join.${i}.check.srt

rm -f $TMP_DIR/smllg${breed}/${breed}${j}.lst; rm -f $TMP_DIR/smllg${breed}/${breed}${k}.lst; rm -f $TMP_DIR/smllg${breed}/${breed}${i}.check.srt;
done




#qualichecks single external Proben ohne GeneSeek lese an anderen Ort aus da sie anderst gejoint werden muessen. nur deie aus dem aktuellen run!!!
for i in gcscore callingrate heterorate; do 
j=$(echo $i | cut -b1-3);
k=$(echo $j | awk '{print "_-"$1}')

srun=${run}
awk '{if($3 == "") print $1,$2,"+",FILENAME; else print $0,FILENAME}' $CHCK_DIR/${srun}/${i}.check.* | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/smllg${breed}/${breed}${i}.check.srt

#hole geneseek haarkartennummer join via TVD;GeneSeekFile
awk '{print $4}' $TMP_DIR/smllg${breed}/${breed}${i}.check.srt | sort -T ${SRT_DIR} -u | while read filename; do basename ${filename} | cut -d'.' -f3 | sed 's/_FinalReport//g' ; done > $TMP_DIR/smllg${breed}/${breed}${j}.lst

while read fname; do if ! test -s ${SMP_DIR}/${fname}_Sample_Map.txt; then cat $TMP_DIR/smllg${breed}/${breed}${i}.check.srt | grep  ${fname}| tr ' ' ';' | sort -T ${SRT_DIR} -t';' -k1,1 | join -t';' -o'2.1 1.1' -1 1 -2 15 - <(sort -T ${SRT_DIR} -t';' -k15,15 $WORK_DIR/crossref.txt) | tr ';' ' ' |\
awk -v ff=${fname} '{print "Z",$1,$2,"Z","Z","Z","Z",ff}'; fi ; done < $TMP_DIR/smllg${breed}/${breed}${j}.lst | sort -T ${SRT_DIR} -t' ' -k2,2 |\

join -t' ' -o'1.2 2.2 1.8' -1 2 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}probentrackingID.srt) | sed 's/ /\;/2' > $TMP_DIR/smllg${breed}/${breed}${k}.lst

awk '{l=split($4,a,".")} {print $1";"a[3],$2,$3}' $TMP_DIR/smllg${breed}/${breed}${i}.check.srt | sed 's/_FinalReport//g' |sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'2.1 1.1 1.2 1.3' -1 1 -2 2 - <(sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/smllg${breed}/${breed}${k}.lst )| awk '{l=split($2,a,";")} {print $1";"a[1],$3,$4}' | tr ';' ' ' | sed 's/OOOPS/NOT\-OK/g' >> $TMP_DIR/chcks${breed}/${breed}join.${i}.check.srt

rm -f $TMP_DIR/smllg${breed}/${breed}${j}.lst; rm -f $TMP_DIR/smllg${breed}/${breed}${k}.lst; rm -f $TMP_DIR/smllg${breed}/${breed}${i}.check.srt;

done


#ebenfalls anderen orts auslesen
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | grep -v "kein Tier mit der ID" | awk 'BEGIN{FS=";"}{print $2,$1,$1,$3}' > $TMP_DIR/${breed}join.animalinfo.join



#NEUE pedigreeImputierte Tiere ebenfalls anderen Ort auslesen da sie dann einfach angehaengt werden
awk -v razza=${breed} '{if($2 == 0) print $1,razza}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}pedigree.imputiert.${run}.tmp
#pedigreeImputierte Tiere
awk -v razza=${breed} '{if($2 == 0) print $1,razza}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}pedigree.imputiert.${oldrun}.txt
join -t' ' -o'1.1 1.2' -1 1 -2 1 -v1 $TMP_DIR/${breed}pedigree.imputiert.${run}.tmp $TMP_DIR/${breed}pedigree.imputiert.${oldrun}.txt |\
   awk -v outo=${outzo} -v razza=${breed} '{if($2 == razza) print $1,outo; else print $1,"ooops"}' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}pedigree.imputiert.${run}.txt



echo " "
RIGHT_END=$(date +"%x %r %Z")
echo $RIGHT_END Ende ${SCRIPT}
