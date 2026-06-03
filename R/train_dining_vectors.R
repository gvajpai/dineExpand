#' Train custom restaurant word vectors from a text corpus
#'
#' Trains GloVe word embeddings on a character vector of restaurant reviews
#' and returns an L2-normalised matrix compatible with [expand_dining()] and
#' [expand_dining_lexicon()]. Useful when you have your own proprietary review
#' corpus or want domain-specific vectors beyond the default Yelp model.
#'
#' Requires the \pkg{text2vec} package.
#'
#' @param texts Character vector of restaurant reviews or any hospitality text.
#' @param dims Integer. Embedding dimensions. Default `100L`. Higher values
#'   capture more nuance but require more memory and training time.
#' @param vocab_size Integer. Maximum vocabulary size. Default `100000L`.
#' @param min_count Integer. Minimum token frequency to include in vocabulary.
#'   Default `5L`. Raise to `10` on limited memory.
#' @param window Integer. Co-occurrence window size. Default `5L`.
#' @param iterations Integer. Training epochs. Default `20L`. Increase to
#'   `30` for higher quality on large corpora.
#' @param n_threads Integer. CPU threads for training. Defaults to all
#'   available cores via [parallel::detectCores()].
#' @param cache_path Character or `NULL`. If provided, saves the trained
#'   matrix as an RDS file at this path. Default `NULL`.
#'
#' @return An L2-normalised numeric matrix (words × dimensions), invisibly.
#'   Compatible with [expand_dining()], [expand_dining_lexicon()], and all
#'   `lexiExpand` functions via the `vectors` argument.
#'
#' @seealso [load_dining_vectors()], [expand_dining()]
#'
#' @examples
#' \dontrun{
#' library(data.table)
#' reviews <- fread("my_restaurant_reviews.csv")
#'
#' vecs <- train_dining_vectors(
#'   texts      = reviews$text,
#'   dims       = 100L,
#'   cache_path = "~/my_restaurant_vectors.rds"
#' )
#'
#' expand_dining(c("aroma", "flavor"), vectors = vecs)
#' }
#'
#' @export
train_dining_vectors <- function(
    texts,
    dims       = 100L,
    vocab_size = 100000L,
    min_count  = 5L,
    window     = 5L,
    iterations = 20L,
    n_threads  = parallel::detectCores(),
    cache_path = NULL
) {
  # ── Check text2vec ────────────────────────────────────────────────────────
  if (!requireNamespace("text2vec", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.pkg text2vec} is required to train custom vectors.",
      "i" = "Install with {.run install.packages('text2vec')}."
    ))
  }

  if (!is.character(texts) || length(texts) == 0L) {
    cli::cli_abort(
      "{.arg texts} must be a non-empty character vector of review texts."
    )
  }

  total <- length(texts)
  cli::cli_inform(
    "Training GloVe on {.val {total}} texts ({dims}d, {iterations} iterations)."
  )

  # ── Step 1: Clean and tokenise ────────────────────────────────────────────
  cli::cli_inform("Step 1/5: Cleaning and tokenising...")

  texts_clean <- texts |>
    tolower() |>
    (\(x) gsub("([a-z])[.,!?;:\"']+\\b", "\\1", x))() |>
    (\(x) gsub("\\b[.,!?;:\"']+([a-z])", "\\1", x))() |>
    (\(x) gsub("\\s+", " ", x))() |>
    trimws()

  tokens <- text2vec::space_tokenizer(texts_clean)
  rm(texts_clean)
  gc()

  # ── Step 2: Build and prune vocabulary ───────────────────────────────────
  cli::cli_inform(
    "Step 2/5: Building vocabulary (min_count = {min_count}, max = {vocab_size})..."
  )

  it    <- text2vec::itoken(tokens, progressbar = base::interactive())
  vocab <- text2vec::create_vocabulary(it)
  vocab <- text2vec::prune_vocabulary(
    vocab,
    term_count_min = as.integer(min_count),
    vocab_term_max = as.integer(vocab_size)
  )

  cli::cli_inform("  Vocabulary: {.val {nrow(vocab)}} terms retained.")

  # ── Step 3: Co-occurrence matrix ─────────────────────────────────────────
  cli::cli_inform("Step 3/5: Building co-occurrence matrix (window = {window})...")

  vectoriser <- text2vec::vocab_vectorizer(vocab)
  it2        <- text2vec::itoken(tokens, progressbar = base::interactive())
  tcm        <- text2vec::create_tcm(
    it2, vectoriser, skip_grams_window = as.integer(window)
  )

  rm(tokens, it, it2, vectoriser, vocab)
  gc()

  # ── Step 4: Train GloVe ───────────────────────────────────────────────────
  cli::cli_inform("Step 4/5: Training GloVe ({dims}d, {iterations} iterations)...")

  glove <- text2vec::GlobalVectors$new(
    rank          = as.integer(dims),
    x_max         = 100L,
    learning_rate = 0.05
  )

  set.seed(42L)
  wv_main <- glove$fit_transform(
    x               = tcm,
    n_iter          = as.integer(iterations),
    convergence_tol = 0.001,
    n_threads       = as.integer(n_threads)
  )

  wv_context   <- glove$components
  word_vectors <- wv_main + t(wv_context)

  rm(tcm, wv_main, wv_context, glove)
  gc()

  # ── Step 5: Clean and normalise ───────────────────────────────────────────
  cli::cli_inform("Step 5/5: Cleaning vocabulary and normalising vectors...")

  # Remove empty or NA names from punctuation stripping
  bad <- which(is.na(rownames(word_vectors)) |
                 rownames(word_vectors) == "")
  if (length(bad) > 0L) {
    word_vectors <- word_vectors[-bad, ]
    cli::cli_inform("  Removed {length(bad)} empty vocabulary entries.")
  }

  # Remove duplicates (keep first occurrence — highest frequency)
  dupes <- which(duplicated(rownames(word_vectors)))
  if (length(dupes) > 0L) {
    word_vectors <- word_vectors[-dupes, ]
    cli::cli_inform("  Removed {length(dupes)} duplicate entries.")
  }

  # L2 normalise
  word_vectors <- .l2_normalise(word_vectors)

  cli::cli_inform(c(
    "v" = "Training complete: {.val {nrow(word_vectors)}} words \u00d7 \\
           {.val {ncol(word_vectors)}} dimensions."
  ))

  # ── Save if requested ─────────────────────────────────────────────────────
  if (!is.null(cache_path)) {
    saveRDS(word_vectors, cache_path)
    size_mb <- round(file.size(cache_path) / 1024^2, 1)
    cli::cli_inform("  Saved to {.path {cache_path}} ({size_mb} MB).")
  }

  invisible(word_vectors)
}
