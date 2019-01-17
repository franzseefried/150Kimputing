#######################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
#######################################################
#set -x
HOST=rapid.braunvieh.ch
SERVICE=AR01.braunvieh.ch
USERNAME=gestho
PASSWORD=gestho
SCRIPT=${BIN_DIR}/getIDsfromARGUSforAnimalsMissingInPedigrees.sql
OUTPUTFILE=${TMP_DIR}/ZZZZZZZZZZ.sqlout
SCRIPTPARAMETER="ZZZZZZZZZZ"
sql ${USERNAME}/${PASSWORD}@//${HOST}:1521/${SERVICE} @${SCRIPT} ${OUTPUTFILE} ${SCRIPTPARAMETER}
