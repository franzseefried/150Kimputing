#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "


#######################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
#######################################################

ort=$(uname -a | awk '{print $1}' )
if [ ${ort} == "Darwin" ]; then
    echo "change entweder zu eiger, titlis, beverin oder castor"
    exit 1
elif [ ${ort} == "Linux" ]; then
  maschine=$(uname -a | awk '{print $2}'  | cut -d'.' -f1)
  if [ ${maschine} == "titlis" ]; then
    echo "change to castor due to sql issues"
#    exit 1
  elif [ ${maschine} == "beverin" ]; then
    echo "change to castor due to sql issues"
    exit 1
  elif [ ${maschine} == "castor" ]; then
    numberOFparallelJOBS=33
  elif [ ${maschine} == "eiger" ]; then
    echo "change to castor due to sql issues"
    exit 1
  else
    echo "change entweder zu eiger, titlis, beverin oder castor"
    exit 1
  fi
else
  echo "oops komisches Betriebssystem ich stoppe"
  exit 1
fi


#cp $WORK_DIR/animal.overall.info $WRK_DIR/animal.overall.info.${oldrun}
ALT=$(wc -l $WRK_DIR/animal.overall.info.${oldrun} | awk '{print $1}')
echo "altes infofile hat ${ALT} Zeilen:"
echo " "

echo "animallst aufbauen"
for zofol in bvch shb vms; do
for dicht in LD HD; do
  colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ${IMPUTATIONFLAG} | awk '{print $1}')
  colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
  CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v densit=${dicht} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})
  for chip in ${CHIPS} ; do
    cd $SNP_DIR/dataWide${chip}/${zofol}
    linkarray=$(find -maxdepth 1 -type l -exec basename {} \;)
    echo ${linkarray} | grep "[0-9]" |  sed 's/\.lnk//g' | tr ' ' '\n' 
  done
done
done | sort -T ${SRT_DIR} -u  > $WORK_DIR/animal.overall.lst
echo "No of records after reading links"
wc -l $WORK_DIR/animal.overall.lst

cd ${MAIN_DIR}




#SHB Pedigree genuegt da alle SNP Tiere auf ARGUS sind
(awk '{print substr($0,1,10)";"substr($0,58,14)}' /qualstore03/data_zws/pedigree/data/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat;
 awk '{print substr($0,1,10)";"substr($0,58,14)}' /qualstore03/data_zws/pedigree/data/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat;
 awk '{print substr($0,1,10)";"substr($0,58,14)}' /qualstore03/data_zws/pedigree/data/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat;
 awk '{print substr($0,1,10)";"substr($0,58,14)}' /qualstore03/data_zws/pedigree/data/jer/${DatPEDIjer}_pedigree_rrtdm_JER.dat) | sed 's/ //g' | awk 'BEGIN{FS=";"}{print $2,$1}' | sort -u -T ${SRT_DIR} > $TMP_DIR/allBRDS.tvdZuIdanimal


awk '{print $2,$1}' $TMP_DIR/allBRDS.tvdZuIdanimal > $TMP_DIR/allBRDS.idanimalZutvd
nnotfound=$($BIN_DIR/awk_fetchCOLtwo_keepCOL1 $TMP_DIR/allBRDS.idanimalZutvd $WORK_DIR/animal.overall.lst | awk '{if($2 == "#") print}' | wc -l | awk '{print $1}')
if [ ${nnotfound} -gt 0 ]; then
   echo " ";
   echo "ooops es hat Tiere im SNP-ARCHIV die in keinem nationalen Pedigree sind"
#   echo "Diese werden im aktuellen Run nicht beruecksichtigt"
   $BIN_DIR/awk_fetchCOLtwo_keepCOL1 $TMP_DIR/allBRDS.idanimalZutvd $WORK_DIR/animal.overall.lst | awk '{if($2 == "#") print}'
fi




$BIN_DIR/awk_umcodeVonEINSaufZWEImitLeerschlag $TMP_DIR/allBRDS.tvdZuIdanimal <(cut -d';' -f15 $WORK_DIR/crossref.txt | grep "[0-9]") | sed 's/ //g' >> $WORK_DIR/animal.overall.lst
sort -u $WORK_DIR/animal.overall.lst -o $WORK_DIR/animal.overall.lst



echo "Aufbau crossreffile fuer $WORK_DIR/animal.overall.lst"
#SHB Pedigree genuegt da alle SNP Tiere auf ARGUS sind
(awk '{print substr($0,1,10)";"substr($0,12,10)";"substr($0,23,10)";"substr($0,41,16)";"substr($0,58,14)";"substr($0,73,8)";"substr($0,82,3)}' /qualstore03/data_zws/pedigree/data/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat;
 awk '{print substr($0,1,10)";"substr($0,12,10)";"substr($0,23,10)";"substr($0,41,16)";"substr($0,58,14)";"substr($0,73,8)";"substr($0,82,3)}' /qualstore03/data_zws/pedigree/data/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat;
 awk '{print substr($0,1,10)";"substr($0,12,10)";"substr($0,23,10)";"substr($0,41,16)";"substr($0,58,14)";"substr($0,73,8)";"substr($0,82,3)}' /qualstore03/data_zws/pedigree/data/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat | awk 'BEGIN{FS=";"}{if($7 == 70 || $7 == 60) print $1";"$2";"$3";"$4";"$5";"$6";""SI";else print $0}' ;
 awk '{print substr($0,1,10)";"substr($0,12,10)";"substr($0,23,10)";"substr($0,41,16)";"substr($0,58,14)";"substr($0,73,8)";"substr($0,82,3)}' /qualstore03/data_zws/pedigree/data/jer/${DatPEDIjer}_pedigree_rrtdm_JER.dat) | sed 's/ //g' |sort -T ${SRT_DIR} -u  > $TMP_DIR/allBRDS.pedigree.info
