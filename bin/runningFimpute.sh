#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

###############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
#numberOfParallelMEHDIJobs=$(eval nproc|awk '{printf "%.0f", ($1/2)+0.5}' | awk '{print $1}')


### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  echo "Usage: $SCRIPT -o <string>"
  echo "  where <string> specifies the Output: haplotypes or genotypes"
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the chromosome: numerical chromosome code or wholeGenome"
  echo "Usage: $SCRIPT -d <string>"
  echo "  where <string> specifies the specific variant: e.g. CSN1_A1A2"
  echo "Usage: $SCRIPT -m <string>"
  echo "  where <string> specifies the Option for Evaluating Imputation Acc.: MASK or nothing is allowed"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:o:c:d:m: FLAG; do
  case $FLAG in
    b) # set option "b"
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
     d) # set option "d"
      export SNP=$(echo $OPTARG)
      ;;
     m) # set option "m"
      export impacc=$(echo $OPTARG)
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
     *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'breed not specified, must be specified using option -b <string>'   
fi
if [ -z "${output}" ]; then
      usage 'OUTPUT not specified, must be specified using option -o <string>'   
fi
if [ -z "${BTA}" ]; then
      usage 'code for chromosome not specified, must be specified using option -c <string>'   
fi
#$SNP kann leer sein!!!
#echo "Hallo ; ${SNP} ; "
#impacc kann leer sein
#echo "Hallo ; ${impacc} ;"
set -o errexit
set -o nounset

echo "running runFimpute BTA ${BTA} using ${numberOfParallelMEHDIJobs} No. of threads for breed ${impacc}${breed}:"



(echo "title=\"${BTA} Imputation for ${impacc}${breed}\";"
echo "genotype_file=\"${FIM_DIR}/${impacc}${breed}BTA${BTA}${SNP}_FImpute.geno\";"
echo "snp_info_file=\"${FIM_DIR}/${breed}BTA${BTA}${SNP}_FImpute.snpinfo\";"
echo "ped_file=\"${FIM_DIR}/${breed}Fimpute.ped_siredamkorrigiert_NGPsiredamkorrigiert\";"
echo "parentage_test /ert_mm=0.02 /ert_m=0.01 /find_match_cnflt /remove_conflict;"
if [ ${output} == "genotypes" ] ;then
echo "save_genotype;"
fi
echo "add_ungen /min_fsize=4 /output_min_fsize=4 /output_min_call_rate=0.95;"
echo "output_folder=\"${FIM_DIR}/${impacc}${breed}BTA${BTA}${SNP}${outfolder}\";"
echo "njob=${numberOfParallelMEHDIJobs};")> ${FIM_DIR}/${impacc}${breed}Fimpute${BTA}${SNP}.${output}_standard.ctr

echo " "
echo "FImpute Parameters are as follows"
cat ${FIM_DIR}/${impacc}${breed}Fimpute${BTA}${SNP}.${output}_standard.ctr


$FRG_DIR/FImpute_Linux ${FIM_DIR}/${impacc}${breed}Fimpute${BTA}${SNP}.${output}_standard.ctr -o




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
