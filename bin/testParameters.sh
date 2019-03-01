#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
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
elif [ ${1} == "HOL" ]; then
        echo $1 > /dev/null
elif [ ${1} == "VMS" ]; then
        echo $1 > /dev/null
else
        echo " $1 != BSW / HOL / VMS, ich stoppe"
        exit 1
fi
breed=${1}

#make directories
mkdir -p ${WORK_DIR}
mkdir -p ${FIM_DIR}
mkdir -p ${CHCK_DIR}/${run}
mkdir -p ${BVCH_DIR}/${run}
mkdir -p ${SHB_DIR}/${run}
mkdir -p ${VMS_DIR}/${run}
mkdir -p $BCP_DIR/${run}/binaryfiles

if [ ${snpstrat} == "S" ] && [ ${ReadGenotypes} == "B" ]; then
   echo "Given Arguments do not make sense"
   echo "SNPstrategie was defined as:      ${snpstrat}"
   echo "ReadGenotypes was defined as:     ${ReadGenotypes}"
   $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
   exit 1
fi
if [ -z ${compImp} ]; then
   echo "Paraeter ${compImp} is missing in Parameterfile"
   exit 1
fi
#check Server
ort=$(uname -a | awk '{print $1}' )
if  [ ${ort} == "Darwin" ]; then
   echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
   $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
   exit 1
fi
#check that animal.overall.info is younger than 5 hours
if test "`find $WORK_DIR/animal.overall.info -mmin +700`"; then 
   echo "$WORK_DIR/animal.overall.info is too old. Rerun PROG_DIR/design.forInfofile.sh";
   $BIN_DIR/sendErrorMail.sh ${SCRIPT} ${1}; 
   exit 1;
fi


#test some files which are needed if they exist
for ifile in ${REFTAB_FiRepTest} ${REFTAB_SiTeAr} ${EINZELGENMAPFILEFROMFINALRP} ${SSNPSiGeTe} ${ISAGPARENTAGESBOLIST} ${REFTAB_CHIPS}; do
   if ! test -s ${ifile}; then echo "${ifile} does not exist or has sitze zero"; $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}; exit 1; fi
done

#test if parameters which need to be without alphanumeric signs are without alphabetical signs
for ipar in ${GWASmaf} ${GWASgeno} ${GWASmind} ${GWAShwe} ${MaxLthHTL} ${relshipthreshold} ${AIMSAMPLESIZE} ${propBad} ${compImp} ${minchipstatus} ${maxAllowedRelship} ${YthrldM} ${YthrldF} ${PARthrld} ${ISAGCLRT} ${BADISAG} ${blutanteilsgrenze} ${minplausibleMVrelship} ${minInbreedOnMVrelship} ${gnrmcoeffTWINS} ${numberOfParallelHAPLOTYPEJobs} ${numberOfParallelSIGEIMPJobs} ${CLLRT} ${HTRT} ${GCSCR} ${fixSNPdatum} ${HDfixSNPdatum} ;do
#https://unix.stackexchange.com/questions/92445/bash-script-check-if-a-variable-is-in-a-z
re='[a-zA-Z]'
if [[ "${ipar}" =~ $re ]]; then
  echo "INVALID PARAMETER ${ipar} from ${lokal}/parfiles/steuerungsvariablen.ctr.sh "
  $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
  exit 1
fi
done

#test parameter HDimputing
if [ -z ${HDfollows} ]; then echo "Parameter HDfollows fehlt"; $BIN_DIR/sendErrorMail.sh CheckParameter HDfollows; exit 1; fi
if [ ${HDfollows} != "Y" ] && [ ${HDfollows} != "N" ]; then echo Parameter HDfollows falsch angegeben, must be Y or N; $BIN_DIR/sendErrorMail.sh CheckParameter HDfollows;exit 1;fi

#GWAS HFT paramaters tested
if [ ${GWASsetofANIS} != "HD" ] && [ ${GWASsetofANIS} != "LD" ]; then
  echo "INVALID PARAMETER ${GWASsetofANIS} from ${lokal}/parfiles/steuerungsvariablen.ctr.sh "
  $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
  exit 1
fi
if [ ${HFTSNPSET} != "HD" ] && [ ${HFTSNPSET} != "LD" ]; then
  echo "INVALID PARAMETER ${HFTSNPSET} from ${lokal}/parfiles/steuerungsvariablen.ctr.sh "
  $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
  exit 1
fi


