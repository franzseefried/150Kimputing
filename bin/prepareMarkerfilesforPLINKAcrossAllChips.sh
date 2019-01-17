#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit
START_DIR=pwd

if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ]  || [ ${1} == "VMS" ]; then

if [ ${1} == "BSW" ]; then
	zofol=$(echo "bvch")
fi
if [ ${1} == "HOL" ]; then
	zofol=$(echo "shb")
fi
if [ ${1} == "VMS" ]; then
        zofol=$(echo "vms")
fi
else 
  echo "unbekannter Systemcode BSW VMS oder HOL erlaubt"
  exit 1
fi


if [ -z $2 ]; then
   echo "brauche den Code für die Chipdichte HD oder LD"
   exit 1
elif [ $2 == "LD" ] || [ $2 == "HD" ]; then
   echo $2 > /dev/null
   dichte=${2}
else
   echo "Der Code fuer die Chipdichte muss LD oder HD sein, ist aber ${2}"
   exit 1
fi


set -o nounset
breed=${1}

if [ ${snpstrat} == "F" ]; then
if ! test -s $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt; then
   echo "you have choosen a fixSNPdatum, where I tried to take the SNPmap now"
   echo "that map $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt does not exist or has size ZERO"
   echo "change parameter or check"
   $BIN_DIR/sendErrorMail.sh ${SCRIPT} $1
   exit 1
fi
else
   echo "you have NOT choosen a fixSNPdatum, which meacn you want to select a new SNPset"
   echo "for that you have to creat an OVERall snp map and eliminate all problems with coodinates etc..."
   echo "change parameter or do this first"
   $BIN_DIR/sendErrorMail.sh ${SCRIPT} $1
   exit 1
fi

awk '{if(NR > 1) print $2,$1,"0",$3}' $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/OVERALL.${breed}.zielmap







#define breed loop
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ImputationDensityLD50K | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')

CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v ee=${dichte} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
lgtC=$(echo ${CHIPS} | wc -w | awk '{print $1}')
if [ ${lgtC} -eq 0 ]; then
  echo "keie Chips angegeben in ${REFTAB_CHIPS} in Kolonne ImputationDensityLD50K "
  exit 1
fi

#Zielmap wg unterschiedlichen Koordinaten zwischen den Chipmaps z.B. Hapmap34615BES10Contig5861594
#OVERALL.zielmap ist hier eine 50K V1&V2 map HD also noch nicht drin
#awk '{ sub("\r$", ""); print }' ${FIFTYKMAP} | tr ';' ' ' |\
#       sed -n '2,$p' |\
#       awk '{if($4 != "#NV" )print $8,$4" 0 "$9; else if($3 != "#NV" )print $8,$3" 0 "$9 }' |\
#       sed 's/-//g' |\
#       sed 's/_//g' |\
#       sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/OVERALL.${breed}.zielmap

#maps: Zeile 79 bis 84 holt die 50K Vereinigungszielmap und wann immer unterschiede in den Koordinaten oder dem BTA bestehen, werden die Angaben aus der 50K Zielmap uebernommen
for chip in ${CHIPS} ; do
  chipINTid=$(awk -v ccc=${chip} 'BEGIN{FS=";"}{if($5 == ccc) print $8}' /qualstore03/data_zws/parameterfiles/CDCBchipCodes.lst )
  echo $chip $chipINTid
  sed 's/Dominant Red/Dominant_Red/g' $MAP_DIR/intergenomics/SNPindex_${chipINTid}_new_order.txt |\
    awk '{print $2,$3,$1,"0",$4}' |\
    sed 's/Dominant Red/Dominant_Red/g' |\
    sed 's/_//g' |\
    sed 's/-//g' |\
    sort -T ${SRT_DIR} -t' ' -k1,1n |\
    cut -d' ' -f2- |\
    awk '{if($1 > 30) print "30",$2,$3,$4; else print $1,$2,$3,$4}' |\
    awk '{print NR,$1,$2,$3,$4}' |\
    sort -T ${SRT_DIR} -t' ' -k3,3 |\
    join -t' ' -o'1.1 1.2 1.3 1.4 1.5 2.1 2.4' -e'-' -a1 -1 3 -2 2 - $TMP_DIR/OVERALL.${breed}.zielmap |\
    awk '{if((($2 != $6) && ($6 != "-")) || (($5 != $7) && ($6 != "-"))) print $1,$6,$3,$4,$7; else print $1,$2,$3,$4,$5}' |\
    sort -T ${SRT_DIR} -t' ' -k1,1n |\
    cut -d' ' -f2- > $TMP_DIR/${breed}.${chip}.map
