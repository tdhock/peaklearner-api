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
PeakSegPipeline::downloadProblems(genome, contigs.bed)
