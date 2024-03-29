setwd("~/GitHub/190917_tRF_RNA_binding")
rm(list = ls())

options(stringsAsFactors = F)

library(plyr)
library(dplyr)
library(ggplot2)

# RBP sequence motifs ####
# https://doi.org/10.1016/j.molcel.2018.05.001
#function
get.count.change <- function(BM, LF) {
  return((BM * 2^LF) - BM)
}
#read motif data####
#>5mers####
motif_5_raw <- read.csv("RBP_motifs/5mers.csv")
RBPS_len_5 <- (ncol(motif_5_raw)/2)
motif_5 <- vector(mode = "list", length = RBPS_len_5)
lines <- seq(length = RBPS_len_5, by = 2)
names(motif_5) <- colnames(motif_5_raw)[lines]
pref_motif_5 <- motif_5
for(i in 1:RBPS_len_5) {
  motif_5[[i]] <- data.frame(motif_5_raw[,lines[i]:(lines[i]+1)])
}
for(i in 1:length(motif_5)) {
  colnames(motif_5[[i]]) <- c("motif_5", "R-1")
  motif_5[[i]] <- motif_5[[i]][!is.na(motif_5[[i]]$`R-1`),]
  pref_motif_5[[i]] <- motif_5[[i]][1,]
}
#>>all probabilities for 5-mers####
(motif_5_df <- ldply(motif_5))
#>>only the preferred 5-mer for each RNABP####
(pref_motif_5_df <- ldply(pref_motif_5))

#>6mers####
motif_6_raw <- read.csv("RBP_motifs/6mers.csv")
RBPS_len_6 <- (ncol(motif_6_raw)/2)
motif_6 <- vector(mode = "list", length = RBPS_len_6)
lines <- seq(length = RBPS_len_6, by = 2)
names(motif_6) <- colnames(motif_6_raw)[lines]
pref_motif_6 <- motif_6
for(i in 1:RBPS_len_6) {
  motif_6[[i]] <- data.frame(motif_6_raw[,lines[i]:(lines[i]+1)])
}
for(i in 1:length(motif_6)) {
  colnames(motif_6[[i]]) <- c("motif_6", "R-1")
  motif_6[[i]] <- motif_6[[i]][!is.na(motif_6[[i]]$`R-1`),]
  pref_motif_6[[i]] <- motif_6[[i]][1,]
}
#>>all probabilities for 6-mers####
(motif_6_df <- ldply(motif_6))
#>>only the preferred 6-mer for each RNABP####
(pref_motif_6_df <- ldply(pref_motif_6))

#>7mers####
motif_7_raw <- read.csv("RBP_motifs/7mers.csv")
RBPS_len_7 <- (ncol(motif_7_raw)/2)
motif_7 <- vector(mode = "list", length = RBPS_len_7)
lines <- seq(length = RBPS_len_7, by = 2)
names(motif_7) <- colnames(motif_7_raw)[lines]
pref_motif_7 <- motif_7
for(i in 1:RBPS_len_7) {
  motif_7[[i]] <- data.frame(motif_7_raw[,lines[i]:(lines[i]+1)])
}
for(i in 1:length(motif_7)) {
  colnames(motif_7[[i]]) <- c("motif_7", "R-1")
  motif_7[[i]] <- motif_7[[i]][!is.na(motif_7[[i]]$`R-1`),]
  pref_motif_7[[i]] <- motif_7[[i]][1,]
}
#>>all probabilities for 7-mers####
(motif_7_df <- ldply(motif_7))
#>>only the preferred 7-mer for each RNABP####
(pref_motif_7_df <- ldply(pref_motif_7))

