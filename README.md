
<!-- README.md is generated from README.Rmd. Please edit that file -->

# OTBsegm

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/OTBsegm)](https://CRAN.R-project.org/package=OTBsegm)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Codecov test
coverage](https://codecov.io/gh/Cidree/OTBsegm/graph/badge.svg)](https://app.codecov.io/gh/Cidree/OTBsegm)
[![License: GPL
v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

**OTBsegm** is an R package that provides a user-friendly interface to
the unsupervised image segmentation algorithms available in [Orfeo
ToolBox (OTB)](https://www.orfeo-toolbox.org/), a powerful open-source
library for remote sensing image processing. **OTBsegm** is built on top
of [`link2GI`](https://r-spatial.github.io/link2GI/) R package,
providing easy access to image segmentation algorithms.

To use {`OTBsegm`}, you must first install OTB on your machine. Once OTB
is installed and properly linked through {`link2GI`} (see examples),
this package allows you to easily integrate OTB’s segmentation
algorithms into your workflows.

## Installation

You can install the development version of OTBsegm from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("Cidree/OTBsegm")
```

## Example

We will see how to segment an image included in the package:

``` r
## load packages
library(link2GI)
library(OTBsegm)
library(terra)
#> Warning: package 'terra' was built under R version 4.4.3
#> terra 1.8.29

## load image
image_sr <- rast(system.file("raster/pnoa.tiff", package = "OTBsegm"))

## visualize
plotRGB(image_sr)
```

<img src="man/figures/README-unnamed-chunk-2-1.png" width="100%" />

The image is a 500x500 meters RGB tile, with a spatial resolution of 15
cm in Galicia, Spain. The meanshift algorithm has the next important
arguments:

- **spatialr**: spatial radius of the neighborhood

- **ranger**: range radius defining the radius (expressed in radiometry
  unit) in the multispectral space

- **minsize**: minimum size of a region (in pixel unit) in segmentation.
  Smaller clusters will be merged to the neighboring cluster with the
  closest radiometry. If set to 0 no pruning is done.

In order to use the algorithms, we need to link our OTB installation
using {`link2GI`}:

``` r
otblink <- link2GI::linkOTB(searchLocation = "C:/OTB/")
```

Once we are connected, we can apply the segmentation algorithm and
visualize the results:

``` r
results_ms_sf <- segm_meanshift(
    image    = image_sr,
    otb      =  otblink,
    spatialr = 5,
    ranger   = 40,
    minsize  = 100L
)
#> Reading layer `file72281844ebe' from data source 
#>   `C:\Users\User\AppData\Local\Temp\RtmpEPZgGK\file72281844ebe.shp' 
#>   using driver `ESRI Shapefile'
#> Simple feature collection with 6947 features and 1 field
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 608000 ymin: 4713000 xmax: 608500 ymax: 4713500
#> Projected CRS: ETRS89 / UTM zone 29N
```

``` r
plotRGB(image_sr)
plot(sf::st_geometry(results_ms_sf), add = TRUE)
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />
