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
  echo "Usage: $SCRIPT -a <string>"
  echo "  where <string> specifies the animal given by 14bytes TVD"
  echo "Usage: $SCRIPT -p <string>"
  echo "  where <string> specifies the parent to be checked given by 14bytes TVD"
  exit 1
}


outtime=$(date +"%x" | awk 'BEGIN{FS="/"}{print $2$1$3}')

while getopts :a:p: FLAG; do
  case $FLAG in
    a) # set option "a"
      SAMPLE=$(echo $OPTARG | tr a-z A-Z)
      ;;
    p) # set option "p"
      PARENT=$(echo $OPTARG | tr a-z A-Z)
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### # check that breed is not empty
if [ -z "${SAMPLE}" ]; then
      usage 'Breed not specified, must be specified using option -b <string>'   
fi
### # check that parent is not empty
if [ -z "${PARENT}" ]; then
    usage 'Parent name must be specified using option -p <string>'      
fi


set -o nounset
set -o errexit

#######Funktionsdefinition
getColmnNrSemicl () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}
##########################

#get Info about SNP from Reftab
getColmnNrSemicl SNP_Name ${ISAGPARENTAGESBOLIST} ; colORG=$colNr_
getColmnNrSemicl SNPName ${ISAGPARENTAGESBOLIST} ; colSCT=$colNr_
getColmnNrSemicl ISAG-Core ${ISAGPARENTAGESBOLIST} ; colCORE=$colNr_
getColmnNrSemicl ISAG-Extra ${ISAGPARENTAGESBOLIST} ; colEXTRA=$colNr_
getColmnNrSemicl Discovery ${ISAGPARENTAGESBOLIST} ; colDISCOVERY=$colNr_
getColmnNrSemicl MS_Imputation ${ISAGPARENTAGESBOLIST} ; colMSIMPUTATION=$colNr_
getColmnNrSemicl Top_A/B_alleles  ${ISAGPARENTAGESBOLIST} ; colALLELES=$colNr_
#echo $colORG $colSCT $colCORE $colEXTRA $colMSIMPUTATION $colALLELES


echo $SAMPLE $PARENT

#holen der IDSAMPLE
IDSAMPLE=$(awk -v ss=${SAMPLE} 'BEGIN{FS=";"}{if($2 == ss) print $1}' $WORK_DIR/animal.overall.info)
IDPARENT=$(awk -v ss=${PARENT} 'BEGIN{FS=";"}{if($2 == ss) print $1}' $WORK_DIR/animal.overall.info)
if test -z ${IDSAMPLE}; then
echo "IDSAMPLE ${SAMPLE} not in $WORK_DIR/animal.overall.info"
exit 1
fi
if test -z ${IDPARENT}; then
echo "IDPARENT ${PARENT} not in $WORK_DIR/animal.overall.info"
exit 1
fi

