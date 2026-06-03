#' Load pre-trained restaurant word vectors
#'
#' Downloads and caches word vectors pre-trained on 512,140 Yelp restaurant
#' reviews (100 dimensions, ~100,000 vocabulary terms). The download
#' (~33 MB) happens **once**; subsequent calls load from the local cache or
#' from the session cache (instant).
#'
#' @param cache_dir Character. Directory for caching the vectors file.
#'   Defaults to a user-level data directory via [rappdirs::user_data_dir()].
#' @param overwrite Logical. Re-download even if already cached. Default
#'   `FALSE`.
#' @param timeout Integer. Download timeout in seconds. Default `300`.
#'
#' @return An L2-normalised numeric matrix (words × 100 dimensions) with
#'   restaurant-domain vocabulary as row names. Compatible with
#'   [expand_dining()], [expand_dining_lexicon()], and all
#'   `lexiExpand::expand_dict()` calls via the `vectors` argument.
#'
#' @details
#' The vectors were trained using the GloVe algorithm (Pennington et al.,
#' 2014) on restaurant reviews from the Yelp Open Dataset. Training used
#' a co-occurrence window of 5, 100 dimensions, and 20 iterations.
#' Restaurant-specific vocabulary (e.g. \emph{umami}, \emph{gastropub},
#' \emph{waitstaff}) clusters meaningfully in this space, making it
#' far more suitable for hospitality research than general-purpose
#' embeddings trained on Wikipedia or news corpora.
#'
#' The vectors file is hosted as a GitHub release asset at:
#' `https://github.com/gvajpai/dineExpand/releases/download/v0.1.0-data/yelp_restaurant_glove_100d.rds`
#'
#' @seealso [expand_dining()], [expand_dining_lexicon()],
#'   [train_dining_vectors()]
#'
#' @examples
#' \dontrun{
#' # Download and cache (first run only)
#' vecs <- load_dining_vectors()
#'
#' # Force re-download
#' vecs <- load_dining_vectors(overwrite = TRUE)
#'
#' # Custom cache location
#' vecs <- load_dining_vectors(cache_dir = "~/my_vectors/")
#' }
#'
#' @export
load_dining_vectors <- function(
    cache_dir = rappdirs::user_data_dir("dineExpand"),
    overwrite = FALSE,
    timeout   = 300L
) {
  cache_key <- "yelp_restaurant_100d"

  # ── Session cache ────────────────────────────────────────────────────────
  if (!overwrite && !is.null(.dineexpand_env$vectors[[cache_key]])) {
    cli::cli_inform("Using session-cached dining vectors.")
    return(invisible(.dineexpand_env$vectors[[cache_key]]))
  }

  # ── Ensure cache directory ───────────────────────────────────────────────
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
    cli::cli_inform("Created cache directory: {.path {cache_dir}}")
  }

  rds_path <- .vectors_cache_path(cache_dir)

  # ── Load from disk if cached ─────────────────────────────────────────────
  if (file.exists(rds_path) && !overwrite) {
    cli::cli_inform("Loading cached dining vectors from disk...")
    mat <- readRDS(rds_path)
    .dineexpand_env$vectors[[cache_key]] <- mat
    cli::cli_inform(c(
      "v" = "Loaded {.val {nrow(mat)}} words \u00d7 {.val {ncol(mat)}} dimensions."
    ))
    return(invisible(mat))
  }

  # ── Download ─────────────────────────────────────────────────────────────
  vectors_url <- paste0(
    "https://github.com/gvajpai/dineExpand/releases/download/",
    "v0.1.0-data/yelp_restaurant_glove_100d.rds"
  )

  cli::cli_inform(c(
    "!" = "Downloading restaurant GloVe vectors (~33 MB). This happens only once.",
    "i" = "Trained on 512,140 Yelp restaurant reviews.",
    "i" = "URL: {.url {vectors_url}}"
  ))

  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = as.integer(timeout))

  tmp <- tempfile(fileext = ".rds")

  tryCatch(
    utils::download.file(
      url      = vectors_url,
      destfile = tmp,
      mode     = "wb",
      quiet    = FALSE
    ),
    warning = function(w) {
      if (grepl("Timeout|downloaded length", conditionMessage(w), ignore.case = TRUE)) {
        cli::cli_abort(c(
          "Download timed out or was incomplete.",
          "i" = "Try: {.code load_dining_vectors(timeout = 600)}."
        ))
      }
      warning(w)
    },
    error = function(e) {
      cli::cli_abort(c(
        "Download failed.",
        "x" = conditionMessage(e),
        "i" = "Check your internet connection."
      ))
    }
  )

  # ── Validate ─────────────────────────────────────────────────────────────
  mat <- tryCatch(
    readRDS(tmp),
    error = function(e) {
      cli::cli_abort(c(
        "Downloaded file could not be read.",
        "x" = conditionMessage(e)
      ))
    }
  )

  if (!is.matrix(mat) || !is.numeric(mat) || is.null(rownames(mat))) {
    cli::cli_abort(
      "Downloaded file does not contain a valid word-vector matrix."
    )
  }

  # ── Save to permanent cache ───────────────────────────────────────────────
  file.copy(tmp, rds_path, overwrite = TRUE)
  unlink(tmp)

  .dineexpand_env$vectors[[cache_key]] <- mat

  cli::cli_inform(c(
    "v" = "Vectors cached at: {.path {rds_path}}",
    " " = "Loaded {.val {nrow(mat)}} words \u00d7 {.val {ncol(mat)}} dimensions."
  ))

  invisible(mat)
}
