#This script is written to rapidly draw any file  produced produced by IOscop 
# as a couple of Offsets and the either sequence of I/O requests or sequences of memory faults.
#
#
# Copyright 2018 Qwant Entreprise, Inc. 
# Author: Abdulqawi SAIF


args <- commandArgs(trailingOnly = TRUE)

library(tools)  # for the file extensions
pdf(paste("out",file_path_sans_ext(args[1]),".pdf", sept=""),width=8, height=4)
dataTable <- read.table(args[1], header=TRUE)
ifelse("type" %in% colnames(dataTable),
dataFrame <- data.frame(offset=dataTable$offset, latency=dataTable$latency_ms, type=dataTable$type),
dataFrame <- data.frame(offset=dataTable$offset, latency=dataTable$latency_ms))

temp = nrow(dataFrame)
dataFrame$i <- seq(1,as.numeric(temp))
if ("type" %in% colnames(dataFrame))
{
plot(dataFrame$i, dataFrame$offset, xlab="IO requests",ylab="Offset",  pch = 20, col = ifelse(dataFrame$type==0,'red','blue'))
legend('topleft', legend= c("Read IO req.", "Write IO req."), col=c("red", "blue"),pch = c(19,19), cex=0.8)
} else {
plot(dataFrame$i, dataFrame$offset, xlab="IO requests",ylab="Offset",  pch = 20, col ="black")
legend('topleft', legend= c("mmap mem. faults"), col=c("black"),pch =19, cex=0.8)
}
invisible(dev.off())

