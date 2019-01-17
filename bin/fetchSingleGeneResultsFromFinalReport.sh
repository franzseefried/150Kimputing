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


cd $LAB_DIR
if ! test -s ${EINZELGEN_DIR}/${run} ; then
  mkdir ${EINZELGEN_DIR}/${run}
fi
heute=$(date +"%Y%m%d")
for zo in ${VMS_DIR} ${SHB_DIR} ${BVCH_DIR}; do
#for zo in ${VMS_DIR} ; do
if ! test -d ${zo}/${run} ;then
  mkdir ${zo}/${run}
else
  if [  ! -z "ls  ${zo}/${run} " ];then
    rm -f ${zo}/${run}/*
  fi
fi
done

for labfile in $(ls *toWorkWith) ; do
#for labfile in $(ls Qualitas*toWorkWith) ; do
  nSNP=$(wc -l ${labfile} | awk '{print $1}')
  if [ ${nSNP} -eq 0 ]; then
	rm -f ${labfile}
  else
       breed=$(echo $labfile | cut -b1-3)
       if [ ${breed} == "BSW" ]; then
         ZIELDIR=${BVCH_DIR}/${run}
       fi
       if [ ${breed} == "HOL" ]; then
         ZIELDIR=${SHB_DIR}/${run}
       fi
       if [ ${breed} == "VMS" ]; then
         ZIELDIR=${VMS_DIR}/${run}
       fi
       if ! test -s ${EINZELGEN_DIR}/${run}/${breed} ; then
           mkdir -p ${EINZELGEN_DIR}/${run}/${breed}
       fi
       testsInFiRep=$(awk '{print $1}' ${REFTAB_FiRepTest})
       $BIN_DIR/awk_fetchSingleGenes  ${REFTAB_FiRepTest} ${labfile} > ${EINZELGEN_DIR}/${run}/${breed}/${labfile}.single.gene
      
       for i in ${testsInFiRep[*]};do
        idd=$(awk -v j=${i} '{FS=";"} {if ($6 == j )print $1}' ${REFTAB_SiTeAr})
        bezarg=$(awk -v j=${i} '{FS=";"} {if ($6 == j )print $2}' ${REFTAB_SiTeAr})
        beztyp=$(awk -v j=${i} '{FS=";"} {if ($6 == j )print $5}' ${REFTAB_SiTeAr})
        rasseN=$(awk -v j=${i} '{FS=";"} {if ($6 == j )print $7}' ${REFTAB_SiTeAr})
        
        if [[ "${rasseN}" == *"${breed}"* ]]; then
#echo $labfile $i good
          $BIN_DIR/awk_codeSingleGenesForARGUS ${SNP_DIR}/einzelgen/argus/glossar/${i}GenotypeInterpretation.txt <(awk -v te=${i} '{if($1 == te) print $2";"$3$4}' ${EINZELGEN_DIR}/${run}/${breed}/${labfile}.single.gene) | awk 'BEGIN{FS=";"}{if($2 != "") print}' >> $ZIELDIR/${idd}.${bezarg}.${heute}.CH.${beztyp}.ImportGenmarker.dat
        else
#echo $labfile $i bad
        chckHet=$($BIN_DIR/awk_codeSingleGenesForARGUS ${SNP_DIR}/einzelgen/argus/glossar/${i}GenotypeInterpretation.txt <(awk -v te=${i} '{if($1 == te) print $2";"$3$4}' ${EINZELGEN_DIR}/${run}/${breed}/${labfile}.single.gene) | awk 'BEGIN{FS=";"}{if(substr($2,3,1) == "C" || substr($2,3,1) == "D") print}' | wc -l | awk '{print $1}')
          if [ ${chckHet} -gt 0 ]; then
             echo " "
             echo "Achtung habe das defekte Allel von ${i} in einer Rasse in der es bisher nicht bekannt ist:"
             echo " "
             $BIN_DIR/awk_codeSingleGenesForARGUS ${SNP_DIR}/einzelgen/argus/glossar/${i}GenotypeInterpretation.txt <(awk -v te=${i} '{if($1 == te) print $2";"$3$4}' ${EINZELGEN_DIR}/${run}/${breed}/${labfile}.single.gene) | awk 'BEGIN{FS=";"}{if(substr($2,3,1) == "C" || substr($2,3,1) == "D") print}'
             echo " "
          fi       
       fi
       done  
fi
done



cd ${lokal}
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

