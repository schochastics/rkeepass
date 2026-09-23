check_string <- function(x, arg, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(invisible(NULL))
  }
  if (!is.character(x) || length(x) != 1 || is.na(x)) {
    stop(sprintf("`%s` must be a single string.", arg), call. = FALSE)
  }
  invisible(NULL)
}

check_file <- function(x, arg) {
  if (!file.exists(x) || dir.exists(x)) {
    stop(sprintf("`%s` does not exist: '%s'.", arg, x), call. = FALSE)
  }
  normalizePath(x)
}
