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
elif [ $1 == 'BSW' ] || [ $1 == 'HOL' ]  || [ $1 == 'VMS' ]; then
set -o nounset
    breed=$(echo "$1")


#test if current system is identical with previous system
ARR2=$(awk '{if(NR > 1)print $1}' $HIS_DIR/${breed}.RUN${oldrun}snp_info.txt | tr '\n' ' ' )
ARR3=$(awk '{if(NR > 1)print $1}' ${FIM_DIR}/${breed}BTAwholeGenome.out/snp_info.txt |tr '\n' ' ' )
ARR1=$(awk '{if(NR > 1)print $1}' $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt |tr '\n' ' ' )
A=${ARR1[@]};
B=${ARR2[@]};
C=${ARR3[@]};
if [ "$A" == "$B" ] && [ "$A" == "$C" ] ; then
    echo "Current SNPsytem is identical with previous one -> ready for fast comparison" ;
else
   if [ "$A" == "$B" ];then
      echo "oldrun $oldrun SNPsytem differs from $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt"
   fi
   if [ "$A" == "$C" ];then
     echo "current SNPsytem differs from $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt"
   fi
   exit 1
fi;




    cut -d' ' -f1,5 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/${breed}id1id2.reftab
#if false; then
    #definiere Schnittmenge Tiere die sowohl im aktuelle Monat als auch im Vormonat LD-Tiere waren
    join -t' ' -o'1.1 1.2 2.2' -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis) <(sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis) | awk '{if($2 == 2 && $3 == 2) print $1,"LD"}' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.imputierteLDtiere.schnittmenge
    join -t' ' -o'1.1 1.2 2.2' -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis) <(sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis) | awk '{if($2 == 1 && $3 == 1) print $1,"DB" }' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.imputierteHDtiere.schnittmenge
    join -t' ' -o'1.1 1.2 2.2' -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis) <(sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis) | awk '{if($2 == 0 && $3 == 0) print $1,"P" }' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.imputierteUNGENOTYPEDtiere.schnittmenge
#fi
#ableiten des Chipstatus ausgehend vom Parameter im parameterfile
if [ -z ${compImp} ]; then
   echo "ooops ${compImp} is missing in Parameterfile"
   exit 1
else
if [ ${compImp} -eq 3 ]; then
   chipstatusset="2 1 0"
elif [ ${compImp} -eq 2 ]; then
   chipstatusset="2 0"
elif [ ${compImp} -eq 1 ]; then
   chipstatusset="2"
else
   echo "ooops komischer Code fuer ${compImp} im Parameterfile"
   exit 1
fi
fi


    for t in ${chipstatusset}; do
#    for t in 2 0 1; do
	if [ ${t} == '2' ]; then
	    vglfile=imputierteLDtiere
	elif [ ${t} == '0' ]; then
	    vglfile=imputierteUNGENOTYPEDtiere
    elif [ ${t} == '1' ]; then
        vglfile=imputierteHDtiere
	else
	    echo oops komischer Code
	    exit 1
	fi

	#aktuelles Ergebnis
	awk -v code=${t} '{if($2 == code)print $1,$3}' $FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt > $TMP_DIR/${breed}.result.${t}
	$BIN_DIR/awk_umkodierungID1zuID2 $TMP_DIR/${breed}id1id2.reftab  $TMP_DIR/${breed}.result.${t} >  $HIS_DIR/${breed}.RUN${run}.result.${vglfile}.TVD
	Nsnp=$(wc -l $HIS_DIR/${breed}.RUN${run}snp_info.txt | awk '{print $1}')
	thresholdToBeBad=$(echo ${Nsnp} | awk -v p=${propBad} '{printf "%8.0f\n", $1*p}' | awk '{print $1}')
	readableProb=$(echo ${propBad} | awk '{print $1*100}')
#    done
#fi
#exit 1
    rm -f  $TMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}
 #   for tiere in imputierteLDtiere imputierteUNGENOTYPEDtiere ; do