$BIN_DIR/awk_tripleUmcoding $TMP_DIR/allBRDS.pedigree.info $WORK_DIR/animal.overall.lst > $WORK_DIR/animal.overall.info
sort -u $WORK_DIR/animal.overall.info -o $WORK_DIR/animal.overall.info

NEU=$(wc -l $WORK_DIR/animal.overall.info | awk '{print $1}')
if [ ${NEU} -lt ${ALT} ]; then
   echo "ooops das neue ${WORK_DIR}/animal.overall.lst hat weniger records: ${NEU} , wie das alte $WORK_DIR/animal.overall.info: ${ALT} "
   echo "..... sehr seltsam, checks needed if all animals have been collected"
   echo " "
else
   echo "neues infofile hat ${NEU} Zeilen"
   echo " "
fi



nnotfound=$($BIN_DIR/awk_fetchCOLtwo_keepCOL1 $TMP_DIR/allBRDS.tvdZuIdanimal <(cut -d';' -f15 $WORK_DIR/crossref.txt | grep "[0-9]") | awk '{if($2 == "#") print}' | wc -l | awk '{print $1}')
if [ ${nnotfound} -gt 0 ]; then
   echo " ";
   echo "Es hat Tiere im SAMPLESHEET die in keinem nationalen Pedigree sind"
   #echo "hole Info von ARGUS und haenge sie an  $WORK_DIR/animal.overall.info sonst gehen die neu von GeneSeek gelieferten Genotypen verloren"
   $BIN_DIR/awk_fetchCOLtwo_keepCOL1 $TMP_DIR/allBRDS.tvdZuIdanimal <(cut -d';' -f15 $WORK_DIR/crossref.txt | grep "[0-9]") | awk '{if($2 == "#") print }'
   cp $WORK_DIR/animal.overall.info $WORK_DIR/animal.overall.infoORG
   $BIN_DIR/awk_fetchCOLtwo_keepCOL1 $TMP_DIR/allBRDS.tvdZuIdanimal <(cut -d';' -f15 $WORK_DIR/crossref.txt | grep "[0-9]") |\
       awk '{if($2 == "#") print $1}'  |\
       sort -u |\
       while read TVD; do 
       #echo $TVD
       cat $BIN_DIR/getIDsfromARGUSforAnimalsMissingInPedigrees.sh | sed "s/ZZZZZZZZZZ/${TVD}/g" > $TMP_DIR/${TVD}getIDsfromARGUS.sh
       chmod 777 $TMP_DIR/${TVD}getIDsfromARGUS.sh
       done
       for i in $(ls $TMP_DIR/*getIDsfromARGUS.sh); do
       aa=$(basename ${i} | cut -b1-14)
       bb=$(echo $aa | cut -b3-14)
       #echo $i
       $i >/dev/null
       #ls -trl $TMP_DIR/${aa}.sqlout
       if test -s $TMP_DIR/${aa}.sqlout ; then
       sed -i 's/\"//g' $TMP_DIR/${aa}.sqlout
       idanimal=$(grep $bb $TMP_DIR/${aa}.sqlout  | awk 'BEGIN{FS=","}{if(NF==3) print}' | tail -1 | cut -d',' -f1)
       ITBID=$(grep $bb $TMP_DIR/${aa}.sqlout | awk 'BEGIN{FS=","}{if(NF==3) print}' | tail -1 | cut -d',' -f2)
       ANISEX=$(grep $bb $TMP_DIR/${aa}.sqlout | awk 'BEGIN{FS=","}{if(NF==3) print}' | tail -1 | cut -d',' -f3)
       if ! test -z ${idanimal} ;then
       echo "${idanimal};${aa};${ITBID};DUMMYNAME;        ;${ANISEX};              ;                   ;             ;        ;  ;              ;                   ;            " #>> $WORK_DIR/animal.overall.info
       else
       echo " "
       echo "${aa} hat kein sql ergebnis, manuell eintragen in work/animal.overall.info...aber preufe bitte zuerst nochmal via dessen idanimal ob das Tier wirklich nicht in animal.overall.info drin ist"
       echo " "
       fi
       fi
       done
else
echo "Alle Tiere aus dem Samplesheet sind in den nationalen Pedigrees drin"
fi
cp $WORK_DIR/animal.overall.info $WRK_DIR/animal.overall.info.${run}
NEU=$(wc -l $WORK_DIR/animal.overall.info | awk '{print $1}')
echo "neues infofile hat ${NEU} Zeilen:"
echo " "
rm -f $TMP_DIR/allBRDS.pedigree.info $TMP_DIR/allBRDS.idanimalZutvd $TMP_DIR/*getIDsfromARGUS.sh
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
