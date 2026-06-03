test_that("load_dining_vectors uses session cache on second call", {
  # Inject a fake matrix via getFromNamespace (avoids ::: assignment issue)
  env   <- getFromNamespace(".dineexpand_env", "dineExpand")
  fake  <- matrix(rnorm(50), nrow = 5, ncol = 10)
  rownames(fake) <- c("aroma", "flavor", "texture", "service", "ambience")
  fake  <- getFromNamespace(".l2_normalise", "dineExpand")(fake)
  env$vectors[["yelp_restaurant_100d"]] <- fake

  result <- load_dining_vectors()
  expect_true(is.matrix(result))
  expect_equal(nrow(result), 5L)

  # Clean up
  env$vectors[["yelp_restaurant_100d"]] <- NULL
})

test_that("load_dining_vectors creates cache directory if missing", {
  tmp <- tempfile()
  expect_false(dir.exists(tmp))

  # Will fail at download but the dir should be created first
  tryCatch(
    load_dining_vectors(cache_dir = tmp, timeout = 1L),
    error = function(e) NULL
  )

  expect_true(dir.exists(tmp))
  unlink(tmp, recursive = TRUE)
})
