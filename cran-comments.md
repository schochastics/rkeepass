## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.
* checking compiled code ... NOTE: non-API calls to R ('BODY', 'CLOENV',
  'DATAPTR', 'ENCLOS', 'FORMALS'). These come from extendr-api 0.7 and need
  to be resolved by upgrading extendr before submission.
* The package uses Rust via 'extendr'. All Rust dependencies are vendored in
  `src/rust/vendor.tar.xz`, and the build runs offline. Cargo and rustc
  versions are reported during configure (`tools/msrv.R`).
