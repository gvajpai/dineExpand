# Helper — build a small synthetic restaurant-like vector matrix
make_test_vectors <- function(seed = 42L) {
  set.seed(seed)
  words <- c(
    "aroma", "flavor", "texture", "ambience", "decor",
    "attentive", "friendly", "service", "staff", "prompt",
    "delicious", "tasty", "fresh", "savory", "crispy",
    "revisit", "return", "loyal", "recommend", "again",
    "adventurous", "novel", "exotic", "unfamiliar", "unique",
    paste0("w", seq_len(25))
  )
  mat <- matrix(rnorm(length(words) * 20), nrow = length(words), ncol = 20)
  rownames(mat) <- words
  dineExpand:::.l2_normalise(mat)
}

test_that("expand_dining returns data frame in non-interactive mode", {
  mat <- make_test_vectors()

  result <- expand_dining(
    seed        = "aroma",
    n           = 5L,
    threshold   = 0.0,
    interactive = FALSE,
    vectors     = mat
  )

  expect_s3_class(result, "data.frame")
  expect_true(all(c("word", "similarity", "seed", "pct_match") %in% names(result)))
  expect_false("aroma" %in% result$word)
})

test_that("expand_dining works with vector of seeds", {
  mat <- make_test_vectors()

  result <- expand_dining(
    seed        = c("revisit", "return", "loyal"),
    n           = 5L,
    threshold   = 0.0,
    interactive = FALSE,
    vectors     = mat
  )

  expect_s3_class(result, "data.frame")
  expect_false(any(c("revisit", "return", "loyal") %in% result$word))
})

test_that("expand_dining centroid mode returns centroid in seed column", {
  mat <- make_test_vectors()

  result <- expand_dining(
    seed        = c("aroma", "flavor"),
    seed_mode   = "centroid",
    n           = 5L,
    threshold   = 0.0,
    interactive = FALSE,
    vectors     = mat
  )

  expect_true(all(result$seed == "centroid"))
})

test_that("expand_dining errors on non-character seed", {
  mat <- make_test_vectors()
  expect_error(
    expand_dining(seed = 123, vectors = mat, interactive = FALSE),
    regexp = "character"
  )
})

test_that("expand_dining warns when threshold too high", {
  mat <- make_test_vectors()
  expect_warning(
    expand_dining(
      seed        = "aroma",
      threshold   = 0.9999,
      interactive = FALSE,
      vectors     = mat
    ),
    regexp = "No candidates"
  )
})
