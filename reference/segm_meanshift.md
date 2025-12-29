# Mean-Shift Segmentation

Applies the mean-shift segmentation algorithm to an image file or a
SpatRaster

## Usage

``` r
segm_meanshift(
  image,
  otb,
  spatialr = 5L,
  ranger = 15,
  thresh = 0.1,
  maxiter = 100L,
  minsize = 100L,
  mode = "vector",
  vector_neighbor = FALSE,
  vector_stitch = TRUE,
  vector_minsize = 1L,
  vector_simplify = 0.1,
  vector_tilesize = 1024L,
  mask = NULL
)
```

## Arguments

- image:

  path or `SpatRaster`

- otb:

  output of
  [`link2GI::linkOTB()`](https://r-spatial.github.io/link2GI/reference/linkOTB.html)

- spatialr:

  integer. Spatial radius of the neighborhood

- ranger:

  range radius defining the radius (expressed in radiometry unit) in the
  multispectral space

- thresh:

  algorithm iterative scheme will stop if mean-shift vector is below
  this threshold or if iteration number reached maximum number of
  iterations

- maxiter:

  integer. Algorithm iterative scheme will stop if convergence hasn’t
  been reached after the maximum number of iterations

- minsize:

  integer. Minimum size of a region (in pixel unit) in segmentation.
  Smaller clusters will be merged to the neighboring cluster with the
  closest radiometry. If set to 0 no pruning is done

- mode:

  processing mode, either 'vector' or 'raster'. See details

- vector_neighbor:

  logical. If FALSE (the default) a 4-neighborhood connectivity is
  activated. If TRUE, a 8-neighborhood connectivity is used

- vector_stitch:

  logical. If TRUE (the default), scans polygons on each side of tiles
  and stitch polygons which connect by more than one pixel

- vector_minsize:

  integer. Objects whose size in pixels is below the minimum object size
  will be ignored during vectorization

- vector_simplify:

  simplify polygons according to a given tolerance (in pixel). This
  option allows reducing the size of the output file or database.

- vector_tilesize:

  integer. User defined tiles size for tile-based segmentation. Optimal
  tile size is selected according to available RAM if NULL

- mask:

  an optional raster used for masking the segmentation. Only pixels
  whose mask is strictly positive will be segmented

## Value

`sf` or `SpatRaster`

## Details

Mean-Shift is a region-based segmentation algorithm that groups pixels
with similar characteristics. It's a non-parametric clustering technique
that groups pixels based on spatial proximity and feature similarity
(color, intensity). This method is particularly effective for preserving
edges and defailt while simplifying textures in high-resolution images.
Steps:

1.  Initialization: Each pixel is treated as a point in a
    multi-dimensional space (combining spatial and color features).

2.  Mean Shift Iterations: For each pixel, a search window moves toward
    the region with the highest data density (local maxima) by
    calculating the mean of neighboring pixels within the window.

3.  Convergence: The process repeats until the movement of the window
    becomes negligible, indicating convergence.

4.  Label Assignment: Pixels that converge to the same mode (local
    maxima) are grouped into the same region.

The most important parameters are:

- spatialr: defines the size of the neighborhood

- ranger: determines similarity in the feature space

- maxiter: limits the number of iterations for convergence

- thresh: defines the convergence criterion based on pixel movement

The processing mode 'vector' will output a vector file, and process the
input image piecewise. This allows performing segmentation of very large
images. IN contrast, 'raster' mode will output a labeled raster, and it
cannot handle large data. If mode is 'raster', all the 'vector\_\*'
arguments are ignored.

## Examples

``` r
if (FALSE) { # \dontrun{
## load packages
library(link2GI)
library(OTBsegm)
library(terra)

## load sample image
image_sr <- rast(system.file("raster/pnoa.tiff", package = "OTBsegm"))

## connect to OTB (change to your directory)
otblink <- link2GI::linkOTB(searchLocation = "C:/OTB/")

## apply segmentation
results_ms_sf <- segm_meanshift(
    image    = image_sr,
    otb      = otblink,
    spatialr = 5,
    ranger   = 25,
    maxiter  = 10,
    minsize  = 10
)
} # }
```
