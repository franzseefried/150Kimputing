#!/bin/bash
RIGHT_NOW=$(date )
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
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the parameter for the chromosome"
  echo "Usage: $SCRIPT -p <string>"
  echo "  where <string> specifies the name of the position"
  echo "Usage: $SCRIPT -s <string>"
  echo "  where <string> specifies the name of the SNP"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :p:c:s:b: FLAG; do
  case $FLAG in
    p) # set option "t"
      export map=$(echo $OPTARG | awk '{print ($1)}')
      ;;
    c) # set option "c"
      export chr=$(echo $OPTARG )
      ;;
    s) # set option "s"
      export snp=$(echo $OPTARG )
      ;;
    b) # set option "b"
      export breed=$(echo $OPTARG )
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that TVD is not empty
if [ -z "${chr}" ]; then
      usage 'Chromosome not specified, must be specified using option -c <string>'   
fi
### # check that labefile is not empty
if [ -z "${map}" ]; then
    usage 'Parameter for Position must be specified using option -p <string>'      
fi
if [ -z "${snp}" ]; then
      usage 'SNP not specified, must be specified using option -s <string>'   
fi
if [ -z "${breed}" ]; then
      usage 'Breed not specified, must be specified using option -b <string>'   
fi
set -o nounset
set -o errexit

OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
exit 1
fi

#achrung file hat header geht aber trotzdem mit <
PosOfSNPtoInsertHD=$(awk -v m=${map} '{if($3 < m) print}' $FIM_DIR/${breed}BTA${chr}_FImpute.snpinfo | wc -l | awk '{print $1+1}')
PosOfSNPtoInsertLD=$(awk -v m=${PosOfSNPtoInsertHD} '{if($4 <= m-1) print $5}' $FIM_DIR/${breed}BTA${chr}_FImpute.snpinfo | awk '{if($0 != "[A-Z]" ) print}' | sort -T ${SRT_DIR} -n | awk 'END { print $1+1}')
#echo $PosOfSNPtoInsertHD $PosOfSNPtoInsertLD

echo " "
(awk -v m=${PosOfSNPtoInsertHD} '{if(NR  <= m) print}' $FIM_DIR/${breed}BTA${chr}_FImpute.snpinfo ;
echo "${snp} ${chr} ${map} ${PosOfSNPtoInsertHD} ${PosOfSNPtoInsertLD}" | awk '{print $1,$2,$3,$4,$5}';
awk -v m=${PosOfSNPtoInsertHD} '{if(NR > m && $5 != 0) print $1,$2,$3,$4+1,$5+1; if(NR > m && $5 == 0) print $1,$2,$3,$4,$5}' $FIM_DIR/${breed}BTA${chr}_FImpute.snpinfo ) > $FIM_DIR/${breed}BTA${chr}${snp}_FImpute.snpinfo

#hole Results from direct Genetest
join -t' ' -o'1.1 2.2' -1 5 -2 1 <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) <(sort -T ${SRT_DIR} -t' ' -k1,1 $WRK_DIR/${breed}.${snp}.lst ) > $TMP_DIR/${breed}.${snp}.snp.update
nsnpHD=$(awk '{if($4 != 0 && NR > 1) print $4}' $FIM_DIR/${breed}BTA${chr}_FImpute.snpinfo | sort -T ${SRT_DIR} -n | awk 'END {print $1}')
endstrHD=$(echo $nsnpHD $PosOfSNPtoInsertHD | awk '{print $1-$2}')
nsnpLD=$(awk '{if($5 != 0 && NR > 1) print $5}' $FIM_DIR/${breed}BTA${chr}_FImpute.snpinfo | sort -T ${SRT_DIR} -n | awk 'END {print $1}')
endstrLD=$(echo $nsnpLD $PosOfSNPtoInsertLD | awk '{print $1-$2}')
#echo $nsnpHD $endstrHD $nsnpLD $endstrLD
#insert SNP into SNPfile
(head -1 $FIM_DIR/${breed}BTA${chr}_FImpute.geno ;
awk -v positionHD=${PosOfSNPtoInsertHD} -v endstringHD=${endstrHD} -v positionLD=${PosOfSNPtoInsertLD} -v endstringLD=${endstrLD} 'BEGIN {FS=" "}{if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));status[$1]=$2;}}  \
    else {sub("\015$","",$(NF));STAT="0";STAT=status[$1];if(STAT != "" && $2 == 1){print $1,$2,substr($3,1,(positionHD-1))"#"STAT"#"substr($3,positionHD,endstringHD+1)} \
    if (STAT == "" && $2 == 1) {print $1,$2,substr($3,1,(positionHD-1))"#"5"#"substr($3,positionHD,endstringHD+1)} \
    if(STAT != "" && $2 == 2){print $1,$2,substr($3,1,(positionLD-1))"#"STAT"#"substr($3,positionLD,endstringLD+1)} \
    if (STAT == "" && $2 == 2) {print $1,$2,substr($3,1,(positionLD-1))"#"5"#"substr($3,positionLD,endstringLD+1)}}}' $TMP_DIR/${breed}.${snp}.snp.update $FIM_DIR/${breed}BTA${chr}_FImpute.geno)   | sed 's/#//g' > $FIM_DIR/${breed}BTA${chr}${snp}_FImpute.geno

    
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
