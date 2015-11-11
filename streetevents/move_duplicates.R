## Move duplicated files

# Identify duplicates based on MD5 signatures
calls <- system('find /Volumes/2TB/data/streetevents -name "*.xml.gz" -depth 1 -print0 | xargs -0 md5', intern=TRUE)
calls <- do.call(rbind, strsplit(calls, split=" = "))
calls <- as.data.frame(calls, stringsAsFactors=FALSE)
colnames(calls) <- c("file", "md5sum")
calls$file <- gsub("\\)", "", gsub("^.*\\(", "", calls$file))

# Function to move files to a 'duplicates' subdirectory
move_dupe <- function(path) {
    if (file.exists(path)) {
        file.rename(path, sub("/", "/duplicates/", path)) 
    } else { return(FALSE) }
}

# Now, move all duplicates
result <- unlist(lapply(calls[duplicated(calls[,"md5sum"]),"file"], move_dupe))