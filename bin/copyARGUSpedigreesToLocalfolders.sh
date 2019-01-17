#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
export lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit

if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}
fi


echo " "
echo "BVCH"
if test -s ${PEDI_DIR}/data/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat; then
echo "${PEDI_DIR}/data/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat ist bereits vorhanden, Pedigreefile wird nicht geholt von ${DEUTZ_DIR}/qualitas/zws/ "
else
if test -s ${DEUTZ_DIR}/qualitas/zws/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat; then
ls -trl ${DEUTZ_DIR}/qualitas/zws/${DatPEDIbvch}*BVCH* 
mv ${DEUTZ_DIR}/qualitas/zws/${DatPEDIbvch}*BVCH* ${PEDI_DIR}/data/bvch/.
ls -trl ${PEDI_DIR}/data/bvch/${DatPEDIbvch}*BVCH*
else
echo "${DEUTZ_DIR}/qualitas/zws/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat does not exist. Clarify!!!"
exit 1
fi
fi
echo " "

echo " "
echo "JER"
if test -s ${PEDI_DIR}/data/jer/${DatPEDIjer}_pedigree_rrtdm_JER.dat; then
echo "${PEDI_DIR}/data/jer/${DatPEDIjer}_pedigree_rrtdm_JER.dat ist bereits vorhanden, Pedigreefile wird nicht geholt von ${DEUTZ_DIR}/qualitas/zws/ "
else
if test -s ${DEUTZ_DIR}/qualitas/zws/${DatPEDIjer}_pedigree_rrtdm_JER.dat; then
ls -trl ${DEUTZ_DIR}/qualitas/zws/${DatPEDIjer}*JER*
mv ${DEUTZ_DIR}/qualitas/zws/${DatPEDIjer}*JER* ${PEDI_DIR}/data/jer/.
ls -trl ${PEDI_DIR}/data/jer/${DatPEDIjer}*JER*
else
echo "${DEUTZ_DIR}/qualitas/zws/${DatPEDIjer}_pedigree_rrtdm_JER.dat does not exist. Clarify!!!"
exit 1
fi
fi
echo " "



echo "Swissherdbook"
if test -s ${PEDI_DIR}/data/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat; then
echo "${PEDI_DIR}/data/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat ist bereits vorhanden, Pedigreefile wird nicht geholt von ${DEUTZ_DIR}/qualitas/zws/ "
else
if test -s ${DEUTZ_DIR}/qualitas/zws/${DatPEDIshb}_pedigree_rrtdm_SHB.dat; then
ls -trl ${DEUTZ_DIR}/qualitas/zws/${DatPEDIshb}*SHB* 
mv ${DEUTZ_DIR}/qualitas/zws/${DatPEDIshb}*SHB* ${PEDI_DIR}/data/shb/.
ls -trl ${PEDI_DIR}/data/shb/${DatPEDIshb}*SHB*
else
echo "${DEUTZ_DIR}/qualitas/zws/${DatPEDIshb}_pedigree_rrtdm_SHB.dat does not exist. Clarify!!!"
exit 1
fi
fi
echo " "





echo "VMS"
if test -s ${PEDI_DIR}/data/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat; then
echo "${PEDI_DIR}/data/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat ist bereits vorhanden, Pedigreefile wird nicht geholt von ${DEUTZ_DIR}/qualitas/zws/ "
else
if test -s ${DEUTZ_DIR}/qualitas/zws/${DatPEDIvms}_pedigree_rrtdm_VMS.dat; then
ls -trl ${DEUTZ_DIR}/qualitas/zws/${DatPEDIvms}*VMS* 
mv ${DEUTZ_DIR}/qualitas/zws/${DatPEDIvms}*VMS* ${PEDI_DIR}/data/vms/.
ls -trl ${PEDI_DIR}/data/vms/${DatPEDIvms}*VMS*
else
echo "${DEUTZ_DIR}/qualitas/zws/${DatPEDIvms}_pedigree_rrtdm_VMS.dat does not exist. Clarify!!!"
exit 1
echo " "
fi
fi




echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}
