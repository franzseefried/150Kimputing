#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "
##############################################################
cd /qualstore03/data_zws/snp/50Kimputing
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit

### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -t <string>"
  echo "  where <string> specifies the parameter for the TVD ID"
  echo "Usage: $SCRIPT -l <string>"
  echo "  where <string> specifies the name of the labfile to be checked"
  echo "Usage: $SCRIPT -i <string>"
  echo "  where <string> specifies the name of the mapfile to be checked"
  echo "Usage: $SCRIPT -n <string>"
  echo "  where <string> specifies the No of SNPs to be checked"
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the name of the chip"
  echo "Usage: $SCRIPT -o <string>"
  echo "  where <string> specifies the flag of the outtimestamp"
  echo "Usage: $SCRIPT -a <string>"
  echo "  where <string> specifies the filename for outfile"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :t:l:i:n:c:o:a: FLAG; do
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
    i) # set option "i"
      export imap=$(echo $OPTARG )
      ;;
    n) # set option "n"
      export nmap=$(echo $OPTARG )
      ;;
    c) # set option "c"
      export chip=$(echo $OPTARG )
      ;;
    o) # set option "o"
      export outtime=$(echo $OPTARG )
      ;;
    a) # set option "a"
      export labfileout=$(echo $OPTARG )
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
if [ -z "${imap}" ]; then
    usage 'Parameter for imap must be specified using option -i <string>'
exit 1
fi
### # check that nmap is not empty
if [ -z "${nmap}" ]; then
    usage 'Parameter for nmap must be specified using option -n <string>'
exit 1
fi
### # check that chip is not empty
if [ -z "${chip}" ]; then
    usage 'Parameter for chip must be specified using option -c <string>'
exit 1
fi
### # check that outtime is not empty
if [ -z "${outtime}" ]; then
    usage 'Parameter for outtime must be specified using option -o <string>'
exit 1
fi
### # check that outtime is not empty
if [ -z "${labfileout}" ]; then
    usage 'Parameter for outfilenameending must be specified using option -a <string>'
exit 1
fi

OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
exit 1
fi

#(
idin=$(awk -v m=${tvd} '{if($1 == m) print $2}' $TMP_DIR/intergenomics.id.lst.${labfile} )
awk -v tierchen=${tvd} '{if ($2 == tierchen) print $1,$3$4}' ${LAB_DIR}/${labfile} > ${TMP_DIR}/${tvd}.${labfile}
gt=$($BIN_DIR/awk_snporder ${TMP_DIR}/${tvd}.${labfile} $TMP_DIR/MAP${imap}.srt | sort -T ${SRT_DIR} -t' ' -k1,1n | awk '{gsub("AA","2",$2);gsub("AB","1",$2);gsub("BB","0",$2);gsub("--","5",$2); print $2}' | tr '\n' ' ' | sed 's/ //g')
if ! test -z ${gt} ;then
   nSNP=$(echo $gt | wc -c | awk '{print $1-1}' )
   notcall=$(echo $gt | sed 's/[0-2]//g' | wc -c | awk '{print $1-1}' )
   callrate=$(echo ${notcall} ${nSNP} | awk '{printf "%.0f\n", (1-($1/$2))*100}')
   if [ ${callrate} -lt 90 ]; then echo "habe Callrate von ${callrate} von $idin in string von ${labfile}, bitte checken denn das ist sehr wenig"; exit 1; fi
   if [ ${nSNP} != ${nmap} ]; then echo "habe unterschiedich viele Genotypen im built String als in der Map"; echo ${nSNP} ${nmap} ${labfile}; exit 1; fi
   land=CHE
   echo "705 ${land} ${idin} ${nSNP} ${gt}"  | awk '{print $1$2,$3,$4,$5 }'| awk '{printf "%-10s%+19s%+11s %s\n" , $1,$2,$3,$4 }' > $ITL_DIR/${chip}/705.${idin}.${chip}.${outtime}.${labfileout}
fi  
#)&

    
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
