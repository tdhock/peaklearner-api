library(data.table)
one.hub <- data.table(
  user="Public",
  hub="H3K4me3_TDH_ENCODE")
hub.dir <- one.hub[, file.path("hubs", user, hub)]
dir.create(hub.dir, showWarnings = FALSE, recursive = TRUE)
info.json <- file.path(hub.dir, "info.json")
if(!file.exists(info.json)){
  info.url <- one.hub[, sprintf(
    "https://peaklearner.rc.nau.edu/%s/%s/info/",
    user, hub)]
  download.file(info.url, info.json)
}
tracks.csv <- file.path(hub.dir, "tracks.csv")
if(file.exists(tracks.csv)){
  tracks.dt <- data.table::fread(tracks.csv)
}else{
  info.list <- RJSONIO::fromJSON(info.json)
  tracks.dt <- data.table(do.call(rbind, info.list[["tracks"]]))
  tracks.dt[, genome := info.list[["genome"]] ]
  data.table::fwrite(tracks.dt, tracks.csv)
}

for(track.i in 1:nrow(tracks.dt)){
  one.track <- tracks.dt[track.i]
  genome.txt.gz <- one.track[, file.path(
    "genomes", paste0(genome, ".txt.gz"))]
  dir.create(dirname(genome.csv), showWarnings = FALSE, recursive = TRUE)
  if(!file.exists(genome.txt.gz)){
    genome.url <- one.track[, sprintf(
      "http://hgdownload.soe.ucsc.edu/goldenPath/%s/database/chromInfo.txt.gz",
      genome)]
    download.file(genome.url, genome.txt.gz)
  }
  chrom.size.dt <- data.table::fread(
    genome.txt.gz, col.names=c("chrom", "bases"), colClasses=list(NULL=3))
  labels.url <- sprintf(
    "https://peaklearner.rc.nau.edu/%s/%s/%s/data/labels/",
    one.hub[["user"]], one.hub[["hub"]], one.track[["key"]])
  for(chrom.i in 1:nrow(chrom.size.dt)){
    one.chrom <- chrom.size.dt[chrom.i]
    post.list <- with(one.chrom, list(ref=chrom, start=0, end=bases))
    post.json <- RJSONIO::toJSON(post.list, asIs = FALSE)
    httr::POST(labels.url, query=post.json)
  }
}
chr1.list <- list(ref = "chr1", start = 0, end = 249250621)
httr::POST("https://peaklearner.rc.nau.edu/Public/H3K4me3_TDH_ENCODE/aorta_ENCFF115HTK/data/labels/", query=chr1.list)
httr::POST("https://peaklearner.rc.nau.edu/Public/H3K4me3_TDH_ENCODE/aorta_ENCFF115HTK/data/labels/", body=chr1.list)
httr::GET("https://api.github.com/repos/tdhock/nc/issues", query=list(state="closed"))

192.168.0.25
