#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`

#######################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
#######################################################
if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}
fi
set -o nounset
set -o errexit
LOGFILE=$(echo $SCRIPT | awk -v LL=${LOG_DIR} 'BEGIN{FS="."}{print LL"/"$1".log"}')
echo $RIGHT_NOW Start ${SCRIPT} >> ${LOGFILE}
echo " " >> ${LOGFILE}


ort=$(uname -a | awk '{print $1}' )
if [ ${ort} == "Darwin" ]; then
    echo "change entweder zu eiger, titlis, beverin oder castor" >> ${LOGFILE}
    exit 1
elif [ ${ort} == "Linux" ]; then
  maschine=$(uname -a | awk '{print $2}'  | cut -d'.' -f1)
  if [ ${maschine} == "titlis" ]; then
    linkaufloesung="/qualstore03"
  elif [ ${maschine} == "beverin" ]; then
    linkaufloesung="/qualstore03"
  elif [ ${maschine} == "castor" ]; then
    linkaufloesung="/qualstorzws01"
  elif [ ${maschine} == "speer" ]; then
    linkaufloesung="/qualstorzws01"
  elif [ ${maschine} == "eiger" ]; then
    linkaufloesung="/qualstorzws01"
  else
    echo "unknonw server" >> ${LOGFILE}
    exit 1
  fi
else
  echo "oops komisches Betriebssystem ich stoppe" >> ${LOGFILE}
  exit 1
fi


if [ -z ${ReadGenotypes} ];then echo "...OOOPS: Variable ReadGenotypes is empty: check ${lokal}/parfiles/steuerungsvariablen.ctr.sh" >> ${LOGFILE}; exit 1; fi
if [ ${ReadGenotypes} != "A" ] && [ ${ReadGenotypes} != "B" ]; then echo "...OOOPS: Variable ReadGenotypes is different than expected: A or B are allowed but it was set to ${ReadGenotypes}   . Change!!!" >> ${LOGFILE}; exit 1; fi

