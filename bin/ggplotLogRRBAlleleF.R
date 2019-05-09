args <- commandArgs(TRUE)
if(length(args) != 9) stop("didn't recieve 9 arguments")

chr<- args[1]
HPL<- args[2]
BEG<- args[3]
sto<- args[4]
INFILE1 <- args[5]
INFILE2 <- args[6]
OUTFILE1<- args[7]
OUTFILE2<- args[8]
PLOTARG<-args[9]
#logRR & Balelefrq sind im selbem infile drin, damit die selbe Fkt nbenutzt werdne kann, muesen unterschiedliche Spalten verwendet werden
if (PLOTARG != "LogRR" && PLOTARG != "BAlleleF"){print("Arg PLOTARG was invalid"); quit()}
if (PLOTARG == "LogRR"){poscol<-c(4);myylim<-c(-1,1)}
if (PLOTARG == "BAlleleF"){poscol<-c(3);myylim<-c(0,1)}

##############################################################
inst_pack <- installed.packages()
pkgs <- c("MASS","stats","grDevices","ggplot2","doParallel","parallel","dplyr")
for (p in pkgs){
  if(!p %in% inst_pack)
    install.packages(p, repos = "https://cran.rstudio.com")
}
library(MASS)
library(stats)
library(grDevices)
library(doParallel)
library(parallel)
library(dplyr)
library(ggplot2)



###############################################################
#Funktion zur Analyse der SNPs
#rechne fŸr jeden SNP die durchschnittlich LogRR abhŠngig vom Haplotypenstatus
#funktion muss SNP und datensatz mitgegeben werden
statSNP <- function(GTS,dataf) {
    sSNP<-filter(dataf,SNP==GTS)
    if (nrow(sSNP) >0){
        #restab<-(data.frame(aggregate(sSNP[,c(4)],list(sSNP$HPLSTT),FUN=mean,na.rm=T)))
        restab<-(data.frame(aggregate(sSNP[,poscol],list(sSNP$HPLSTT),FUN=mean,na.rm=T)))
        names(restab)<-c("GTS","mean")        
        #merge mit defines GTS so that all 3 Genotypes get an results also when they are missing in the data
        endtab<-as.data.frame(c(0,1,2),byrow=T)
        names(endtab)<-c("GTS")
        resdat<-merge(endtab,restab,by.x="GTS",by.y="GTS",all.x=T)
        resvec<-resdat[,2]
        #cat(GTS,resvec,"\n")
#        resvec2<-data.frame(GTS,resvec)
        return(resvec)
     }
     #else {
     #print("No dataframe selected")
     #}
}
##############################################################




#default variables
Freq <- c(0)
minFreq <- as.numeric(Freq)


###Einlesen des Haplotypen-Files
data <- as.data.frame(scan(file= INFILE1, sep=" ",what=list(SNP="", TVD="", Ballele=0, LogRR=0, HPLSTT=0)))
head(data)
#EInlesen der SNP-liste
SNPlst <- as.data.frame(scan(file=INFILE2, sep=" ",what=list(dummy="", SNPname="", BTA="0", Bp="0")))
head(SNPlst)
#convert to numeric column Bp
SNPlst$Bp <- as.numeric(as.character(SNPlst$Bp))
str(SNPlst)


###############################################################
##### Analyse der SNPs nach ${PLOTARG} und Haplotypenstatus ####
###############################################################
print(paste(c("Analyse der SNPs nach "),PLOTARG,c(" und Haplotypenstatus"),sep=""))
nrSNPs <- SNPlst[,2]
noSNPs <- dim(SNPlst)[1]
print(paste("No of SNPs: ", noSNPs))
hmax=length(unique((data$HPLSTT)))
print(paste("No of GenotypeLevels: ", hmax))

no_cores <- detectCores() - 1
registerDoParallel(cores=no_cores)
getDoParWorkers()
cl <- makeCluster(no_cores)
numSNPs<-dim(SNPlst)[1]
#numSNPs<-5
#start time
strt<-Sys.time()

#delete file if it exists
deleteStat<-if (file.exists(OUTFILE1)) file.remove(OUTFILE1)
open_con <- file(OUTFILE1, open="a")
for (s in nrSNPs){
    #sts <- foreach(icount(numSNPs)) %dopar% {
    #    print(numSNPs)
    #    s<-as.character(SNPlst[numSNPs,2])
    #data.frame(feature=rnorm(10))
    st<-statSNP(s,data)
    if(!is.null(st)){
       cat(s,statSNP(s,data), "\n", file = open_con, append = TRUE)
    }
}
close(open_con)
#class(sts)
print(Sys.time()-strt)
stopCluster(cl)



