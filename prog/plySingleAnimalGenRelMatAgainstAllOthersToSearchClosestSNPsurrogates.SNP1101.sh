#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


#run one anial against all genotyped animals to search closest SNP-relatives
# Kommandozeilenargumenten einlesen und pruefen
if test -z $1; then
  echo "FEHLER: Kein Argument erhalten. Diesem Shell-Script muss ein Rassenkuerzel mitgegeben werden! --> PROGRAMMABBRUCH"
  exit 1
fi
breed=$(echo $1 | awk '{print toupper($1)}')
if [ ${breed} != "BSW" ] && [ ${breed} != "HOL" ] && [ ${breed} != "VMS" ]; then
  echo "FEHLER: Diesem shell-Script wurde ein unbekanntes Rassenkuerzel uebergeben! (BSW / HOL / VMS sind zulaessig) --> PROGRAMMABBRUCH"
  exit 1
fi
# Kommandozeilenargumenten einlesen und pruefen
if test -z $2; then
  echo "FEHLER: Kein Argument erhalten. Diesem Shell-Script muss eine TVDNummer mitgegeben werden! --> PROGRAMMABBRUCH"
  exit 1
fi
animal=$(echo $2 | awk '{print toupper($1)}')
nbytes=$(echo $animal | wc -c | awk '{print $1}')
if [ ${nbytes} != 15 ]; then echo "${animal} ist nicht 14 stellig, heisst es ist keine korrekte TVD" ; exit 1; fi
if ! grep -q ${animal} $WORK_DIR/${breed}Typisierungsstatus${run}.txt; then
  echo "${animal} ist in $WORK_DIR/${breed}Typisierungsstatus${run}.txt nicht drin, heisst es ist nicht typisiert oder die TVD ist falsch"
  exit 1
fi 
idanimal=$(awk -v tier=${animal} '{if($5 == tier) print $1}' $WORK_DIR/ped_umcodierung.txt.${breed} ) 
if [ -z "${idanimal}" ]; then
     echo das Tier finde ich nicht
     exit 1
fi   

#keep coreanimals
if [ ${breed} == "BSW" ]; then
(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed})) |\
   awk '{if(($3+$4+$5) > 0.5) print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.INDIcoreanimals.txt
fi
if [ ${breed} == "HOL" ]; then
(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed})) |\
   awk '{if(($3+$5) > 0.5) print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.INDIcoreanimals.txt
fi
if [ ${breed} == "VMS" ]; then
(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed})) |\
   awk '{if(($3+$4+$5) > 0.5) print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.INDIcoreanimals.txt
fi


#if ! test -s  $TMP_DIR/${breed}.INDIcoreanimals.txt; then
#test if given animal is member of $TMP_DIR/${breed}.INDIcoreanimals.txt
memberC=$(awk -v tier=${animal} '{if($1 == tier) print $1}' $TMP_DIR/${breed}.INDIcoreanimals.txt ) 


echo " "
echo "check if GRM and PRM file exist"
for ffile in $SMS_DIR/${1}-GRM/gmtx_kin1.txt $SMS_DIR/${1}-PRM/amtx_kin1.txt; do  
    $BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh ${1} ${ffile} 2>&1
done
echo " "


if [ ! -z "${memberC}" ]; then
#collect alle typisierten Tiere inkl umsortieren so dass der ältere kollege immer als zweites steht
startfile=$WORK_DIR/${breed}Typisierungsstatus${run}.txt
#echo $memberC


#aufbau file mit den Tier und alle anderen Tiere
awk '{ sub("\r$", ""); print }' ${startfile} |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 2.1' -1 1 -2 5 - <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
   awk -v aa=${animal} -v bb=${idanimal} '{print aa,bb,$1,$2}' |\
   sort -T ${SRT_DIR} -t' ' -k3,3 |\
   join -t' ' -o'1.1 1.2 1.3 1.4' -1 3 -2 1 - $TMP_DIR/${breed}.INDIcoreanimals.txt |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   tee $SMS_DIR/${breed}.${animal}.allSNPrelshipPairsInPairs.toBechecked | awk '{print $2,$4}' > $SMS_DIR/${breed}.${animal}.allSNPrelshippairsInRows.toBechecked



  if test -s $SMS_DIR/${breed}.${animal}.allSNPrelshippairsInRows.toBechecked.out; then
    rm -f $SMS_DIR/${breed}.${animal}.allSNPrelshippairsInRows.toBechecked.out
  fi
    


