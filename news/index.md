# Changelog

## OTBsegm 0.1.1

Solve CRAN errors tests on Linux.

### BUG FIXES

- Mask wasn’t properly used in
  [`segm_meanshift()`](https://cidree.github.io/OTBsegm/reference/segm_meanshift.md),
  [`segm_watershed()`](https://cidree.github.io/OTBsegm/reference/segm_watershed.md),
  and
  [`segm_mprofiles()`](https://cidree.github.io/OTBsegm/reference/segm_mprofiles.md)

- Removed `mask` argument from
  [`segm_lsms()`](https://cidree.github.io/OTBsegm/reference/segm_lsms.md)
  since this function doesn’t support it

## OTBsegm 0.1.0

CRAN release: 2025-05-06

- Initial CRAN submission.
