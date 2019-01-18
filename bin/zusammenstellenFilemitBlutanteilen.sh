#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit
set -o nounset

# Kommandozeilenargumenten einlesen und pruefen
if test -z $1; then
  echo "FEHLER: Kein Argument erhalten. Diesem Shell-Script muss ein Rassenkuerzel mitgegeben werden! --> PROGRAMMABBRUCH"
  exit 1
fi
breed=$(echo $1 | awk '{print toupper($1)}')

if [ ${breed} != "BSW" ] && [ ${breed} != "HOL" ] && [ ${breed} != "VMS" ]; then
  echo "FEHLER: Diesem shell-Script wurde ein unbekanntes Rassenkuerzel uebergeben! (BSW und HOL sind zulaessig) --> PROGRAMMABBRUCH"
  exit 1
fi
#set -o nounset

#do not change anything here
OS=$(uname -s)
if [ $OS = "Linux" ]; then
	echo you are on Linux
elif [ $OS = "Darwin" ]; then
	unset LANG
  	echo you are on Mac
else
  echo "FEHLER: Unbekannters Betriebssystem ($OS) --> PROGRAMMABBRUCH"
  exit 1
fi
if [ ${breed} == "BSW" ]; then
	#blutfile=${PED_DIR}/bvch/${DatPEDIbvch}_Blood_pedigree_rrtdm_BVCH.dat
	blutfile=${PEDI_DIR}/work/bv/${DatPEDIbvch}_Blood_pedigree_rrtdm_BVJE.dat
	echo " "
	echo "Ziel: Aubau eines Files mit den Blutanteilen OB und BV und BS. Kein JER da dort zu wenig SNPDaten da sind um z.B. die genom. RelMatrix aufstellen zu koennen" 
	cat ${PEDI_DIR}/work/bv/${DatPEDIbvch}_pedigree_rrtdm_BVJE.dat | tr ' ' '_' | awk '{print substr($0,1,10),substr($0,58,14)}' | sed 's/_//g' > $TMP_DIR/${breed}idTVD.ped
	cat ${PEDI_DIR}/work/bv/${DatPEDIbvch}_pedigree_rrtdm_BVJE.dat | tr ' ' '_' | awk '{print substr($0,58,14),substr($0,41,16)}' | sed 's/_//g' > $TMP_DIR/${breed}ITB16TVD.ped
fi
if [ ${breed} == "HOL" ]; then
	echo "ich nehme das Blutfile vom gemischten SHB / SHZV pedigree: /qualstore03/data_zws/pedigree/work/rh/blut_shb_shzv.dat"
	blutfile=${PEDI_DIR}/work/rh/blut_shb_shzv.dat
	echo " "
	echo "Ziel: Aubau eines Files mit den Blutanteilen SI und MO und HO"
	cat ${PEDI_DIR}/work/rh/pedi_shb_shzv.dat | tr ' ' '_' | awk '{print substr($0,1,10),substr($0,58,14)}' | sed 's/_//g' > $TMP_DIR/${breed}idTVD.ped
	cat ${PEDI_DIR}/work/rh/pedi_shb_shzv.dat | tr ' ' '_' | awk '{print substr($0,58,14),substr($0,41,16)}' | sed 's/_//g' > $TMP_DIR/${breed}ITB16TVD.ped
fi
if [ ${breed} == "VMS" ]; then
	blutfile=${PED_DIR}/vms/${DatPEDIvms}_Blood_pedigree_rrtdm_VMS.dat
	echo " "
	echo "Ziel: Aubau eines Files mit den Blutanteilen LM und DR und AN" 
	cat ${PEDI_DIR}/data/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat | tr ' ' '_' | awk '{print substr($0,1,10),substr($0,58,14)}' | sed 's/_//g' > $TMP_DIR/${breed}idTVD.ped
	cat ${PEDI_DIR}/data/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat | tr ' ' '_' | awk '{print substr($0,58,14),substr($0,41,16)}' | sed 's/_//g' > $TMP_DIR/${breed}ITB16TVD.ped
fi

${PEDBIN_DIR}/convertBlutFormat ${blutfile} $TMP_DIR/${breed}blutfile.out
err=$(echo $?)
if [ ${err} -gt 0 ]; then
	echo "ooops Fehler ${PEDBIN_DIR}/convertBlutFormat"
	exit 1
fi

if [ ${breed} == "BSW" ]; then
	#die relevanten Blutanteile zur vereinfachten Rasseberechnung wurden von USN definiert uns werden hier abgearbeitet
	for i in OB BV BS; do
    	echo "consider ${i} fuer BSW"
    	awk -v m=${i} '{if($2 == m) print $1,$2,$3}' $TMP_DIR/${breed}blutfile.out | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/blutfile${i}.out 
	done

	echo "struktur output iitbid16;tvd;ob-anteil;bs-anteil;bv-anteil"
	awk '{print $1" l"}' $TMP_DIR/${breed}blutfile.out | sort -T ${SRT_DIR} -T ${SRT_DIR} -u |  sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 2.3' -a1 -e'0' -1 1 -2 1 - $TMP_DIR/blutfileOB.out  |\
   		sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2 2.3' -a1 -e'0' -1 1 -2 1 - $TMP_DIR/blutfileBS.out |\
   		sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2 1.3 2.3' -a1 -e'0' -1 1 -2 1 - $TMP_DIR/blutfileBV.out |\
   		tr ' ' ';' | sed 's/\;/ /1' > $TMP_DIR/${breed}.Blutanteile.tmp
	$BIN_DIR/awk_umcodeVonEINSaufZWEImitLeerschlag $TMP_DIR/${breed}idTVD.ped $TMP_DIR/${breed}.Blutanteile.tmp | awk '{print $1,$1";"$2}'  > $TMP_DIR/${breed}.Blutanteile.tvd
	$BIN_DIR/awk_umcodeVonEINSaufZWEImitLeerschlag $TMP_DIR/${breed}ITB16TVD.ped  $TMP_DIR/${breed}.Blutanteile.tvd | tr ' ' ';' | awk 'BEGIN{FS=";"}{print $1";"$2";"$3/1000";"$4/1000";"$5/1000}' > $TMP_DIR/${breed}.Blutanteile.txt
       rm -f $TMP_DIR/blutfileOB.out $TMP_DIR/blutfileBS.out $TMP_DIR/blutfileBV.out
