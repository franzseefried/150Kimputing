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
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the Imputation system with options bsw, hol or vms"
  echo "Usage: $SCRIPT -m <string>"
  echo "  where <string> specifies the Name of the Chip that should be integerated: e.g. QUAGSEQ"
  echo "Usage: $SCRIPT -p <string>"
  echo "  where <string> specifies the Name of the PLINK ped file: complete path is requested"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:m:p: FLAG; do
  case $FLAG in
    b) # set option "b"
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
          if [ ${breed} == "BSW" ]; then
             natfolder=sbzv
          fi
          if [ ${breed} == "HOL" ]; then
             natfolder=swissherdbook
          fi
          if [ ${breed} == "vms" ]; then
             natfolder=mutterkuh
          fi
      else
          usage "Breed not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    m) # set option "s"
      export newchip=$(echo $OPTARG)
      ;;
    p) # set option "s"
      export PEDFILE=$(echo $OPTARG)
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'BREED not specified, must be specified using option -b <string>'   
fi
### # check that setofanomals is not empty
if [ -z "${newchip}" ]; then
    usage 'Parameter for the polymophism must be specified using option -m <string>'      
fi
### # check that setofanomals is not empty
if [ -z "${PEDFILE}" ]; then
    usage 'Parameter for the pedfile must be specified using option -p <string>'
fi
if [ ${breed} == "BSW" ]; then
   pedbreed=bv
   peddata=bvch
   allowedITB="BSW JER"
   pedi=$(echo "${PEDWORK_DIR}/${pedbreed}/UpdatedRenumMergedPedi_${DatPEDIbvch}.txt")
   pedibig=$(echo "${PED_DIR}/${peddata}/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat")
fi
if [ ${breed} == "HOL" ]; then
   pedbreed=rh
   peddata=shb
   allowedITB="HOL RED SIM"
   pedi=$(echo "${PEDWORK_DIR}/${pedbreed}/UpdatedRenumMergedPedi_${DatPEDIshb}.txt")
   pedibig=$(echo "${PED_DIR}/${peddata}/${DatPEDIshb}_pedigree_rrtdm_SHB.dat")
fi
if [ ${breed} == "VMS" ]; then
   pedbreed=vms
   peddata=vms
   allowedITB="LIM AAN"
   pedi=$(echo "${PEDWORK_DIR}/${pedbreed}/UpdatedRenumMergedPedi_${DatPEDIvms}.txt")
   pedibig=$(echo "${PED_DIR}/${peddata}/${DatPEDIvms}_pedigree_rrtdm_VMS.dat")
fi

##########################################################################################
# Funktionsdefinition

# Funktion gibt Spaltennummer gemaess Spaltenueberschrift in csv-File zurueck.
# Es wird erwartet, dass das Trennzeichen das Semikolon (;) ist
getColmnNr () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}

##########################################################################################



#make some basic tests
if [  -z ${PEDFILE} ]; then
echo "OOOPS... ${PEDFILE} does not exist or has size zero"
exit 1
fi
#check that is is in AB coding
CodeAlleles=$(cut -d' ' -f7- ${PEDFILE} | tr ' ' '\n' | sort -T ${SRT_DIR} -u | tr '\n' ' ' |sed 's/ //g')
if [ ${CodeAlleles} != "0AB" ]; then echo "OOOPS... inlcuded Allel Codings are as follows: ${CodeAlleles} ... but \"0AB\" is required"; exit 1; fi
#check NoofElemets
nEqualElements=$(awk '{print NF}' ${PEDFILE} | sort -u -T ${SRT_DIR} | wc -l | awk '{print $1}' )
if [ ${nEqualElements} != 1 ]; then echo "OOOPS... $PEDFILE had records which differ in No. of elements"; exit 1; fi
mapfilename=$(basename ${PEDFILE} | sed 's/\.ped/\.map/g')
mypath=$(dirname ${PEDFILE})
nrecmap=$(wc -l ${mypath}/${mapfilename} | awk '{print $1}')
ngtsped=$(awk '{print (NF-6)/2}' ${PEDFILE} | sort -u -T ${SRT_DIR} | awk '{print $1}')
echo ${ngtsped} ${nrecmap}
if [ ${nrecmap} != ${ngtsped} ]; then echo "OOOPS ... $PEDFIE does not macth to its mapfile"; exit 1; fi  

