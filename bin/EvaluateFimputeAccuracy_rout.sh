#!/bin/bash
###
###
###
###   Purpose:   Evaluate FImpute Imputation Accuracy
###   started:   2018-10-10 09:38:56 (MFI)
###
### ###################################################################### ###

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
  $ECHO "$l_MSG"
  $ECHO "Usage: $SCRIPT -b <Rasse>"
  $ECHO "  where -b <Rasse> entweder BSW, HOL oder VMS..."
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
while getopts ":b:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      breed=$OPTARG
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

# Check whether required arguments have been defined
if test "$breed" == ""; then
  usage "-b <breed> not defined"
fi

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
### # ====================================================================== #
### # Main part of the script starts here ...
start_msg

echo "Rasse" $breed 

echo "Check if Temp-folder exists:" >> $LOG
 
	m_c=$(${FIM_DIR}/MASK${breed}BTA${BTA}.out/genotypes_imp.txt)
	n_c=$(${FIM_DIR}/${breed}BTA${BTA}.out/genotypes_imp.txt)
	echo "Imputation Accuracy calculated for:" 
	echo "TRUE" $n_c 
	echo -e "MASKED" $m_c "\n" 

	if [ -n "${VGL-}" ]
	then
		echo "You defined a set of individuals to be compared" 
    	echo $VGL 
		vgl_cu=$(awk -v c="$c" '{print $c}' <(echo $VGL))
    	n_v=$(awk '{print NF}' <(echo $VGL))
    	if [[ "$n_v" != "$n_m" ]]; 
    	then
    		echo "The number of comparison files does not correspond to the number of Imputations"
    		exit 1
    	fi
    	echo "You defined a set of individuals to be compared????" >> $LOG
    	echo $vgl_cu >> $LOG
	else
    	echo "No files with individuals to be compared are provided">> $LOG
    	echo "Define animals in comparison from the files">>$LOG
    	echo "Search for individuals with different chip density in the two genotype files" >> $LOG
    	cat <(awk '{print $1,$2}' $n_c) <(awk '{print $1,$2}' $m_c) | sort | uniq -c | awk '$1!=2 {print $2}' | sort | uniq -c | awk '$1==2 {print $2}' > ${TEMP}/VergleichTiere.txt	   
    	vgl_cu=$(echo ${TEMP}/VergleichTiere.txt)
    fi
	# Files Umformatieren und nur Vergleichstiere behalten
	wc -l $vgl_cu
	awk '{if(FILENAME==ARGV[1]) {tier[$1]} else {if($1 in tier) {print}}}' $vgl_cu $n_c > ${TEMP}/TrueGeno.txt
	awk '{if(FILENAME==ARGV[1]) {tier[$1]} else {if($1 in tier) {print}}}' $vgl_cu $m_c > ${TEMP}/ImpGeno.txt

	awk '{print length($3)}' ${TEMP}/TrueGeno.txt | tail
	awk '{print length($3)}' ${TEMP}/ImpGeno.txt | tail
	awk '{print $1,$3}' ${TEMP}/TrueGeno.txt | sed 's/./& /g' | awk -F'   ' '{gsub(/ /,"",$1);print $0}'  | sort -k1,1  > ${TEMP}/true_scen.txt
	awk '{print $1,$3}' ${TEMP}/ImpGeno.txt | sed 's/./& /g' | awk -F'   ' '{gsub(/ /,"",$1);print $0}'  | sort -k1,1  > ${TEMP}/imp_scen.txt
	nsnp=$(head -1 ${TEMP}/true_scen.txt | awk '{print NF-1}')
	nsnpi=$(head -1 ${TEMP}/imp_scen.txt | awk '{print NF-1}')
	echo $nsnp
	echo $nsnpi
	if [[ "$nsnp" != "$nsnpi" ]];
	then 
		echo "Not the same number of SNP in both files -> STOP"
		exit 1
	fi
	
	nanim=$(wc -l ${TEMP}/true_scen.txt | awk '{print $1}' )
	nanimi=$(wc -l ${TEMP}/imp_scen.txt | awk '{print $1}' )
	
	if [[ "$nanim" != "$nanimi" ]];
	then 
		echo "Not the same number of ANIMALS in both files -> STOP"
		exit 1
	fi
	
	#Check Stat file
	
	if [ -n "${STAT-}" ]
	then
		echo "You defined a stat file for MAF and Genecontent" >> $LOG
    	echo $STAT >> $LOG
		sta_c=$(awk -v c="$c" '{print $c}' <(echo $STAT))
    	n_v=$(awk '{print NF}' <(echo $STAT))
    	if [[ "$n_v" == 1 ]]; 
    	then
    		echo "You provided only 1 Statfile -> same MAF and GeneContent will be used for all scenarios" >> $LOG
    	elif [[ "$n_v" != "$n_m" ]]; 
    	then
    		echo "The number of stat files does not correspond to the number of Imputations and is neither 1 ->STOP" >> $LOG
    		exit 1
    	fi
	else
    	echo "No STAT files and no MAF or GeneContent files are provided">> $LOG
    	echo "Try to define STAT from fimpute result folder (only works if this is the same folder as the MASKFILE)">>$LOG
    	sta_c=$(awk -F'/' '{OFS="/"}{$NF="";print $0,"stat_snp.txt"}' <(echo $m_c))
    	if [[ -s "$sta_c" ]];
    	then
    		echo "File exists "$sta_c >> $LOG
    	else
    		echo "Can't get the stat_snp file from the fimpute folder of the MASK File -> provide stat or MAF and GeneContent File -> STOP" >> $LOG
    		exit 1
    	fi
    fi
    
	if [ -n "${INFO-}" ]
	then
		echo "You defined a Info File" >> $LOG
    	echo $INFO >> $LOG
		info_c=$(awk -v c="$c" '{print $c}' <(echo $INFO))
    	n_v=$(awk '{print NF}' <(echo $INFO))
    	if [[ "$n_v" == 1 ]]; 
    	then
    		echo "You provided only 1 Statfile -> same Infofile will be used for all scenarios" >> $LOG
    	elif [[ "$n_v" != "$n_m" ]]; 
    	then
    		echo "The number of stat files does not correspond to the number of Imputations and is neither 1 ->STOP" >> $LOG
    		exit 1
    	fi
	else
    	echo "No Info File was provided">> $LOG
    	echo "Try to define Info from fimpute result folder (only works if this is the same folder as the MASKFILE)">>$LOG
    	info_c=$(awk -F'/' '{OFS="/"}{$NF="";print $0,"snp_info.txt"}' <(echo $m_c))
    	if [[ -s "$info_c" ]];
    	then
    		echo "File exists "$info_c >> $LOG
    	else
    		echo "Can't get the Info file from the fimpute folder of the MASK File -> provide Info-File -> STOP" >> $LOG
    		exit 1
    	fi
    fi

	awk 'NR>2 {print ((0.5*$5)+$6)*2}' $sta_c > ${TEMP}/genecont.txt
	(echo "MAF"; awk 'NR>2 {print $8}' $sta_c) > ${TEMP}/maf.txt
	(echo "MAF"; awk 'NR>2 {print $8}' $sta_c) > ${TEMP}/maf_all.txt
	out_c=$(awk -v c="$c" '{print $c}' <(echo $OUT))
	echo "# PARAMETER FILE    ">${out_c}_EvaluateFimputeOutput.par
	echo "NumAnim             $nanim">>${out_c}_EvaluateFimputeOutput.par
	echo "NumMarker           $nsnp">>${out_c}_EvaluateFimputeOutput.par
	echo "LogFile             '${out_c}_EvaluateFimputeOutput.log'">>${out_c}_EvaluateFimputeOutput.par
	echo "In_Val_truegeno     '${TEMP}/true_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
	echo "In_Val_impgeno      '${TEMP}/imp_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
	echo "In_MAF              '${TEMP}/maf.txt'">>${out_c}_EvaluateFimputeOutput.par
	echo "In_MAF_ALL          '${TEMP}/maf_all.txt'">>${out_c}_EvaluateFimputeOutput.par
	echo "In_GeneContent      '${TEMP}/genecont.txt'">>${out_c}_EvaluateFimputeOutput.par
	echo "In_SNPInfo          '${info_c}'">>${out_c}_EvaluateFimputeOutput.par
	echo "Out_CorrelationFile '${out_c}_Ind_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
	echo "Out_CorrFileMAF '${out_c}_MAF_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
    echo "Out_CorrSNP                 '${out_c}_SNP_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
			
	$BIN/EvalAnyFimptoFimp_regionalacc ${out_c}_EvaluateFimputeOutput.par >> $LOG
	if [ -n "${HIGHER-}" ]
	then
		
		n_high=$(awk '{print NF}' <(echo $HIGHER))
		if [  "$n_high" == "$n_m" ]
		then
			echo "You defined Allele frequency files HIGHER for each scenario" >> $LOG
			echo "Please make sure that the file is formatted in plink .frq (CHR, SNP, A1 (minor A or B), A2 (major A or B)" >> $LOG
			high_c=$(awk -v c="$c" '{print $c}' <(echo $HIGHER))
			echo $high_c >> $LOG
		
			(echo "MAF"; awk '{if(FILENAME==ARGV[1]) 
			{tier[$1]} else {if($2 in tier) {print $5}}}' $sta_c $high_c) > ${TEMP}/maf_higher.txt
			
			(echo "MAF"; awk '{if(FILENAME==ARGV[1]) 
			{tier[$1]} else {if($2 in tier) {print $5}}}' $sta_c $high_c) > ${TEMP}/maf_all_higher.txt
	
			awk '{if(FILENAME==ARGV[1]) 
			{tier[$1]} else {if($2 in tier) {print}}}' $sta_c $high_c |\
			awk '{if($3=="B") $6=2*$5; else if($4=="B") $6=(1-$5)*2; print $6}'> ${TEMP}/genecont_higher.txt
			out_c=$(echo ${out_c}_higher)
			awk 'NR>2 {print ((0.5*$5)+$6)*2}' $sta_c > ${TEMP}/genecont.txt
			(echo "MAF"; awk 'NR>2 {print $8}' $sta_c) > ${TEMP}/maf.txt
			(echo "MAF"; awk 'NR>2 {print $8}' $sta_c) > ${TEMP}/maf_all.txt
			echo "# PARAMETER FILE    ">${out_c}_EvaluateFimputeOutput.par
			echo "NumAnim             $nanim">>${out_c}_EvaluateFimputeOutput.par
			echo "NumMarker           $nsnp">>${out_c}_EvaluateFimputeOutput.par
			echo "LogFile             '${out_c}_EvaluateFimputeOutput.log'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_Val_truegeno     '${TEMP}/true_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_Val_impgeno      '${TEMP}/imp_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_MAF              '${TEMP}/maf_higher.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_MAF_ALL          '${TEMP}/maf_all_higher.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_GeneContent      '${TEMP}/genecont_higher.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_SNPInfo          '${info_c}'">>${out_c}_EvaluateFimputeOutput.par
			echo "Out_CorrelationFile '${out_c}_Ind_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "Out_CorrFileMAF '${out_c}_MAF_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "Out_CorrSNP                 '${out_c}_SNP_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
			
			$BIN/EvalAnyFimptoFimp_regionalacc ${out_c}_EvaluateFimputeOutput.par >> $LOG

		elif [ -n "${HIGH_HOW-}" ]
		then
			n_howhi=$(awk '{print NF}' <(echo $HIGH_HOW))
			if [ "$n_howhi" != "$n_m" ]
			then
				echo "Please define HIGH_HOW (0 1) for all scenarios" >> $LOG
			else	
				echo "You defined which HIGHER file to be used for which scenario" >> $LOG
				howhi_c=$(awk -v c="$c" '{print $c}' <(echo $HIGH_HOW))
				if [ "$howhi_c" == 1 ]
				then
					echo "For $n_c you defined a HIGHER file" >> $LOG
					echo "Please make sure that the file is formatted in plink .frq (CHR, SNP, A1 (minor A or B), A2 (major A or B)" >> $LOG
					val=$(awk -v c="$c" '{for(i=1;i<=c;i++) t+=$i; print t; t=0}' <(echo $HIGH_HOW))
					high_c=$(awk -v c="$val" '{print $c}' <(echo $HIGHER))
					echo $high_c >> $LOG
				
					(echo "MAF"; awk '{if(FILENAME==ARGV[1]) 
					{tier[$1]} else {if($2 in tier) {print $5}}}' $sta_c $high_c) > ${TEMP}/maf_higher.txt
					
					(echo "MAF"; awk '{if(FILENAME==ARGV[1]) 
					{tier[$1]} else {if($2 in tier) {print $5}}}' $sta_c $high_c) > ${TEMP}/maf_all_higher.txt
					
					awk '{if(FILENAME==ARGV[1]) 
					{tier[$1]} else {if($2 in tier) {print}}}' $sta_c $high_c |\
					awk '{if($3=="B") $6=2*$5; else if($4=="B") $6=(1-$5)*2; print $6}'> ${TEMP}/genecont_higher.txt
					
					out_c=$(echo ${out_c}_higher)
					

					echo "# PARAMETER FILE    ">${out_c}_EvaluateFimputeOutput.par
					echo "NumAnim             $nanim">>${out_c}_EvaluateFimputeOutput.par
					echo "NumMarker           $nsnp">>${out_c}_EvaluateFimputeOutput.par
					echo "LogFile             '${out_c}_EvaluateFimputeOutput.log'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_Val_truegeno     '${TEMP}/true_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_Val_impgeno      '${TEMP}/imp_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_MAF              '${TEMP}/maf_higher.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_MAF_ALL          '${TEMP}/maf_all_higher.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_GeneContent      '${TEMP}/genecont_higher.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_SNPInfo          '${info_c}'">>${out_c}_EvaluateFimputeOutput.par
					echo "Out_CorrelationFile '${out_c}_Ind_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "Out_CorrFileMAF '${out_c}_MAF_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "Out_CorrSNP                 '${out_c}_SNP_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
					
					$BIN/EvalAnyFimptoFimp_regionalacc ${out_c}_EvaluateFimputeOutput.par >> $LOG
				else
					echo "no HIGHER for this Scenario" >> $LOG
				fi
			fi
		fi
	fi
	out_c=$(awk -v c="$c" '{print $c}' <(echo $OUT))
	if [ -n "${LOWER-}" ]
	then
		
		n_low=$(awk '{print NF}' <(echo $LOWER))
		if [  "$n_low" == "$n_m" ]
		then
			echo "You defined Allele frequency files LOWER for each scenario" >> $LOG
			echo "Please make sure that the file is formatted in plink .frq (CHR, SNP, A1 (minor A or B), A2 (major A or B)" >> $LOG
			low_c=$(awk -v c="$c" '{print $c}' <(echo $LOWER))
			echo $low_c >> $LOG
		
			(echo "MAF"; awk '{if(FILENAME==ARGV[1]) 
			{tier[$1]} else {if($2 in tier) {print $5}}}' $sta_c $low_c) > ${TEMP}/maf_lower.txt
			
			(echo "MAF"; awk '{if(FILENAME==ARGV[1]) 
			{tier[$1]} else {if($2 in tier) {print $5}}}' $sta_c $low_c) > ${TEMP}/maf_all_lower.txt
	
			awk '{if(FILENAME==ARGV[1]) 
			{tier[$1]} else {if($2 in tier) {print}}}' $sta_c $low_c |\
			awk '{if($3=="B") $6=2*$5; else if($4=="B") $6=(1-$5)*2; print $6}'> ${TEMP}/genecont_lower.txt
			out_c=$(echo ${out_c}_lower)
			
			echo "# PARAMETER FILE    ">${out_c}_EvaluateFimputeOutput.par
			echo "NumAnim             $nanim">>${out_c}_EvaluateFimputeOutput.par
			echo "NumMarker           $nsnp">>${out_c}_EvaluateFimputeOutput.par
			echo "LogFile             '${out_c}_EvaluateFimputeOutput.log'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_Val_truegeno     '${TEMP}/true_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_Val_impgeno      '${TEMP}/imp_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_MAF              '${TEMP}/maf_lower.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_MAF_ALL          '${TEMP}/maf_all_lower.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_GeneContent      '${TEMP}/genecont_lower.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "In_SNPInfo          '${info_c}'">>${out_c}_EvaluateFimputeOutput.par
			echo "Out_CorrelationFile '${out_c}_Ind_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "Out_CorrFileMAF '${out_c}_MAF_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
			echo "Out_CorrSNP                 '${out_c}_SNP_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
			
			$BIN/EvalAnyFimptoFimp_regionalacc ${out_c}_EvaluateFimputeOutput.par >> $LOG

		elif [ -n "${LOW_HOW-}" ] || [ -n "${HIGH_HOW-}" ]
		then
			if [ -z "${LOW_HOW-}" ] && [ -n "${HIGH_HOW-}" ]
			then
				LOW_HOW=$(echo $HIGH_HOW)
				echo "The same scenarios for Higher and lower are called" >> $LOG
			fi
			 
			n_howlo=$(awk '{print NF}' <(echo $LOW_HOW))
			if [ "$n_howlo" != "$n_m" ]
			then
				echo "Please define LOW_HOW (0 1) for all scenarios" >> $LOG
			else	
				echo "You defined which LOWER file to be used for which scenario" >> $LOG
				howlo_c=$(awk -v c="$c" '{print $c}' <(echo $LOW_HOW))
				if [ "$howlo_c" == 1 ]
				then
					echo "For $n_c you defined a LOWER file" >> $LOG
					echo "Please make sure that the file is formatted in plink .frq (CHR, SNP, A1 (minor A or B), A2 (major A or B)" >> $LOG
					val=$(awk -v c="$c" '{for(i=1;i<=c;i++) t+=$i; print t; t=0}' <(echo $LOW_HOW))
					low_c=$(awk -v c="$val" '{print $c}' <(echo $LOWER))
					echo $low_c >> $LOG
				
					(echo "MAF"; awk '{if(FILENAME==ARGV[1]) 
					{tier[$1]} else {if($2 in tier) {print $5}}}' $sta_c $low_c) > ${TEMP}/maf_lower.txt
					
					(echo "MAF"; awk '{if(FILENAME==ARGV[1]) 
					{tier[$1]} else {if($2 in tier) {print $5}}}' $sta_c $low_c) > ${TEMP}/maf_all_lower.txt
					
					awk '{if(FILENAME==ARGV[1]) 
					{tier[$1]} else {if($2 in tier) {print}}}' $sta_c $low_c |\
					awk '{if($3=="B") $6=2*$5; else if($4=="B") $6=(1-$5)*2; print $6}'> ${TEMP}/genecont_lower.txt
					out_c=$(echo ${out_c}_lower)
					
					echo "# PARAMETER FILE    ">${out_c}_EvaluateFimputeOutput.par
					echo "NumAnim             $nanim">>${out_c}_EvaluateFimputeOutput.par
					echo "NumMarker           $nsnp">>${out_c}_EvaluateFimputeOutput.par
					echo "LogFile             '${out_c}_EvaluateFimputeOutput.log'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_Val_truegeno     '${TEMP}/true_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_Val_impgeno      '${TEMP}/imp_scen.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_MAF              '${TEMP}/maf_lower.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_MAF_ALL          '${TEMP}/maf_all_lower.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_GeneContent      '${TEMP}/genecont_lower.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "In_SNPInfo          '${info_c}'">>${out_c}_EvaluateFimputeOutput.par
					echo "Out_CorrelationFile '${out_c}_Ind_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "Out_CorrFileMAF '${out_c}_MAF_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
					echo "Out_CorrSNP                 '${out_c}_SNP_correlations.txt'">>${out_c}_EvaluateFimputeOutput.par
					
					$BIN/EvalAnyFimptoFimp_regionalacc ${out_c}_EvaluateFimputeOutput.par >> $LOG
				else
					echo "No LOWER for this scenario" >>$LOG
				fi
			fi
		fi
	fi
if [ -n "${Anim-}" ]
then
Rscript Plot_Imputation_Accuracy_reg.R $OUT $Anim >> $LOG
echo "true"
else
Rscript Plot_Imputation_Accuracy_reg.R $OUT >> $LOG
echo "false"
fi
#

### # ====================================================================== #
### # Script ends here
end_msg >> $LOG
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