done



#vorbereitung Koordinaten usw
if [ ${2} == "LD" ]; then
echo "baue Vereinigungsmap GGPLDv2 und GGPLDv3 und GGPLDv4 GGPLD47K"
    awk '{ sub("\r$", ""); print $1,$2,$5,$6}' /qualstore03/data_zws/snp/data/mapFiles/GGPv3_Public_E_StrandReport_FDT.txt  | sed 's/Dominant Red/Dominant_Red/g' | tr ' ' '\t' > ${MAP_DIR}/SNP_Map-GGPLDv3.txt
    awk '{ sub("\r$", ""); print }' $LDMAP | awk '{if($3 < 30 && $3 !~ "[A-Z]" && $4 > 0) print $3,$2,"0",$4}' |\
       sed 's/-//g' | sed 's/_//g' | sed 's/ Neogen/ /g' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}LD2.srtmap
    awk '{ sub("\r$", ""); print }' $LD3MAP | awk '{if($3 < 30 && $3 !~ "[A-Z]" && $4 > 0) print $3,$2,"0",$4}' |\
       sed 's/-//g' | sed 's/_//g' | sed 's/ Neogen/ /g' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}LD3.srtmap
	awk '{ sub("\r$", ""); print }' $LD4MAP | awk '{if($3 < 30 && $3 !~ "[A-Z]" && $4 > 0) print $3,$2,"0",$4}' |\
       sed 's/-//g' | sed 's/_//g' | sed 's/ Neogen/ /g' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}LD4.srtmap
    awk '{ sub("\r$", ""); print }' $LD4bMAP | awk '{if($3 < 30 && $3 !~ "[A-Z]" && $4 > 0) print $3,$2,"0",$4}' |\
       sed 's/-//g' | sed 's/_//g' | sed 's/ Neogen/ /g' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}LD4b.srtmap       
    awk '{ sub("\r$", ""); print }' $ULDMAP | awk '{if($3 < 30 && $3 !~ "[A-Z]" && $4 > 0) print $3,$2,"0",$4}' |\
       sed 's/-//g' | sed 's/_//g' | sed 's/ Neogen/ /g' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}ULD.srtmap
    join -t' ' -o'1.1 1.2 1.3 1.4' -1 2 -2 2 $TMP_DIR/${breed}LD3.srtmap $TMP_DIR/${breed}LD2.srtmap > $TMP_DIR/${breed}LD23.tmpmap
    join -t' ' -o'1.1 1.2 1.3 1.4' -v1 -1 2 -2 2 $TMP_DIR/${breed}LD3.srtmap $TMP_DIR/${breed}LD2.srtmap > $TMP_DIR/${breed}LDnur3.tmpmap
    join -t' ' -o'2.1 2.2 2.3 2.4' -v2 -1 2 -2 2 $TMP_DIR/${breed}LD3.srtmap $TMP_DIR/${breed}LD2.srtmap > $TMP_DIR/${breed}LDnur2.tmpmap
    (cat $TMP_DIR/${breed}LD23.tmpmap;
	cat $TMP_DIR/${breed}LDnur3.tmpmap;
	cat $TMP_DIR/${breed}LDnur2.tmpmap;) | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}LD.map

    join -t' ' -o'1.1 1.2 1.3 1.4' -v1 -1 2 -2 2 $TMP_DIR/${breed}LD4.srtmap $TMP_DIR/${breed}LD.map > $TMP_DIR/${breed}LDneuIn4.tmpmap
    join -t' ' -o'1.1 1.2 1.3 1.4' -v1 -1 2 -2 2 $TMP_DIR/${breed}LD4b.srtmap $TMP_DIR/${breed}LD.map | sort -T ${SRT_DIR} -t' ' -k2,2 | join -t' ' -o'1.1 1.2 1.3 1.4' -v1 -1 2 -2 2 - <(sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/${breed}LDneuIn4.tmpmap) > $TMP_DIR/${breed}LDneuIn4b.tmpmap
    join -t' ' -o'1.1 1.2 1.3 1.4' -v1 -1 2 -2 2 $TMP_DIR/${breed}ULD.srtmap $TMP_DIR/${breed}LD.map | sort -T ${SRT_DIR} -t' ' -k2,2 | join -t' ' -o'1.1 1.2 1.3 1.4' -v1 -1 2 -2 2 - <(sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/${breed}LDneuIn4.tmpmap) | sort -T ${SRT_DIR} -t' ' -k2,2 | join -t' ' -o'1.1 1.2 1.3 1.4' -v1 -1 2 -2 2 - <(sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/${breed}LDneuIn4b.tmpmap) > $TMP_DIR/${breed}LDneuInULD.tmpmap
        
    (cat $TMP_DIR/${breed}LD23.tmpmap;
	cat $TMP_DIR/${breed}LDnur3.tmpmap;
	cat $TMP_DIR/${breed}LDnur2.tmpmap;
	cat $TMP_DIR/${breed}LDneuIn4.tmpmap;
	cat $TMP_DIR/${breed}LDneuIn4b.tmpmap;
	cat $TMP_DIR/${breed}LDneuInULD.tmpmap;) | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}LD.zielmap	
