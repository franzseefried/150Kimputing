inst_pack <- installed.packages()
pkgs <- c("stringr")
for (p in pkgs){
  if(!p %in% inst_pack)
    install.packages(p, repos = "https://cran.rstudio.com")
}

library(stringr)
#R Script zur berechung der Sample Statistik 200 Abstammungs-SNP
args<-commandArgs(trailingOnly = TRUE)
if(length(args)!=3) stop("didn't recieve 3 arguments")

#variable <- read.table(file="/qualstore03/data_zws/snp/50Kimputing/parfiles/steuerungsvariablen.ctr.sh", sep="=", fill=TRUE)
#k <- nrow(variable)
# for (i in 1:k) {
#   if (variable[i,1] == "BAT_DIR")      { INDIR <- variable[i,2] }
# }


#Variablen aus der Komandozeile
INFILE        <- args[1]
SNPFILE       <- args[2]
OUTFILE       <- args[3]



###Einlesen des INPUTFILES
data <- as.data.frame(scan(file= INFILE, sep=";",
    what=list(IDANIMAL=0, REQUESTERID=0, GT="", NSNPS=0, CLRTCHIP=0),quiet=TRUE))
#head(data)
#SNP-liste einlesen
SNPlst <- as.data.frame(scan(file=SNPFILE, sep=" ", 
    what=list(SNP="", FLAG="", SEQ="0"),quiet=TRUE))
#head(SNPlst)


###############################################################
##### Analyse der SNPs nach Callrate                       ####
###############################################################
#print("Analyse der SNPs nach Callrate")
nSNPs     <- dim(SNPlst)[1]
nSAMPLEs  <- dim(data)[1]

ss        <- SNPlst[,1]
#select GT string
#define length of gts
nb        <- nchar(as.vector(data[1,3]))
#split gt string into single SNPs 
SGT       <- as.data.frame(str_split_fixed(data$GT,"",nb))
#head(SGT)
for (i in 1:nb){
nB<-length(which(SGT[,i]==5))
SNPCLRT<-100-(100*(nB/nSAMPLEs))
#if(SNPCLRT < 95){
sel <-(paste(ss[i],SNPCLRT,sep=" "))
cat(sel, "\n", file = OUTFILE, append = TRUE)
#print(paste(ss[i],SNPCLRT,sep=" "))
#}
}

   
