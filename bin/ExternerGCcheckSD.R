args <- commandArgs(TRUE)
if(length(args) != 2) stop("didn't recieve 2 arguments")

PARFILE        <- args[1]

#Variablen aus dem grossen Parameterfile
variable <- read.table(file=PARFILE, sep="=", fill=TRUE)
k <- nrow(variable)
for (i in 1:k) {
  if (variable[i,1] == "WRKF_DIR") { WRKF_DIR <- as.character(variable[[i,2]])}
}

INFILE=args[2]


data     <-read.table(file=INFILE,header=FALSE,sep=" ")
#sd GCscore
stdv<-round((sd(data$V2)*100),digits=0)
print(stdv)
quit()

