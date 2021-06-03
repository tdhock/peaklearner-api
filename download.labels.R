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

label.dt.list <- list()
for(track.i in 1:nrow(tracks.dt)){
  one.track <- tracks.dt[track.i]
  genome.txt.gz <- one.track[, file.path(
    "genomes", paste0(genome, ".txt.gz"))]
  dir.create(dirname(genome.txt.gz), showWarnings = FALSE, recursive = TRUE)
  if(!file.exists(genome.txt.gz)){
    genome.url <- one.track[, sprintf(
      "http://hgdownload.soe.ucsc.edu/goldenPath/%s/database/chromInfo.txt.gz",
      genome)]
    download.file(genome.url, genome.txt.gz)
  }
  chrom.size.dt <- data.table::fread(
    genome.txt.gz, col.names=c("chrom", "bases"), colClasses=list(NULL=3))
  labels.url <- sprintf(
    "https://peaklearner.rc.nau.edu/%s/%s/%s/labels/",
    one.hub[["user"]], one.hub[["hub"]], one.track[["key"]])
  for(chrom.i in 1:nrow(chrom.size.dt)){
    one.chrom <- chrom.size.dt[chrom.i]
    post.list <- with(one.chrom, list(command = "get", args = list(ref=chrom, start=0, end=bases)))
    post.result <- httr::POST(labels.url, body=post.list, encode="json")
    (content.list <- httr::content(post.result))
    one.label.dt <- do.call(rbind, lapply(content.list, as.data.table))
    label.dt.list[[paste(track.i, chrom.i)]] <- data.table(
      one.track, one.chrom, one.label.dt)
  }
}
dput(post.list)
out <- httr::POST("https://peaklearner.rc.nau.edu/Public/H3K4me3_TDH_ENCODE/aorta_ENCFF115HTK/labels/", body=list(command = "get", args = list(ref = "chr5", start = 0, end = 180915260L)), encode="json")
cat(httr::content(out, as="text"))