if test -s ${HIS_DIR}/UnlinkedAnimalsfor.${run}.txt; then
sort -T ${SRT_DIR} -u ${HIS_DIR}/UnlinkedAnimalsfor.${run}.txt -o ${HIS_DIR}/UnlinkedAnimalsfor.${run}.txt
fi
#delete WRK_DIR und FIM_DIR
rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}
rm -rf ${FIM_DIR}
mkdir -p ${FIM_DIR}
echo " " >> ${LOGFILE}
echo "Check if enough disk space is available" >> ${LOGFILE}
#$BIN_DIR/df.sh START >> ${LOGFILE}
echo " " >> ${LOGFILE}
echo "delete single external samples that have data being delivered but that have already Imputation result" >> ${LOGFILE}
cd ${EXTIND_DIR};
for i in $(ls *.txt); do 
r=$(head -20 ${i} | tail -1 | awk '{print substr($2,4,16)}'); 
echo $i $r; 
done | while IFS=" "; read a snp; do
#in animal.overall.info sind nur Tiere dirn die entweder beriets im SNP-System sind oder im neuen Samplesheet sind 
t=$(awk -v g=${snp} 'BEGIN{FS=";"}{if(substr($3,4,16) == g) print $2}' ${WRK_DIR}/animal.overall.info.${oldrun} | cut -b1-100);
snpden=$(fgrep ${t} ${HIS_DIR}/*.RUN${oldrun}.IMPresult.tierlis | cut -d' ' -f2 | head -1)
if [ ! -z ${snpden} ]; then
if [ ${snpden} > 0 ]; then
echo "${a} is deleted since sample ${snp} has already an Imputation result with chipdensity ${snpden}" >> ${LOGFILE};
rm -f ${a}
$BIN_DIR/sendInformationMailHOL.sh ${a} ${snp} ${snpden} >> ${LOGFILE}
fi
fi
done
#delete empty files
for file in $( ls * ) ; do
    if [ ! -s ${file} ] ; then
        echo "file ${file} is empty and deleted" >> ${LOGFILE};
        rm -f ${file};
    fi;
done
cd ${MAIN_DIR}


echo "copy ARGUS pedigrees to local folders" >> ${LOGFILE}
$BIN_DIR/copyARGUSpedigreesToLocalfolders.sh 2>&1 >> ${LOGFILE}

echo " "
if test -s ${PEDI_DIR}/data/shzv/${pedigreeSHZV}; then
echo "${PEDI_DIR}/data/shzv/${pedigreeSHZV} ist bereits vorhanden, Pedigreefile vom SHZV wird nicht geholt" >> ${LOGFILE}
else
echo "download SHZV Pedigree" >> ${LOGFILE}
$BIN_DIR/fetchSHZVpedigreeFromFTP.sh 2>&1 >> ${LOGFILE}
echo " " >> ${LOGFILE}
fi
echo "Make directory for CHECKLogs from CurrentIMPRUN" >> ${LOGFILE}
mkdir -p ${CHCK_DIR}/${run}
for i in gcscore.check heterorate.check callingrate.check; do
touch ${CHCK_DIR}/${run}/${i}.DUMMY.txt
done
echo " " >> ${LOGFILE}
echo "make directory for single gene tests" >> ${LOGFILE}
mkdir -p ${DEUTZ_DIR}/sbzv/dsch/in/${run}
mkdir -p ${DEUTZ_DIR}/swissherdbook/dsch/in/${run}
echo " " >> ${LOGFILE}
echo "make Run-Directory fuer Einzelgenfiles: $RES_DIR/${run} " >> ${LOGFILE}
mkdir -p $RES_DIR/${run}
echo " " >> ${LOGFILE}



if  test -s  ${HIS_DIR}/BSW_SumUpLOG.${run}.csv  ||  test -s  ${HIS_DIR}/HOL_SumUpLOG.${run}.csv ; then
  echo "ooops .... es wurde ${run} als Run angegeben. Diesen Run aber hab es schon mal. Alte Archivdaten wuerden ueberschrieben werden." >> ${LOGFILE}
  echo "Das ist nicht zulaessig, ich stoppe" >> ${LOGFILE}
  exit 1
fi

#test oldrun
if ! test -s  ${HIS_DIR}/BSW_SumUpLOG.${oldrun}.csv  || ! test -s  ${HIS_DIR}/HOL_SumUpLOG.${oldrun}.csv ; then
  echo "ooops .... es wurde ${oldrun} als OLDRun angegeben. Diesen Run aber gab es nicht." >> ${LOGFILE}
  echo "Das ist nicht zulaessig, ich stoppe" >> ${LOGFILE}
  exit 1
fi


if ! test -s ${HDD_DIR}/BSWTypisierungsstatus${oldrun}.txt || ! test -s  ${HDD_DIR}/HOLTypisierungsstatus${oldrun}.txt ; then
  echo "ooops .... es wurde ${run} als HDRun angegeben. Diesen Run aber gab es nicht." >> ${LOGFILE}
  echo "Das ist nicht zulaessig, ich stoppe" >> ${LOGFILE}
  exit 1
fi

if ! test -s ${PED_DIR}/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat || ! test -s ${PED_DIR}/shzv/${pedigreeSHZV} || ! test -s ${PED_DIR}/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat || ! test -s ${PED_DIR}/jer/${DatPEDIjer}_pedigree_rrtdm_JER.dat; then
 echo "Mindestens eines der angegebenen nationalen Pedigrees existiert nicht" >> ${LOGFILE}
 echo "Ich stoppe" >> ${LOGFILE}
 exit 1
fi

echo " " >> ${LOGFILE}
for pdgree in ${PED_DIR}/shzv/${pedigreeSHZV} ${PED_DIR}/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat ${PED_DIR}/jer/${DatPEDIjer}_pedigree_rrtdm_JER.dat ${PED_DIR}/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat; do
echo "Check if there are animals without sektinoscode in ${pdgree}" >> ${LOGFILE}
ohnesektionscodeN=0;
ohnesektionscodeN=$(awk '{if(substr($0,39,2) == "  ") print}' ${pdgree} | wc -l | awk '{print $1}')
if [ ${ohnesektionscodeN} != 0 ]; then
echo "...OOOPS: Es hat ${ohnesektionscodeN} ohne Sektionscode in ${pdgree}." >> ${LOGFILE}
echo "Das ist nicht erlaubt. Problem auf der Datenbank beheben und neues Pedigree holen" >> ${LOGFILE}
exit 1
else
echo "Alle Tiere in ${pdgree} haben einen Sektionscode." >> ${LOGFILE}
fi
echo " " >> ${LOGFILE}
done


echo "Kombinieren originale Sample-Submission files und Aufbau crossreffile" >> ${LOGFILE}
$BIN_DIR/combineOriginalSamplesheetsInto1file.sh >> ${LOGFILE}
echo " " >> ${LOGFILE}
#Anmerkung: die Unterteilung in current und previous wird benoetigt, da die externen SNP-Auftraege im Sammellog am Ende nur aus dem neuesten Logfile gezogen werden duerfen. Sonst passt die Schnittstelle zur Datenbank nicht und meldet zu viele externe SNP-Auftraege zurueck
if ! test -s ${WRK_DIR}/currentSamplesheet/${crossreffile} ; then
	echo "${WRK_DIR}/currentSamplesheet/${crossreffile} existiert nicht. Das kann schon sein wenn z.B. ein Run ohne neue GeneSeek Daten gemacht wird."  >> ${LOGFILE}
	echo "Ich brauche aber ein Samplesheet zum aktuellen Run. Daher wird eines angelegt."  >> ${LOGFILE}
        echo "BarCode;Animal ID;Breeding organisation;Name;Probeneingang;Rasse;GebDat;SNPI_ID;SNPI_ANIMAL_ID;SAK_MANDANT_ID;ABSTKTR;Sex;GGP_Bovine50K;BOV_HD_T;BOV_uHD_150k_T;GGP_F250_Tissue-R&D;GGP_BOV50K_A2;GGP_BOV50K_Brachyspina;GGP_BOV50K_Coat_Color;GGP_BOV50K_CVM;GGP_BOV50K_HCD;GGP_BOV50K_HornPoll;BOV_uHD_A2;BOV_uHD_Brachyspina;BOV_uHD_Coat_Color;BOV_uHD_CVM;BOV_uHD_HCD;BOV_uHD_HornPoll;BOV_uHD_Myostatin;Black;CVM;HP_Gold;Myostatin Beef;Dairy Recessives Panel;Milk Proteins;Sample Type;Batch ID" > ${WRK_DIR}/currentSamplesheet/${crossreffile}
fi
#verschieben des aelteren in den anderen ordner
mv ${WRK_DIR}/currentSamplesheet/${crossreffileMV} ${WRK_DIR}/previousSamplesheets/.
echo " " >> ${LOGFILE}
echo "ich behalte 9 previous crossreffiles in $WRK_DIR/allSamplesheets/ naemlich das der 9 vorigen Runs" >> ${LOGFILE}
echo "+ 1 neues file in $WORK_DIR/allSamplesheets/ naemlich das aktuelle" >> ${LOGFILE}
echo " " >> ${LOGFILE}
#archivieren des aeltesten crossreffiles
if test -s ${WRK_DIR}/previousSamplesheets/${crossreffileOLD} ; then
	mv ${WRK_DIR}/previousSamplesheets/${crossreffileOLD} /qualstore03/data_archiv/SNP/SampleSheets/.
	if test -s /qualstore03/data_archiv/SNP/SampleSheets/${crossreffileOLD} ; then
		echo "${WRK_DIR}/previousSamplesheets/${crossreffileOLD} was moved to /qualstore03/data_archiv/SNP/SampleSheets" >> ${LOGFILE}
	else
		echo "ooops move hat nicht geklappt :-(" >> ${LOGFILE}
	fi
else
	echo "${WRK_DIR}/previousSamplesheets/${crossreffileOLD} existierte nicht und wurde so nicht archiviert. " >> ${LOGFILE}
        rm -f ${WRK_DIR}/previousSamplesheets/${crossreffileOLD}
fi


echo " " >> ${LOGFILE}


#Verarbeitung SampleSheets
echo "folgendes aktuelles crossreffiles liegt bereit. Bitte kontrollieren" >> ${LOGFILE}
ls -trl $WRK_DIR/currentSamplesheet/*.txt >> ${LOGFILE}
echo "dazukommen die folgenden aelteren crossreffiles. Bitte kontrollieren" >> ${LOGFILE}
ls -trl $WRK_DIR/previousSamplesheets/*.txt >> ${LOGFILE}
echo " " >> ${LOGFILE}
echo " " >> ${LOGFILE}
echo "make Run-Directory fuer Einzelgenfiles: $RES_DIR/${run} " >> ${LOGFILE}
mkdir -p $RES_DIR/${run}
echo " " >> ${LOGFILE}
echo "make Directory Archive  $BCP_DIR/${run}/binaryfiles" >> ${LOGFILE}
mkdir -p $BCP_DIR/${run}/binaryfiles
echo " " >> ${LOGFILE}
echo " " >> ${LOGFILE}
echo "Fetch new GeneSeek data now" >> ${LOGFILE}
$BIN_DIR/accessNewGenotypeDataFromGeneSeek.sh 2>&1 >> ${LOGFILE}

if test -s $LOG_DIR/skript1.log ; then
nNEW=$(awk '{if($0 ~ "data_archiv") print}' $LOG_DIR/skript1.log |wc -l | awk '{print $1}')
if [ ${nNEW} -gt 0 ];then
   echo "#############################################" >> ${LOGFILE}
   nALL=$(grep data_archiv $LOG_DIR/skript1.log |sort -T ${SRT_DIR} -t' ' -k1,1n | awk -F ' *' '$1 ~ /^[0-9]+$/{print $1}' | awk '{SUM +=$1} END{print SUM}')
   echo "Printing Sum of all newly delivered GeneSeek samples across all chips: ... ${nALL}" >> ${LOGFILE}
   echo "#############################################" >> ${LOGFILE}
fi
fi



echo " " >> ${LOGFILE}
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT} >> ${LOGFILE}
