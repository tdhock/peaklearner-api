library(data.table)
user <- "Public"
hub <- "H3K4me3_TDH_ENCODE"
hub.url <- sprintf(
  "https://peaklearner.rc.nau.edu/%s/%s/",
  user, hub)
hub.dir <- file.path("hubs", user, hub)
info.json <- file.path(hub.dir, "info.json")
if(!file.exists(info.json)){
  info.url <- sprintf(
    paste0(hub.url, "info"),
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

today.str <- strftime(Sys.time(), "%Y-%m-%d")
today.dir <- file.path(
  hub.dir, "modelSummaries", today.str)
summary.dt.list <- list()
for(track.i in seq_along(track.id.vec)){
  track.id <- track.id.vec[[track.i]]
  for(contig.i in 1:nrow(some.contigs)){
    contig <- some.contigs[contig.i]
    modelSum.url <- sprintf(
      "%s%s/modelSum?ref=%s&start=%s",
      hub.url, track.id, contig[["chrom"]], contig[["contigStart"]])
    modelSum.csv <- file.path(
      today.dir, track.id,
      contig[["chrom"]], contig[["contigStart"]],
      "modelSum.csv")
    dir.create(dirname(modelSum.csv), recursive=TRUE, showWarnings=FALSE)
    cat(sprintf(
      "%4d / %4d tracks %4d / %4d contigs\n",
      track.i, length(track.id.vec), contig.i, nrow(some.contigs)))
    while(!file.exists(modelSum.csv)){
      tryCatch({
        download.file(
          modelSum.url, modelSum.csv,
          quiet=TRUE, headers=c("accept"="text/csv"))
      }, error=function(e){
        NULL
      })
    }
    this.summary <- data.table::fread(modelSum.csv, drop=1, header=TRUE)
    if(nrow(this.summary)){
      nonzero.peaks <- this.summary[numPeaks != 0]
      if(nrow(nonzero.peaks)){
        first <- nonzero.peaks[1]
        this.summary[numPeaks==0, `:=`(
          possible_fn=first$possible_fn,
          possible_fp=first$possible_fp,
          regions=first$regions,
          fn=first$possible_fn
        )]
      }
      summary.dt.list[[paste(track.i, contig.i)]] <- data.table(
        track.id,
        contig,
        this.summary)
    }
  }
}
summary.dt <- do.call(rbind, summary.dt.list)

today.csv <- paste0(today.dir, ".csv")
data.table::fwrite(summary.dt, today.csv)
system(paste("git add", today.csv))
unlink(today.dir, recursive=TRUE)

##summary.dt <- data.table::fread("hubs/Public/H3K4me3_TDH_ENCODE/modelSummaries/2021-10-13.csv")

summary.dt[, computing.status := ifelse(numPeaks < 0, "computing", "done")]
contig.track.summary <- summary.dt[, .(
  models=.N,
  done=sum(computing.status=="done"),
  min.regions=min(regions),
  max.regions=max(regions),
  min.errors=min(errors),
  max.errors=max(errors),
  min.peaks=min(numPeaks),
  max.peaks=max(numPeaks)
), by=.(track.id, chrom, contigStart, contigEnd)]

contig.track.summary[, .(
  track.contigs=.N
), keyby=.(penalties.computed=done)]
contig.track.summary[, sum(done)]