echo "genomic Relationships"
  ${FRG_DIR}/holeVerwandtschaftenAusRelMatrix $SMS_DIR/${breed}-GRM/gmtx_kin1.txt $SMS_DIR/${breed}.${animal}.allSNPrelshippairsInRows.toBechecked $SMS_DIR/${breed}.${animal}.allSNPrelshippairsInRows.toBechecked.out
echo "pedigree Relationships"
  ${FRG_DIR}/holeVerwandtschaftenAusRelMatrix $SMS_DIR/${breed}-PRM/amtx_kin1.txt $SMS_DIR/${breed}.${animal}.allSNPrelshippairsInRows.toBechecked $SMS_DIR/${breed}.${animal}.allPEDIGREErelshippairsInRows.toBechecked.out
  
  join -t' ' -o'1.1 1.2 1.3 2.3' -1 2 -2 2 <(sort -T ${SRT_DIR} -t' ' -k2,2 $SMS_DIR/${breed}.${animal}.allSNPrelshippairsInRows.toBechecked.out) <(sort -T ${SRT_DIR} -t' ' -k2,2 $SMS_DIR/${breed}.${animal}.allPEDIGREErelshippairsInRows.toBechecked.out) > $SMS_DIR/${breed}.${animal}.allRELSHIPpairsInRows.toBechecked.out

(echo "TVDanimal idImputing TVDsurrogate idsurrogate GRelship PRelship AgeStatus";
  sort -T ${SRT_DIR} -t' ' -k2,2 $SMS_DIR/${breed}.${animal}.allRELSHIPpairsInRows.toBechecked.out |\
  join -t' ' -o'2.1 1.1 2.3 1.2 1.3 1.4' -1 2 -2 4 - <(sort -T ${SRT_DIR} -t' ' -k4,4 $SMS_DIR/${breed}.${animal}.allSNPrelshipPairsInPairs.toBechecked ) |awk '{if($2 > $4) print $1,$2,$3,$4,$5,$6,"AY"; else if ($2 == $4) print $1,$2,$3,$4,$5,$6,"AA"; else print $1,$2,$3,$4,$5,$6,"AO"}' ) >  ${RES_DIR}/${animal}.${breed}.SNP1101againstAllTypis.SetOfAni.${run}.txt 

 
#fuer initiale auswertung / kontrolle nun die records aus der aMatrix
#${BIN_DIR}/linux/holeVerwandtschaftenAusRelMatrix $SMS_DIR/${breed}-PRM/amtx_kin1.txt $SMS_DIR/${breed}.${animal}.allSNPrelshippairsInRows.toBechecked $SMS_DIR/${breed}.${animal}.allAMATrelshippairsInRows.toBechecked.out
#sort -T ${SRT_DIR} -t' ' -k2,2 $SMS_DIR/${breed}.${animal}.allAMATrelshippairsInRows.toBechecked.out |\
#  join -t' ' -o'2.1 1.1 2.3 1.2 1.3' -1 2 -2 4 - <(sort -T ${SRT_DIR} -t' ' -k4,4 $SMS_DIR/${breed}.${animal}.allSNPrelshipPairsInPairs.toBechecked) | awk '{if($2 > $4) print $1,$2,$3,$4,$5,"AY"; else if ($2 == $4) print $1,$2,$3,$4,$5,"AA"; else print $1,$2,$3,$4,$5,"AO"}' >  ${RES_DIR}/${animal}.${breed}.AMATagainstAllTypis.SetOfAni.${run}.txt

##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh $BIN_DIR/${SCRIPT} $2
else
echo " "
echo "${animal} hat zu wenig Blutanteil und ist nicht im Prozess enthalten"
echo " "
fi

echo " "
RIGHT_NOW=$(date )
echo $RIGHT_END Ende ${SCRIPT}
