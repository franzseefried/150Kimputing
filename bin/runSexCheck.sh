#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "
##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit
cd ${LAB_DIR}
### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -t <string>"
  echo "  where <string> specifies the parameter for the TVD ID"
  echo "Usage: $SCRIPT -l <string>"
  echo "  where <string> specifies the name of the labfile to be checked"
  echo "Usage: $SCRIPT -f <string>"
  echo "  where <string> specifies the functionname for the sexcheck"
  echo "Usage: $SCRIPT -g <string>"
  echo "  where <string> specifies the geneseek name of the chip"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :t:l:f:g: FLAG; do
  case $FLAG in
    t) # set option "t"
      export tvd=$(echo $OPTARG | awk '{print toupper($1)}')
      cle=$(echo ${tvd} | awk '{print length($1)}')
      if [ ${cle} != 14 ]; then
      echo "TVS was given as ${tvd} which is wrong since it does not count 14 bytes"
      exit 1
      fi
      ;;
    l) # set option "l"
      export labfile=$(echo $OPTARG )
      ;;
    f) # set option "f"
      export sexcheckfunction=$(echo $OPTARG )
      ;;
    g) # set option "g"
      export geneseekname=$(echo $OPTARG )
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that TVD is not empty
if [ -z "${tvd}" ]; then
      usage 'TVD not specified, must be specified using option -t <string>' 
      exit 1  
fi
### # check that labefile is not empty
if [ -z "${labfile}" ]; then
    usage 'Parameter for labfile must be specified using option -l <string>'      
    exit 1
fi
### # check that imap is not empty
if [ -z "${sexcheckfunction}" ]; then
    usage 'Parameter for imap must be specified using option -f <string>'
    exit 1
fi
### # check that imap is not empty
if [ -z "${geneseekname}" ]; then
    usage 'Parameter for imap must be specified using option -g <string>'
    exit 1
fi

OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
exit 1
fi

#define sexcheckfunctions
#PAR grenzen von Wiggans Mail 16.08.2016 Bob Schnabel
PAR () {
awk '{ sub("\r$", ""); print }' ${MAP_DIR}/GeneSeek/SNP_Map_${geneseekname}.txt | awk '{if($3 == "X") print $1" "$2" "$3" "$4}' |\
   awk '{if($4 >= 137109768 && $4 <= 137489806) print $2" "$1;
        if($4 >= 137944239 && $4 <= 139048093) print $2" "$1;
        if($4 >= 140113328 && $4 <= 140454411) print $2" "$1;
        if($4 >= 143036320 && $4 <= 148820237) print $2" "$1}' > $TMP_DIR/sxchck.${geneseekname}.${tvd}.mp
$BIN_DIR/awk_grepLDSNP $TMP_DIR/sxchck.${geneseekname}.${tvd}.mp ${TMP_DIR}/${tvd}.${labfile} > $TMP_DIR/${tvd}.${labfile}.sexchck
nSEX=$(awk '{if($3$4 != "--") print }' $TMP_DIR/${tvd}.${labfile}.sexchck | awk 'END {print NR}')
nSEXHETERO=$(awk '{if($3$4 == "AB") print}' $TMP_DIR/${tvd}.${labfile}.sexchck |awk 'END {print NR}')
#back value from function is here die Anzahl heterozygote Calls Grenze aus Mail von Wiggans er nimmt 50 unabhaengig wieviele SNP es hat
#da die pseudoautosomale Region Test nur bei 50K Chip angewendet wird sind es sowieso immer genuegend SNP
bckval=$(echo ${nSEXHETERO})
}




YCHR () {
awk '{ sub("\r$", ""); print }' ${MAP_DIR}/GeneSeek/SNP_Map_${geneseekname}.txt | awk '{if($3 == "Y") print $2" "$1}' > $TMP_DIR/sxchck.${geneseekname}.${tvd}.mp
#if [ ${gesecode} == "BOVUHDV03" ]; then
#exclude problematic SNPs from 150K chip see mail Gary Evans 7 Dec 2017
#cat $TMP_DIR/sxchck.${chip}.mp | grep -f ${MAP_DIR}/CDCB.SexSNPs.txt > $TMP_DIR/sxchck.${chip}.mp.mod2
#mv $TMP_DIR/sxchck.${chip}.mp.mod2 $TMP_DIR/sxchck.${chip}.mp
#fi
$BIN_DIR/awk_grepLDSNP $TMP_DIR/sxchck.${geneseekname}.${tvd}.mp ${TMP_DIR}/${tvd}.${labfile} > $TMP_DIR/${tvd}.${labfile}.sexchck
nSEX=$(awk 'END {print NR}' $TMP_DIR/${tvd}.${labfile}.sexchck)
nSEXCALLED=$(awk '{if($3$4 != "--") print}' $TMP_DIR/${tvd}.${labfile}.sexchck |awk 'END {print NR}')
#back value from function is here YCALLRATE auf den Y-Chr SNPs
bckval=$(echo ${nSEXCALLED} ${nSEX} | awk '{print $1/$2}')
}

SEXANIMAL=$(awk -v ID=${tvd} 'BEGIN{FS=";"}{if($2 == ID) print $6}' $WORK_DIR/animal.overall.info | sed 's/ //g' |  head -1)
if [ -z ${SEXANIMAL} ]; then echo "Variable SEXANIMAL is NULL for ${tvd} im ${labfile}";exit 1; fi
awk -v tierchen=${tvd} '{if ($2 == tierchen) print $1,$2,$3$4}' ${labfile} > ${TMP_DIR}/${tvd}.${labfile}



#aufruf der SexCheck-Funktion hier
${sexcheckfunction}



if [ ${sexcheckfunction} == "YCHR" ]; then
#logik: Males need more than a proprotion of ${YthrldM} genotype callings, females are allowed to have maximal a proportion of ${YthrldF} called genotype calls
echo ${tvd} ${SEXANIMAL} ${sexcheckfunction} ${geneseekname} ${YthrldM} ${YthrldF} ${bckval} |\
  awk  -v ss=${SEXANIMAL} -v bva=${bckval} -v tdm=${YthrldM} -v tdf=${YthrldF} '{if(ss == "M" && bva <= tdm) print $1";"$2";"$3";"$4";"$5";"$7";Y"; else if(ss == "F" && bva >= tdf) print $1";"$2";"$3";"$4";"$6";"$7";Y";else print $1";"$2";"$3";"$4";"$6";"$7";N" }' > $TMP_DIR/${tvd}.${labfile}.sexcheck
##>> ${ZOMLD_DIR}/${run}.BADsexCheck.lst
fi
if [ ${sexcheckfunction} == "PAR" ]; then
#Logik: males are allowed to have less then ${PARthrld} heterozygous calls, females are requires to have >= than ${PARthrld} heterozygous calls
echo " "
echo ${tvd} ${SEXANIMAL} ${sexcheckfunction} ${geneseekname} ${PARthrld} ${bckval} |\
  awk  -v ss=${SEXANIMAL} -v bva=${bckval} -v td=${PARthrld} '{if(ss == "M" && bva >= td) print $1";"$2";"$3";"$4";"$5";"$6";Y";else if(ss == "F" && bva <= td) print $1";"$2";"$3";"$4";"$5";"$6";Y";else print $1";"$2";"$3";"$4";"$6";"$7";N" }' > $TMP_DIR/${tvd}.${labfile}.sexcheck 
##>> ${ZOMLD_DIR}/${run}.BADsexCheck.lst
fi
rm -f ${TMP_DIR}/${tvd}.${labfile}


    
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
