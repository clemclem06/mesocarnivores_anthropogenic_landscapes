if (!requireNamespace("librarian", quietly = TRUE)) install.packages("librarian")
librarian::shelf(rstudioapi, readxl, ggplot2, dplyr, tidyr, openxlsx, unmarked, quiet = TRUE)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

meta <- read_excel("GAR_Metadata_dim_avecpop.xlsx")

### choice a date
# debut <- as.Date("2021-05-01")
# fin <- as.Date("2021-10-31")

debut <- as.Date("2021-11-01")
fin <- as.Date("2022-04-30") 

### and the matrice with it

#y1 <- readRDS("y_gar_all8_2021_05_01_2021_10_31.rds")
y1 <- readRDS("y_gar_all8_2021_11_01_2022_04_30.rds")

meta <- meta %>%
  filter(Retrieval_date >= debut & Setup_date <= fin)

meta$pop_mean <- as.numeric(scale(meta$pop_mean))

sitecovs <- data.frame(
  dim1   = meta$dim1, 
  dim2   = meta$dim2, 
  pop    = meta$pop_mean, 
  statut = meta$statut, 
  vision = meta$vision
)


y1 <- array(as.integer(y1), dim(y1))

matrice1 <- y1[,,1] #mongooselargegrey
matrice2 <- y1[,,2] #mongoosesmallcapegrey
matrice3 <- y1[,,3] #mongoosewatermarsh
matrice4 <- y1[,,4] #genetcapelargespotted
matrice5 <- y1[,,5] #caracal
matrice6 <- y1[,,6] #honey badger
matrice7 <- y1[,,7] #leopard
matrice8 <- y1[,,8] #human

species_name <- c(
  "mongooselargegrey",     # matrice 1
  "mongoosesmallcapegrey", # matrice 2
  "mongoosewatermarsh",    # matrice 3
  "genetcapelargespotted", # matrice 4
  "caracal",               # matrice 5 
  "honeybadger",           # matrice 6 
  "leopard",               # matrice 7
  "human"                  # matrice 8
)

matrices <- mget(paste0("matrice", 1:8))
names(matrices) <- species_name

# FULLY INACTIVE CAMERA REMOVING
empty_site <- which(rowSums(is.na(matrices[[1]])) == ncol(matrices[[1]]))

if (length(empty_site) > 0) {
  sitecovs <- sitecovs[-empty_site, , drop = FALSE]
  matrices <- lapply(matrices, function(m) m[-empty_site, , drop = FALSE])
  cat(length(empty_site), "inactive(s) camera(s).\n")
} else {
  cat("No inactive camera\n")
}


#### Single species

resultats_occupancy_single <- data.frame()
for (i in 1:8) {
  nom_esp <- species_name[i]
  cat(sprintf("Single species model for : %s...\n", nom_esp))
  
  y_mat <- as.matrix(matrices[[i]])
  data_single <- unmarkedFrameOccu(y = y_mat, siteCovs = sitecovs)
  
  res <- tryCatch({
    occu(~vision ~dim1+dim2+pop+statut, data = data_single)
  }, error = function(e) {
    message(sprintf("Erreur de convergence pour %s : %s", nom_esp, e$message))
    return(NULL)
  })
  
  if (!is.null(res)) {
    sum_res <- summary(res)
    
    df_occ <- as.data.frame(sum_res$state)
    df_occ$Parametre <- rownames(df_occ)
    df_occ$Type <- "Occupancy"
    
    df_det <- as.data.frame(sum_res$det)
    df_det$Parametre <- rownames(df_det)
    df_det$Type <- "Detection"
    
    df_res <- rbind(df_occ, df_det)
    df_res$Espece <- nom_esp
    rownames(df_res) <- NULL
    
    resultats_occupancy_single <- rbind(resultats_occupancy_single, df_res)
  }
}

if (nrow(resultats_occupancy_single) > 0) {
  resultats_occupancy_single <- resultats_occupancy_single %>%
    select(Espece, Type, Parametre, everything())
}