#FIND MOTIFS IN TRF SEQUENCES####
#EXAMPLE DATA####
trf_dif_exprs <- readRDS(file = "working_data/stroke_DE_tRFs.rds")
#>5mer hits####
#>>preferred motifs####
pref_motif_5_hits <- lapply(pref_motif_5_df$motif_5, function(x) grep(x, trf_dif_exprs$sequence))
names(pref_motif_5_hits) <- names(pref_motif_5)
pref_motif_5_hits <- lapply(pref_motif_5_hits, function(x) trf_dif_exprs[x,])
pref_motif_5_hits <- pref_motif_5_hits[lapply(pref_motif_5_hits, function(x) length(x[[1]])) > 0]

pref_motif_5_hits_df <- ldply(pref_motif_5_hits)
# pref_motif_5_hits_df$condition <- factor(pref_motif_5_hits_df$condition, levels = c("30min", "60min", "2days", "4days"))
pref_motif_5_hits_df$countChange <- get.count.change(pref_motif_5_hits_df$baseMean, pref_motif_5_hits_df$log2FoldChange)

ggplot(pref_motif_5_hits_df, aes(.id, asinh(countChange), fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") + theme(axis.text.x = element_text(angle = 60, hjust = 1))

#>>>rank by count-change####
pref_motif_5_hits_df$CC_rank <- rank(-abs(pref_motif_5_hits_df$countChange))

pref_motif_5_hits_df <- pref_motif_5_hits_df[order(pref_motif_5_hits_df$CC_rank),]
#>>>most "active"####
#RNABPs
dplyr::count(unique(pref_motif_5_hits_df[,c(".id", "MINTplate")]), .id, sort = T)
#tRFs
dplyr::count(unique(pref_motif_5_hits_df[,c(".id", "MINTplate")]), MINTplate, sort = T)

#single conditions
for(condition in unique(pref_motif_5_hits_df$condition)) {
  df <- pref_motif_5_hits_df[pref_motif_5_hits_df$condition == condition,]
  means <-
    aggregate(df$countChange,
              by = list(df$.id),
              FUN = "mean")
  means <- means[order(means$x), ]
  df$.id <-
    factor(df$.id, levels = means$Group.1)
  g <- ggplot(df,
              aes(.id,
                  countChange, fill = condition, color = condition)) + geom_boxplot() +
    facet_wrap("condition") +
    theme(axis.text.x = element_text(angle = 60, hjust = 1))
  print(g)
  readline("[Enter] to continue, [Esc] to quit")
}

#>>all motifs####
motif_5_hits <- vector(mode = "list", length = RBPS_len_5)
for(i in 1:length(motif_5)) {
  temp <- motif_5[[i]]
  hits <- lapply(temp$motif_5, function(x) grep(x, trf_dif_exprs$sequence))
  hits <- lapply(hits, function(x) trf_dif_exprs[x,])
  names(hits) <- temp$`R-1`
  hits <- hits[lapply(hits, function(x) length(x[[1]])) > 0]
  hits <- ldply(hits)
  if(nrow(hits)>0)
    colnames(hits)[1] <- "R-1"
  motif_5_hits[[i]] <- hits
}
names(motif_5_hits) <- names(motif_5)
motif_5_hits <- motif_5_hits[lapply(motif_5_hits, function(x) nrow(x)) > 0]

motif_5_hits_df <- ldply(motif_5_hits)
# motif_5_hits_df$condition <- factor(motif_5_hits_df$condition, levels = c("30min", "60min", "2days", "4days"))
motif_5_hits_df$`R-1` <- as.numeric(motif_5_hits_df$`R-1`)
hist(motif_5_hits_df$`R-1`)

#by amino acid
ggplot(motif_5_hits_df, aes(unlist(lapply(motif_5_hits_df$amino_acid, function(x) paste(x[[1]], collapse = ", "))), 
                            log2FoldChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") + theme(axis.text.x = element_text(angle = 60, hjust = 1))

#by tRNA
ggplot(motif_5_hits_df, aes(unlist(lapply(motif_5_hits_df$origin, function(x) paste(x[[1]], collapse = ", "))), 
                            log2FoldChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") + theme(axis.text.x = element_text(angle = 60, hjust = 1))

ggplot(motif_5_hits_df, aes(.id, 
                            motif_5_hits_df$`R-1`, fill = condition, color = condition)) + geom_boxplot() +
  # facet_wrap("condition") + 
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

ggplot(motif_5_hits_df, aes(.id, 
                            log2FoldChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

motif_5_hits_df$countChange <- get.count.change(motif_5_hits_df$baseMean, motif_5_hits_df$log2FoldChange)

ggplot(motif_5_hits_df, aes(.id, 
                            asinh(countChange), fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

#>>>single conditions####
for(condition in unique(motif_5_hits_df$condition)) {
  df <- motif_5_hits_df[motif_5_hits_df$condition == condition,]
  means <-
    aggregate(df$countChange,
              by = list(df$.id),
              FUN = "mean")
  means <- means[order(means$x), ]
  df$.id <-
    factor(df$.id, levels = means$Group.1)
  g <- ggplot(df, aes(.id, countChange, fill = MINTplate, color = MINTplate, size = `R-1`)) + 
    geom_point(position = position_jitter(width = .2, height = 0), alpha = .5) +
    facet_wrap("condition") +
    theme(axis.text.x = element_text(angle = 60, hjust = 1), legend.position = "none")
  print(g)
  readline("[Enter] to continue, [Esc] to quit")
}

#>6mer hits####
#>>preferred motifs####
pref_motif_6_hits <- lapply(pref_motif_6_df$motif_6, function(x) grep(x, trf_dif_exprs$sequence))
names(pref_motif_6_hits) <- names(pref_motif_6)
pref_motif_6_hits <- lapply(pref_motif_6_hits, function(x) trf_dif_exprs[x,])
pref_motif_6_hits <- pref_motif_6_hits[lapply(pref_motif_6_hits, function(x) length(x[[1]])) > 0]

pref_motif_6_hits_df <- ldply(pref_motif_6_hits)
# pref_motif_6_hits_df$condition <- factor(pref_motif_6_hits_df$condition, levels = c("30min", "60min", "2days", "4days"))
pref_motif_6_hits_df$countChange <- get.count.change(pref_motif_6_hits_df$baseMean, pref_motif_6_hits_df$log2FoldChange)

ggplot(pref_motif_6_hits_df, aes(.id, countChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") + theme(axis.text.x = element_text(angle = 60, hjust = 1))

pref_motif_6_hits_df$CC_rank <- rank(-abs(pref_motif_6_hits_df$countChange))

pref_motif_6_hits_df <- pref_motif_6_hits_df[order(pref_motif_6_hits_df$CC_rank),]
dplyr::count(unique(pref_motif_6_hits_df[,c(".id", "MINTplate")]), .id, sort = T)
dplyr::count(unique(pref_motif_6_hits_df[,c(".id", "MINTplate")]), MINTplate, sort = T)

#>>all motifs####
motif_6_hits <- vector(mode = "list", length = RBPS_len_6)
for(i in 1:length(motif_6)) {
  temp <- motif_6[[i]]
  hits <- lapply(temp$motif_6, function(x) grep(x, trf_dif_exprs$sequence))
  hits <- lapply(hits, function(x) trf_dif_exprs[x,])
  names(hits) <- temp$`R-1`
  hits <- hits[lapply(hits, function(x) length(x[[1]])) > 0]
  hits <- ldply(hits)
  if(nrow(hits)>0)
    colnames(hits)[1] <- "R-1"
  motif_6_hits[[i]] <- hits
}
names(motif_6_hits) <- names(motif_6)
motif_6_hits <- motif_6_hits[lapply(motif_6_hits, function(x) nrow(x)) > 0]

motif_6_hits_df <- ldply(motif_6_hits)
# motif_6_hits_df$condition <- factor(motif_6_hits_df$condition, levels = c("30min", "60min", "2days", "4days"))
motif_6_hits_df$`R-1` <- as.numeric(motif_6_hits_df$`R-1`)
hist(motif_6_hits_df$`R-1`)

ggplot(motif_6_hits_df, aes(unlist(lapply(motif_6_hits_df$amino_acid, function(x) paste(x[[1]], collapse = ", "))), 
                            log2FoldChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") + theme(axis.text.x = element_text(angle = 60, hjust = 1))

ggplot(motif_6_hits_df, aes(unlist(lapply(motif_6_hits_df$origin, function(x) paste(x[[1]], collapse = ", "))), 
                            log2FoldChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") + theme(axis.text.x = element_text(angle = 60, hjust = 1))

ggplot(motif_6_hits_df, aes(.id, 
                            motif_6_hits_df$`R-1`, fill = condition, color = condition)) + geom_boxplot() +
  # facet_wrap("condition") + 
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

ggplot(motif_6_hits_df, aes(.id, 
                            log2FoldChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

motif_6_hits_df$countChange <- get.count.change(motif_6_hits_df$baseMean, motif_6_hits_df$log2FoldChange)

ggplot(motif_6_hits_df, aes(.id, 
                            countChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

for(condition in unique(motif_6_hits_df$condition)) {
  df <- motif_6_hits_df[motif_6_hits_df$condition == condition,]
  means <-
    aggregate(df$countChange,
              by = list(df$.id),
              FUN = "mean")
  means <- means[order(means$x), ]
  df$.id <-
    factor(df$.id, levels = means$Group.1)
  g <- ggplot(df, aes(.id, countChange, fill = MINTplate, color = MINTplate, size = `R-1`)) + 
    geom_point(position = position_jitter(width = .2, height = 0), alpha = .5) +
    facet_wrap("condition") +
    theme(axis.text.x = element_text(angle = 60, hjust = 1), legend.position = "none")
  print(g)
  readline("[Enter] to continue, [Esc] to quit")
}


#>7mer hits####
#>>preferred motifs####
pref_motif_7_hits <- lapply(pref_motif_7_df$motif_7, function(x) grep(x, trf_dif_exprs$sequence))
names(pref_motif_7_hits) <- names(pref_motif_7)
pref_motif_7_hits <- lapply(pref_motif_7_hits, function(x) trf_dif_exprs[x,])
pref_motif_7_hits <- pref_motif_7_hits[lapply(pref_motif_7_hits, function(x) length(x[[1]])) > 0]

pref_motif_7_hits_df <- ldply(pref_motif_7_hits)
# pref_motif_7_hits_df$condition <- factor(pref_motif_7_hits_df$condition, levels = c("30min", "60min", "2days", "4days"))
pref_motif_7_hits_df$countChange <- get.count.change(pref_motif_7_hits_df$baseMean, pref_motif_7_hits_df$log2FoldChange)

ggplot(pref_motif_7_hits_df, aes(.id, countChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") + theme(axis.text.x = element_text(angle = 60, hjust = 1))

pref_motif_7_hits_df$CC_rank <- rank(-abs(pref_motif_7_hits_df$countChange))

pref_motif_7_hits_df <- pref_motif_7_hits_df[order(pref_motif_7_hits_df$CC_rank),]
dplyr::count(unique(pref_motif_7_hits_df[,c(".id", "MINTplate")]), .id, sort = T)
dplyr::count(unique(pref_motif_7_hits_df[,c(".id", "MINTplate")]), MINTplate, sort = T)

#>>all motifs####
motif_7_hits <- vector(mode = "list", length = RBPS_len_7)
for(i in 1:length(motif_7)) {
  temp <- motif_7[[i]]
  hits <- lapply(temp$motif_7, function(x) grep(x, trf_dif_exprs$sequence))
  hits <- lapply(hits, function(x) trf_dif_exprs[x,])
  names(hits) <- temp$`R-1`
  hits <- hits[lapply(hits, function(x) length(x[[1]])) > 0]
  hits <- ldply(hits)
  if(nrow(hits)>0)
    colnames(hits)[1] <- "R-1"
  motif_7_hits[[i]] <- hits
}
names(motif_7_hits) <- names(motif_7)
motif_7_hits <- motif_7_hits[lapply(motif_7_hits, function(x) nrow(x)) > 0]

motif_7_hits_df <- ldply(motif_7_hits)
# motif_7_hits_df$condition <- factor(motif_7_hits_df$condition, levels = c("30min", "60min", "2days", "4days"))
motif_7_hits_df$`R-1` <- as.numeric(motif_7_hits_df$`R-1`)
hist(motif_7_hits_df$`R-1`)

ggplot(motif_7_hits_df, aes(unlist(lapply(motif_7_hits_df$amino_acid, function(x) paste(x[[1]], collapse = ", "))), 
                            log2FoldChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") + theme(axis.text.x = element_text(angle = 60, hjust = 1))

ggplot(motif_7_hits_df, aes(unlist(lapply(motif_7_hits_df$origin, function(x) paste(x[[1]], collapse = ", "))), 
                            log2FoldChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") + theme(axis.text.x = element_text(angle = 60, hjust = 1))

ggplot(motif_7_hits_df, aes(.id, 
                            motif_7_hits_df$`R-1`, fill = condition, color = condition)) + geom_boxplot() +
  # facet_wrap("condition") + 
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

ggplot(motif_7_hits_df, aes(.id, 
                            log2FoldChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

motif_7_hits_df$countChange <- get.count.change(motif_7_hits_df$baseMean, motif_7_hits_df$log2FoldChange)

ggplot(motif_7_hits_df, aes(.id, 
                            countChange, fill = condition, color = condition)) + geom_boxplot() +
  facet_wrap("condition") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

for(condition in unique(motif_7_hits_df$condition)) {
  df <- motif_7_hits_df[motif_7_hits_df$condition == condition,]
  means <-
    aggregate(df$countChange,
              by = list(df$.id),
              FUN = "mean")
  means <- means[order(means$x), ]
  df$.id <-
    factor(df$.id, levels = means$Group.1)
  g <- ggplot(df, aes(.id, countChange, fill = MINTplate, color = MINTplate, size = `R-1`)) + 
    geom_point(position = position_jitter(width = .2, height = 0), alpha = .5) +
    facet_wrap("condition") +
    theme(axis.text.x = element_text(angle = 60, hjust = 1), legend.position = "none")
  print(g)
  readline("[Enter] to continue, [Esc] to quit")
}

#PLOT####
#function####
plot.rbp <- function(df, title = NULL, asin = F) {
  df$MINTMINTplate <- as.factor(df$MINTplate)
  df$.id <- as.character(df$.id)
  means <-
    aggregate(df$countChange,
              by = list(df$.id),
              FUN = "sum")
  means <- means[order(means$x),]
  df$.id <-
    factor(df$.id, levels = factor(means$Group.1))
  if(asin) {
    g <- ggplot(df,
                aes(
                  .id,
                  asinh(countChange),
                  fill = MINTMINTplate,
                  color = MINTMINTplate,
                  size = `R-1`
                )) +
      geom_point(position = position_jitter(width = .2, height = 0), alpha = .5) +
      theme(axis.text.x = element_text(angle = 60, hjust = 1),
            legend.position = "none") +
      ggtitle(title)
  } else {
    g <- ggplot(df,
                aes(
                  .id,
                  countChange,
                  fill = MINTMINTplate,
                  color = MINTMINTplate,
                  size = `R-1`
                )) +
      geom_point(position = position_jitter(width = .2, height = 0), alpha = .5) +
      theme(axis.text.x = element_text(angle = 60, hjust = 1),
            legend.position = "none") +
      ggtitle(title)
  }
  print(g)
}

plot.rbp(motif_6_hits_df, "CNTF 6mers", asin = T)