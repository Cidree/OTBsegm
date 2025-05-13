

#' Large-scale segmentation using Mean-Shift
#'
#' Applies the Mean-Shift segmentation algorithm to an image file
#' or a SpatRaster. Suitable for large images
#'
#' @param image path to raster, or SpatRaster
#' @param otb output of [link2GI::linkOTB()]
#' @param spatialr integer. Spatial radius of the neighborhood
#' @param ranger range radius defining the radius (expressed in radiometry unit)
#' in the multispectral space
#' @param minsize integer. Minimum size of a region (in pixel unit) in segmentation. Smaller
#' clusters will be merged to the neighboring cluster with the closest radiometry.
#' If set to 0 no pruning is done
#' @param tilesize integer. Size of the tiles during the tile-wise processing
#' @param mode processing mode, either 'vector' or 'raster'. See details
#' @param ram integer. Available memory for processing (in MB)
#'
#' @returns sf or SpatRaster
#' @export
#'
#' @details
#'
#' Mean-Shift is a region-based segmentation algorithm that groups pixels with
#' similar characteristics. It's a non-parametric clustering technique that groups
#' pixels based on spatial proximity and feature similarity (color, intensity). This
#' method is particularly effective for preserving edges and defailt while simplifying
#' textures in high-resolution images. Steps:
#'
#' 1. Initialization: Each pixel is treated as a point in a multi-dimensional space
#' (combining spatial and color features).
#' 2. Mean Shift Iterations: For each pixel, a search window moves toward the region
#' with the highest data density (local maxima) by calculating the mean of neighboring
#' pixels within the window.
#'
#' 3. Convergence: The process repeats until the movement of the window becomes
#' negligible, indicating convergence.
#'
#' 4. Label Assignment: Pixels that converge to the same mode (local maxima) are
#' grouped into the same region.
#'
#' The most important parameters are:
#'
#' * spatialr: defines the size of the neighborhood
#' * ranger: determines similarity in the feature space
#' * maxiter: limits the number of iterations for convergence
#' * thresh: defines the convergence criterion based on pixel movement
#'
#' The processing mode 'vector' will output a vector file, and process the input
#' image piecewise. This allows performing segmentation of very large images. IN
#' contrast, 'raster' mode will output a labeled raster, and it cannot handle
#' large data. If mode is 'raster', all the 'vector_*' arguments are ignored.
#'
#' @examples
#' \dontrun{
#' ## load packages
#' library(link2GI)
#' library(OTBsegm)
#' library(terra)
#'
#' ## load sample image
#' image_sr <- rast(system.file("raster/pnoa.tiff", package = "OTBsegm"))
#'
#' ## connect to OTB (change to your directory)
#' otblink <- link2GI::linkOTB(searchLocation = "C:/OTB/")
#'
#' ## apply segmentation
#' results_ms_sf <- segm_lsms(
#'     image = image_sr,
#'     otb   = otblink,
#'     spatialr = 5,
#'     ranger   = 25,
#'     minsize  = 10
#' )
#'
#' plotRGB(image_sr)
#' plot(st_geometry(results_ms_sf), add = TRUE)
#' }
segm_lsms <- function(image,
                      otb,
                      spatialr = 5L,
                      ranger   = 15,
                      minsize  = 100L,
                      tilesize = 500L,
                      mode     = "vector",
                      ram      = 256L
) {

    ## 0. Setup
    init_files <- list.files(".", pattern = "^file.*\\FINAL.tif$")

    ## 1. Prepare image
    if (inherits(image, "SpatRaster")) {
        image.path <- tempfile(fileext = ".tiff")
        terra::writeRaster(image, image.path)
    } else if (is.character(image)) {
        image.path <- image
    } else {
        cli::cli_abort("<image> in invalid format")
    }

    ## 2. Prepare algorithm
    cmd <- link2GI::parseOTBFunction(algo = "LargeScaleMeanShift", gili = otb)

    ## 3. Update parameters
    cmd$input_in  <- image.path
    cmd$spatialr  <- spatialr
    cmd$ranger    <- ranger
    cmd$minsize   <- minsize
    cmd$tilesizex <- tilesize
    cmd$tilesizey <- tilesize
    cmd$ram       <- ram

    ## 4. Vector or raster mode ?
    cmd$mode <- mode
    if (mode == "vector") {
        segm.out.path       <- tempfile(fileext = ".shp")
        cmd$mode.vector.out <- segm.out.path
    } else {
        segm.out.path       <- tempfile(fileext = ".tiff")
        cmd$mode.raster.out <- segm.out.path

    }

    ## 5. Run algorithm
    segm <- link2GI::runOTB(
        otbCmdList = cmd,
        gili       = otb
    )

    ## 6. Clean temp files
    final_files <- list.files(".", pattern = "^file.*\\FINAL.tif$")
    delete_files <- setdiff(final_files, init_files)
    invisible(file.remove(delete_files))

    ## Results
    return(segm)

}