print(head(resultats_occupancy_single))

write.xlsx(
  resultats_occupancy_single, 
  file = "resultats_occupancy_single_summer.xlsx",  #!!! winter or summer !!!
  asTable = TRUE,        
  firstRow = TRUE,        
  headerStyle = createStyle(textDecoration = "BOLD"), 
  overwrite = TRUE
)


### MULTISPECIES

detFormulas <- c('~vision', '~vision')
occFormulas <- c('~dim1+dim2+pop+statut', '~dim1+dim2+pop+statut', '~1')

paires <- combn(names(matrices), 2)

resultats_coefficients <- data.frame()
resultats_co_occ       <- data.frame()

for (i in 1:ncol(paires)) {
  nom_esp1 <- paires[1, i]
  nom_esp2 <- paires[2, i]
  
  cat(sprintf("[%02d/%02d] Multispecies analysis : %s vs %s...\n", 
              i, ncol(paires), nom_esp1, nom_esp2))
  
  y_list <- list(matrices[[nom_esp1]], matrices[[nom_esp2]])
  names(y_list) <- c(nom_esp1, nom_esp2)
  
  data_multi <- unmarkedFrameOccuMulti(y_list, siteCovs = sitecovs, obsCovs = NULL)
  
  res <- tryCatch({
    occuMulti(detFormulas, occFormulas, data_multi, penalty = 1)
  }, error = function(e) {
    message(sprintf("Convergence error: %s", nom_esp1, nom_esp2, e$message))
    return(NULL)
  })
  
  if (!is.null(res)) {
    # coefficient extraction
    sum_res <- summary(res)
    
    df_occ <- as.data.frame(sum_res$state)
    df_occ$Parametre <- rownames(df_occ)
    df_occ$Type <- "Occupancy"
    
    df_det <- as.data.frame(sum_res$det)
    df_det$Parametre <- rownames(df_det)
    df_det$Type <- "Detection"
    
    df_res <- bind_rows(df_occ, df_det)
    df_res$Esp1  <- nom_esp1
    df_res$Esp2  <- nom_esp2
    df_res$Paire <- paste(nom_esp1, nom_esp2, sep = "_vs_")
    rownames(df_res) <- NULL
    
    resultats_coefficients <- bind_rows(resultats_coefficients, df_res)
    
    # co-occurence probability
    df_pred <- predict(res, 'state', species = c(nom_esp1, nom_esp2))
    df_pred$statut <- sitecovs$statut
    
    resume_statut <- df_pred %>%
      group_by(statut) %>%
      summarise(
        Moyenne_CoOcc = mean(Predicted, na.rm = TRUE),
        SD_CoOcc      = sd(Predicted, na.rm = TRUE),
        .groups       = "drop"
      ) %>%
      pivot_wider(
        names_from  = statut,
        values_from = c(Moyenne_CoOcc, SD_CoOcc),
        names_glue  = "{statut}_{.value}"
      ) %>%
      mutate(Esp1 = nom_esp1, Esp2 = nom_esp2)
    
    resultats_co_occ <- bind_rows(resultats_co_occ, resume_statut)
  }
}

if (nrow(resultats_coefficients) > 0) {
  resultats_coefficients <- resultats_coefficients %>% 
    select(Paire, Esp1, Esp2, Type, Parametre, everything())
}

if (nrow(resultats_co_occ) > 0) {
  resultats_co_occ <- resultats_co_occ %>% 
    select(Esp1, Esp2, everything())
}

wb <- createWorkbook()

addWorksheet(wb, "Coefficients")
writeDataTable(wb, "Coefficients", resultats_coefficients, tableStyle = "TableStyleLight1")

addWorksheet(wb, "Co_occurrence")
writeDataTable(wb, "Co_occurrence", resultats_co_occ, tableStyle = "TableStyleLight1")

saveWorkbook(wb, file = "resultats_occuMulti_summer.xlsx", overwrite = TRUE) # !!! winter or summer !!!