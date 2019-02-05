#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT} 
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
# Funktion gibt Spaltennummer gemaess Spaltenueberschrift in einem File zurueck.
# Es wird erwartet, dass das Trennzeichen Leerzeichen sind
getColmnNrLZ () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: File
  colNr_=$(head -1 $2 | tr -s ' ' | tr ' ' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
  if test -z $colNr_ ; then
    echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
    echo "... oder Feldtrenner in $2 sind nicht Leerzeichen"
    exit 1
  fi
}
### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  echo "Usage: $SCRIPT -a <string>"
  echo "  where <string> specifies the Parameter for the Female to be mated"
  echo "Usage: $SCRIPT -m <string>"
  echo "  where <string> specifies the Parameter for the Male to be mated"  
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:a:m: FLAG; do
  case $FLAG in
    b) # set option "b"
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
     #     if [ ${breed} == "BSW" ]; then
     #        natfolder=sbzv
     #     fi
     #     if [ ${breed} == "HOL" ]; then
     #        natfolder=swissherdbook
     #     fi
     #     if [ ${breed} == "vms" ]; then
     #        natfolder=mutterkuh
     #     fi
      else
          usage "Breed not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    a) # set option "a"
      export female=$(echo $OPTARG | sed 's/\.//g')
      lf=$(echo $female | awk '{print length($1)}')
      if [ ${lf} != 14 ]; then
         echo "TVDid of female to be mated does not have 14 bytes"
      exit 1
      fi      
      ;;
    m) # set option "m"
      export male=$(echo $OPTARG | sed 's/\.//g')
      lm=$(echo $male | awk '{print length($1)}')
      if [ ${lm} != 14 ]; then
         echo "TVDid of male to be mated does not have 14 bytes"
      exit 1
      fi
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
echo $male $female
## # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'BREED not specified, must be specified using option -b <string>'   
fi
### # check that setofanomals is not empty
if [ -z "${female}" ]; then
    usage 'Parameter for the Female to be Mated must be specified using option -a <string>'      
fi
if [ -z "${male}" ]; then
    usage 'Parameter for the Male to be Mated must be specified using option -m <string>'
fi
smryFILE=${RES_DIR}/GTpredictionSummary-${breed}-${run}.txt

if ! test -s ${smryFILE} ; then
   echo "${smryFILE} does not exist or has size zero"
   exit 1
fi




#function to read haplotype summary


getColmnNrLZ GebDat ${smryFILE}; colSTART=$(echo $colNr_ | awk '{print $1+1}')
getColmnNrLZ SireTVD ${smryFILE}; colEND=$(echo $colNr_ | awk '{print $1-1}')


echo $colSTART $colEND

echo "check where female is a carrier:" 
CarrierCol=$(awk -v ani=${female}  -v lation=${pop} '{if($1 == ani) print  }' ${smryFILE} | cut -d' ' -f${colSTART}-${colEND} | tr ' ' '\n' | cat -n | awk '{if($2 > 0) print $1}' | tr '\n' ' ' | awk -v g=${colSTART} '{for(i = 1; i <= NF; i++) { print $i+(g-1) } }')

#echo $CarrierCol 
echo ${female} is carrier of
for i in ${CarrierCol}; do
awk -v ani=${female} -v b=${i} '{if(NR == 1) print $b  }' ${smryFILE}
awk -v ani=${female} -v b=${i} '{if($1 == ani) print  $1,$b}' ${smryFILE}
done
echo " "
echo " "
echo "select males as mating partner which do NOT carry any haplotype where ${female} is a carrier into $TMP_DIR/${female}.matingPartnersAvoidRiskMatings"
cp ${smryFILE} ${TMP_DIR}/${breed}.mateOrganizer.${run}

for j in ${CarrierCol}; do
  awk -v b=${i} -v jj=${j} '{if(substr($3,7,1) == "M"  && $jj == 0) print }' ${TMP_DIR}/${breed}.mateOrganizer.${run} > $TMP_DIR/${breed}.mateOrganizer.${run}.red
  mv ${TMP_DIR}/${breed}.mateOrganizer.${run}.red ${TMP_DIR}/${breed}.mateOrganizer.${run}
done

getColmnNrLZ GebDat ${smryFILE}; colSORT=$(echo $colNr_ | awk '{print $1}')
(awk '{if(NR == 1) print}' ${smryFILE};
sort -T ${SRT_DIR} -t' ' -k${colSORT}nr ${TMP_DIR}/${breed}.mateOrganizer.${run} ) > $TMP_DIR/${female}.matingPartnersAvoidRiskMatings

echo "select males as mating partner which do carry any haplotype where ${female} is a carrier into $TMP_DIR/${female}.matingPartnersForRiskMating"
cp ${smryFILE} ${TMP_DIR}/${breed}.mateOrganizer.${run}

rm -f $TMP_DIR/${breed}.mateOrganizer.${run}.red
for j in ${CarrierCol}; do
awk -v b=${i} -v jj=${j} '{if(substr($3,7,1) == "M" && $jj > 0) print }' ${TMP_DIR}/${breed}.mateOrganizer.${run} >> $TMP_DIR/${breed}.mateOrganizer.${run}.red
done
getColmnNrLZ GebDat ${smryFILE}; colSORT=$(echo $colNr_ | awk '{print $1}')
(awk '{if(NR == 1) print}' ${smryFILE};
sort -T ${SRT_DIR} -t' ' -k${colSORT}nr ${TMP_DIR}/${breed}.mateOrganizer.${run}.red ) > $TMP_DIR/${female}.matingPartnersForRiskMatings

echo " "
echo "print selected MatingPartner"
echo " "
nm=$(awk -v mm=${male} '{if($1 == mm) print}' $TMP_DIR/${female}.matingPartnersAvoidRiskMatings | wc -l | awk '{print $1}' )
if [ ${nm} -gt 0 ]; then
echo "Selected MatingSire ${male} fits to selected female"
(awk '{if(NR == 1) print }' ${smryFILE};
awk -v ff=${female} '{if($1 == ff) print}' $smryFILE;
awk -v mm=${male} '{if($1 == mm) print}' $smryFILE)
else
nr=$(awk -v mm=${male} '{if($1 == mm) print}' $TMP_DIR/${female}.matingPartnersForRiskMatings | wc -l | awk '{print $1}' )
if [ ${nr} -gt 0 ]; then
echo "OOOOOPS ... Selected MatingSire ${male} does NOT fit to selected female"
(awk '{if(NR == 1) print }' ${smryFILE};
awk -v ff=${female} '{if($1 == ff) print}' $smryFILE;
awk -v mm=${male} '{if($1 == mm) print}' $smryFILE)
fi
fi
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT} 
