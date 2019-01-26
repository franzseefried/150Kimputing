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
START_DIR=$(pwd)


if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
fi

set -o nounset
breed=${1}


halist=$(cat $TMP_DIR/${breed}.[A-Z]*.selected | tr '\n' ' ')
echo $halist 
exit 1

if [ ${breed} == "BSW" ]; then
halists=$(echo "$RES_DIR/RUN${run}${breed}.2-85-91.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.5-21-27.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.7-40-44.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.13-43-44.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.13-51-57.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.21-19-21.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.25-11-13.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.27-22-27.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.19-BH2.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.1-7-14.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.4-54-55.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.1-28-29.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.1-FH2.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.5-72-74.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.11-104-105.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.14-12-17.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.14-46-48.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.13-22-25.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.17-55-60.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.20-65-66.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.22-wF.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.SMA.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.SDM.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.ARA.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.P.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.BE.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.WE.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.KK.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.629-RYF.Fimpute.all.haploCOUNTS 
                $RES_DIR/RUN${run}${breed}.BK1.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.BK2.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.BLG.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.1-10-15.Fimpute.all.haploCOUNTS 
                $RES_DIR/RUN${run}${breed}.2-86-88.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.5-59-64.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.5-70-74.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.7-42-43.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.10-35-42.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.12-24-35.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.13-22-28.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.21-2-5.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.21-18-20.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.22-14-19.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.23-39-46.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.29-35-38.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.1-25-27.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.4-44-47.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.5-65-66.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.5-67-69.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.5-79-83.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.6-64-72.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.14-10-16.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.20-58-62.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.23-27-31.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.24-RD.Fimpute.all.haploCOUNTS")
fi
if [ ${breed} == "HOL" ]; then
halists=$(echo "$RES_DIR/RUN${run}${breed}.1-HH2.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.11-CDH.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.18-DCM.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.2-13-15.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.2-56-60.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.6-7-14.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.7-10-18.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.11-52-56.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.12-70-77.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.2-5-7.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.25-0-8.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.23-24-32.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.18-58-62.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.16-13-23.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.21-21-23.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.23-13-23.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.21-48-56.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.5-18-19.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.14-20-22.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.20-23-24.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.HH1.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.HH3.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.HH4.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.BL.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.CV.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.BY.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.P.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.TP.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.KK.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.7-MG.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.e.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.ED.Fimpute.all.singleGeneImputation 
                $RES_DIR/RUN${run}${breed}.BR.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.VR.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.BK1.Fimpute.all.singleGeneImputation $RES_DIR/RUN${run}${breed}.BK2.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.9-HH5.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.BLG.Fimpute.all.singleGeneImputation
                $RES_DIR/RUN${run}${breed}.2-12-15.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.2-57-59.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.2-7-9.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.3-18-23.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.5-61-65.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.6-4-9.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.6-12-14.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.7-1-5.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.7-6-20.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.8-92-100.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.8-25-40.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.9-89-94.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.10-7-11.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.11-50-55.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.12-66-68.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.13-14-20.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.16-20-24.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.18-58-64.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.21-19-22.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.21-41-49.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.21-58-61.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.21-67-69.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.23-36-40.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.25-0-3.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.25-27-29.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.26-55-84.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.27-17-22.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.5-16-20.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.14-16-17.Fimpute.all.haploCOUNTS $RES_DIR/RUN${run}${breed}.15-43-47.Fimpute.all.haploCOUNTS
                $RES_DIR/RUN${run}${breed}.15-43-47.Fimpute.all.haploCOUNTS")
fi


sleep 30


for filetocheck in ${halists} ; do
TIERLIScheck () {
existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${filetocheck}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
echo $RIGHT_NOW
fi
done


echo "file to check  ${filetocheck}  exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${filetocheck} )
 echo $lmod	
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 240 ]; then
    shotresult=same
    echo "${filetocheck} is ready now ${RIGHT_NOW}"
 fi
done

}
TIERLIScheck
done
fi



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
