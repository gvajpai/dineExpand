make_test_vectors <- function(seed = 42L) {
  set.seed(seed)
  words <- c(
    "aroma", "flavor", "texture",
    "delighted", "excited", "moved",
    "attentive", "friendly", "welcoming",
    paste0("w", seq_len(41))
  )
  mat <- matrix(rnorm(length(words) * 20), nrow = length(words), ncol = 20)
  rownames(mat) <- words
  getFromNamespace(".l2_normalise", "dineExpand")(mat)
}

test_that("expand_dining_lexicon returns data frame with dimension column", {
  mat <- make_test_vectors()

  lex <- data.frame(
    word      = c("aroma",     "flavor",    "texture",
                  "delighted", "excited",   "moved",
                  "attentive", "friendly",  "welcoming"),
    dimension = c("sensory",   "sensory",   "sensory",
                  "affect",    "affect",    "affect",
                  "service",   "service",   "service"),
    stringsAsFactors = FALSE
  )

  result <- expand_dining_lexicon(
    lex, n = 5L, threshold = 0.0, vectors = mat
  )

  expect_s3_class(result, "data.frame")
  expect_true("dimension" %in% names(result))
  expect_true(all(unique(result$dimension) %in% c("sensory", "affect", "service")))
  expect_false(any(result$word %in% lex$word))
})

test_that("expand_dining_lexicon accepts custom column names", {
  mat <- make_test_vectors()

  lex <- data.frame(
    term      = c("aroma", "flavor"),
    construct = c("sensory", "sensory"),
    stringsAsFactors = FALSE
  )

  result <- expand_dining_lexicon(
    lex, word_col = "term", dim_col = "construct",
    n = 5L, threshold = 0.0, vectors = mat
  )

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0L)
})

test_that("expand_dining_lexicon errors on non-data-frame input", {
  mat <- make_test_vectors()
  expect_error(
    expand_dining_lexicon(c("aroma", "flavor"), vectors = mat),
    regexp = "data frame"
  )
})
