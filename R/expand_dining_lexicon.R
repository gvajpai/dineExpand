#' Expand a full lexicon data frame using restaurant-domain embeddings
#'
#' Accepts a two-column data frame (words + dimension labels) and expands
#' every dimension using vectors pre-trained on Yelp restaurant reviews.
#' A convenience wrapper around [lexiExpand::expand_lexicon()] with automatic
#' dining vector loading.
#'
#' @param lexicon A data frame with at least two columns: words and dimension
#'   labels. Column names are detected automatically (first = words, second =
#'   dimensions) or specified via `word_col` and `dim_col`.
#' @param word_col Character. Name of the word column. If `NULL` (default),
#'   the first column is used.
#' @param dim_col Character. Name of the dimension column. If `NULL`
#'   (default), the second column is used.
#' @param n Integer. Candidates per seed word. Default `20L`.
#' @param threshold Numeric. Minimum cosine similarity. Default `0.65`.
#' @param seed_mode Character. `"individual"` (default) or `"centroid"`.
#'   See [expand_dining()].
#' @param vectors Numeric matrix or `NULL`. Pre-loaded dining vectors. If
#'   `NULL`, loaded automatically via [load_dining_vectors()]. Pass a
#'   pre-loaded matrix when expanding multiple lexicons in one session.
#' @param cache_dir Character. Vector cache directory.
#'
#' @return A `data.frame` with columns `word`, `similarity`, `seed`,
#'   `pct_match`, and `dimension` — one row per candidate across all
#'   dimensions, sorted by dimension then descending similarity. Words
#'   already in the lexicon are excluded.
#'
#' @seealso [expand_dining()], [load_dining_vectors()],
#'   [lexiExpand::export_dict()]
#'
#' @examples
#' \dontrun{
#' vecs <- load_dining_vectors()
#'
#' # Any two-column lexicon
#' my_dict <- data.frame(
#'   word      = c("aroma",     "flavor",   "texture",
#'                 "delighted", "excited",  "moved",
#'                 "revisit",   "return",   "loyal"),
#'   dimension = c("sensory",   "sensory",  "sensory",
#'                 "affect",    "affect",   "affect",
#'                 "revisit",   "revisit",  "revisit")
#' )
#'
#' candidates <- expand_dining_lexicon(my_dict, vectors = vecs)
#' table(candidates$dimension)
#'
#' # Custom column names
#' expand_dining_lexicon(my_dict,
#'                       word_col = "term",
#'                       dim_col  = "construct",
#'                       vectors  = vecs)
#' }
#'
#' @export
expand_dining_lexicon <- function(
    lexicon,
    word_col  = NULL,
    dim_col   = NULL,
    n         = 20L,
    threshold = 0.65,
    seed_mode = c("individual", "centroid"),
    vectors   = NULL,
    cache_dir = rappdirs::user_data_dir("dineExpand")
) {
  seed_mode <- match.arg(seed_mode)

  if (is.null(vectors)) {
    vectors <- load_dining_vectors(cache_dir = cache_dir)
  }

  lexiExpand::expand_lexicon(
    lexicon   = lexicon,
    word_col  = word_col,
    dim_col   = dim_col,
    n         = n,
    threshold = threshold,
    seed_mode = seed_mode,
    vectors   = vectors
  )
}