outfilein<-read.table(file=OUTFILE1,sep=" ", header=F)
names(outfilein)<-c("SNP","GT0","GT1","GT2")
LSTSNP<-merge(SNPlst,outfilein,by.x="SNPname",by.y="SNP")
LSTplot<-LSTSNP[,c(4,5,6,7)]
#insert missing valuecode
LSTplot[is.na(LSTplot[,])] <- -9

#as.numeric(as.character(LSTplot$Bp))
#is.numeric(LSTplot$Bp)
#define x-labels
minXplot<-min(LSTplot$Bp)
maxXplot<-max(LSTplot$Bp)
xseq<-seq(from = minXplot, to = maxXplot, by=100000)

if (PLOTARG == "BAlleleF"){
    print(c("Plot erstellen by plotting also homozygous wildtype"))
    header <- paste("average ",PLOTARG," homozygous wildytpe (black), carriers (red) and homozygous-carriers (blue).","Chromosom",chr,"_",BEG,"_",sto,"_",HPL, sep=" ")
    pdf(file=OUTFILE2,width=30,height=20)
    print(ggplot(LSTplot,aes(x=Bp,y=GT0,group = 1)) +
           ylim(myylim) +
           geom_point(size=2.5,shape=21,fill="black") +
           geom_point(aes(y=GT1),size=2.5,shape=21,color="red",fill="red") +
           geom_point(aes(y=GT2),size=2.5,shape=21,color="blue",fill="blue") +
           ylab(paste("Mean ",PLOTARG,sep="")) +
           theme(axis.text.x = element_text(angle=90)) +
           scale_x_continuous(breaks = xseq) +
           labs(title=header))
    dev.off()
}
if (PLOTARG == "LogRR"){
    print(c("Plot erstellen by plotting also GT1 / GT2 vs GT0 values"))
    header <- paste("delta ",PLOTARG," carriers (red) and homozygous-carriers (blue) vs. homoygous wildtype.","Chromosom",chr,"_",BEG,"_",sto,"_",HPL, sep=" ")
    pdf(file=OUTFILE2,width=30,height=20)
    print(ggplot(LSTplot,aes(x=Bp,y=GT0,group = 1)) +
           ylim(myylim) +
           #geom_point(size=2.5,shape=21,fill="black") +
           geom_point(aes(y=GT1-GT0),size=2.5,shape=21,color="red",fill="red") +
           geom_point(aes(y=GT2-GT0	),size=2.5,shape=21,color="blue",fill="blue") +
           ylab(paste("Mean ",PLOTARG,sep="")) +
           theme(axis.text.x = element_text(angle=90)) +
           scale_x_continuous(breaks = xseq) +
           labs(title=header))
    dev.off()
}

print(paste("Eine Grafik fuer ",PLOTARG," wurde erstellt",sep=""))



###################################################################
if (PLOTARG == "BAlleleF"){
     #plot PLOTARG for each sample in the dataset
     animals<-unique(data$TVD)
     for (animal in animals){
        print(animal)
        s<-subset(data,TVD==animal)
        carrier<-as.numeric(unique(s$HPLSTT))
        if( carrier == 0 ){colplot<-c("black")}
        if( carrier == 1 ){colplot<-c("red")}
        if( carrier == 2 ){colplot<-c("blue")}
        LSTANIMAL<-merge(SNPlst,s,by.x="SNPname",by.y="SNP")
     #   print(names(LSTANIMAL))
        ANIMALPLOT<-LSTANIMAL[,c(4,6)]
     #   #insert missing value code
        ANIMALPLOT[is.na(ANIMALPLOT[,])] <- c(-9)
        #print(paste(animal,dim(ANIMALPLOT)),sep="")
        header <- paste(PLOTARG," for ",animal," colour: if homozygotes -> black, if carrier -> red, if homozygous-carrier -> blue.","Chromosom",chr,"_",BEG,"_",sto,"_",HPL, sep=" ")
        aout<-paste("BAlleleF",animal,"-GT",carrier,"-",sep="")
        pdfname<-sub("BAlleleF{1}", aout, OUTFILE2)
     #   print(pdfname)
     #   pdfname<-c(paste(dir,PLOTARG,"_",animal,"carrierstat",carrier,"_Chromosom",chr,"_",BEG,"_",sto,"_",HPL,".pdf", sep=""))
        pdf(file=pdfname,width=30,height=20)
            print(ggplot(ANIMALPLOT,aes(x=Bp,y=Ballele,group = 1)) +
                   ylim(myylim) +
                   geom_point(size=2.5,shape=21,color=colplot,fill=colplot) +
                   ylab(PLOTARG) +
                   theme(axis.text.x = element_text(angle=90)) +
                   scale_x_continuous(breaks = xseq) +
                   labs(title=header))
        dev.off()
      }   
}
