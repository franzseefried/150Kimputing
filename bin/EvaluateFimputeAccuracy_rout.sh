#!/bin/bash
###
###
###
###   Purpose:   Evaluate FImpute Imputation Accuracy for Routine Imputing
###   started:   2018-10-10 09:38:56 (MFI)
###
### ###################################################################### ###
##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

set -o errexit
set -o nounset
set -o pipefail

# ======================================== # ======================================= #
# global constants                         #                                         #
# ---------------------------------------- # --------------------------------------- #
# prog paths                               #                                         #  
ECHO=/bin/echo                             # PATH to echo                            #
DATE=/bin/date                             # PATH to date                            #
BASENAME=/usr/bin/basename                 # PATH to basename function               #
DIRNAME=/usr/bin/dirname                   # PATH to dirname function                #
# ---------------------------------------- # --------------------------------------- #
# directories                              #                                         #
INSTALLDIR=`$DIRNAME ${BASH_SOURCE[0]}`    # installation dir of bashtools on host   #
# ---------------------------------------- # --------------------------------------- #
# files                                    #                                         #
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`       # Set Script Name variable                #
# ======================================== # ======================================= #



### # ====================================================================== #
### # functions

usage () {
  local l_MSG=$1
  echo "$l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  echo "Usage: $SCRIPT -o <string>"
  echo "  where <string> specifies the Output: haplotypes or genotypes"
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the chromosome: numerical chromosome code or wholeGenome"
  echo "Usage: $SCRIPT -n <string>"
  echo "  where <string> specifies the chip name which is used for the higher and lower SNP densities"

  exit 1
}

### # produce a start message
start_msg () {
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
}

### # produce an end message
end_msg () {
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
}



### # ====================================================================== #
### # Use getopts for commandline argument parsing ###
### # If an option should be followed by an argument, it should be followed by a ":".
### # Notice there is no ":" after "h". The leading ":" suppresses error messages from
### # getopts. This is required to get my unrecognized option code to work.
a_example=""
b_example=""
c_example=""
while getopts ":b:o:c:n:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
      else
          usage "Breed not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
     o) # set option "o"
      export output=$(echo $OPTARG)
      if [ ${output} == "genotypes" ] || [ ${output} == "haplotypes" ]; then
          if [ ${output} == "genotypes" ]; then
            outfolder=".out"
          else
            outfolder=".haplos"
          fi
      else
          usage "Output Parameter not correct, must be specified: genotypes / haplotypes using option -o <string>"
          exit 1
      fi
      ;;
     c) # set option "c"
      export BTA=$(echo $OPTARG)
      BTAstring=$((seq 1 1 29 )|tr '\n' ';'|sed 's/^/\;/g')
      g=$(echo ";${BTA};");
      if [ ${BTA} == "wholeGenome" ] || [[ ";${BTAstring};" == *"${g}"* ]] ; then
          echo ${BTA} > /dev/null
      else
          usage "Chromosome Parameter not correct, must be specified: numerical BTAcode or wholeGenome using option -o <string>"
          exit 1
      fi
      ;;
     n) # set option "c"
      export chip=$(echo $OPTARG)
      ;;
    :)
      usage "-$OPTARG requires an argument"
      ;;
    ?)
      usage "Invalid command line argument (-$OPTARG) found"
      ;;
  esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.




echo $FIM_DIR
echo $RES_DIR
echo $TMP_DIR
echo $LOG_DIR

### # ====================================================================== #
### # Main part of the script starts here ...
start_msg

echo "Rasse" $breed 
 
m_c=$(echo ${FIM_DIR}/MASK${breed}BTA${BTA}${outfolder}/genotypes_imp.txt)
n_c=$(echo ${FIM_DIR}/${breed}BTA${BTA}${outfolder}/genotypes_imp.txt)
echo "Imputation Accuracy calculated for:" 
echo "TRUE" $n_c 
echo -e "MASKED" $m_c "\n" 

vgl_cu=$(echo $TMP_DIR/selectedMASK.animals.${breed})
# Files Umformatieren und nur Vergleichstiere behalten
wc -l $vgl_cu
awk '{if(FILENAME==ARGV[1]) {tier[$1]} else {if($1 in tier) {print}}}' $vgl_cu $n_c > ${TMP_DIR}/TrueGeno.eval.${breed}.txt
awk '{if(FILENAME==ARGV[1]) {tier[$1]} else {if($1 in tier) {print}}}' $vgl_cu $m_c > ${TMP_DIR}/ImpGeno.eval.${breed}.txt

awk '{print length($3)}' ${TMP_DIR}/TrueGeno.eval.${breed}.txt | tail -1
awk '{print length($3)}' ${TMP_DIR}/ImpGeno.eval.${breed}.txt | tail -1
awk '{print $1,$3}' ${TMP_DIR}/TrueGeno.eval.${breed}.txt | sed 's/./& /g' | awk -F'   ' '{gsub(/ /,"",$1);print $0}'  | sort -k1,1  > ${TMP_DIR}/TrueGeno.eval.scen.${breed}.txt
awk '{print $1,$3}' ${TMP_DIR}/ImpGeno.eval.${breed}.txt | sed 's/./& /g' | awk -F'   ' '{gsub(/ /,"",$1);print $0}'  | sort -k1,1  > ${TMP_DIR}/ImpGeno.eval.scen.${breed}.txt
nsnp=$(head -1 ${TMP_DIR}/TrueGeno.eval.scen.${breed}.txt | awk '{print NF-1}')
nsnpi=$(head -1 ${TMP_DIR}/ImpGeno.eval.scen.${breed}.txt | awk '{print NF-1}')
echo $nsnp
echo $nsnpi
if [[ "$nsnp" != "$nsnpi" ]];
then 
	echo "Not the same number of SNP in both files -> STOP"
	exit 1
fi

nanim=$(wc -l ${TMP_DIR}/TrueGeno.eval.scen.${breed}.txt | awk '{print $1}' )
nanimi=$(wc -l ${TMP_DIR}/ImpGeno.eval.scen.${breed}.txt | awk '{print $1}' )

if [[ "$nanim" != "$nanimi" ]];
then 
	echo "Not the same number of ANIMALS in both files -> STOP"
	exit 1
fi
	
	echo "Try to define STAT from fimpute result folder (only works if this is the same folder as the MASKFILE)"
	sta_c=$(echo ${FIM_DIR}/MASK${breed}BTA${BTA}${outfolder}/stat_snp.txt)
	if [[ -s "$sta_c" ]];
	then
		echo "File exists "$sta_c
	else
		echo "Can't get the stat_snp file from the fimpute folder of the MASK File -> STOP"
		exit 1
	fi


	echo "Try to define Info from fimpute result folder (only works if this is the same folder as the MASKFILE)"
	info_c=$(echo ${FIM_DIR}/MASK${breed}BTA${BTA}${outfolder}/snp_info.txt)
	if [[ -s "$info_c" ]];
	then
		echo "File exists "$info_c
	else
		echo "Can't get the Info file from the fimpute folder of the MASK File -> provide Info-File -> STOP"
		exit 1
	fi


awk 'NR>2 {print ((0.5*$5)+$6)*2}' $sta_c > ${TMP_DIR}/genecont.eval.${breed}.txt
(echo "MAF"; awk 'NR>2 {print $8}' $sta_c) > ${TMP_DIR}/maf.eval.${breed}.txt
(echo "MAF"; awk 'NR>2 {print $8}' $sta_c) > ${TMP_DIR}/maf_all.eval.${breed}.txt

		
Rscript ${BIN_DIR}/EvaluateIMPACC.R ${RES_DIR}/ $breed "all"  ${TMP_DIR}/ ${FIM_DIR}/



for a in higher lower
do
	high_c=$(echo $TMP_DIR/${breed}.${chip}.${a}.fuerALLELEFREQ2.frq)
	echo $high_c
	if [[ ! -s "$high_c" ]];
	then
	 	echo "File $high_c doesn't exist, no Evaluation of Imputation accuracy with MAF-correction $a is done"
	 	continue
	 fi

	(echo "MAF";  awk '{if(FILENAME==ARGV[1]) 
	{tier[$1]=$1;snp[$1]=$2} else {if($1 in tier) {print snp[$1]}}}' <(awk '{print $2,$5}' $high_c) $sta_c) > ${TMP_DIR}/maf_${a}.eval.${breed}.txt
	head ${TMP_DIR}/maf_${a}.eval.${breed}.txt

	(echo "MAF";  awk '{if(FILENAME==ARGV[1]) 
	{tier[$1]=$1;snp[$1]=$2} else {if($1 in tier) {print snp[$1]}}}' <(awk '{print $2,$5}' $high_c) $sta_c) > ${TMP_DIR}/maf_all_${a}.eval.${breed}.txt
	head ${TMP_DIR}/maf_all_${a}.eval.${breed}.txt

	awk '{if(FILENAME==ARGV[1]) 
	{tier[$1]=$1;snp[$1]=$0} else {if($1 in tier) {print snp[$1]}}}' <(awk '{print $2,$3,$4,$5}' $high_c) $sta_c |\
	awk '{if($2=="B") $5=2*$4; else if($3=="B") $5=(1-$4)*2; print $5}'> ${TMP_DIR}/genecont_${a}.eval.${breed}.txt
	head ${TMP_DIR}/genecont_${a}.eval.${breed}.txt

Rscript ${BIN_DIR}/EvaluateIMPACC.R ${RES_DIR}/ $breed $a  ${TMP_DIR}/ ${FIM_DIR}/


done

Rscript ${BIN_DIR}/Plot_Imputation_Accuracy_rout.R ${RES_DIR}/${breed}.eval.all. ${RES_DIR}/${breed}.eval.higher. ${RES_DIR}/${breed}.eval.lower. $vgl_cu $breed $PDF_DIR $chip
#

### # ====================================================================== #
### # Script ends here
end_msg


### # ====================================================================== #
### # What comes below is documentation that can be used with perldoc

: <<=cut
=pod

=head1 NAME

    - 

=head1 SYNOPSIS


=head1 DESCRIPTION

Evaluate Imputation Accuracy


=head2 Requirements




=head1 LICENSE

Artistic License 2.0 http://opensource.org/licenses/artistic-license-2.0


=head1 AUTHOR

Mirjam Spengeler <mirjam.spengeler@qualitasag.ch>


=head1 DATE

2018-10-10 09:38:56

=cut