echo "Your map has ${nrecmap} SNPs"
echo "Be carefull: it is not checked here if your new maps has SNPs which are aready inlcuded in another map with different chromosomes / basepairs!!!!!"
#check that SNP was put into SNPmap parameterlist
getColmnNr QuagCode ${REFTAB_CHIPS} ; colCode=$colNr_
nwcl=$(awk -v cc=${colCode} -v givenChip=${newchip} 'BEGIN{FS=";"}{if($cc == givenChip) print $0}' ${REFTAB_CHIPS} | wc -l | awk '{print $1}')

if [ ${nwcl} != 1 ];then echo "OOOPS... given Map / Chip ${newchip} is not inlcuded or is included more than once in ${REFTAB_CHIPS}  ";exit 1; fi

echo "code not tested from here further on!!!!!!!!!!!!!!!!!!!!!"
#write map now
if [ -z ${SNP_DIR}/data/mapFiles/intergenomics/SNPindex_${newchip}_new_order.txt ]; then echo "OOOPS... map exists already: delete manually for safety reason";exit 1;fi 
awk '{printf "%-53s%+6s%+10s%+15s%+10s\n", $2,NR,$1,$4,NR4}' ${mypath}/${mapfilename} > ${SNP_DIR}/data/mapFiles/intergenomics/SNPindex_${newchip}_new_order.txt
echo "map was written:"
ls -trl ${SNP_DIR}/data/mapFiles/intergenomics/SNPindex_${newchip}_new_order.txt


#make directories
if test -d ${SNP_DIR}/dataWide${newchip} ;then 
   echo "Required directory ${SNP_DIR}/dataWide${newchip} already exists: check or remove manually, I stop here due to safety reason";
   exit 1 
fi
mkdir -p ${SNP_DIR}/dataWide${newchip}
for i in bvch shb vms; do 
   mkdir ${SNP_DIR}/dataWide${newchip}/${i}; 
done
mkdir ${ARCH_DIR}/dataWide${newchip}
for i in anafi bvch cdcb interbeef intergenomics shb vms; do
   mkdir ${ARCH_DIR}/dataWide${newchhip}/${i}; 
done


echo "writing down to archive and set links"
awk -v aa=${allowedITB} '{if(length($1) == 19 && substr($1,1,3) ~ aa ) print substr($1,4,16)}' ${PEDFILE} | while read line; do r=$(grep  $line ${pedibig} | awk '{print $1,substr($5,3,16)}');echo "${line} $r ";done > $TMP_DIR/seq.idanimal.seqid

awk 'BEGIN{FS=" ";OFS=" "}{ if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));NP[$1]=$2;}} else {sub("\015$","",$(NF));ECD=NP[substr($1,4,16)]; if (ECD != "") {print ECD,$0}}}' $TMP_DIR/seq.idanimal.seqid ${PEDFILE} | cut -d' ' -f1,8- > $TMP_DIR/seq.ped
cut -d' ' -f1 $TMP_DIR/seq.ped |while read muni; do awk -v m=${muni} '{if($1 == m)print }' $TMP_DIR/seq.ped > ${ARCH_DIR}/SNP/dataWide${newchip}/${peddata}/705.${muni}.${newchip}.${heute}.TXT.gtTXT;done
cut -d' ' -f1 seq.ped |while read muni; do ln -s ${ARCH_DIR}/SNP/dataWide${newchip}/${peddata}/705.${muni}.${newchip}.${heute}.TXT.gtTXT ${SNP_DIR}/dataWide${newchip}/${peddata}/${muni}.lnk;done

echo "the following links were set:"
ls -trl  ${SNP_DIR}/dataWide${newchip}/${peddata}/*.lnk
echo " "


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT} 

