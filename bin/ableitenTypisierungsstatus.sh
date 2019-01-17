#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
#set -o errexit


if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ]  || [ ${1} == "VMS" ]; then

if [ ${1} == "BSW" ]; then
	zofol=$(echo "bvch")
	natpedi=${PEDI_DIR}/work/bv/${DatPEDIbvch}_pedigree_rrtdm_BVJE.dat
fi
if [ ${1} == "HOL" ]; then
	zofol=$(echo "shb")
	natpedi=${PED_DIR}/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat
fi
if [ ${1} == "VMS" ]; then
    zofol=$(echo "vms")
	natpedi=${PED_DIR}/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat
fi
#set -o nounset
breed=${1};


awk '{print substr($0,1,10)";"substr($0,58,14)}' ${natpedi} | sed 's/ //g' | tr ';' ' '  > $TMP_DIR/${breed}.status.umcd

echo "Typisierungsstatus wird ermittelt"
for dicht in LD HD; do
  colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ImputationDensityLD150K | awk '{print $1}')
  colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
  CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v densit=${dicht} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})


  for chip in ${CHIPS} ; do
    cd $SNP_DIR/dataWide${chip}/${zofol}
    linkarray=$(find -maxdepth 1 -type l -exec basename {} \;)
    echo ${linkarray} | grep "[0-9]" |  sed 's/\.lnk//g' | tr ' ' '\n' 
  done | sort -T ${SRT_DIR} -u | awk -v dd=${dicht} '{print $1,dd}' > $TMP_DIR/${breed}.startanimallst.${dicht}
done


(awk '{print $1,"s"}' $TMP_DIR/${breed}.startanimallst.HD; 
   awk '{print $1,"s"}' $TMP_DIR/${breed}.startanimallst.LD;) |sort -T ${SRT_DIR} -u -t' ' -k1,1 |\
   join -t' ' -o'1.1 2.2' -a1 -e'-' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -T ${SRT_DIR} -k1,1 $TMP_DIR/${breed}.startanimallst.HD) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 2.2' -a1 -e'-' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -T ${SRT_DIR} -k1,1 $TMP_DIR/${breed}.startanimallst.LD) |\
   awk '{if      ($2 == "-" && $3 == "LD") print $1,$3; \
         else if ($2 == "HD" && $3 == "-") print $1,"DB"; \
         else if ($2 == "HD" && $3 == "LD") print $1,"DB"; \
         else print $1,"ooops"}' > $TMP_DIR/${breed}Typisierungsstatus${run}.tmp
         
  $BIN_DIR/awk_umkodierungID1zuID2 $TMP_DIR/${breed}.status.umcd $TMP_DIR/${breed}Typisierungsstatus${run}.tmp > $WORK_DIR/${breed}Typisierungsstatus${run}.txt
cp $WORK_DIR/${breed}Typisierungsstatus${run}.txt $WRK_DIR/${breed}Typisierungsstatus${run}.txt
	  echo "check Typisierungsstatus"
	  n1=$(awk '{print $1 }' $WORK_DIR/${breed}Typisierungsstatus${run}.txt | sort -T ${SRT_DIR} | uniq -c | awk '{if($1 != 1) print}' | wc -l | awk '{print $1}')
	  if [ ${n1} -gt 0 ]; then
	  	echo "ooops $WORK_DIR/${breed}Typisierungsstatus${run}.txt entahelt Tier(e) mehrfach... please check"
	  	exit 1
	  fi
rm -f $TMP_DIR/${breed}.startanimallst.* 
rm -f $TMP_DIR/${breed}Typisierungsstatus${run}.tmp
rm -f $TMP_DIR/${breed}.status.umcd

else
    echo "falsche Rasse, ich stoppe :("
    exit 1
fi

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
