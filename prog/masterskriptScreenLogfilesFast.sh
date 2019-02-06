#!/bin/bash
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS "
    exit 1
elif [ ${1} == "BSW" ]; then
	echo $1 > /dev/null
        zodr=sbzv
elif [ ${1} == "HOL" ]; then
	echo $1 > /dev/null
        zodr=swissherdbook
elif [ ${1} == "VMS" ]; then
        echo $1 > /dev/null
        zodr=mutterkuh
else
	echo " $1 != BSW / HOL / VMS, ich stoppe"
	exit 1
fi

if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}
fi


#check Server
ort=$(uname -a | awk '{print $1}' )
if  [ ${ort} == "Darwin" ]; then
   echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
   $BIN_DIR/sendErrorMail.sh ${SCRIPT} $1
elif [ ${ort} == "Linux" ]; then
##################################
echo "Keyoutput from 7 for $1" > $WRK_DIR/${1}.LogScreening.${run}.log
cat $LOG_DIR/7masterskriptFimputeRunStandard_${1}.log >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo "Keyoutput from SumUpComparison for ${1} " >> $WRK_DIR/${1}.LogScreening.${run}.log
cat $LOG_DIR/${1}.SumUpComparison.log >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo "Keyoutput from NewSameplSummary for ${1} " >> $WRK_DIR/${1}.LogScreening.${run}.log
cat $LOG_DIR/${1}.NewSampleSummary.log >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo "Keyoutput from FastCheckLOGfirectory for ${1} " >> $WRK_DIR/${1}.LogScreening.${run}.log
$BIN_DIR/fastCheckLOGdirectory.sh ${1} >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
if [ ${1} != "VMS" ]; then
echo "Keyoutput from fastCheckSingleLocusHaplotyping for ${1} " >> $WRK_DIR/${1}.LogScreening.${run}.log
$PROG_DIR/fastCheckSingleLocusHaplotyping.sh ${1} >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
fi
echo "count no of Result-Records comparing last two runs:" >> $WRK_DIR/${1}.LogScreening.${run}.log
wc -l $HIS_DIR/${1}.RUN${oldrun}.IMPresult.tierlis >> $WRK_DIR/${1}.LogScreening.${run}.log
wc -l $HIS_DIR/${1}.RUN${run}.IMPresult.tierlis >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo "Overview about Genotypes of single markers that will be stored in ARGUS" >> $WRK_DIR/${1}.LogScreening.${run}.log
if [ "$(ls -A $DEUTZ_DIR/${zodr}/dsch/in/${run})" ]; then
for filee in $(ls $DEUTZ_DIR/${zodr}/dsch/in/${run}/*.dat); do 
awk 'BEGIN{FS=";"}{print $2}' $filee | sort | uniq -c | awk '{print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k1,1nr | awk -v ff=${filee} '{printf "%-8s%-10s%-100s\n", $1,$2,ff }';
done >> $WRK_DIR/${1}.LogScreening.${run}.log
else
echo "directory $DEUTZ_DIR/${zodr}/dsch/in/${run} is empty ---> check" >> $WRK_DIR/${1}.LogScreening.${run}.log
fi
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo " " >> $WRK_DIR/${1}.LogScreening.${run}.log
echo "Count proportion of NULL and NOTOK results for each samplesheet:" >> $WRK_DIR/${1}.LogScreening.${run}.log
echo "Note: samples included in second youngest file in ${WRK_DIR}/previousSamplesheets without result will be feedbacked by NEW SAMPLE REQUIRED" >> $WRK_DIR/${1}.LogScreening.${run}.log
for ifile in $(ls ${WRK_DIR}/previousSamplesheets/*.txt);do
$BIN_DIR/checkSamplesWithNULLresponse.sh -f ${ifile} -b ${1} >> $WRK_DIR/${1}.LogScreening.${run}.log
done
for ifile in $(ls ${WRK_DIR}/currentSamplesheet/*.txt);do
$BIN_DIR/checkSamplesWithNULLresponse.sh -f ${ifile} -b ${1} >> $WRK_DIR/${1}.LogScreening.${run}.log
done
echo "Be happy since you have reached to the end of ${SCRIPT}" >> $WRK_DIR/${1}.LogScreening.${run}.log
mv $WRK_DIR/${1}.LogScreening.${run}.log $LOG_DIR/${1}.LogScreening.${run}.log
$BIN_DIR/sendAttentionMailAboutFinalLogSummary.sh ${1}
fi
echo " "
RIGHT_END=$(date)
echo RIGHT_END Ende ${SCRIPT}