#    for tiere in ${vglfile} ; do
	($BIN_DIR/awk_grepTIEREvonFILE $TMP_DIR/${breed}.${vglfile}.schnittmenge $HIS_DIR/${breed}.RUN${run}.result.${vglfile}.TVD | awk -v dat=${run} '{print $1,dat,$2}'
	 $BIN_DIR/awk_grepTIEREvonFILE $TMP_DIR/${breed}.${vglfile}.schnittmenge $HIS_DIR/${breed}.RUN${oldrun}.result.${vglfile}.TVD | awk -v dat=${oldrun} '{print $1,dat,$2}') > $TMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}
 #   done > $TMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}


    awk '{print $1}' $TMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun} | sort | uniq -c | awk '{if($1 != 2) print $2}' > $TMP_DIR/LD.rm.tiere
    grep -v -f $TMP_DIR/LD.rm.tiere  $TMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun} |  sort -T ${SRT_DIR} -t' ' -k1,1 -k2,2nr -T ${SRT_DIR} >  $HIS_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}


    rm -f $HIS_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.out
    #run R here:
    Rscript $BIN_DIR/readAndCompareFimputeResult_lineBYline.R ${PAR_DIR}/steuerungsvariablen.ctr.sh $HIS_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}

    (echo "Tier Run NdiffSNP_${run}_-_${oldrun} currentITBbreed currentAni_race_id Kurzname";
       sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.out |\
       join -t' ' -o'1.1 1.2 1.3 2.2 2.4 2.3' -1 1 -2 1 -a1 -e'-' - <(awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f2,3,4,11 | sed 's/ //g' | tr ';' ' ' | awk '{print $1,substr($2,1,3),$3,$4}' | sort -T ${SRT_DIR} -t' ' -k1,1) |\
       sort -T ${SRT_DIR} -t' ' -k3,3nr  ) > $RES_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.lst

    echo "Check list $RES_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.lst:"
    echo "here are the top bad samples for ${vglfile}:"
    nbad=$(awk -v BAD=${thresholdToBeBad} '{if($3 > BAD) print $1}' $RES_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.lst | wc -l | awk '{print $1}' )
    if [ ${nbad} -gt 10 ]; then
       echo "Es gibt ${nbad} ${vglfile} Tiere mit mehr als ${readableProb}% GenotypMutationen im Vergleich zur ${oldrun} Imputation:"
       nnbad=$(echo ${nbad} | awk '{print $1+5}')    
       head -${nnbad}  $RES_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.lst | awk '{printf "%-20s%-10s%+15s%+20s%+30s%+30s\n", $1,$2,$3,$4,$5,$6}'
    else
       echo "Es gibt mehr als 11 ${vglfile} Tiere mit mehr als ${readableProb}% GenotypMutationen im Vergleich zur ${oldrun} Imputation:"
       head $RES_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.lst | awk '{printf "%-20s%-10s%+15s%+20s%+30s%+30s\n", $1,$2,$3,$4,$5,$6}'
    fi
    rm -f $HIS_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}
    #rm -f $HIS_DIR/${breed}.RUN${run}.result.${vglfile}.TVD
    rm -f $HIS_DIR/${breed}.RUN${old3run}.result.${vglfile}.TVD
    done
 
   rm -f $TMP_DIR/${breed}id1id2.reftab
   rm -f $TMP_DIR/${breed}.imputierteLDtiere.schnittmenge
   rm -f $TMP_DIR/${breed}.imputierteHDtiere.schnittmenge
   rm -f $TMP_DIR/${breed}.imputierteUNGENOTYPEDtiere.schnittmenge
   rm -f $TMP_DIR/${breed}.result.[0-9]
   rm -f $TMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}
   rm -f $TMP_DIR/LD.rm.tiere
    
else
    echo "komischer breedcode :-("
    exit 1
fi

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
