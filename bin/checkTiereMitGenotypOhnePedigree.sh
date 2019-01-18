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
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ]  || [ ${1} == "VMS" ]; then

if [ ${1} == "BSW" ]; then
	zofol=$(echo "bvch")
	natpedi=${PED_DIR}/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat
        mixpedi=${PEDI_DIR}/work/bv/${DatPEDIbvch}_pedigree_rrtdm_BVJE.dat
fi
if [ ${1} == "HOL" ]; then
	zofol=$(echo "shb")
	natpedi=${PED_DIR}/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat
        mixpedi=${PEDI_DIR}/work/rh/pedi_shb_shzv.dat
fi
if [ ${1} == "VMS" ]; then
        zofol=$(echo "vms")
        natpedi=${PED_DIR}/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat
        mixpedi=${PED_DIR}/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat
fi
set -o nounset
breed=${1};

awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1,2 | sed 's/ //g' | tr ';' ' ' |  sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -u > $TMP_DIR/${breed}.ovlinfo.umcd
#awk '{print substr($0,1,10)";"substr($0,58,14)}' ${natpedi} | sed 's/ //g' | tr ';' ' '  > $TMP_DIR/${breed}.status.umcd
awk '{print substr($0,1,10)";"substr($0,58,14)}' ${mixpedi} | sed 's/ //g' | tr ';' ' ' | awk '{print $2,$1}' > $TMP_DIR/${breed}.mixpedi.umcd

echo "animallists are built"
for dicht in LD HD; do
  colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ImputationDensityLD150K | awk '{print $1}')
  colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
  CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v densit=${dicht} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})


  for chip in ${CHIPS} ; do
    cd $SNP_DIR/dataWide${chip}/${zofol}
    linkarray=$(find -maxdepth 1 -type l -exec basename {} \;)
    echo ${linkarray} | grep "[0-9]" |  sed 's/\.lnk//g' | tr ' ' '\n' 
  done | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -u | awk -v dd=${dicht} '{print $1,dd}' > $TMP_DIR/${breed}.startanimallst.${dicht}
done


(awk '{print $1,"s"}' $TMP_DIR/${breed}.startanimallst.HD; 
   awk '{print $1,"s"}' $TMP_DIR/${breed}.startanimallst.LD;) |sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 2.2' -a1 -e'-' -1 1 -2 1 - <(sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -T ${SRT_DIR} -k1,1 $TMP_DIR/${breed}.startanimallst.HD) |\
   sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 2.2' -a1 -e'-' -1 1 -2 1 - <(sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -T ${SRT_DIR} -k1,1 $TMP_DIR/${breed}.startanimallst.LD) |\
   awk '{if      ($2 == "-" && $3 == "LD") print $1,$3; \
         else if ($2 == "HD" && $3 == "-") print $1,"DB"; \
         else if ($2 == "HD" && $3 == "LD") print $1,"DB"; \
         else print $1,"ooops"}' > $TMP_DIR/${breed}Typisierungsstatus${run}.tmp
         
  $BIN_DIR/awk_umkodierungID1zuID2 $TMP_DIR/${breed}.ovlinfo.umcd $TMP_DIR/${breed}Typisierungsstatus${run}.tmp > $TMP_DIR/${breed}.TVDanimals.lst
  $BIN_DIR/awk_umkodierungID1zuID2_PrintNOTFOUNDs $TMP_DIR/${breed}.mixpedi.umcd $TMP_DIR/${breed}.TVDanimals.lst | awk '{print $1";""NoPedigreeRecord"";"$2}' > $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${run}.csv


    if test -s $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${run}.csv ; then 
	nwl=$(wc -l $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${run}.csv | awk '{print $1}')
        echo " "
        echo "Es hat ${nwl} ${breed} Tiere die zwar einen Genotyp haben aber keinen PedigreeRecord."
	echo "Check file $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${run}.csv und suche nach Ursachen"
	echo "wird im gesammelten logfile nach Abschluss der Imputation zurueckgemeldet an ZO "
        echo " "
    else
	echo "Alle ${breed} Tiere mit Genotyp haben einen PedigreeRecord."
    fi



   #update timestamp for links which had in last Run excluded due to pedigree issues unabhängig fom parameter im parameterfile
   today=$(date '+%Y%m%d' | awk '{print $1"0001"}')
   if test -s $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${oldrun}.csv; then
     for animal in $(awk 'BEGIN{FS=";"}{print $1}' $ZOMLD_DIR/${breed}_TiereMitGenotypOhnePedigree${oldrun}.csv); do
         idanimal=$(awk -v aa=${animal} 'BEGIN{FS=";"}{if($2 == aa)print $1}' $WORK_DIR/animal.overall.info)
         if [ ! -z ${idanimal} ]; then
            for linklist in $(ls ${SNP_DIR}/dataWide*/${zofol}/${idanimal}.lnk); do
              touch -h -t ${today} ${linklist}
            done
         fi
     done
   fi

rm -f $TMP_DIR/${breed}.ovlinfo.umcd
rm -f $TMP_DIR/${breed}.status.umcd
rm -f $TMP_DIR/${breed}.mixpedi.umcd
rm -f $TMP_DIR/${breed}.TVDanimals.lst


else
   echo kenne die angebene Rasse ${1} nicht
fi


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}


