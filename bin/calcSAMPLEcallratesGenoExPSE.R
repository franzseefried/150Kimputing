#R Script zur berechung der Sample Statistik 200 Abstammungs-SNP
args<-commandArgs(trailingOnly = TRUE)
if(length(args)!=2) stop("didn't receive 2 arguments")

#variable <- read.table(file="/qualstore03/data_zws/snp/50Kimputing/parFiles/steuerungsvariablen.ctr.sh", sep="=", fill=TRUE)
#k <- nrow(variable)
# for (i in 1:k) {
#   if (variable[i,1] == "BAT_DIR")      { INDIR <- variable[i,2] }
# }


#Variablen aus der Komandozeile
INFILE        <- args[1]
OUTFILE       <- args[2]

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
  #sOutputFn <- paste(psInputFn, ".clrt", sep = "")
  ### # open a connection to input file
  conSnpInfo  <- file(psInputFn, "r")
  ### # read header, if we have one
  if (pbHasHeader) {
    sCurSnpLine  <- readLines(conSnpInfo, n = 1)
    cat("Header: ", sCurSnpLine, "\n")
  }
  ### # loop ueber input lines
  while (length(sCurSnpLine  <- readLines(conSnpInfo, n = 1) ) > 0) {
    # split input line at semikolon into character vector
    vecCurSnp <- unlist(strsplit(sCurSnpLine, ";"))
    #print(vecCurSnp[5])
    # convert char with calls into a vector of chars
    vecCurCall <- as.numeric(unlist(strsplit(vecCurSnp[3], "")))
    #print(vecCurCall[1:20])
    ## calc callrate
    clrtISAG<-round(100-(100*(length(which(vecCurCall==5))/length(vecCurCall))),digits=1)
    cat(vecCurSnp[1], vecCurSnp[4], vecCurSnp[5], clrtISAG, "\n", file = OUTFILE, append = TRUE)
  }
  
  close(conSnpInfo)
}
# recodeSnpInfo(smallSnpInput.fn, TRUE)
### # 700000 columns
snpInput.fn <- INFILE
recodeSnpInfo(snpInput.fn, FALSE)
#unix.time(recodeSnpInfo(snpInput.fn, FALSE))
