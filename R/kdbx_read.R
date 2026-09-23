#' Read a KeePass Database File
#'
#' Reads entries from a KeePass `.kdbx` database file (versions 3.x and 4.x).
#'
#' @param path Character scalar. Path to the `.kdbx` file.
#' @param password Character scalar or `NULL`. The database master password.
#' @param keyfile Character scalar or `NULL`. Path to a key file.
#'
#' @details
#' At least one of `password` or `keyfile` must be provided.
#' The function auto-detects the KDBX version (3.x or 4.x).
#' Protected fields (like passwords) are automatically decrypted.
#' Fields that are empty or not set in the database are returned as `NA`.
#'
#' @return A data.frame of class `kdbx_entries` with one row per entry and
#'   columns:
#'   \describe{
#'     \item{uuid}{Character. The unique identifier of the entry.}
#'     \item{group_path}{Character. The slash-separated path of the group
#'       containing this entry (e.g., `"Root/Internet"`). The first component
#'       is the name of the database's root group, which is `"Root"` by
#'       default but can be renamed in KeePass.}
#'     \item{title}{Character. The entry title.}
#'     \item{username}{Character. The username field.}
#'     \item{password}{Character. The password field (decrypted).}
#'     \item{url}{Character. The URL field.}
#'     \item{notes}{Character. The notes field.}
#'   }
#'
#'   Passwords are masked when the result is printed (see
#'   [print.kdbx_entries()]) but are stored in plain text in the `password`
#'   column.
#'
#' @export
#' @examples
#' path <- system.file("extdata", "example.kdbx", package = "rkeepass")
#' db <- kdbx_read(path, password = "test123")
#' db[db$group_path == "Root/Internet", ]
kdbx_read <- function(path, password = NULL, keyfile = NULL) {
  check_string(path, "path")
  check_string(password, "password", allow_null = TRUE)
  check_string(keyfile, "keyfile", allow_null = TRUE)

  if (is.null(password) && is.null(keyfile)) {
    stop("At least one of `password` or `keyfile` must be provided.", call. = FALSE)
  }

  path <- check_file(path, "path")
  if (!is.null(keyfile)) {
    keyfile <- check_file(keyfile, "keyfile")
  }

  res <- kdbx_read_impl(path, password, keyfile)
  if (!is.null(res$err)) {
    stop(res$err, call. = FALSE)
  }

  new_kdbx_entries(data.frame(res$ok))
}

new_kdbx_entries <- function(x) {
  class(x) <- c("kdbx_entries", class(x))
  x
}

#' Print KeePass entries
#'
#' Prints the entries returned by [kdbx_read()] with the `password` column
#' masked, so that passwords do not end up in the console or in logs.
#'
#' @param x A `kdbx_entries` object.
#' @param ... Passed on to [print.data.frame()].
#' @param reveal Logical. If `TRUE`, passwords are printed in plain text.
#'
#' @return `x`, invisibly.
#' @export
#' @examples
#' path <- system.file("extdata", "example.kdbx", package = "rkeepass")
#' db <- kdbx_read(path, password = "test123")
#' db
#' print(db, reveal = TRUE)
print.kdbx_entries <- function(x, ..., reveal = FALSE) {
  out <- x
  class(out) <- setdiff(class(out), "kdbx_entries")
  if (!isTRUE(reveal) && "password" %in% names(out)) {
    out$password[!is.na(out$password)] <- "********"
  }
  print(out, ...)
  invisible(x)
}
