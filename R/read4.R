read_kdbx4_header <- function(file, max_field_size = 1000000) {
  con <- file(file, "rb")
  on.exit(close(con))

  # Helpers
  read_uint32 <- function(con) {
    raw <- readBin(con, "raw", n = 4)
    sum(as.integer(raw) * 256^(0:3))
  }

  read_uint16 <- function(con) {
    raw <- readBin(con, "raw", n = 2)
    sum(as.integer(raw) * 256^(0:1))
  }

  field_type_names <- list(
    "0" = "EndOfHeader",
    "2" = "CipherID",
    "3" = "CompressionFlags",
    "4" = "MasterSeed",
    "7" = "EncryptionIV",
    "11" = "KdfParameters",
    "12" = "PublicCustomData"
  )

  # --- Read signature ---
  sig1 <- read_uint32(con)
  sig2 <- read_uint32(con)

  if (sig1 != 0x9AA2D903 || sig2 != 0xB54BFB67) {
    stop("Invalid KDBX signature")
  }

  minor_version <- read_uint16(con)
  major_version <- read_uint16(con)

  # --- Read header fields ---
  known_fields <- list()
  unknown_fields <- list()

  while (TRUE) {
    field_type <- readBin(con, "integer", size = 1, signed = FALSE)

    if (field_type == 0) {
      # marker <- readBin(con, "raw", n = 4)
      # if (!all(marker == as.raw(c(0x0D, 0x0A, 0x0D, 0x0A)))) {
      # }
      break
    }

    field_size <- read_uint32(con)

    if (field_size > max_field_size) {
      stop("Field size too large", field_size)
    }

    field_data <- readBin(con, "raw", n = field_size)
    field_name <- field_type_names[[as.character(field_type)]]

    if (!is.null(field_name)) {
      known_fields[[field_name]] <- field_data
    } else {
      unknown_fields[[as.character(field_type)]] <- field_data
    }
  }

  list(
    version = c(major = major_version, minor = minor_version),
    known_fields = known_fields,
    unknown_fields = unknown_fields
  )
}

parse_variant_map <- function(raw_bytes, verbose = TRUE) {
  con <- rawConnection(raw_bytes, "rb")
  on.exit(close(con))

  read_uint8 <- function() readBin(con, "integer", size = 1, signed = FALSE)
  read_uint16 <- function()
    sum(as.integer(readBin(con, "raw", n = 2)) * 256^(0:1))
  read_uint32 <- function()
    sum(as.integer(readBin(con, "raw", n = 4)) * 256^(0:3))
  read_uint64 <- function()
    sum(
      as.numeric(readBin(con, "integer", size = 1, n = 8, signed = FALSE)) *
        256^(0:7)
    )
  read_int32 <- function() readBin(con, "integer", size = 4, signed = TRUE)
  read_int64 <- function()
    sum(as.integer(readBin(con, "raw", n = 8)) * 256^(0:7))
  read_bytes <- function(n) readBin(con, "raw", n = n)
  read_string <- function(n) rawToChar(read_bytes(n), multiple = FALSE)

  entries <- list()

  version <- read_uint16()
  if (bitwShiftR(version, 8) > 1) {
    stop(sprintf("Unsupported VariantMap version: 0x%X", version))
  }

  while (TRUE) {
    type <- read_uint8()
    if (type == 0x00) {
      break
    }

    key_len <- read_uint32()
    key_raw <- read_bytes(key_len)
    key <- rawToChar(key_raw, multiple = FALSE) # preserves nulls inside
    value_len <- read_uint32()

    value <- switch(
      as.character(type),
      "4" = {
        if (value_len != 4) stop("UInt32 size mismatch")
        read_uint32()
      },
      "5" = {
        if (value_len != 8) stop("UInt64 size mismatch")
        read_uint64()
      },
      "8" = {
        if (value_len != 1) stop("Bool size mismatch")
        read_uint8() != 0
      },
      "12" = {
        if (value_len != 4) stop("Int32 size mismatch")
        read_int32()
      },
      "13" = {
        if (value_len != 8) stop("Int64 size mismatch")
        read_int64()
      },
      "24" = read_string(value_len),
      "66" = read_bytes(value_len),
      {
        warning(sprintf("Unknown type: 0x%02X for key '%s'", type, key))
        read_bytes(value_len)
      }
    )

    entries[[key]] <- value
  }

  leftover <- length(raw_bytes) - seek(con, where = NA)
  if (leftover > 0)
    warning(sprintf("%d bytes not consumed in VariantMap", leftover))

  entries
}
