if (!requireNamespace("librarian", quietly = TRUE)) install.packages("librarian")
librarian::shelf(rstudioapi, openxlsx, lubridate, ggplot2, dplyr, readxl, overlap, quiet = TRUE)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

########GARDEN ROUTE

gar <- read_excel("GAR_data_meso_30min.xlsx") 
meta_gar <- read_excel("GAR_metadata_dim_withpop.xlsx")

date_debut <- as.POSIXct("2021-05-01 00:00:00")
date_fin   <- as.POSIXct("2022-04-30 23:59:59")

gar <- gar %>% 
  filter(DateTimeOriginal >= date_debut & DateTimeOriginal <= date_fin) %>% 
  inner_join(meta_gar %>% select(cam, statut), by = c("Station" = "cam")) %>% 
  mutate(
    DateTime_parsed = ymd_hms(DateTimeOriginal),
    heure  = hour(DateTime_parsed),
    minute = minute(DateTime_parsed),
    rad    = (heure * 60 + minute) * 2 * pi / (24 * 60)
  )

toutes_especes <- c(
  "human activity",  "leopard", "caracal", "honeybadger", 
  "genetcapelargespotted", "mongooselargegrey", "mongoosesmallcapegrey", "mongoosewatermarsh"
)

paires_combinaisons <- combn(toutes_especes, 2, simplify = FALSE)

for (st in c("protected", "non_protected")) {
  
  gar_sub <- gar %>% filter(statut == st)
  liste_lignes_CR <- vector("list", length(paires_combinaisons))
  
  for (i in seq_along(paires_combinaisons)) {
    
    print(i)
    
    esp1 <- paires_combinaisons[[i]][1]
    esp2 <- paires_combinaisons[[i]][2]
    
    A_rad <- gar_sub$rad[gar_sub$Species == esp1]
    B_rad <- gar_sub$rad[gar_sub$Species == esp2]
    
    n_A <- length(A_rad)
    n_B <- length(B_rad)
    
    if (n_A >= 20 && n_B >= 20) {
      type_est <- if (min(n_A, n_B) < 50) "Dhat1" else "Dhat4"
      
      t0   <- overlapEst(A_rad, B_rad, kmax = 3, adjust = c(0.8, 1, 4), n.grid = 128, type = type_est)
      bt   <- bootstrap(A_rad, B_rad, 1000, smooth = TRUE, kmax = 3, adjust = NA, n.grid = 512, type = type_est)
      conf <- bootCI(t0, bt, conf = 0.95)
      
      liste_lignes_CR[[i]] <- data.frame(
        Espece_1      = esp1,
        Espece_2      = esp2,
        N_Espece_1    = n_A,
        N_Espece_2    = n_B,
        Estimateur    = type_est,
        Overlap_Value = round(unname(t0[type_est]), 4),
        IC_inf_perc   = round(conf["perc", "lower"], 4),
        IC_sup_perc   = round(conf["perc", "upper"], 4),
        stringsAsFactors = FALSE
      )
    }
  }
  
  resultats_overlap <- bind_rows(liste_lignes_CR)
  write.xlsx(resultats_overlap, file = paste0("gar_overlap_", st, ".xlsx"), rowNames = FALSE)
}


########OVERBERG AND DE HOOP

ove <- read.xlsx("OVE_data_meso_30min.xlsx")
dhp <- read.xlsx("DHP_data_meso_30min.xlsx")

ove$DateTimeOriginal<- ove$DateTimeOriginal*60*60*24
ove$DateTimeOriginal <- as.POSIXct(ove$DateTimeOriginal, format = "%Y-%m-%d %H:%M:%S")
ove$DateTimeOriginal <- ove$DateTimeOriginal - (70*365+19)*24*60*60 
ove$DateTimeOriginal <- round(ove$DateTimeOriginal, units = "secs")
ove$DateTimeOriginal <- as.character(ove$DateTimeOriginal, format = "%Y-%m-%d %H:%M:%S")

dhp$DateTimeOriginal<- dhp$DateTimeOriginal*60*60*24
dhp$DateTimeOriginal <- as.POSIXct(dhp$DateTimeOriginal, format = "%Y-%m-%d %H:%M:%S")
dhp$DateTimeOriginal <- dhp$DateTimeOriginal - (70*365+19)*24*60*60
dhp$DateTimeOriginal <- round(dhp$DateTimeOriginal, units = "secs")
dhp$DateTimeOriginal <- as.character(dhp$DateTimeOriginal, format = "%Y-%m-%d %H:%M:%S")

toutes_especes <- c(
  "human",  "leopard", "caracal", "honeybadger", 
  "genetcapelargespotted", "mongooselargegrey", "mongoosesmallcapegrey", "mongoosewatermarsh" #slight change it is human and not human activity
)

paires_combinaisons <- combn(toutes_especes, 2, simplify = FALSE)

### OVERBERG

