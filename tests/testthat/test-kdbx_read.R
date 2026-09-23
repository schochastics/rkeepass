test_that("kdbx_read returns a data.frame with expected columns", {
  result <- kdbx_read(example_kdbx(), password = "test123")

  expect_s3_class(result, "data.frame")
  expect_named(
    result,
    c("uuid", "group_path", "title", "username", "password", "url", "notes")
  )
  expect_equal(nrow(result), 4)
  for (col in names(result)) {
    expect_type(result[[col]], "character")
  }
})

test_that("kdbx_read returns correct entry data", {
  result <- kdbx_read(example_kdbx(), password = "test123")

  email_row <- result[result$title == "Email", ]
  expect_equal(email_row$username, "user@example.com")
  expect_equal(email_row$password, "emailpass123")
  expect_equal(email_row$group_path, "Root")
  expect_equal(email_row$notes, "My email account")
})

test_that("kdbx_read preserves group hierarchy", {
  result <- kdbx_read(example_kdbx(), password = "test123")

  expect_equal(result$group_path[result$title == "GitHub"], "Root/Internet")
  expect_equal(result$group_path[result$title == "MyBank"], "Root/Banking")
})

test_that("kdbx_read returns NA for empty fields", {
  result <- kdbx_read(example_kdbx(), password = "test123")
  expect_true(is.na(result$notes[result$title == "GitHub"]))

  result <- kdbx_read(fixture("kdbx3_password.kdbx"), password = "demopass")
  empty <- result[result$uuid == "222dd179-cb64-44c8-a7f6-cd0bc7731816", ]
  expect_true(is.na(empty$title))
  expect_true(is.na(empty$username))
  expect_true(is.na(empty$password))
  expect_equal(empty$notes, "This entry has an empty title, username, and password")
})

test_that("kdbx_read reads KDBX 3.x databases", {
  result <- kdbx_read(fixture("kdbx3_password.kdbx"), password = "demopass")

  expect_equal(nrow(result), 6)
  expect_true("sample/General/Subgroup" %in% result$group_path)
  expect_equal(
    result$password[which(result$title == "test entry")],
    "nWuu5AtqsxqNhnYgLwoB"
  )
})

test_that("kdbx_read supports keyfile-only authentication", {
  result <- kdbx_read(
    fixture("kdbx4_keyfile.kdbx"),
    keyfile = fixture("kdbx4_keyfile.key")
  )

  expect_equal(nrow(result), 1)
  expect_equal(result$title, "Test")
  expect_equal(result$password, "pass")
})

test_that("kdbx_read supports password plus keyfile authentication", {
  path <- fixture("kdbx4_password_keyfile.kdbx")
  keyfile <- fixture("kdbx4_password_keyfile.keyx")

  result <- kdbx_read(path, password = "demopass", keyfile = keyfile)
  expect_equal(result$title, "secret")

  expect_error(kdbx_read(path, keyfile = keyfile), "Incorrect password or keyfile")
  expect_error(kdbx_read(path, password = "demopass"), "Incorrect password or keyfile")
})

test_that("kdbx_read errors on wrong password", {
  expect_error(
    kdbx_read(example_kdbx(), password = "wrongpassword"),
    "Incorrect password or keyfile"
  )
})

test_that("kdbx_read errors on files that are not KeePass databases", {
  expect_error(
    kdbx_read(fixture("README.md"), password = "test"),
    "Not a valid KeePass database"
  )
})

test_that("kdbx_read errors on missing files", {
  expect_error(
    kdbx_read("nonexistent.kdbx", password = "test"),
    "`path` does not exist"
  )
  expect_error(
    kdbx_read(example_kdbx(), keyfile = "nonexistent.key"),
    "`keyfile` does not exist"
  )
})

test_that("kdbx_read errors when no credentials provided", {
  expect_error(
    kdbx_read(example_kdbx()),
    "At least one of `password` or `keyfile` must be provided"
  )
})

test_that("kdbx_read validates argument types", {
  expect_error(kdbx_read(1), "`path` must be a single string")
  expect_error(kdbx_read(example_kdbx(), password = 123), "`password` must be a single string")
  expect_error(kdbx_read(example_kdbx(), password = c("a", "b")), "`password` must be a single string")
  expect_error(kdbx_read(example_kdbx(), password = NA_character_), "`password` must be a single string")
  expect_error(kdbx_read(example_kdbx(), keyfile = TRUE), "`keyfile` must be a single string")
})
