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
#'
#' @return A data.frame with one row per entry and columns:
#'   \describe{
#'     \item{uuid}{Character. The unique identifier of the entry.}
#'     \item{group_path}{Character. The slash-separated path of the group
#'       containing this entry (e.g., `"Root/Internet"`).}
#'     \item{title}{Character. The entry title.}
#'     \item{username}{Character. The username field.}
#'     \item{password}{Character. The password field (decrypted).}
#'     \item{url}{Character. The URL field.}
#'     \item{notes}{Character. The notes field.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' db <- kdbx_read("my_database.kdbx", password = "secret")
#' db[db$group_path == "Root/Email", ]
#' }
kdbx_read <- function(path, password = NULL, keyfile = NULL) {
  path <- normalizePath(path, mustWork = TRUE)

  if (is.null(password) && is.null(keyfile)) {
    stop("At least one of `password` or `keyfile` must be provided.")
  }

  if (!is.null(keyfile)) {
    keyfile <- normalizePath(keyfile, mustWork = TRUE)
  }

  cols <- kdbx_read_impl(path, password, keyfile)

  data.frame(cols, stringsAsFactors = FALSE)
}
