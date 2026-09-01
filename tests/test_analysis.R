script_arg <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", script_arg[grep("^--file=", script_arg)])
repo_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
source(file.path(repo_dir, "R", "analyze_positioning.R"))

similarity <- read_distance_matrix(file.path(repo_dir, "data", "similarity_distances.csv"))
attributes <- read_distance_matrix(file.path(repo_dir, "data", "attribute_distances.csv"))
similarity_fit <- fit_positioning_map(similarity, "similarity_based")
attribute_fit <- fit_positioning_map(attributes, "attribute_based")

stopifnot(nrow(similarity_fit$coordinates) == 5)
stopifnot(similarity_fit$summary$nearest_pair == "Nike / Adidas")
stopifnot(attribute_fit$summary$nearest_pair == "Adidas / NewBalance")
stopifnot(similarity_fit$summary$goodness_of_fit > 0.75)
stopifnot(attribute_fit$summary$goodness_of_fit > 0.95)

run_analysis(repo_dir)
stopifnot(file.exists(file.path(repo_dir, "outputs", "similarity_map.png")))
stopifnot(file.exists(file.path(repo_dir, "outputs", "attribute_map.png")))

message("All athletic-shoe positioning checks passed.")
