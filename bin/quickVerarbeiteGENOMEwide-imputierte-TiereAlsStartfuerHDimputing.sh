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

#define function to chek when parallel jobs are ready

PRLLRUNcheck () {
#echo ${1};
existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${1}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
fi
done


echo "file to check  ${1}  exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${1} )
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 120 ]; then
    shotresult=same
    echo "${1} is ready now ${RIGHT_NOW}"
 fi
done

}


##############################################################

if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
elif [ $1 == 'BSW' ] || [ $1 == 'HOL' ] ; then
set -o nounset
    breed=$(echo "$1")

    rm -f $TMP_DIR/${breed}LD.fimpute.ergebnis.${run}.*


    echo "cut the SNPs which are in the set of HDsnps. Be careful, they need the same annotation in HDimp as here in 50Kimp"
    #es ist nicht moegich alle 50K SNPs in die HD Imputation zu schicken, da nicht alle 50KSNPs auf dem HDChip sind. Es wuerden also SNPs ins System kommen die in der HD-Referenz fehlen
    join -t' ' -o'1.2' -1 1 -2 1 <(awk '{if(NR > 1) print $1,$4}' $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | sort -T ${SRT_DIR} -t' ' -k1,1) <(awk '{if(NR > 1) print $1,$2}' $HDHIS_DIR/${breed}.RUN${HDfixSNPdatum}snp_info.txt | sort -T ${SRT_DIR} -t' ' -k1,1) | sort -T ${SRT_DIR} -t' ' -k1,1n > $TMP_DIR/${breed}.selectedColsforGTfile

    echo "ich behalte nur tatsaechlich typisierte Tiere, d.h. Tiere die rein an Hand ihrer typisierten Nachkommen imputiert werden sind ausgeschlossen"
    echo " ";
    awk '{if(NR > 1 && $2 > 0) print $1,$2,$3}' $FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt > $TMP_DIR/${breed}.fmptrgb.txt

#aufteilen auf ${numerOfParallelRjobs}
        noofani=$(wc -l $TMP_DIR/${breed}.fmptrgb.txt | awk '{print $1}') 
#achtung trick: immer + 0.5 damit immer auf die nachste ganzzahl aufgerundet wird
        nAniPerRun=$(echo ${noofani} ${numberOfParallelRJobs} | awk '{printf "%.0f", ($1/$2)+0.5}')
        n=0;
        z=$(echo ${n} ${nAniPerRun} | awk -v m=${nAniPerRun} '{print 1+($1*m)}')
#        echo $z $noofani;
        while [ ${noofani} -gt ${z} ] ; do
           echo "now starting ${n} loop";
           startRow=$(echo "1 ${n} ${nAniPerRun}" | awk '{print $1+($2*$3)}')
           endRow=$(echo "${n} 1 ${nAniPerRun}" | awk '{print ($1+$2)*$3}')
           #echo $n $startRow $endRow;
           #cut the SNPs here using an script running in parallel for samples
           nohup ${BIN_DIR}/selectSNPsfromFimputeErgebnis.sh ${breed} ${startRow} ${endRow} ${n} 2>&1 > $LOG_DIR/${SCRIPT}.${breed}.${n}.log  &
           
           #update n and z
           n=$(echo $n | awk '{print $1+1}')
           z=$(echo ${n} ${nAniPerRun} | awk -v m=${nAniPerRun} '{print 1+($1*m)}')
        done

    echo " "
    sleep 180;
    echo "check now if outfiles are ready"
    for np in $(seq 0 $(echo "${numberOfParallelRJobs} 2" | awk '{print $1-$2}')); do
         PRLLRUNcheck $TMP_DIR/${breed}LD.fimpute.ergebnis.${run}.${np}
    done

    echo " "
    echo "collect all files from parallel runs now"
    cat $TMP_DIR/${breed}LD.fimpute.ergebnis.${run}.[0-9]*  > $HD_DIR/${breed}LD.fimpute.ergebnis.${run}


    echo "Transfer der LD Map now"
    (awk '{if(NR == 1) print $1,$2,$3,$4,$5}' $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt ;
    join -t' ' -o'1.1 1.2 1.3 1.4' -1 1 -2 1 <(awk '{if(NR > 1) print $1,$2,$3,$4}' $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | sort -T ${SRT_DIR} -t' ' -k1,1) <(awk '{if(NR > 1) print $1,$2}' $HDHIS_DIR/${breed}.RUN${HDfixSNPdatum}snp_info.txt | sort -T ${SRT_DIR} -t' ' -k1,1) | sort -T ${SRT_DIR} -t' ' -k4,4n | awk '{print $1,$2,$3,"0",NR}')   > $HD_DIR/${breed}LD.fimpute.snp_info.${run}


else
    echo  "Rasse muss entweder BSW oder HOL sein... Prozess wird gestoppt"
fi




echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
