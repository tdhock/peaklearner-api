library(data.table)
user <- "Public"
hub <- "H3K4me3_TDH_ENCODE"
hub.dir <- file.path("hubs", user, hub)
info.json <- file.path(hub.dir, "info.json")
if(!file.exists(info.json)){
  info.url <- sprintf(
    "https://peaklearner.rc.nau.edu/%s/%s/info",
    user, hub)
  download.file(
    info.url,
    info.json)
}
info.list <- RJSONIO::fromJSON(info.json)
genome <- info.list[["genome"]]
contigs.bed <- file.path("contigs", paste0(genome, ".bed"))
dir.create(dirname(contigs.bed), showWarnings=FALSE)
if(!file.exists(contigs.bed)){
  PeakSegPipeline::downloadProblems(genome, contigs.bed)
}

## Take a character vector of chromosomes such as chr1, chr2,
## chr10, chr20, chrX, chrY, chr17, chr17_ctg5_hap1 and assign
## each a number that sorts them first numerically if it exists,
## then using the _suffix, then alphabetically.
orderChrom <- function(chrom.vec, ...){
  stopifnot(is.character(chrom.vec))
  value.vec <- unique(chrom.vec)
  chr.dt <- nc::capture_first_vec(
    value.vec,
    "chr",
    name_or_number="[^:_]+",
    extra_name="_[^:]*", "?",
    ":?",
    chromStart="[^-]*", "?",
    "-?",
    chromEnd="[^-]*", "?") 
  ord.vec <- chr.dt[, order(
    suppressWarnings(as.numeric(name_or_number)),
    name_or_number,
    extra_name,
    as.numeric(chromStart))]
  rank.vec <- seq_along(value.vec)
  names(rank.vec) <- value.vec[ord.vec]
  order(rank.vec[chrom.vec], ...)
}

all.contigs <- data.table::fread(
  file=contigs.bed,
  col.names=c("chrom", "contigStart", "contigEnd"))
(some.contigs <- all.contigs[!grepl("_", chrom)][orderChrom(chrom)])
unique(some.contigs[["chrom"]])
track.id.vec <- names(info.list[["tracks"]])

for(track.i in seq_along(track.id.vec)){
  track.id <- track.id.vec[[track.i]]
  for(contig.i in 1:nrow(some.contigs)){
    contig <- some.contigs[contig.i]
  }
}
