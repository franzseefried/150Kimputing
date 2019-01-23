###
###
###   Purpose:   Compare Fimpute Results
###   Inputfile enthält 2 Ergebnisse zeilenweise untereinander, sortiert nach Tier
###   started:   2014/10/13 (pvr/fsf)
###
### ############################################# ###

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


########################################################
### # recoding with a function
recodeSnpInfo <- function(psInputFn, pbHasHeader = FALSE) {
  ###
  ###   recodeSnpInfo(psInputFn): recoding of SNP Info in psInputFn
  ###     results will be written to an output file which has the 
  ###     same name as the input file with ".out" pasted to it. 
  ###     If old output files with the same name exist, new output
  ###     will be appended, hence delete any old output first
  ### ############################################################# ###
  ### # check whether input file exists
  stopifnot(file.exists(psInputFn))
  ### # define output filename based on psInputFn
  sOutputFn <- paste(psInputFn, ".out", sep = "")
  ### # open a connection to input file
  conSnpInfo  <- file(psInputFn, "r")
  ### # read header, if we have one
  if (pbHasHeader) {
    sCurSnpLine  <- readLines(conSnpInfo, n = 1)
    cat("Header: ", sCurSnpLine, "\n")
  }
  ### # loop ueber input lines
  while (length(sCurSnpLine  <- readLines(conSnpInfo, n = 1) ) > 0) {
    # split input line at white-space into character vector
    vecCurSnp <- unlist(strsplit(sCurSnpLine, "[\t ]+"))
    # convert char with calls into a vector of chars
    vecCurCall <- as.numeric(unlist(strsplit(vecCurSnp[3], "")))
#print(vecCurCall[1:20])
    # select second line of same animal
	  sOldSnpLine  <- readLines(conSnpInfo, n = 1)
	  vecOldSnp  <- unlist(strsplit(sOldSnpLine, "[\t ]+"))
	  vecOldCall <- as.numeric(unlist(strsplit(vecOldSnp[3], "")))
#print(vecOldCall[1:20])
	  #mache den Vergleich
	  vecDiff<-vecCurCall-vecOldCall
#	  print(vecDiff[1:20])
	  NumSNP<-length(vecDiff)
	  NumDiff<-length(which(vecDiff!=0,arr.ind=FALSE))	
	  cat( vecCurSnp[1], vecCurSnp[2], NumDiff, "\n", file = sOutputFn, append = TRUE)
  }
  
  close(conSnpInfo)
}

# recodeSnpInfo(smallSnpInput.fn, TRUE)
### # 700000 columns
snpInput.fn <- INFILE
recodeSnpInfo(snpInput.fn, FALSE)
#unix.time(recodeSnpInfo(snpInput.fn, FALSE))


