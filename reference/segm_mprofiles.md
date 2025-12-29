# Morphological profiles segmentation

Applies the morphological profiles segmentation algorithm to an image
file or a SpatRaster

## Usage

``` r
segm_mprofiles(
  image,
  otb,
  size = 5L,
  start = 1L,
  step = 1L,
  sigma = 1,
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

- size:

  integer. Size of the profiles

- start:

  integer. Initial radius of the structuring element in pixels

- step:

  integer. Radius step in pixels along the profile

- sigma:

  profiles values under the threshold will be ignored

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

The morphological profiles segmentation algorithm is a region-based
image segmentation technique that applies a series of morphological
operations using structuring elements of increasing size to capture
spatial patterns and textures within the image. Steps:

1.  Morphological Filtering: The algorithm applies a sequence of
    openings (removing small bright structures) and closings (removing
    small dark structures) to the input image using structuring elements
    (e.g., disks, rectangles).

2.  Profile Generation: It generates a profile for each pixel by
    recording the response of the morphological operations at different
    scales.

3.  Feature Extraction: These profiles help capture both fine and coarse
    structures within the image, creating a set of features that can be
    used for classification or segmentation.

4.  Segmentation (Optional): The extracted profiles can be input into a
    classifier or segmentation algorithm to differentiate between
    regions with distinct spatial characteristics.

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
results_ms_sf <- segm_mprofiles(
    image = image_sr,
    otb   = otblink,
    size  = 5,
    start = 3,
    step  = 20,
    sigma = 1
)
} # }
```
