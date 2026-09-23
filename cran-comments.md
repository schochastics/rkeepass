## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.
* The package uses Rust via 'extendr'. All Rust dependencies are vendored in
  `src/rust/vendor.tar.xz`, and the build runs offline. Cargo and rustc
  versions are reported during configure (`tools/msrv.R`).
