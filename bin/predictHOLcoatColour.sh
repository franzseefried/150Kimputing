#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

#attention this script is a rough one since it reads fix the files. which meand SINGLEGENE must have been done fpr VR etc
breed=HOL

(echo "TVD Dominant_Red MC1R358_1 MC1R_EBR_2 MC1R" 
join -t' ' -o'1.1 1.2 2.2' -1 1 -2 1 <(sort -t' ' -k1,1 $RES_DIR/RUN${run}${breed}.Dominant_Red.Fimpute.SINGLEGENE ) <(sort -t' ' -k1,1 $RES_DIR/RUN${run}${breed}.MC1R358_1.Fimpute.SVM) |\
sort -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 2.2' -1 1 -2 1 - <(sort -t' ' -k1,1 $RES_DIR/RUN${run}${breed}.MC1R_EBR_2.Fimpute.SVM) |\
sort -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 1.4 2.2' -1 1 -2 1 - <(sort -t' ' -k1,1 $RES_DIR/RUN${run}${breed}.MC1R.Fimpute.SVM) |\
sort -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 1.4 1.5 2.2' -1 1 -2 1 - <(sort -t' ' -k1,1 $RES_DIR/RUN${run}${breed}.3bpDelPMELFALB.Fimpute.HAPLOTYPE) |\
sort -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6' -1 1 -2 1 - <(awk 'BEGIN{FS=";"}{if($5 > 0.000) print $2" m"}' $TMP_DIR/${breed}.Blutanteile.mod | sort -t' ' -k1,1) |\
awk '{if      ($2 >= 1)                                   print $0,"variantred RED RH";
      else if ($2 == 0 && $3 <= 1 && $4 >= 0 && $5 == 0)  print $0,"black HOL HO";
      else if ($2 == 0 && $3 <= 1 && $4 >= 0 && $5 >= 0)  print $0,"black HOL RF";
      else if ($2 == 0 && $3 == 2 && $4 >= 1 && $5 == 0)  print $0,"blackred RED RH";
      else if ($2 == 0 && $3 == 2 && $4 >= 1 && $5 >= 1)  print $0,"blackred RED RF";
      else if ($2 == 0 && $3 == 2 && $4 == 0 && $5 == 0)  print $0,"redwild RED RH";
      else if ($2 == 0 && $3 == 2 && $4 == 0 && $5 == 1)  print $0,"redwild RED RH";
      else if ($2 == 0 && $3 == 2 && $4 == 0 && $5 == 2)  print $0,"red RED RH";
      else                                                print $0,"--- HOL --"}' |\
awk '{if($6 == 0) print $0,"fullcolour";
      else if ($6 == 1) print $0,"diluted1";
      else if ($6 == 2) print $0,"diluted2"}' )      > $RES_DIR/${breed}.PhenotypePrediction.CoatColour.txt




echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