#pruefen ob genotypisiert
for s in ${IDSAMPLE} ${IDPARENT}; do
n=$(ls -trl $SNP_DIR/dataWide*/*/${s}.lnk | wc -l)
if [ ${n} -gt 0 ]; then
echo ok > /dev/null
else
echo "$s has nor genotype link"
exit 1
fi
done

nS=$(ls $SNP_DIR/dataWide*/*/${IDSAMPLE}.lnk )
nP=$(ls $SNP_DIR/dataWide*/*/${IDPARENT}.lnk )
echo " "
echo "Parentage Verification starts now for ${IDSAMPLE}. Consider only 196 ISAG SNPs. hart programmiert"
echo " "
pids=
for labfile in ${nS} ; do
#(
  errorcounterTIER=0
  fileloc=$(ls -trl   ${labfile} | awk '{print $11}')
  bfileloc=$(basename ${fileloc})
  chip=$(echo ${fileloc} | cut -d'/' -f5 | sed 's/dataWide//g')
  #echo $labfile $fileloc $chip
 
  #aufbau mapfile
  getColmnNrSemicl QuagCode ${REFTAB_CHIPS}; colCC=${colNr_};
  getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS}; colDD=${colNr_};
  intname=$(awk -v cc=${colCC} -v dd=${colDD} -v ee=${chip} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
  awk '{ sub("\r$", ""); print }' $MAP_DIR/intergenomics/SNPindex_${intname}_new_order.txt | sed 's/Dominant Red/Dominant_Red/g' | awk '{if($3 > 30) print "30",toupper($1),"0",$4;else print $3,toupper($1),"0",$4}' > $TMP_DIR/${IDSAMPLE}.${bfileloc}.map
  #aufbau pedfile
  cat ${fileloc} | sed 's/ /o /1' | sed 's/ / 0 0 9 9 /1' | sed 's/^/1 /g' > $TMP_DIR/${IDSAMPLE}.${bfileloc}.ped
  #schneiden der 200 AbstammungsSNP
  awk '{ sub("\r$", ""); print }' ${ISAGPARENTAGESBOLIST} | awk -v a=${colORG} -v b=${colCORE} -v c=${colEXTRA} 'BEGIN{FS=";"}{if($b == 1 || $c == 1) print $a,"Y"}' | awk '{print $1,$2,NR}' > $TMP_DIR/${bfileloc}.outmap.isagsnplst
  cat $TMP_DIR/${bfileloc}.outmap.isagsnplst | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2 1.3' -1 1 -2 1 - <(sed 's/Dominant Red/Dominant_Red/g' $MAP_DIR/intergenomics/SNPindex_${intname}_new_order.txt | awk '{print toupper($1),"a"}' | sort -T ${SRT_DIR} -t' ' -k1,1 ) | sort -T ${SRT_DIR} -t' ' -k3,3n | awk '{print $1}' | tee $TMP_DIR/${IDSAMPLE}.${bfileloc}.GENOEXPSEmap | awk '{print $1,"B"}' > $TMP_DIR/${IDSAMPLE}.${bfileloc}.map.force.Bcount
  $FRG_DIR/plink --ped $TMP_DIR/${IDSAMPLE}.${bfileloc}.ped --map $TMP_DIR/${IDSAMPLE}.${bfileloc}.map --allow-no-sex --missing-genotype '0' --missing-phenotype '9' --cow --extract $TMP_DIR/${IDSAMPLE}.${bfileloc}.GENOEXPSEmap  --recodeA --reference-allele $TMP_DIR/${IDSAMPLE}.${bfileloc}.map.force.Bcount --out $TMP_DIR/${IDSAMPLE}.${bfileloc}.GENOEXPSE > /dev/null
  #zuerst umsortieren des gtstrings aus dem archiv
  head -1 $TMP_DIR/${IDSAMPLE}.${bfileloc}.GENOEXPSE.raw | tr ' ' '\n' | sed -s "s/_[A-Z]$//g" | awk '{if(NR > 6) print $1}' | awk '{print $1,NR}' |sort -T ${SRT_DIR} -t' ' -k1,1 |\
     join -t' '  -o'1.1 1.2 2.3' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${bfileloc}.outmap.isagsnplst) | sort -T ${SRT_DIR} -t' ' -k2,2 |\
     join -t' ' -o'1.1 1.2 1.3 2.1' -1 2 -2 2 - <(tail -1 $TMP_DIR/${IDSAMPLE}.${bfileloc}.GENOEXPSE.raw | tr ' ' '\n' | awk '{if(NR > 6) print $1}' | awk '{print $1,NR}' | sort -T ${SRT_DIR} -t' ' -k2,2) |\
     sort -T ${SRT_DIR} -t' ' -k3,3n | awk -v ii=${IDSAMPLE} '{print $1,ii,$3,$4}' > $TMP_DIR/${IDSAMPLE}.${bfileloc}.neugenoexpse
  #auffuellen fehlende SNP neue Typisierung
  awk -v indi=${IDSAMPLE} 'BEGIN{FS=" "}{ \
      if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$2;ss[$1]=$4;mp[$1]=$3}} \
      else {sub("\015$","",$(NF));bpT=sp[$1];spT=ss[$1];mpT=mp[$1]; \
      if   (bpT != "") print $1,bpT,spT,mpT; \
      else print $1,indi,"--",$3}}' $TMP_DIR/${IDSAMPLE}.${bfileloc}.neugenoexpse $TMP_DIR/${bfileloc}.outmap.isagsnplst > $TMP_DIR/${IDSAMPLE}.${bfileloc}.neugenoexpse.full
 gtALT=$(sort -T ${SRT_DIR} -t' ' -k4,4n $TMP_DIR/${IDSAMPLE}.${bfileloc}.neugenoexpse.full | awk '{gsub("AA","0",$3);gsub("AB","1",$3);gsub("BB","2",$3);gsub("--","5",$3);gsub("NA","5",$3); print $3}' | tr '\n' ' ')
 echo "${IDSAMPLE} ${gtALT}" > $TMP_DIR/${IDSAMPLE}.quartaer
 CLRTn=$(cut -d' ' -f2- $TMP_DIR/${IDSAMPLE}.quartaer | tr ' ' '\n' | grep 5 | wc -l | awk '{print $1}')
 CLRTTier=$(echo ${CLRTn} 200 | awk '{print 1-($1/$2)}')
 echo " "
 
 #hole Eltern genotypen aus dem Archiv
 for plabfile in ${nP}; do
        errorcounterTIER=0
        pfileloc=$(ls -trl   ${plabfile} | awk '{print $11}')
        pbfileloc=$(basename ${pfileloc})
        pchip=$(echo ${pfileloc} | cut -d'/' -f5 | sed 's/dataWide//g')
        #echo $plabfile ${pfileloc} ${pchip}
       
        #aufbau mapfile
        getColmnNrSemicl QuagCode ${REFTAB_CHIPS}; colCC=${colNr_};
        getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS}; colDD=${colNr_};
        intname=$(awk -v cc=${colCC} -v dd=${colDD} -v ee=${pchip} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
        awk '{ sub("\r$", ""); print }' $MAP_DIR/intergenomics/SNPindex_${intname}_new_order.txt | sed 's/Dominant Red/Dominant_Red/g' | awk '{if($3 > 30) print "30",toupper($1),"0",$4;else print $3,toupper($1),"0",$4}' > $TMP_DIR/${IDPARENT}.${pbfileloc}.map
        #aufbau pedfile
        cat ${pfileloc} | sed 's/ /o /1' | sed 's/ / 0 0 9 9 /1' | sed 's/^/1 /g' > $TMP_DIR/${IDPARENT}.${pbfileloc}.ped
        #schneiden der 200 AbstammungsSNP
        awk '{ sub("\r$", ""); print }' ${ISAGPARENTAGESBOLIST} | awk -v a=${colORG} -v b=${colCORE} -v c=${colEXTRA} 'BEGIN{FS=";"}{if($b == 1 || $c == 1) print $a,"Y"}' | awk '{print $1,$2,NR}' > $TMP_DIR/${pbfileloc}.outmap.isagsnplst
        cat $TMP_DIR/${pbfileloc}.outmap.isagsnplst | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2 1.3' -1 1 -2 1 - <(sed 's/Dominant Red/Dominant_Red/g' $MAP_DIR/intergenomics/SNPindex_${intname}_new_order.txt | awk '{print toupper($1),"a"}' | sort -T ${SRT_DIR} -t' ' -k1,1 ) | sort -T ${SRT_DIR} -t' ' -k3,3n | awk '{print $1}' | tee $TMP_DIR/${IDPARENT}.${pbfileloc}.GENOEXPSEmap | awk '{print $1,"B"}' > $TMP_DIR/${IDPARENT}.${pbfileloc}.map.force.Bcount
        $FRG_DIR/plink --ped $TMP_DIR/${IDPARENT}.${pbfileloc}.ped --map $TMP_DIR/${IDPARENT}.${pbfileloc}.map --allow-no-sex --missing-genotype '0' --missing-phenotype '9' --cow --extract $TMP_DIR/${IDPARENT}.${pbfileloc}.GENOEXPSEmap  --recodeA --reference-allele $TMP_DIR/${IDPARENT}.${pbfileloc}.map.force.Bcount --out $TMP_DIR/${IDPARENT}.${pbfileloc}.GENOEXPSE > /dev/null
        #zuerst umsortieren des gtstrings aus dem archiv
        head -1 $TMP_DIR/${IDPARENT}.${pbfileloc}.GENOEXPSE.raw | tr ' ' '\n' | sed -s "s/_[A-Z]$//g" | awk '{if(NR > 6) print $1}' | awk '{print $1,NR}' |sort -T ${SRT_DIR} -t' ' -k1,1 |\
           join -t' '  -o'1.1 1.2 2.3' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${pbfileloc}.outmap.isagsnplst) | sort -T ${SRT_DIR} -t' ' -k2,2 |\
           join -t' ' -o'1.1 1.2 1.3 2.1' -1 2 -2 2 - <(tail -1 $TMP_DIR/${IDPARENT}.${pbfileloc}.GENOEXPSE.raw | tr ' ' '\n' | awk '{if(NR > 6) print $1}' | awk '{print $1,NR}' | sort -T ${SRT_DIR} -t' ' -k2,2) |\
           sort -T ${SRT_DIR} -t' ' -k3,3n | awk -v ii=${IDPARENT} '{print $1,ii,$3,$4}' > $TMP_DIR/${IDPARENT}.${pbfileloc}.neugenoexpse
        #auffuellen fehlende SNP neue Typisierung
        awk -v indi=${IDPARENT} 'BEGIN{FS=" "}{ \
            if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$2;ss[$1]=$4;mp[$1]=$3}} \
            else {sub("\015$","",$(NF));bpT=sp[$1];spT=ss[$1];mpT=mp[$1]; \
            if   (bpT != "") print $1,bpT,spT,mpT; \
            else print $1,indi,"--",$3}}' $TMP_DIR/${IDPARENT}.${pbfileloc}.neugenoexpse $TMP_DIR/${pbfileloc}.outmap.isagsnplst > $TMP_DIR/${IDPARENT}.${pbfileloc}.neugenoexpse.full
       gtALT=$(sort -T ${SRT_DIR} -t' ' -k4,4n $TMP_DIR/${IDPARENT}.${pbfileloc}.neugenoexpse.full | awk '{gsub("AA","0",$3);gsub("AB","1",$3);gsub("BB","2",$3);gsub("--","5",$3);gsub("NA","5",$3); print $3}' | tr '\n' ' ')
       echo "${IDPARENT} ${gtALT}" > $TMP_DIR/${IDPARENT}.quartaer
       CLRTp=$(cut -d' ' -f2- $TMP_DIR/${IDPARENT}.quartaer | tr ' ' '\n' | grep 5 | wc -l | awk '{print $1}')
       CLRTPare=$(echo ${CLRTp} 200 | awk '{print 1-($1/$2)}')

       
       #ls -trl $TMP_DIR/${IDSAMPLE}.quartaer $TMP_DIR/${IDPARENT}.quartaer
       (cat  $TMP_DIR/${IDSAMPLE}.quartaer; cat $TMP_DIR/${IDPARENT}.quartaer) | cut -d' ' -f2- | cut -d' ' -f1-56,58-140,142-145,147-151,153-200 > $TMP_DIR/${IDSAMPLE}.${IDPARENT}.forAnalysis
       #(cat  $TMP_DIR/${IDSAMPLE}.quartaer; cat $TMP_DIR/${IDPARENT}.quartaer) | cut -d' ' -f2-  > $TMP_DIR/${IDSAMPLE}.${IDPARENT}.forCHecking
       #cat $TMP_DIR/${IDSAMPLE}.${IDPARENT}.forAnalysis
       for ((i=1; i<=196; i++));do 
            #nur wenn alle 2 Genotypen vorhanden sind
            NcllrtSNP=$(awk -v j=${i} '{if(NR <= 2) print $j}' $TMP_DIR/${IDSAMPLE}.${IDPARENT}.forAnalysis | grep 5 | wc -l | awk '{print $1}')
            if [ ${NcllrtSNP} -eq 0 ]; then
                DELTA=$(awk -v j=${i} '{if(NR <= 2) print $j}' $TMP_DIR/${IDSAMPLE}.${IDPARENT}.forAnalysis | tr '\n' ' ' | awk ' function abs(v) {return v < 0 ? -v : v} {print abs($1-$2)}')
                #eigentliche Abstammungskontrolle also Tier und Elter unterscheidlich
                if [ ${IDSAMPLE} != ${IDPARENT} ];then
                    if [ ${DELTA} -lt 2 ]; then
                       echo "alles ok " > /dev/null
                    else
                       #echo "$i FEHLER1"
                       errorcounterTIER=$(echo ${errorcounterTIER} | awk '{print $1+1}')
                    fi
                fi
                #identitätskontrolle also Tier wird mit sich selber verglichen
                if [ ${IDSAMPLE} == ${IDPARENT} ];then
                    if [ ${DELTA} -eq 0 ]; then
                       echo "alles ok " > /dev/null
                    else
                       #echo "$i FEHLER1"
                       errorcounterTIER=$(echo ${errorcounterTIER} | awk '{print $1+1}')
                    fi
                fi
            fi
        done
        if [ ${errorcounterTIER} -lt 2 ]; then
          echo "${IDSAMPLE} ${labfile} ${CLRTTier} against ${IDPARENT} ${plabfile} ${CLRTPare}: : - ) ${errorcounterTIER} "
          #echo ${fileloc} ${labfile} ${pfileloc} ${plabfile}
        else
          echo "${IDSAMPLE} ${labfile} ${CLRTTier} against ${IDPARENT} ${plabfile} ${CLRTPare}: OOOPS ${errorcounterTIER} "
          #echo ${fileloc} ${labfile} ${pfileloc} ${plabfile}
        fi
  done
#)&
done


#pid=$!
#pids=(${pids[@]} $pid)
#done
#
#sleep 20
#echo "Here ar the jobids of the stated Jobs"
#echo ${pids[@]}
#nJobs=$(echo ${pids[@]} | wc -w | awk '{print $1}')
#echo "Waiting till Jobs are finished"
#while [ $nJobs -gt 0 ]; do
#  pids_old=${pids[@]}
#  pids=
#  nJobs=0
#  for pid in ${pids_old[@]}; do
#    if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
#      nJobs=$(($nJobs+1))
#      pids=(${pids[@]} $pid)
#    fi
#  done
#  sleep 20
#done


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
