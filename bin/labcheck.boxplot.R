inst_pack <- installed.packages()
pkgs <- c("plyr", "ggplot2", "stringr")
for (p in pkgs){
  if(!p %in% inst_pack)
    install.packages(p, repos = "https://cran.rstudio.com")
}
library(plyr)
library(ggplot2)
library(stringr)
#Variablen aus der Komandozeile
args <- commandArgs(TRUE)
OUTFILE  <- args[1]
HLINE    <- as.numeric(args[2])
YLIM1    <- as.numeric(args[3])
YLIM2    <- as.numeric(args[4])
INFILE   <- args[5]
data<-read.table(file=INFILE,header=FALSE,sep=" ")
names(data)<-c("sample","quality_criteria","file")
xprint<-as.data.frame(count(data, 'file'))
xprint<-xprint[,2]
                          


pdf(file=OUTFILE,paper = "a4r", width=20/2.54, height=20/2.54)
q<-ggplot(data, aes(x=file, y=quality_criteria)) +
  ylim(YLIM1,YLIM2) +
  geom_hline(yintercept = HLINE) +
  #stat_summary(count(data, 'file'), geom = "text") +
  #geom_label(label=xprint, nudge_x = 0.25, nudge_y = 0.2) +
  geom_boxplot(fill="red", aes(group = cut_width(file, 1)))
q + theme(axis.text.x = element_text(angle = 90, hjust = 1,vjust = 0.5,size=4))
dev.off()

