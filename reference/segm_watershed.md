# Watershed segmentation

Applies the watershed segmentation algorithm to an image file or a
SpatRaster

## Usage

``` r
segm_watershed(
  image,
  otb,
  thresh = 0.01,
  level = 0.1,
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

- thresh:

  depth threshold units in percentage of the maximum depth in the image

- level:

  flood level for generating the merge tree from the initial
  segmentation (from 0 to 1)

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

The watershed segmentation algorithm is a region-based image
segmentation technique inspired by topography. It treats the grayscale
intensity of an image as a topographic surface, where brighter pixels
represent peaks and darker pixels represent valleys. The algorithm
simulates flooding of this surface to separate distinct regions. Steps:

1.  Topographic Interpretation: The input image is treated as a 3D
    landscape, where pixel intensity corresponds to elevation.

2.  Flooding Process: Starting from local minima, the algorithm
    simulates water flooding the surface. As the water rises, distinct
    regions (basins) are formed.

3.  Watershed Lines: When two basins meet, a boundary (watershed line)
    is formed to prevent merging.

4.  Region Labeling: Each basin is assigned a unique label, producing a
    segmented image where boundaries are clearly defined.

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
results_ms_sf <- segm_watershed(
    image  = image_sr,
    otb    = otblink,
    thresh = .1,
    level  = .2
)
} # }
```
