if (!requireNamespace("librarian", quietly = TRUE)) install.packages("librarian")
librarian::shelf(rstudioapi, openxlsx, vegan, ggplot2,  dplyr, camtrapR, SPECIES, ggsci, tidyr, dbmss, entropart, quiet = TRUE)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

data_raw <- read.xlsx("diversity.xlsx", colNames = TRUE)
rownames(data_raw) <- data_raw[, 1]
data <- data_raw[, -1]

data <- as.matrix(data)
class(data) <- "numeric"

min_sample <- min(rowSums(data))

set.seed(6)
n_iter <- 200
rare_data <- matrix(0, nrow = nrow(data), ncol = ncol(data),
                    dimnames = list(rownames(data), colnames(data)))

for(i in 1:n_iter) {
  rare_data <- rare_data + rrarefy(data, sample = min_sample)
}
rare_data <- round(rare_data / n_iter)

clean_abd <- function(vec) {
  x <- as.numeric(vec)
  x <- x[x > 0 & !is.na(x)]
  return(as.AbdVector(x))
}

q.seq <- seq(0, 5, 0.1)

dhp  <- CommunityProfile(Diversity, clean_abd(rare_data[1, ]), q.seq, Correction = "None")
ove  <- CommunityProfile(Diversity, clean_abd(rare_data[2, ]), q.seq, Correction = "None")
grp  <- CommunityProfile(Diversity, clean_abd(rare_data[3, ]), q.seq, Correction = "None")
grnp <- CommunityProfile(Diversity, clean_abd(rare_data[4, ]), q.seq, Correction = "None")

df_dhp    <- as.data.frame.list(dhp);  df_dhp$group    <- "DHNR"
df_ove    <- as.data.frame.list(ove);  df_ove$group    <- "OVE"
df_gar_p  <- as.data.frame.list(grp);  df_gar_p$group  <- "GRNP"
df_gar_np <- as.data.frame.list(grnp); df_gar_np$group <- "GR"

df <- rbind(df_dhp, df_ove, df_gar_p, df_gar_np)

g <- ggplot(df, aes(x = x, y = y, color = group)) +
  geom_line(linewidth = 1) +
  xlab("q - order of diversity") +
  ylab(paste0("Rarefied Diversity (N = ", min_sample, " detections)")) +
  scale_color_manual(values = c(
    "DHNR" = "darkgreen",
    "OVE"  = "lightgreen",
    "GRNP" = "darkblue",
    "GR"   = "lightblue"
  )) +
  theme_bw()

print(g)
ggsave("diversity_rarefied.png", plot = g, width = 8, height = 6, dpi = 300)