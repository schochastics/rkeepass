example_kdbx <- function() {
  system.file("extdata", "example.kdbx", package = "rkeepass")
}

fixture <- function(name) {
  test_path("fixtures", name)
}
