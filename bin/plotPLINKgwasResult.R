args <- commandArgs(TRUE)
if(length(args) != 5) stop("didn't recieve 5 arguments")

BREED<- args[1]
INFILE1<-args[2]
INFILE2<-args[3]
MAINDIR<-args[4]
trait<-args[5]

inst_pack <- installed.packages()
pkgs <- c("MASS","stats","grDevices","qqman")
for (p in pkgs){
  if(!p %in% inst_pack)
    install.packages(p, repos = "https://cran.rstudio.com")
}

library(MASS)
library(stats)
library(grDevices)
library(qqman)


#einlesen des PLINK assoc tests
rawdata <- as.data.frame(scan(file= INFILE1, sep=" ",what=list(CHR=0, SNP="", A1="", A2="", Atest="",FreqCa="",FreqCo="", CHISQ=0, df=0, P=0),quiet = TRUE,skip=1))
head(rawdata)
#einlesen der map
snpmap<-as.data.frame(scan(file=INFILE2,what=list(CHR=0,SNP="",CM=0,BP=0),quiet=TRUE))

#loop ueber die tests
for (tt in unique(rawdata$Atest)){
    tdata<-subset(rawdata,Atest==tt)
    data<-merge(tdata,snpmap,by.X=SNP,by.Y=SNP)
    #remove missing valuecode
    dd<-data[complete.cases(data),]

    out <- paste(MAINDIR,"/","ManhattanPlot_",BREED,".",trait,tt,".pdf",sep="")
    pdf(file=out,paper = "a4r", width=20/2.54, height=20/2.54)
    main <- paste("GWAS ",BREED," ",trait, sep="")
    print(manhattan(dd, main = main,col = c("blue4", "orange3"),cex = 0.5, cex.axis = 0.8))
    dev.off()
}

#out <- paste("Q_Q_plot_",BREED,".",trait,"snp1101.ssr.fimpute.ergebnis.pdf",sep="")
#pdf(file=out,paper = "a4r", width=20/2.54, height=20/2.54))
#main <- paste("Q-Q plot of GWAS p-values ",BREED," ",trait, sep="")
#print(qq(dd$P))
#dev.off()
#}