#loeschen von Abfragefiles falls ein run wiederholt wird
for ifile in $TMP_DIR/${breed}HD.bed $TMP_DIR/${breed}LD.bed ; do
  if test -s ${ifile}; then
     echo "loeschen von ${ifile} da es existiert"
     rm -f ${ifile}
   fi
done

if test -s $LOG_DIR/${breed}.LogScreening.${run}.log; then rm $LOG_DIR/${breed}.LogScreening.${run}.log; fi 
if test -s $RES_DIR/${breed}.GenomicFcoefficient.${run}.txt; then rm $RES_DIR/${breed}.GenomicFcoefficient.${run}.txt;fi 
if test -s $RES_DIR/${breed}.PedigreeFcoefficient.${run}.txt; then rm $RES_DIR/${breed}.PedigreeFcoefficient.${run}.txt;fi
if test -s $ZOMLD_DIR/${breed}.higher.SNPtwins.gcta.${run}.txt; then rm $ZOMLD_DIR/${breed}.higher.SNPtwins.gcta.${run}.txt; fi
if test -s $ZOMLD_DIR/${breed}.lower.SNPtwins.gcta.${run}.txt; then rm $ZOMLD_DIR/${breed}.lower.SNPtwins.gcta.${run}.txt; fi
if test -s $ZOMLD_DIR/${breed}_suspiciousVVs.${run}.csv; then rm $ZOMLD_DIR/${breed}_suspiciousVVs.${run}.csv; fi
if test -s $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv; then rm $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv; fi
if test -s $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis; then rm $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis; fi
#anlegen von sexcheck falls es nicht existiert
if ! test -s $ZOMLD_DIR/${run}.BADsexCheck.lst; then touch  $ZOMLD_DIR/${run}.BADsexCheck.lst; fi
#echo "Make directory for CHECKLogs from CurrentIMPRUN falls ohne neue Proben ein run laeuft und kopiere dann de alten ins neue directory snst geht die Info im Logfile verloren"
if test -d ${CHCK_DIR}/${run} ; then mkdir -p ${CHCK_DIR}/${run} ;fi
#echo "make Run-Directory fuer Einzelgenfiles falls ohne neue Proben ein run laeuft" 
mkdir -p $RES_DIR/${run}
mkdir -p ${DEUTZ_DIR}/swissherdbook/dsch/in/${run}
mkdir -p ${DEUTZ_DIR}/mutterkuh/dsch/in/${run}
mkdir -p ${DEUTZ_DIR}/sbzv/dsch/in/${run}


for ifile in $WRK_DIR/UniBernGenotypes.csv $WRK_DIR/Lager_20140131_Swissgenetics.txt  $WRK_DIR/SeqStiere_ZuordnungStatistik.csv  $WRK_DIR/Lager_20141127_Droegemueller.rebuilt.txt  $WRK_DIR/1000BullGenomesAnimalListDistRun6-Taurus-20170314.csv  $WRK_DIR/OB_ETH_StiereSequenziert.txt   $WRK_DIR/CHE_CDDRcons_ForSequencingSelection_available_fin.txt ; do
if ! test -s ${ifile}; then
echo "file ${ifile} is required but does not exist or has size zero"
exit 1
fi
done

getColmnNr FwdGTpredictionToARGUS ${REFTAB_SiTeAr} ; colFORWARDARGUS=$colNr_
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colCode=$colNr_
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colPA=$colNr_
TestsToBeExtracted=$(awk -v a=${colEXG} -v b=${colGSB} 'BEGIN{FS=";"}{if($a == "Y" ) print $b}' ${REFTAB_SiTeAr} )
for iTestsToBeExtracted in ${TestsToBeExtracted}; do
   algorithm=$(awk -v a=${colCode} -v b=${iTestsToBeExtracted} -v f=${algo} '{FS=";"} {if ($a == b) print $f}' ${REFTAB_SiTeAr})
   forwardToArgus=$(awk -v a=${colCode} -v b=${iTestsToBeExtracted} -v f=${colFORWARDARGUS} '{FS=";"} {if ($a == b) print $f}' ${REFTAB_SiTeAr})
   if [ ${forwardToArgus} == "Y"  ] && [ ! -s ${SNP_DIR}/einzelgen/argus/glossar/${iTestsToBeExtracted}.${algorithm}.Interpretation.txt ]; then echo "ERROR: GTprediction should be forwarded to ARGUS for ${iTestsToBeExtracted} but no Reference Table ${SNP_DIR}/einzelgen/argus/glossar/${iTestsToBeExtracted}.${algorithm}.Interpretation.txt exists";echo " "; exit 1; fi
done





echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