resultats_overlap_ove <- data.frame(
  Espece_1 = character(),
  Espece_2 = character(),
  N_Espece_1 = numeric(),
  N_Espece_2 = numeric(),
  Estimateur = character(),
  Overlap_Value = numeric(),
  IC_inf_perc = numeric(),
  IC_sup_perc = numeric(),
  stringsAsFactors = FALSE
)

for (i in 1:length(paires_combinaisons)) {
  
  print(i)
  
  esp1 <- paires_combinaisons[[i]][1]
  esp2 <- paires_combinaisons[[i]][2]
  
  dates_A <- ove$DateTime[ove$Species == esp1]
  dates_B <- ove$DateTime[ove$Species == esp2]
  
  n_A <- length(dates_A)
  n_B <- length(dates_B)
  
  if (n_A >= 5 && n_B >= 5) {
    
    type_est <- if (min(n_A, n_B) < 50) "Dhat1" else "Dhat4"
  
    A <- ymd_hms(dates_A)
    heure_A <- hour(A)
    minute_A <- minute(A)
    A_rad <- (heure_A * 60 + minute_A) * 2 * pi / (24 * 60)
    
    B <- ymd_hms(dates_B)
    heure_B <- hour(B)
    minute_B <- minute(B)
    B_rad <- (heure_B * 60 + minute_B) * 2 * pi / (24 * 60)
    
    t0 <- overlapEst(A_rad, B_rad, kmax = 3, adjust = c(0.8, 1, 4), n.grid = 128, type = type_est)
  
    bt <- bootstrap(A_rad, B_rad, 1000, smooth = TRUE, kmax = 3, adjust = NA, n.grid = 512, type = type_est)
    
    conf <- bootCI(t0, bt, conf = 0.95)

    valeur_overlap <- t0["Dhat1"]
    ic_inf <- conf["perc", "lower"]
    ic_sup <- conf["perc", "upper"]
    
    resultats_overlap_ove <- rbind(resultats_overlap_ove, data.frame(
      Espece_1 = esp1,
      Espece_2 = esp2,
      N_Espece_1 = n_A,
      N_Espece_2 = n_B,
      Estimateur = type_est,
      Overlap_Value = round(valeur_overlap, 4),
      IC_inf_perc = round(ic_inf, 4),
      IC_sup_perc = round(ic_sup, 4)
    ))
    
  } 
}

write.xlsx(resultats_overlap_ove, file = paste0("ove_overlap.xlsx"), rowNames = FALSE)


### DE HOOP

resultats_overlap_dhp <- data.frame(
  Espece_1 = character(),
  Espece_2 = character(),
  N_Espece_1 = numeric(),
  N_Espece_2 = numeric(),
  Estimateur = character(),
  Overlap_Value = numeric(),
  IC_inf_perc = numeric(),
  IC_sup_perc = numeric(),
  stringsAsFactors = FALSE
)

for (i in 1:length(paires_combinaisons)) {
  
  print(i)
  
  esp1 <- paires_combinaisons[[i]][1]
  esp2 <- paires_combinaisons[[i]][2]
  
  dates_A <- dhp$DateTime[dhp$Species == esp1]
  dates_B <- dhp$DateTime[dhp$Species == esp2]
  
  n_A <- length(dates_A)
  n_B <- length(dates_B)
  
  if (n_A >= 5 && n_B >= 5) {
    
    type_est <- if (min(n_A, n_B) < 50) "Dhat1" else "Dhat4"
    
    A <- ymd_hms(dates_A)
    heure_A <- hour(A)
    minute_A <- minute(A)
    A_rad <- (heure_A * 60 + minute_A) * 2 * pi / (24 * 60)
    
    B <- ymd_hms(dates_B)
    heure_B <- hour(B)
    minute_B <- minute(B)
    B_rad <- (heure_B * 60 + minute_B) * 2 * pi / (24 * 60)
    
    t0 <- overlapEst(A_rad, B_rad, kmax = 3, adjust = c(0.8, 1, 4), n.grid = 128, type = type_est)
    
    bt <- bootstrap(A_rad, B_rad, 1000, smooth = TRUE, kmax = 3, adjust = NA, n.grid = 512, type = type_est)
    
    conf <- bootCI(t0, bt, conf = 0.95)
    
    valeur_overlap <- t0["Dhat1"]
    ic_inf <- conf["perc", "lower"]
    ic_sup <- conf["perc", "upper"]
    
    resultats_overlap_dhp <- rbind(resultats_overlap_dhp, data.frame(
      Espece_1 = esp1,
      Espece_2 = esp2,
      N_Espece_1 = n_A,
      N_Espece_2 = n_B,
      Estimateur = type_est,
      Overlap_Value = round(valeur_overlap, 4),
      IC_inf_perc = round(ic_inf, 4),
      IC_sup_perc = round(ic_sup, 4)
    ))
    
  } 
}

write.xlsx(resultats_overlap_dhp, file = paste0("dhp_overlap.xlsx"), rowNames = FALSE)
