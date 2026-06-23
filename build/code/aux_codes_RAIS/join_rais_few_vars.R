.libPaths("F:/docs/R-library")

library(tidyverse)
library(magrittr)
library(haven)
library(purrr)
library(stringr)
library(arrow)

# setup
years <- 2009:2011
base_path <- "F:/RAIS/admin/id_data/contract_level/"
temp_dir <- "temp_merge_results"
dir.create(temp_dir, showWarnings = FALSE)

# all keys are already standardize
# 11 digits, leading zeros, as.character()

initial_identifiers <- open_dataset("get_outcomes/identificadores_transbrasil.parquet") %>% # replace "." with path to file
  select(num_nis_pessoa_atual, num_cpf_pessoa) %>%
  collect()

initial_identifiers %<>% rename(
  "id_worker" = "num_nis_pessoa_atual",
  "cpf_worker" = "num_cpf_pessoa"
)

initial_identifiers %<>% filter(!is.na(id_worker) & !is.na(cpf_worker))

# the loop
# this will take the longest to run
for (yr in years) {
  
  out_file <- file.path(temp_dir, paste0("match", yr, ".rds"))
  
  # checkpoint: skip if processed
  # used if the code breaks halfway through
  if (file.exists(out_file)) {
    message(paste("Skipping year:", yr, "- File exists."))
    next
  }
  
  message(paste(">>> Processing year: ", yr, " | Time: ", Sys.time()))
  
  file_path <- paste0(base_path, yr, "/", yr, "mgrjes.dta")
  
  if(!file.exists(file_path)) {
    warning(paste("File missing for year", yr))
    next
  }
  
  # load data
  
  rais_data <- read_dta(
    file_path,
    col_select = c( # doesnt break if column missing for a given year
      id_worker,
      cpf_worker, 
      empl_31dec,
      hire_date,
      sep_month,
      reas_sep
    )
  ) %>%
    # drop duplicate rows as recommended
    distinct() 
  
  # waterfall merge
  
  # tier 1: CPF
  match_1 <- initial_identifiers %>%
    inner_join(rais_data, by = "cpf_worker") %>%
    mutate(formal = 1)
  
  leftovers_1 <- initial_identifiers %>%
    anti_join(rais_data, by = "cpf_worker")
  
  #tier 2: NIS/PIS
  match_2 <- leftovers_1 %>%
    inner_join(rais_data, by = "id_worker") %>%
    mutate(formal = 1)
  
  leftovers_2 <- leftovers_1 %>%
    anti_join(rais_data, by = "id_worker") %>%
    mutate(formal = 0)
  
  rm(leftovers_1)
  
  # combine everything
  
  year_panel <- bind_rows(match_1, match_2, leftovers_2) %>%
    mutate(year = yr)
  
  saveRDS(year_panel, out_file)
  message(paste("Finished year:", yr))
  
  # cleanup
  
  rm(rais_data, match_1, match_2, leftovers_2, year_panel)
  gc()
}

# reassembling the full panel

all_matches <- list.files(temp_dir, pattern = "\\.rds$", full.names = TRUE) %>%
  map_dfr(readRDS)
