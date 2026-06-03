#' Expand a seed dictionary using restaurant-domain word embeddings
#'
#' Finds semantically similar words for any dining or hospitality research
#' construct using vectors pre-trained on Yelp restaurant reviews. A
#' convenience wrapper around [lexiExpand::expand_dict()] that automatically
#' loads restaurant vectors and applies dining-appropriate defaults.
#'
#' @param seed Character vector of seed words representing the construct to
#'   expand. Examples:
#'   * Revisit intention: `c("revisit", "return", "loyalty")`
#'   * Food neophobia: `c("adventurous", "novel", "unfamiliar", "exotic")`
#'   * Authenticity: `c("authentic", "traditional", "genuine", "local")`
#'   * Service quality: `c("attentive", "courteous", "prompt", "helpful")`
#' @param n Integer. Number of candidates to surface per seed word. Default
#'   `20L`.
#' @param threshold Numeric in \[0, 1\]. Minimum cosine similarity required.
#'   Default `0.65`. Values above 0.80 return near-synonyms only; 0.60–0.70
#'   gives a broader semantic neighbourhood.
#' @param seed_mode Character. Multi-seed strategy:
#'   * `"individual"` *(default)* — finds neighbours per seed, deduplicates.
#'     The `$seed` column shows which seed drove each match.
#'   * `"centroid"` — finds words nearest the semantic centre of all seeds.
#' @param interactive Logical. If `TRUE` (default in an R session), launches
#'   the word-by-word review wizard. If `FALSE`, returns the ranked data frame
#'   directly — use this in scripts and RMarkdown.
#' @param vectors Numeric matrix or `NULL`. Pre-loaded vector matrix from
#'   [load_dining_vectors()]. If `NULL`, vectors are loaded automatically.
#'   Pass a pre-loaded matrix when calling this function repeatedly to avoid
#'   reloading on each call.
#' @param cache_dir Character. Vector cache directory. Default:
#'   `rappdirs::user_data_dir("dineExpand")`.
#'
#' @return
#' * When `interactive = FALSE`: a `data.frame` with columns `word`,
#'   `similarity`, `seed`, and `pct_match`, sorted by descending similarity.
#' * When `interactive = TRUE`: a `lexiexpand_result` object (invisibly)
#'   with `$accepted`, `$seed`, and `$candidates`. Pass to
#'   [lexiExpand::export_dict()] to export.
#'
#' @seealso [load_dining_vectors()], [expand_dining_lexicon()],
#'   [lexiExpand::export_dict()]
#'
#' @examples
#' \dontrun{
#' vecs <- load_dining_vectors()
#'
#' # Single word
#' expand_dining("aroma", vectors = vecs, interactive = FALSE)
#'
#' # Revisit intention construct
#' expand_dining(c("revisit", "return", "loyalty"),
#'               vectors = vecs, interactive = FALSE)
#'
#' # Food neophobia — centroid mode
#' expand_dining(c("adventurous", "novel", "unfamiliar", "exotic"),
#'               seed_mode = "centroid",
#'               vectors   = vecs,
#'               interactive = FALSE)
#'
#' # Interactive review wizard
#' result <- expand_dining(c("authentic", "traditional", "genuine"),
#'                         vectors = vecs)
#' lexiExpand::export_dict(result, name = "authenticity", format = "list")
#' }
#'
#' @export
expand_dining <- function(
    seed,
    n           = 20L,
    threshold   = 0.65,
    seed_mode   = c("individual", "centroid"),
    interactive = base::interactive(),
    vectors     = NULL,
    cache_dir   = rappdirs::user_data_dir("dineExpand")
) {
  seed_mode <- match.arg(seed_mode)

  if (is.null(vectors)) {
    vectors <- load_dining_vectors(cache_dir = cache_dir)
  }

  lexiExpand::expand_dict(
    seed        = seed,
    n           = n,
    threshold   = threshold,
    seed_mode   = seed_mode,
    interactive = interactive,
    vectors     = vectors
  )
}
