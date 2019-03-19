#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT} 
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  echo "Usage: $SCRIPT -d <string>"
  echo "  where <string> specifies the Imputation level: e.g. LD150KImputation"
  exit 1
}
### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi
while getopts :b:d: FLAG; do
  case $FLAG in
    b) # set option "b"
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
      else
          usage "Breed not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    d) # set option "d"
      export SNPlevel=$(echo $OPTARG)
      ;;
     *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'breed not specified, must be specified using option -b <string>'   
fi
if [ -z "${SNPlevel}" ]; then
      usage 'code for SNPlevel not specified, must be specified using option -d <string>'   
fi
if [ ${breed} == "BSW" ]; then
	zofol=$(echo "bvch")
	natpedi=${PED_DIR}/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat
    mixpedi=${PEDI_DIR}/work/bv/${DatPEDIbvch}_pedigree_rrtdm_BVJE.dat
fi
if [ ${breed} == "HOL" ]; then
	zofol=$(echo "shb")
	natpedi=${PED_DIR}/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat
    mixpedi=${PEDI_DIR}/work/rh/pedi_shb_shzv.dat
fi
if [ ${breed} == "VMS" ]; then
    zofol=$(echo "vms")
    natpedi=${PED_DIR}/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat
    mixpedi=${PED_DIR}/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat
fi
set -o nounset
set -o errexit

awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1,2 | sed 's/ //g' | tr ';' ' ' |  sort -T ${SRT_DIR} -u > $TMP_DIR/${breed}.ovlinfo.umcd
#awk '{print substr($0,1,10)";"substr($0,58,14)}' ${natpedi} | sed 's/ //g' | tr ';' ' '  > $TMP_DIR/${breed}.status.umcd
awk '{print substr($0,1,10)";"substr($0,58,14)}' ${mixpedi} | sed 's/ //g' | tr ';' ' ' | awk '{print $2,$1}' > $TMP_DIR/${breed}.mixpedi.umcd

echo "animallists are built"
for dicht in LD HD; do
  colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ${SNPlevel} | awk '{print $1}')
  colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
  CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v densit=${dicht} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})


  for chip in ${CHIPS} ; do
    cd $SNP_DIR/dataWide${chip}/${zofol}
    linkarray=$(find -maxdepth 1 -type l -exec basename {} \;)
    echo ${linkarray} | grep "[0-9]" |  sed 's/\.lnk//g' | tr ' ' '\n' 
  done | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -u | awk -v dd=${dicht} '{print $1,dd}' > $TMP_DIR/${breed}.startanimallst.${dicht}
done


(awk '{print $1,"s"}' $TMP_DIR/${breed}.startanimallst.HD; 
   awk '{print $1,"s"}' $TMP_DIR/${breed}.startanimallst.LD;) |sort -T ${SRT_DIR}  -t' ' -k1,1 |\
   join -t' ' -o'1.1 2.2' -a1 -e'-' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.startanimallst.HD) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 2.2' -a1 -e'-' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.startanimallst.LD) |\
   awk '{if      ($2 == "-" && $3 == "LD") print $1,$3; \
         else if ($2 == "HD" && $3 == "-") print $1,$2; \
         else if ($2 == "HD" && $3 == "LD") print $1,$2; \
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




echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}