fi



if [ ${breed} == "HOL" ]; then
	#die relevanten Blutanteile zur vereinfachten Rasseberechnung wurden von USN definiert uns werden hier abgearbeitet
	sed 's/SIM/SI/g' $TMP_DIR/${breed}blutfile.out | sed 's/HOL/HO/g' | sed 's/MON/MO/g' > $TMP_DIR/${breed}blutfile.out.mod
	for i in SI MO HO; do
    	echo "consider ${i} fuer HOL"
    	awk -v m=${i} '{if($2 == m) print $1,$2,$3}' $TMP_DIR/${breed}blutfile.out.mod | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/blutfile${i}.out 
	done

	echo "struktur output itbid16;tvd;si-anteil;mo-anteil;ho-anteil"
	awk '{print $1" l"}' $TMP_DIR/${breed}blutfile.out | sort -T ${SRT_DIR} -T ${SRT_DIR} -u |  sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 2.3' -a1 -e'0' -1 1 -2 1 - $TMP_DIR/blutfileSI.out  |\
   		sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2 2.3' -a1 -e'0' -1 1 -2 1 - $TMP_DIR/blutfileMO.out |\
   		sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2 1.3 2.3' -a1 -e'0' -1 1 -2 1 - $TMP_DIR/blutfileHO.out |\
   		tr ' ' ';' | sed 's/\;/ /1' > $TMP_DIR/${breed}.Blutanteile.tmp
	$BIN_DIR/awk_umcodeVonEINSaufZWEImitLeerschlag $TMP_DIR/${breed}idTVD.ped $TMP_DIR/${breed}.Blutanteile.tmp | awk '{print $1,$1";"$2}'  > $TMP_DIR/${breed}.Blutanteile.tvd
	$BIN_DIR/awk_umcodeVonEINSaufZWEImitLeerschlag $TMP_DIR/${breed}ITB16TVD.ped  $TMP_DIR/${breed}.Blutanteile.tvd | tr ' ' ';' | awk 'BEGIN{FS=";"}{print $1";"$2";"$3/1000";"$4/1000";"$5/1000}'  > $TMP_DIR/${breed}.Blutanteile.txt
        rm -f $TMP_DIR/blutfileHO.out $TMP_DIR/blutfileMO.out $TMP_DIR/blutfileSI.out
fi


if [ ${breed} == "VMS" ]; then
	#die relevanten Blutanteile zur vereinfachten Rasseberechnung wurden von USN definiert uns werden hier abgearbeitet
	for i in LM DR AN ; do
    	echo "consider ${i} fuer VMS"
    	awk -v m=${i} '{if($2 == m) print $1,$2,$3}' $TMP_DIR/${breed}blutfile.out | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/blutfile${i}.out 
	done

	echo "struktur output iitbid16;tvd;lm-anteil;dr-anteil;an-anteil"
	awk '{print $1" l"}' $TMP_DIR/${breed}blutfile.out | sort -T ${SRT_DIR} -T ${SRT_DIR} -u |  sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 2.3' -a1 -e'0' -1 1 -2 1 - $TMP_DIR/blutfileLM.out  |\
   		sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2 2.3' -a1 -e'0' -1 1 -2 1 - $TMP_DIR/blutfileDR.out |\
   		sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2 1.3 2.3' -a1 -e'0' -1 1 -2 1 - $TMP_DIR/blutfileAN.out |\
   		tr ' ' ';' | sed 's/\;/ /1' > $TMP_DIR/${breed}.Blutanteile.tmp
	$BIN_DIR/awk_umcodeVonEINSaufZWEImitLeerschlag $TMP_DIR/${breed}idTVD.ped $TMP_DIR/${breed}.Blutanteile.tmp | awk '{print $1,$1";"$2}'  > $TMP_DIR/${breed}.Blutanteile.tvd
	$BIN_DIR/awk_umcodeVonEINSaufZWEImitLeerschlag $TMP_DIR/${breed}ITB16TVD.ped  $TMP_DIR/${breed}.Blutanteile.tvd | tr ' ' ';' | awk 'BEGIN{FS=";"}{print $1";"$2";"$3/1000";"$4/1000";"$5/1000}' > $TMP_DIR/${breed}.Blutanteile.txt
        rm -f $TMP_DIR/blutfileAN.out $TMP_DIR/blutfileDR.out $TMP_DIR/blutfileLM.out
fi
rm -f $TMP_DIR/${breed}idTVD.ped
rm -f $TMP_DIR/${breed}ITB16TVD.ped
rm -f $TMP_DIR/blutfile${i}.out 
rm -f $TMP_DIR/${breed}.Blutanteile.tvd
rm -f $TMP_DIR/${breed}.Blutanteile.tmp
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
