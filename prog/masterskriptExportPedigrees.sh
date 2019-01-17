#!/bin/bash
###
###
###
###   Purpose:   Export Imputing Pedigrees
###   started:   2019-01-16 08:36:39 (fsf)
###
### ###################################################################### ###

set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails

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

### # produce a start message
start_msg () {
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO " ";
}

### # produce an end message
end_msg () {
  $ECHO " ";
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
}




### # ====================================================================== #
### # Main part of the script starts here ...
start_msg

##############################################################
cd /qualstore03/data_zws/snp/50Kimputing
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################



#alle verbaende / imputationssysteme  zusammen . IMMER mandant SBZV da nur dort der job existiert in ARGUS
#mit Ausnahme des Datenbankservers ist das mastersrkipt unabhaengig vom Parameterfile der Imputation -> Archivierung kann erst spaeter erfolgen. 

#schickt Infomail zur Sicherheit ans zws team und max.reich
$BIN_DIR/sendStartMailPedigreeExport.sh


#wenn der Job auf der Datenbank schon laeuft hat er einen speziellen status, dieser wird hier abgefragt. 
#check if it running already. Wenn er schon laeuft, kommt es zum Programm-Abbruch.
rm -f $TMP_DIR/jobstatus.txt
$BIN_DIR/testIfPediExportIsRunning.sh
rSTAT=$(awk '{ sub("\r$", ""); print }' $TMP_DIR/jobstatus.txt | awk '{print $1}')
echo $rSTAT
cat $TMP_DIR/jobstatus.txt
if test ${rSTAT} == 2152 ; then
   echo "Pedigree-Export is already running. it is not allowed to start it de novo"
   $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/masterskriptExportPedigrees.sh
   exit 1 
fi



for zoo in HOL BSW VMS; do
#for zoo in BSW; do
   echo ${zoo};
   #first get ibid from database: job heist PA_ZWS_PEDI.CallExportPedigree, jobid wird geholt, damit der Job via jobid und nicht die plsql prozedur an sich gestartet wird. 
   #Vorteil: mailversand aus ARGUS + job ist auf der Oberflaeche blockiert da "running". 
   #Nachteil: es braucht eine Speicherung des Parameters (parameterfile) welhes in exportPedigrees.sh bzw. dessen update_T_JOB_PARAM.sh Unterprogramm erfolgt
   $BIN_DIR/getJOBIDfromPediExport.sh
      
   #update JOP_VALUE inside exportPedigrees.sh,schreiben der Parameterfile fuer den Datenbankexport und start der Pedigree-Exports  
   ${BIN_DIR}/exportPedigrees.sh -b ${zoo}
     	
done


#schickt Infomail zur Sicherheit ans zws team und max.reich
$BIN_DIR/sendFinishingMailPedigreeExport.sh



##################################
echo Step PedigreeExport done
$BIN_DIR/sendFinishingMailWOarg2.sh $PROG_DIR/masterSkriptExportPedigrees.sh
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler masterskriptExportPedigrees"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/sendFinishingMailWOarg2.sh
        exit 1
fi
echo "----------------------------------------------------"
echo " "



### # ====================================================================== #
### # Script ends here
end_msg



### # ====================================================================== #
### # What comes below is documentation that can be used with perldoc

: <<=cut
=pod

=head1 NAME

   masterskriptExportPedigrees.sh - 

=head1 SYNOPSIS


=head1 DESCRIPTION

Kombinierter Pedigreeexport fuer alle benoetigten Pedigrees


=head2 Requirements




=head1 LICENSE

Artistic License 2.0 http://opensource.org/licenses/artistic-license-2.0


=head1 AUTHOR

fsf <franz.seefried@qualitasag.ch>


=head1 DATE

2019-01-16 08:36:39

=cut