fi



#vorbereitung Koordinaten usw
if [ $2 == "HD" ]; then
echo "baue Vereinigungsmenge: also SNPs 50kV1 UND 50kV2 und 150K"
    awk '{ sub("\r$", ""); print }' ${FIFTYKMAP} | tr ';' ' ' |\
       sed -n '2,$p' |\
       awk '{if($4 != "#NV" )print $8,$4" 0 "$9; else if($3 != "#NV" )print $8,$3" 0 "$9 }' |\
       sed 's/-//g' |\
       sed 's/_//g' |\
       sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/${breed}HD.zielmap              
fi


#aufbau der Maps schlussendlich hier
for cch in ${CHIPS}; do
      join -t' ' -o'1.1 2.1 2.2 2.3 2.4' -1 3 -2 2 <(awk '{print NR,$0}' $TMP_DIR/${breed}.${cch}.map | sort -T ${SRT_DIR} -t' ' -k3,3) <(sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/${breed}${dichte}.zielmap)     >  $WORK_DIR/${breed}.${cch}.map
      join -t' ' -o'1.1 1.2 1.3 1.4 1.5' -1 3 -2 2 -v1 <(awk '{print NR,$0}' $TMP_DIR/${breed}.${cch}.map | sort -T ${SRT_DIR} -t' ' -k3,3) <(sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/${breed}${dichte}.zielmap) >> $WORK_DIR/${breed}.${cch}.map
      sort -T ${SRT_DIR} -t' ' -k1,1n $WORK_DIR/${breed}.${cch}.map | cut -d' ' -f2- > $TMP_DIR/${breed}.tmp.${cch}.map
      awk '{if($1 > 30) print "30",$2,$3,$4; else print $1,$2,$3,$4}' $TMP_DIR/${breed}.tmp.${cch}.map |\
      awk '{if($4 == "#NV") print $1,$2,$3,"0";else print $1,$2,$3,$4}' |\
      awk '{if($1 == "#NV") print "0",$2,$3,$4;else print $1,$2,$3,$4}' |\
      awk '{print NR,$1,$2,$3,$4}' |\
      sort -T ${SRT_DIR} -t' ' -k3,3 |\
      join -t' ' -o'1.1 1.2 1.3 1.4 1.5 2.1 2.4' -e'-' -a1 -1 3 -2 2 - $TMP_DIR/OVERALL.${breed}.zielmap |\
      awk '{if((($2 != $6) && ($6 != "-")) || (($5 != $7) && ($6 != "-"))) print $1,$6,$3,$4,$7; else print $1,$2,$3,$4,$5}' |\
      sort -T ${SRT_DIR} -t' ' -k1,1n |\
      cut -d' ' -f2- |\
      awk '{if($1 > 30) print "30",$2,$3,$4; else print $1,$2,$3,$4}' |\
      awk '{if($4 == "#NV") print $1,$2,$3,"0";else print $1,$2,$3,$4}' |\
      awk '{if($1 == "#NV") print "0",$2,$3,$4;else print $1,$2,$3,$4}' > $WORK_DIR/${breed}.${cch}.map
done




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
