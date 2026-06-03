#' dineExpand: Dining-Specific Semantic Dictionary Expander
#'
#' @description
#' Expands seed dictionaries for dining and hospitality research using word
#' embeddings pre-trained on 512,140 Yelp restaurant reviews. Restaurant-domain
#' vectors are loaded with a single call — no corpus training or manual setup
#' required. Any theoretical construct relevant to dining research can be
#' expanded: revisit intention, food neophobia, authenticity, service quality,
#' price perception, and more.
#'
#' @section Typical workflow:
#' ```r
#' library(dineExpand)
#'
#' # 1. Load restaurant vectors (one-time ~33 MB download, then cached)
#' vecs <- load_dining_vectors()
#'
#' # 2. Expand any dining construct
#' expand_dining(c("revisit", "return", "loyalty"), vectors = vecs)
#'
#' # 3. Expand a full lexicon data frame
#' expand_dining_lexicon(my_dict, vectors = vecs)
#'
#' # 4. Export results
#' lexiExpand::export_dict(result, name = "revisit_intention", format = "list")
#' ```
#'
#' @section Key functions:
#' * [load_dining_vectors()]    — Download & cache Yelp-trained vectors (run once)
#' * [expand_dining()]          — Expand a seed word or vector of seeds
#' * [expand_dining_lexicon()]  — Expand a full lexicon data frame by dimension
#' * [train_dining_vectors()]   — Train custom vectors from your own corpus
#' * `lexiExpand::export_dict()` — Export results to list / data.frame / quanteda
#'
#' @keywords internal
"_PACKAGE"

# ── Session-level vector cache ────────────────────────────────────────────────
.dineexpand_env <- new.env(parent = emptyenv())
.dineexpand_env$vectors <- list()
