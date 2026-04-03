test_that("kdbx_read returns a data.frame with expected columns", {
  db_path <- system.file("extdata", "example.kdbx", package = "rkeepass")
  result <- kdbx_read(db_path, password = "test123")

  expect_s3_class(result, "data.frame")
  expect_named(result, c("uuid", "group_path", "title", "username", "password", "url", "notes"))
})

test_that("kdbx_read returns correct number of entries", {
  db_path <- system.file("extdata", "example.kdbx", package = "rkeepass")
  result <- kdbx_read(db_path, password = "test123")

  expect_equal(nrow(result), 4)
})

test_that("kdbx_read returns correct entry data", {
  db_path <- system.file("extdata", "example.kdbx", package = "rkeepass")
  result <- kdbx_read(db_path, password = "test123")

  email_row <- result[result$title == "Email", ]
  expect_equal(email_row$username, "user@example.com")
  expect_equal(email_row$password, "emailpass123")
  expect_equal(email_row$group_path, "Root")
  expect_equal(email_row$notes, "My email account")
})

test_that("kdbx_read preserves group hierarchy", {
  db_path <- system.file("extdata", "example.kdbx", package = "rkeepass")
  result <- kdbx_read(db_path, password = "test123")

  github_row <- result[result$title == "GitHub", ]
  expect_equal(github_row$group_path, "Root/Internet")

  bank_row <- result[result$title == "MyBank", ]
  expect_equal(bank_row$group_path, "Root/Banking")
})

test_that("kdbx_read all columns are character", {
  db_path <- system.file("extdata", "example.kdbx", package = "rkeepass")
  result <- kdbx_read(db_path, password = "test123")

  for (col in names(result)) {
    expect_type(result[[col]], "character")
  }
})

test_that("kdbx_read errors on wrong password", {
  db_path <- system.file("extdata", "example.kdbx", package = "rkeepass")
  expect_error(kdbx_read(db_path, password = "wrongpassword"))
})

test_that("kdbx_read errors on missing file", {
  expect_error(kdbx_read("nonexistent.kdbx", password = "test"))
})

test_that("kdbx_read errors when no credentials provided", {
  db_path <- system.file("extdata", "example.kdbx", package = "rkeepass")
  expect_error(
    kdbx_read(db_path),
    "At least one of `password` or `keyfile` must be provided"
  )
})
