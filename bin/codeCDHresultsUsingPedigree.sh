#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}
fi


for breed in HOL; do
	rasse=rh
	founderTVD=CA000054577984


	(awk '{if($2 == 2) print $1,"LD"}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis ;
		awk '{if($2 == 1) print $1,"DB"}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis) | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.neucdh.srt
    (awk '{if($2 == 2) print $1,"LD"}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis;
	    awk '{if($2 == 1) print $1,"DB"}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis ) | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.altcdh.srt

        join -t' ' -o'1.1 1.2' -v1 -1 1 -2 1 $TMP_DIR/${breed}.neucdh.srt $TMP_DIR/${breed}.altcdh.srt > $TMP_DIR/${breed}.NewFor.cdh.srt


if test -s $RES_DIR/RUN${run}${breed}.CDH.check_founder_HETEROS.lst; then
	rm -f $RES_DIR/RUN${run}${breed}.CDH.check_founder_HETEROS.lst
fi
if test -s $RES_DIR/RUN${run}${breed}.CDH.check_founder_HOMOS.lst; then
	rm -f $RES_DIR/RUN${run}${breed}.CDH.check_founder_HOMOS.lst
fi



if ! test -s /qualstore03/data_zws/pedigree/work/${rasse}/UpdatedRenumMergedPedi_${DatPEDIshb}.txt ;then
   echo "/qualstore03/data_zws/pedigree/work/${rasse}/UpdatedmergedPedi_${DatPEDIshb}.txt existiert nicht"
   exit 1
elif ! test -s /qualstore03/data_zws/pedigree/data/itb/pedig_${breed}.csv ;then
   echo "/qualstore03/data_zws/pedigree/data/itb/pedig_${breed}.csv existiert nicht"
   exit 1
else

#check ob es heteros hat in den NEUEN Ergebnissen, ab Mrz 2017 nur noch die neuen Tiere via pedigree gecheckt
join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9' -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $RES_DIR/RUN${run}${breed}.11-CDH.Fimpute.all.haploCOUNTS) <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.NewFor.cdh.srt) > $TMP_DIR/forPedicheck.RUN${run}${breed}.11-CDH.Fimpute.all.haploCOUNTS

  checkcarrier=$(awk '{if($2 == 1)print }' $TMP_DIR/forPedicheck.RUN${run}${breed}.11-CDH.Fimpute.all.haploCOUNTS | wc -l | awk '{print $1}')
  echo "Habe $checkcarrier heterozygot haplotypisierte Tiere in den Daten"
  if [ ${checkcarrier} > 0 ]; then
  traeger=$(awk '{if($2 == 1)print $4}' $TMP_DIR/forPedicheck.RUN${run}${breed}.11-CDH.Fimpute.all.haploCOUNTS | sort -T ${SRT_DIR} -n )
  for vieh in ${traeger}; do
  result=0
  echo "${vieh}" > ${TMP_DIR}/cdh.itb
  (echo "logFile            '${TMP_DIR}/renumPedLog'"
   echo "pediFile                  '/qualstore03/data_zws/pedigree/work/${rasse}/UpdatedRenumMergedPedi_${DatPEDIshb}.txt'"
   echo "missingTVDIDCode          UUUUUUUUUUUUUU"
   echo "skipTiereMitFehlerhaftemGeburtsdatum    NO"
   echo "fehlerhaftePediRecFile    '${TMP_DIR}/cdh.fehPedRec'"
   echo "pediFehlerFile            '${TMP_DIR}/cdh.pedFeh'"
   echo "sexFehlerFile             '${TMP_DIR}/cdh.sexFeh'"
   echo "altersdiskrepanzenFile    '${TMP_DIR}/cdh.altDiskr'"
   echo "fehldendeElternFile       '${TMP_DIR}/cdh.fehlElt'"
   echo "listeTiereFuerPedigree    '${TMP_DIR}/cdh.itb'"
   echo "idTypInListeTiereFuerPedigree     itbid19"
   echo "nGenerationen              50"
   echo "renumberedPediFile         '${TMP_DIR}/cdh.renumPed'") > $PAR_DIR/cdh.renumPedIp


  $PEDBIN_DIR/renumRRTDMPed $PAR_DIR/cdh.renumPedIp > $TMP_DIR/renum.log
  
  result=$(awk -v ani=${founderTVD} '{if($6 == ani) print}'  ${TMP_DIR}/cdh.renumPed | wc -l | awk '{print $1}')
  echo ${vieh} ${result} >> $RES_DIR/RUN${run}${breed}.CDH.check_founder_HETEROS.lst
  done
  else
  touch $RES_DIR/RUN${run}${breed}.CDH.check_founder_HETEROS.lst
  fi

#check ob es homos hat in den Ergebnissen
  checkhomos=$(awk '{if($2 == 2)print }' $TMP_DIR/forPedicheck.RUN${run}${breed}.11-CDH.Fimpute.all.haploCOUNTS | wc -l | awk '{print $1}')
  echo "Habe $checkhomos Homozygot-haplotypisierte Tiere in den Daten"
  if [ ${checkhomos} > 0 ]; then
  homos=$(awk '{if($2 == 2)print $4}' $TMP_DIR/forPedicheck.RUN${run}${breed}.11-CDH.Fimpute.all.haploCOUNTS | sort -T ${SRT_DIR} -n )
  for vieh in ${homos}; do
  eltern=$(awk -v tier=${vieh} '{if(substr($5,3,16) == substr(tier,4,16)) print $1","$2 }' /qualstore03/data_zws/pedigree/work/${rasse}/UpdatedRenumMergedPedi_${DatPEDIshb}.txt )
  vater=$(echo $eltern | tr ',' ' ' | awk '{print $1}')
  mutter=$(echo $eltern | tr ',' ' ' | awk '{print $2}')
  sire=$(awk -v ani=${vater} '{if($1 == ani) print $5}' /qualstore03/data_zws/pedigree/work/${rasse}/UpdatedRenumMergedPedi_${DatPEDIshb}.txt )
  dam=$(awk -v anim=${mutter} '{if($1 == anim) print $5}' /qualstore03/data_zws/pedigree/work/${rasse}/UpdatedRenumMergedPedi_${DatPEDIshb}.txt )
  for i in $(echo ${sire} ${dam}); do
  result=0
  echo "${i}" | awk '{print substr($1,3,16)}' > ${TMP_DIR}/cdh.itb
  (echo "logFile            '${TMP_DIR}/OB.renumPedLog'"
   echo "pediFile                  '/qualstore03/data_zws/pedigree/work/${rasse}/UpdatedRenumMergedPedi_${DatPEDIshb}.txt'"
   echo "missingTVDIDCode          UUUUUUUUUUUUUU"
   echo "skipTiereMitFehlerhaftemGeburtsdatum    NO"
   echo "fehlerhaftePediRecFile    '${TMP_DIR}/cdh.fehPedRec'"
   echo "pediFehlerFile            '${TMP_DIR}/cdh.pedFeh'"
   echo "sexFehlerFile             '${TMP_DIR}/cdh.sexFeh'"
   echo "altersdiskrepanzenFile    '${TMP_DIR}/cdh.altDiskr'"
   echo "fehldendeElternFile       '${TMP_DIR}/cdh.fehlElt'"
   echo "listeTiereFuerPedigree    '${TMP_DIR}/cdh.itb'"
   echo "idTypInListeTiereFuerPedigree     itbid16"
   echo "nGenerationen              50"
   echo "renumberedPediFile         '${TMP_DIR}/cdh.renumPed'") > $PAR_DIR/cdh.renumPedIp


  $PEDBIN_DIR/renumRRTDMPed $PAR_DIR/cdh.renumPedIp > $TMP_DIR/renum.log
  
  #result=$(grep ${founderTVD}  ${TMP_DIR}/cdh.renumPed | wc -l | awk '{print $1}')
  
  result=$(awk -v ani=${founderTVD} '{if($6 == ani) print}'  ${TMP_DIR}/cdh.renumPed | wc -l | awk '{print $1}')
  
  echo ${vieh} ${i} ${result} >> $RES_DIR/RUN${run}${breed}.CDH.check_founder_HOMOS.lst
  done
  done
  for vieh in ${homos}; do
  nallele=$(grep $vieh $RES_DIR/RUN${run}${breed}.CDH.check_founder_HOMOS.lst | wc -l | awk '{print $1}')
  echo $vieh $nallele
  done > $RES_DIR/tmp.lst
  else
  touch $RES_DIR/tmp.lst
  fi
fi  

mv $RES_DIR/tmp.lst $RES_DIR/RUN${run}${breed}.CDH.check_founder_HOMOS.lst



#prep final data: reduktion auf Tiere mit mehr als 90 prozen HOL Blut
heute=$(date +"%Y%m%d")
join -t' ' -o'1.1 1.2 1.3 1.4 2.2 1.6' -a1 -e'-' -1 4 -2 1 <( sort -T ${SRT_DIR} -t' ' -k4,4 $RES_DIR/RUN${run}${breed}.11-CDH.Fimpute.all.haploCOUNTS ) <(sort -T ${SRT_DIR} -t' ' -k1,1 $RES_DIR/RUN${run}${breed}.CDH.check_founder_HOMOS.lst) |\
awk '{if($6 == "HO" || $6 == "RF" || $6 == "SF" || $6 == "RH" )  print $1,$2,$3,$4,$5}' |\
sort -T ${SRT_DIR} -t' ' -k4,4 |\
join -t' ' -o'1.1 1.2 1.3 1.4 1.5 2.2' -a1 -e'-' -1 4 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $RES_DIR/RUN${run}${breed}.CDH.check_founder_HETEROS.lst) |\
awk '{if($2 == 0) print $1" CDF";else if($2 == 2 && $5 == 2) print $1" CD2";else if($2 == 2 && $5 == 2) print $1" CD2";else if($2 == 2 && $5 != 2) print $1" CD4"; else if($2 == 1 && $6 == 1) print $1" CD1";else if($2 == 1 && $6 == 0) print $1" CD3";else print $1," OOOPS"}' |\
tee ${RES_DIR}/RUN${run}HOL.11-CDH.Fimpute.all.haploCOUNTS.cd1-5 |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2' -1 1 -2 1 - $TMP_DIR/${breed}.NewFor.cdh.srt |\
tr ' ' ';' > /qualstore03/data_zws/snp/einzelgen/argus/import/${breed}/179.CDH.${heute}.CH.Haplotypen.ImportGenmarker.dat

echo "Wir haben folgende Verteilung der CDH Genotypen im Ergebnisfile /qualstore03/data_zws/snp/einzelgen/argus/import/${breed}/179.CDH.${heute}.CH.Haplotypen.ImportGenmarker.dat:"
cut -d';' -f2 /qualstore03/data_zws/snp/einzelgen/argus/import/${breed}/179.CDH.${heute}.CH.Haplotypen.ImportGenmarker.dat | sort | uniq -c

echo "copy to Folder der anderen Einzelgenergebnisse fuer Swissherdbook"
cp /qualstore03/data_zws/snp/einzelgen/argus/import/${breed}/179.CDH.${heute}.CH.Haplotypen.ImportGenmarker.dat ${DEUTZ_DIR}/swissherdbook/dsch/in/${run}/.
echo " "
echo "ftp upload for SHZV"
$BIN_DIR/ftpUploadOf1File.sh -f 179.CDH.${heute}.CH.Haplotypen.ImportGenmarker.dat -o /qualstore03/data_zws/snp/einzelgen/argus/import/${breed} -z Einzelgen

done




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende codeCDHresultsUsingPedigree.sh

