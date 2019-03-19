#script can handle single animal option or allanimal option 
args<-commandArgs(trailingOnly = TRUE)
if(length(args) < 5) stop("didn't recieve 5 or more arguments")


inst_pack <- installed.packages()
pkgs <- c("stringdist", "doParallel", "foreach", "pryr")
for (p in pkgs){
  if(!p %in% inst_pack)
    install.packages(p, repos = "https://cran.rstudio.com")
}

library(stringdist)
library(doParallel)
library(foreach)


NORECS <- args[1]
INFILE <- args[2]
ANIFILE<- args[3]
OUTFILE<- args[4]
STRATA <- args[5]

if(STRATA != "SINGLEANIMAL" && STRATA != "ALLANIMALS"){print("Argument 5 was not correct");quit();}

if (STRATA == "SINGLEANIMAL"){
  ANIMALI<- args[6]
}

sessionInfo()

gtv<-scan(file=INFILE,what=character(),nlines=NORECS,quiet=TRUE)
gta<-scan(file=ANIFILE,what=character(),nlines=NORECS,quiet=TRUE)
#gtv<-scan(file="/qualstore03/data_projekte/projekte/GPsearch/tmp/BSW.GPsearch.Fgt.haplotypesInRows.FULLY",what=character(),nlines=NORECS,quiet=TRUE)
#gta<-scan(file="/qualstore03/data_projekte/projekte/GPsearch/tmp/BSW.GPsearch.Fgt.animals.FULLY",what=character(),nlines=NORECS,quiet=TRUE)

#https://stackoverflow.com/questions/44629486/speeding-up-stringdist-in-r-using-parallel
# pairwise combinations of haplotypes
#attention limitations of 10^9 for cbn -> loop & define pairwise loops
if(STRATA == "SINGLEANIMAL"){
  #screen for desired animal
  selani<-which(gta[]==ANIMALI)
  cat("selani: ", selani, "\n")
  if(length(selani) == 0){print("Selected Animal was not found in the animal vector");quit()}
}

# constant defining limitation value
const_limit <- 10^8  ### # cannot be set to small value, always use values close to memory limit in R
foreach_chunk_size <- 100

#restrict dimension due to R restricton to 10^9 as maximum length for a vector
if(STRATA=="ALLANIMALS"){if((length(gta)^2) <= const_limit){limitation<-length(gta)^2}else{limitation<-const_limit}}
if(STRATA=="SINGLEANIMAL"){if((length(gta))*length(selani) <= const_limit){limitation<-length(gta)*length(selani)}else{limitation<-const_limit}}

#############################################

### # number of elements (haplotypes or animals) to be compared
nr_elemente <- as.numeric(NORECS)  #10
### # total number of comparisons
#The variable `total_number` stands for total number of comparison that must be done in  our all-against-all
if(STRATA == "ALLANIMALS"){
  total_number <- nr_elemente^2
}
if(STRATA == "SINGLEANIMAL"){
  total_number <- nr_elemente*length(selani)
}
cat("Total number: ", total_number, "\n")

### # limitation (real case = 10^9)
#Due to limitation in RAM or in R, we have to split the total number of comparisons into chunks of possible comparisons. Each chunk can have `nr_possible_comparisons` of comparisons.
nr_possible_comparisons <- limitation  #30
cat("NR possible comparisons (limitation): ", nr_possible_comparisons, "\n")

nr_loops <- floor(total_number / nr_possible_comparisons)
cat("NR LOOPS: ", nr_loops, "\n")

nr_chunks_per_iter <-  floor(nr_possible_comparisons / nr_elemente)
cat("nr chunks: ", nr_chunks_per_iter, "\n")

# simple timing
st <- Sys.time()

noCores<-detectCores()-1
cl <-  makeCluster(noCores,type = 'FORK')
registerDoParallel(cl)
cat("No of cores used: ", noCores, "\n")

### # count number of lines written to result file
n_count_result_lines <- 0

