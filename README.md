
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rkeepass

<!-- badges: start -->

[![R-CMD-check](https://github.com/schochastics/rkeepass/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/schochastics/rkeepass/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

rkeepass reads [KeePass](https://keepass.info/) `.kdbx` database files
directly from R. It supports KDBX versions 3.x and 4.x with automatic
format detection. The heavy lifting is done by the Rust crate
[keepass-rs](https://github.com/sseemayer/keepass-rs).

## Installation

You can install the development version of rkeepass from
[GitHub](https://github.com/schochastics/rkeepass) with:

``` r
# install.packages("pak")
pak::pak("schochastics/rkeepass")
```

### System requirements

You need a working [Rust](https://www.rust-lang.org/tools/install)
toolchain (rustc \>= 1.67).

## Example

``` r
library(rkeepass)

# read a KeePass database with a master password
db <- kdbx_read(
  system.file("extdata", "example.kdbx", package = "rkeepass"),
  password = "test123"
)

db
#>                                   uuid    group_path         title
#> 1 a726a6c6-ab09-42d3-b4dc-cb3d8bfc6767          Root         Email
#> 2 0327251b-228f-4a09-8d82-f32d1c0f294b Root/Internet        GitHub
#> 3 6fb55b5d-a9cb-4ca0-8f5e-e1e31823bc58 Root/Internet StackOverflow
#> 4 911c251d-a49d-472b-b409-b75f5b25408c  Root/Banking        MyBank
#>           username     password                        url
#> 1 user@example.com emailpass123   https://mail.example.com
#> 2          devuser    ghpass456         https://github.com
#> 3          coder42    sopass789  https://stackoverflow.com
#> 4         john_doe  bankpass000 https://mybank.example.com
#>                   notes
#> 1      My email account
#> 2                      
#> 3       Programming Q&A
#> 4 Main checking account
```

The result is a plain data.frame. Each row is one entry, and the
`group_path` column preserves the folder structure of the database.

``` r
# filter by group
db[db$group_path == "Root/Internet", ]
#>                                   uuid    group_path         title username
#> 2 0327251b-228f-4a09-8d82-f32d1c0f294b Root/Internet        GitHub  devuser
#> 3 6fb55b5d-a9cb-4ca0-8f5e-e1e31823bc58 Root/Internet StackOverflow  coder42
#>    password                       url           notes
#> 2 ghpass456        https://github.com                
#> 3 sopass789 https://stackoverflow.com Programming Q&A
```

Key files can be used instead of (or in addition to) a password:

``` r
kdbx_read("my_database.kdbx", password = "secret", keyfile = "my.key")
```
