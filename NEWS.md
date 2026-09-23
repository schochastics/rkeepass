# rkeepass 0.1.0

* Initial release.
* `kdbx_read()` reads entries from KeePass KDBX 3.x and 4.x databases with a
  password, a keyfile, or both.
* Fields that are empty or not set are returned as `NA`.
* Results have class `kdbx_entries`; passwords are masked when printed. Use
  `print(x, reveal = TRUE)` to show them.
* Errors from the Rust side (wrong credentials, invalid files) are reported
  as regular R errors.