#basic principle: define depending on limitation you full comparisons that are possible. loop over them and then when finished, take care of the remaining comparisons to be done
### # loop of full comparisons
for (chunk_idx in 1:nr_loops){
  cat (" *** loop idx: ", chunk_idx, " ", format(Sys.time(), "%a %b %d %X %Y"), "\n")
  base_vec <- rep(1:nr_elemente,nr_chunks_per_iter)
  if (STRATA=="ALLANIMALS"){
    first_vec <- rep(((chunk_idx-1)*nr_chunks_per_iter + 1):(chunk_idx * nr_chunks_per_iter), nr_elemente)
  }
  if (STRATA=="SINGLEANIMAL"){
    first_vec <- rep(selani[1]:selani[2],nr_elemente)
  }
  cat("first_vec created ", " ", format(Sys.time(), "%a %b %d %X %Y"), "\n")
  # (l_result <- list(first = first_vec[order(first_vec)],
  #                   second = base_vec))
  #here comes the list of comparisons to me done
  m_result <- matrix(c(first_vec[order(first_vec)], base_vec), nrow = 2, byrow = TRUE)
  cat("m_result created ", " ", format(Sys.time(), "%a %b %d %X %Y"), "\n")
  ### #  write header to output file
  cat( "Mani", gta[m_result[2,1:nr_elemente]],"\n", file = OUTFILE, append = TRUE)
  
  cat("memory used before computing result: ", pryr::mem_used(), "\n")
  
  chunk_length <- floor(nr_possible_comparisons/foreach_chunk_size)
  startingPoints <- seq(1,nr_possible_comparisons, chunk_length)
  res <- foreach(ii = startingPoints[1:(length(startingPoints)-1)],.combine = 'c') %dopar% {
    # be careful to specify the exact index in the call to stringdist, otherwise, parallelisation of stringdist gets confused
    apply(m_result[,ii:(ii+(chunk_length - 1))],2,function(x) stringdist(gtv[x[1]],gtv[x[2]],method = "hamming"))
  }
  
  
  ### # remaining comparisions from foreach-parallelisation loops
  if(ncol(m_result) > startingPoints[length(startingPoints)]){
    cat("Doing remaining comparisons from ", startingPoints[length(startingPoints)], " to ", ncol(m_result), "\n")
    res <- c(res, apply(m_result[,startingPoints[length(startingPoints)]:ncol(m_result)], 2, function(x) stringdist(gtv[x[1]],gtv[x[2]],method = "hamming")))
  }
  
  cat("Size of result: ", pryr::object_size(res), "\n")
  
  ### # output of res has to be divided, because res is a vector with all results in the current loop iteration
  nr_result_lines <- length(res) / nr_elemente
  for (j in 1:nr_result_lines) {
    # cat( c(ANIMALI, res[((j-1)*nr_elemente + 1):(j*nr_elemente)]),"\n", file = OUTFILE, append = TRUE)
    cat( c(gta[m_result[1,(j-1)*nr_elemente + 1]], res[((j-1)*nr_elemente + 1):(j*nr_elemente)]),"\n", file = OUTFILE, append = TRUE)
    n_count_result_lines <- n_count_result_lines + 1
  }
  
  
  
  # initialize after writing out results
  res <- NULL
  # garbage collect
  gc()
}


cat(" Loops were finished ... ", " ", format(Sys.time(), "%a %b %d %X %Y"), "\n")

# if (STRATA=="SINGLEANIMAL"){
#   first_vec <- rep(selani[1]:selani[2], 
# }



### # remaining comparisions at the end
if (nr_loops * nr_possible_comparisons < total_number ){
    if(STRATA=="ALLANIMALS"){
       cat(" Starting remainder after loop (ALLANIMALS) ... ", " ", format(Sys.time(), "%a %b %d %X %Y"), "\n")
       first_vec <- rep(((chunk_idx * nr_chunks_per_iter)+1):nr_elemente, nr_elemente)
       (base_vec <- rep(1:nr_elemente,(nr_elemente- chunk_idx * nr_chunks_per_iter)))
       # (l_result <- list(first = first_vec[order(first_vec)],
       #                   second = base_vec))
       #Composing the matrix
       m_result <- matrix(c(first_vec[order(first_vec)], base_vec), nrow = 2, byrow = TRUE)
       #Inner parallelisation using `foreach`. First starting positions are defined in `ii`
       res <- foreach(ii = seq(1,nr_possible_comparisons,nr_possible_comparisons/foreach_chunk_size),.combine = 'c') %dopar% {
         
         apply(m_result[,ii:(ii+((nr_possible_comparisons/foreach_chunk_size) - 1))],2,function(x) stringdist(gtv[x[1]],gtv[x[2]],method = "jw"))
         
         
       }
       nr_result_lines <- total_number / nr_elemente - n_count_result_lines
       for (j in 1:nr_result_lines) {
         cat( c(gta[m_result[1,(j-1)*nr_elemente + 1]], res[((j-1)*nr_elemente + 1):(j*nr_elemente)]),"\n", file = OUTFILE, append = TRUE)
       }
    }
   if(STRATA=="SINGLEANIMAL"){
       cat(" You have defined too small limitations so that you ended up here. Increase limitations to solve the problem, since the code down here was not developped! \n") 
   }
   cat(" done with remainder after loop ... ", " ", format(Sys.time(), "%a %b %d %X %Y"), "\n")
   
}


cat("R-Script done\n")

stopCluster(cl)
Sys.time() - st
