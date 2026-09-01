read_distance_matrix <- function(path) {
  source <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  labels <- source[[1]]
  matrix_data <- as.matrix(source[-1])
  storage.mode(matrix_data) <- "double"
  rownames(matrix_data) <- labels

  if (nrow(matrix_data) != ncol(matrix_data)) {
    stop("Distance matrix must be square")
  }
  if (!identical(rownames(matrix_data), colnames(matrix_data))) {
    stop("Row and column brand labels must match")
  }
  if (any(matrix_data < 0) || any(diag(matrix_data) != 0)) {
    stop("Distances must be non-negative with a zero diagonal")
  }
  if (!isTRUE(all.equal(matrix_data, t(matrix_data), tolerance = 1e-10))) {
    stop("Distance matrix must be symmetric")
  }
  matrix_data
}


fit_positioning_map <- function(matrix_data, map_name) {
  fit <- cmdscale(as.dist(matrix_data), k = 2, eig = TRUE)
  coordinates <- data.frame(
    map = map_name,
    brand = rownames(fit$points),
    dimension_1 = fit$points[, 1],
    dimension_2 = fit$points[, 2],
    row.names = NULL
  )

  candidate_pairs <- which(upper.tri(matrix_data), arr.ind = TRUE)
  pair_distances <- matrix_data[candidate_pairs]
  nearest_index <- which.min(pair_distances)
  nearest_pair <- paste(
    rownames(matrix_data)[candidate_pairs[nearest_index, 1]],
    colnames(matrix_data)[candidate_pairs[nearest_index, 2]],
    sep = " / "
  )

  summary <- data.frame(
    map = map_name,
    goodness_of_fit = fit$GOF[1],
    nearest_pair = nearest_pair,
    nearest_distance = pair_distances[nearest_index]
  )
  list(coordinates = coordinates, summary = summary)
}


plot_positioning_map <- function(coordinates, title, path) {
  png(path, width = 1400, height = 900, res = 160)
  par(mar = c(5, 5, 4, 2) + 0.1)
  x_range <- range(coordinates$dimension_1)
  y_range <- range(coordinates$dimension_2)
  x_padding <- max(diff(x_range) * 0.12, 0.25)
  y_padding <- max(diff(y_range) * 0.12, 0.20)
  plot(
    coordinates$dimension_1,
    coordinates$dimension_2,
    type = "n",
    xlim = x_range + c(-x_padding, x_padding),
    ylim = y_range + c(-y_padding, y_padding),
    xlab = "Dimension 1",
    ylab = "Dimension 2",
    main = title,
    panel.first = grid(col = "#e5e7eb")
  )
  points(
    coordinates$dimension_1,
    coordinates$dimension_2,
    pch = 19,
    cex = 1.5,
    col = "#2563eb"
  )
  text(
    coordinates$dimension_1,
    coordinates$dimension_2,
    labels = coordinates$brand,
    pos = ifelse(coordinates$dimension_1 > mean(x_range), 2, 4),
    offset = 0.7,
    cex = 1.05,
    col = "#111827"
  )
  abline(h = 0, v = 0, lty = 3, col = "#9ca3af")
  dev.off()
}


run_analysis <- function(repo_dir) {
  similarity <- read_distance_matrix(file.path(repo_dir, "data", "similarity_distances.csv"))
  attributes <- read_distance_matrix(file.path(repo_dir, "data", "attribute_distances.csv"))
  similarity_fit <- fit_positioning_map(similarity, "similarity_based")
  attribute_fit <- fit_positioning_map(attributes, "attribute_based")

  output_dir <- file.path(repo_dir, "outputs")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(
    rbind(similarity_fit$coordinates, attribute_fit$coordinates),
    file.path(output_dir, "brand_coordinates.csv"),
    row.names = FALSE
  )
  write.csv(
    rbind(similarity_fit$summary, attribute_fit$summary),
    file.path(output_dir, "map_summary.csv"),
    row.names = FALSE
  )
  plot_positioning_map(
    similarity_fit$coordinates,
    "Athletic Shoe Brands: Similarity-Based Positioning",
    file.path(output_dir, "similarity_map.png")
  )
  plot_positioning_map(
    attribute_fit$coordinates,
    "Athletic Shoe Brands: Attribute-Distance Positioning",
    file.path(output_dir, "attribute_map.png")
  )
  invisible(list(similarity = similarity_fit, attribute = attribute_fit))
}


if (sys.nframe() == 0) {
  script_arg <- commandArgs(trailingOnly = FALSE)
  script_path <- sub("^--file=", "", script_arg[grep("^--file=", script_arg)])
  repo_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
  run_analysis(repo_dir)
  message("Athletic shoe positioning analysis completed.")
}
