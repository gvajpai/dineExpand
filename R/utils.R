# ── Internal utilities ────────────────────────────────────────────────────────

# @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x

#' L2-normalise rows of a numeric matrix
#' @keywords internal
.l2_normalise <- function(mat) {
  norms <- sqrt(rowSums(mat^2))
  norms[norms == 0] <- 1
  mat / norms
}

#' Return the default cache path for the dining vectors RDS
#' @keywords internal
.vectors_cache_path <- function(
    cache_dir = rappdirs::user_data_dir("dineExpand")
) {
  file.path(cache_dir, "yelp_restaurant_glove_100d.rds")
}
