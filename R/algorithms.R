#' Mean-Shift Segmentation
#'
#' Applies the mean-shift segmentation algorithm to an image file
#' or a SpatRaster
#'
#' @param image path or `SpatRaster`
#' @param otb output of [link2GI::linkOTB()]
#' @param spatialr integer. Spatial radius of the neighborhood
#' @param ranger range radius defining the radius (expressed in radiometry unit)
#' in the multispectral space
#' @param thresh algorithm iterative scheme will stop if mean-shift vector is
#' below this threshold or if iteration number reached maximum number of iterations
#' @param maxiter integer. Algorithm iterative scheme will stop if convergence hasn’t been
#' reached after the maximum number of iterations
#' @param minsize integer. Minimum size of a region (in pixel unit) in segmentation. Smaller
#' clusters will be merged to the neighboring cluster with the closest radiometry.
#' If set to 0 no pruning is done
#' @param mode processing mode, either 'vector' or 'raster'. See details
#' @param vector_neighbor logical. If FALSE (the default) a 4-neighborhood connectivity
#' is activated. If TRUE, a 8-neighborhood connectivity is used
#' @param vector_stitch logical. If TRUE (the default), scans polygons on each side
#' of tiles and stitch polygons which connect by more than one pixel
#' @param vector_minsize integer. Objects whose size in pixels is below the minimum
#' object size will be ignored during vectorization
#' @param vector_simplify simplify polygons according to a given tolerance (in pixel).
#' This option allows reducing the size of the output file or database.
#' @param vector_tilesize integer. User defined tiles size for tile-based segmentation.
#' Optimal tile size is selected according to available RAM if NULL
#' @param mask an optional raster used for masking the segmentation. Only pixels
#' whose mask is strictly positive will be segmented
#'
#' @returns `sf` or `SpatRaster`
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
#' results_ms_sf <- segm_meanshift(
#'     image    = image_sr,
#'     otb      = otblink,
#'     spatialr = 5,
#'     ranger   = 25,
#'     maxiter  = 10,
#'     minsize  = 10
#' )
#' }
segm_meanshift <- function(image,
                           otb,
                           spatialr = 5L,
                           ranger   = 15,
                           thresh   = 0.1,
                           maxiter  = 100L,
                           minsize  = 100L,
                           mode            = "vector",
                           vector_neighbor = FALSE,
                           vector_stitch   = TRUE,
                           vector_minsize  = 1L,
                           vector_simplify = 0.1,
                           vector_tilesize = 1024L,
                           mask            = NULL

) {
    ## 0. Errors and checks
    spatialr        <- as.integer(round(spatialr))
    vector_minsize  <- as.integer(round(vector_minsize))
    vector_tilesize <- as.integer(round(vector_tilesize))

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
    cmd <- link2GI::parseOTBFunction(algo = "Segmentation", gili = otb)

    ## 3. Update parameters
    cmd$input_in                  <- image.path
    cmd$filter                    <- "meanshift"
    cmd$filter.meanshift.spatialr <- spatialr
    cmd$filter.meanshift.ranger   <- ranger
    cmd$filter.meanshift.thres    <- thresh
    cmd$filter.meanshift.maxiter  <- maxiter
    cmd$filter.meanshift.minsize  <- minsize

    ## 4. Vector or raster mode ?
    cmd$mode <- mode
    if (mode == "vector") {
        segm.out.path            <- tempfile(fileext = ".shp")
        cmd$mode.vector.out      <- segm.out.path
        cmd$mode.vector.inmask   <- mask
        cmd$mode.vector.neighbor <- tolower(vector_neighbor)
        cmd$mode.vector.stitch   <- tolower(vector_stitch)
        cmd$mode.vector.tilesize <- vector_tilesize
        cmd$mode.vector.minsize <- vector_minsize
        cmd$mode.vector.simplify <- vector_simplify
        if (inherits(mask, "SpatRaster")) {
            mask.path <- tempfile(fileext = ".tiff")
            terra::writeRaster(mask, mask.path)
            cmd$mode.vector.inmask   <- mask.path
        }
    } else {
        segm.out.path       <- tempfile(fileext = ".tiff")
        cmd$mode.raster.out <- segm.out.path

    }

    ## 5. Run algorithm
    segm <- link2GI::runOTB(
        otbCmdList = cmd,
        gili       = otb
    )

    ## Results
    return(segm)

}








# #' Connected components segmentation
# #'
# #' Applies the connected components segmentation algorithm to an image file
# #' or a SpatRaster
# #'
# #' @param image path or `SpatRaster`
# #' @param otb output of [link2GI::linkOTB()]
# #' @param expr user defined connection condition, written as a mathematical expression.
# #' Available variables are 'p(i)b(i)', 'intensity_p(i)', and 'distance'. Substitute
# #' (i) by the desired value (e.g. 'intensity_p2 Z 0.5')
# #' @param mode processing mode, either 'vector' or 'raster'. See details
# #' @param vector_neighbor logical. If FALSE (the default) a 4-neighborhood connectivity
# #' is activated. If TRUE, a 8-neighborhood connectivity is used
# #' @param vector_stitch logical. If TRUE (the default), scans polygons on each side
# #' of tiles and stitch polygons which connect by more than one pixel
# #' @param vector_minsize integer. Objects whose size in pixels is below the minimum
# #' object size will be ignored during vectorization
# #' @param vector_simplify simplify polygons according to a given tolerance (in pixel).
# #' This option allows reducing the size of the output file or database.
# #' @param vector_tilesize integer. User defined tiles size for tile-based segmentation.
# #' Optimal tile size is selected according to available RAM if NULL
# #' @param mask an optional raster used for masking the segmentation. Only pixels
# #' whose mask is strictly positive will be segmented
# #'
# #' @returns `sf` or `SpatRaster`
# #' @export
# #'
# #' @details
# #'
# #' The connected components segmentation algorithm groups neighboring pixels with
# #' similar properties into distinct labeled regions. This method works by identifying
# #' sets of adjacent pixels that share the same value or meet a prefined similarity
# #' criterion. Steps:
# #'
# #' 1. Initialization: Each pixel is analyzed to determine if it shares a connection
# #' (4- or 8-connectivity) with its neighbors based on intensity, color,
# #' or other attributes.
# #'
# #' 2. Grouping: Pixels connected by similarity form a region, and each region is
# #' assigned a unique label.
# #'
# #' 3. Label Propagation: The algorithm iterates over the image, assigning the same
# #' label to all connected pixels within a region.
# #'
# #' 4. Output: A segmented image is generated where each region has a unique identifier.
# #'
# #' The processing mode 'vector' will output a vector file, and process the input
# #' image piecewise. This allows performing segmentation of very large images. IN
# #' contrast, 'raster' mode will output a labeled raster, and it cannot handle
# #' large data. If mode is 'raster', all the 'vector_*' arguments are ignored.
# #'
# #' @examples
# #' \dontrun
# #' ## load packages
# #' library(link2GI)
# #' library(OTBsegm)
# #' library(terra)
# #'
# #' ## load sample image
# #' image_sr <- rast(system.file("raster/pnoa.tiff", package = "OTBsegm"))
# #'
# #' ## connect to OTB (change to your directory)
# #' otblink <- link2GI::linkOTB(searchLocation = "C:/OTB/")
# #'
# #' ## apply segmentation
# #' results_ms_sf <- segm_connected_components(
# #'     image = image_sr,
# #'     otb   = otblink,
# #'     expr  = "distance > 1"
# #' )
# #' }
# segm_connected_components <- function(image,
#                                       otb,
#                                       expr            = "distance > 10",
#                                       mode            = "vector",
#                                       vector_neighbor = FALSE,
#                                       vector_stitch   = TRUE,
#                                       vector_minsize  = 1L,
#                                       vector_simplify = 0.1,
#                                       vector_tilesize = 1024L,
#                                       mask            = NULL
#
# ) {
#     ## 0. Errors and checks
#     vector_minsize  <- as.integer(round(vector_minsize))
#     vector_tilesize <- as.integer(round(vector_tilesize))
#
#     ## 1. Prepare image
#     if (inherits(image, "SpatRaster")) {
#         image.path <- tempfile(fileext = ".tiff")
#         terra::writeRaster(image, image.path)
#     } else if (is.character(image)) {
#         image.path <- image
#     } else {
#         cli::cli_abort("<image> in invalid format")
#     }
#
#     ## 2. Prepare algorithm
#     cmd <- link2GI::parseOTBFunction(algo = "Segmentation", gili = otb)
#
#     ## 3. Update parameters
#     cmd$input_in       <- image.path
#     cmd$filter         <- "cc"
#     cmd$filter.cc.expr <- expr
#
#     ## 4. Vector or raster mode ?
#     cmd$mode <- mode
#     if (mode == "vector") {
#         segm.out.path            <- tempfile(fileext = ".shp")
#         cmd$mode.vector.out      <- segm.out.path
#         cmd$mode.vector.inmask   <- mask
#         cmd$mode.vector.neighbor <- tolower(vector_neighbor)
#         cmd$mode.vector.stitch   <- tolower(vector_stitch)
#         cmd$mode.vector.minsize  <- vector_minsize
#         cmd$mode.vector.tilesize  <- vector_tilesize
#         cmd$mode.vector.simplify <- vector_simplify
#     } else {
#         segm.out.path       <- tempfile(fileext = ".tiff")
#         cmd$mode.raster.out <- segm.out.path
#
#     }
#
#     ## 5. Run algorithm
#     segm <- link2GI::runOTB(
#         otbCmdList = cmd,
#         gili       = otb
#     )
#
#     ## Results
#     return(segm)
#
# }


#' Watershed segmentation
#'
#' Applies the watershed segmentation algorithm to an image file
#' or a SpatRaster
#'
#' @param image path or `SpatRaster`
#' @param otb output of [link2GI::linkOTB()]
#' @param thresh depth threshold units in percentage of the maximum depth in the image
#' @param level flood level for generating the merge tree from the initial segmentation
#' (from 0 to 1)
#' @param mode processing mode, either 'vector' or 'raster'. See details
#' @param vector_neighbor logical. If FALSE (the default) a 4-neighborhood connectivity
#' is activated. If TRUE, a 8-neighborhood connectivity is used
#' @param vector_stitch logical. If TRUE (the default), scans polygons on each side
#' of tiles and stitch polygons which connect by more than one pixel
#' @param vector_minsize integer. Objects whose size in pixels is below the minimum
#' object size will be ignored during vectorization
#' @param vector_simplify simplify polygons according to a given tolerance (in pixel).
#' This option allows reducing the size of the output file or database.
#' @param vector_tilesize integer. User defined tiles size for tile-based segmentation.
#' Optimal tile size is selected according to available RAM if NULL
#' @param mask an optional raster used for masking the segmentation. Only pixels
#' whose mask is strictly positive will be segmented
#'
#' @returns `sf` or `SpatRaster`
#' @export
#'
#' @details
#'
#' The watershed segmentation algorithm is a region-based image segmentation
#' technique inspired by topography. It treats the grayscale intensity of an image
#' as a topographic surface, where brighter pixels represent peaks and darker pixels
#' represent valleys. The algorithm simulates flooding of this surface to separate
#' distinct regions. Steps:
#'
#' 1. Topographic Interpretation: The input image is treated as a 3D landscape,
#' where pixel intensity corresponds to elevation.
#' 2. Flooding Process: Starting from local minima, the algorithm simulates water
#' flooding the surface. As the water rises, distinct regions (basins) are formed.
#' 3. Watershed Lines: When two basins meet, a boundary (watershed line) is formed
#' to prevent merging.
#' 4. Region Labeling: Each basin is assigned a unique label, producing a segmented
#' image where boundaries are clearly defined.
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
#' results_ms_sf <- segm_watershed(
#'     image  = image_sr,
#'     otb    = otblink,
#'     thresh = .1,
#'     level  = .2
#' )
#' }
segm_watershed <- function(image,
                           otb,
                           thresh          = 0.01,
                           level           = 0.1,
                           mode            = "vector",
                           vector_neighbor = FALSE,
                           vector_stitch   = TRUE,
                           vector_minsize  = 1L,
                           vector_simplify = 0.1,
                           vector_tilesize = 1024L,
                           mask            = NULL

) {

    ## 0. Manage errors
    if (level < 0 | level > 1) cli::cli_abort("<level> must be between 0 and 1")
    vector_minsize  <- as.integer(round(vector_minsize))
    vector_tilesize <- as.integer(round(vector_tilesize))

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
    cmd <- link2GI::parseOTBFunction(algo = "Segmentation", gili = otb)

    ## 3. Update parameters
    cmd$input_in       <- image.path
    cmd$filter         <- "watershed"
    cmd$filter.watershed.threshold <- thresh
    cmd$filter.watershed.level     <- level

    ## 4. Vector or raster mode ?
    cmd$mode <- mode
    if (mode == "vector") {
        segm.out.path            <- tempfile(fileext = ".shp")
        cmd$mode.vector.out      <- segm.out.path
        cmd$mode.vector.inmask   <- mask
        cmd$mode.vector.neighbor <- tolower(vector_neighbor)
        cmd$mode.vector.stitch   <- tolower(vector_stitch)
        cmd$mode.vector.minsize  <- vector_minsize
        cmd$mode.vector.tilesize  <- vector_tilesize
        cmd$mode.vector.simplify <- vector_simplify
        if (inherits(mask, "SpatRaster")) {
            mask.path <- tempfile(fileext = ".tiff")
            terra::writeRaster(mask, mask.path)
            cmd$mode.vector.inmask   <- mask.path
        }
    } else {
        segm.out.path       <- tempfile(fileext = ".tiff")
        cmd$mode.raster.out <- segm.out.path

    }

    ## 5. Run algorithm
    segm <- link2GI::runOTB(
        otbCmdList = cmd,
        gili       = otb
    )

    ## Results
    return(segm)

}




#' Morphological profiles segmentation
#'
#' Applies the morphological profiles segmentation algorithm to an image file
#' or a SpatRaster
#'
#' @param image path or `SpatRaster`
#' @param otb output of [link2GI::linkOTB()]
#' @param size integer. Size of the profiles
#' @param start integer. Initial radius of the structuring element in pixels
#' @param step integer. Radius step in pixels along the profile
#' @param sigma profiles values under the threshold will be ignored
#' @param mode processing mode, either 'vector' or 'raster'. See details
#' @param vector_neighbor logical. If FALSE (the default) a 4-neighborhood connectivity
#' is activated. If TRUE, a 8-neighborhood connectivity is used
#' @param vector_stitch logical. If TRUE (the default), scans polygons on each side
#' of tiles and stitch polygons which connect by more than one pixel
#' @param vector_minsize integer. Objects whose size in pixels is below the minimum
#' object size will be ignored during vectorization
#' @param vector_simplify simplify polygons according to a given tolerance (in pixel).
#' This option allows reducing the size of the output file or database.
#' @param vector_tilesize integer. User defined tiles size for tile-based segmentation.
#' Optimal tile size is selected according to available RAM if NULL
#' @param mask an optional raster used for masking the segmentation. Only pixels
#' whose mask is strictly positive will be segmented
#'
#' @returns `sf` or `SpatRaster`
#' @export
#'
#' @details
#'
#' The morphological profiles segmentation algorithm is a region-based image segmentation
#' technique that applies a series of morphological operations using structuring
#' elements of increasing size to capture spatial patterns and textures within
#' the image. Steps:
#'
#' 1. Morphological Filtering: The algorithm applies a sequence of openings
#' (removing small bright structures) and closings (removing small dark structures)
#' to the input image using structuring elements (e.g., disks, rectangles).
#'
#' 2. Profile Generation: It generates a profile for each pixel by recording the
#' response of the morphological operations at different scales.
#'
#' 3. Feature Extraction: These profiles help capture both fine and coarse
#' structures within the image, creating a set of features that can be used for
#' classification or segmentation.
#'
#' 4. Segmentation (Optional): The extracted profiles can be input into a classifier
#' or segmentation algorithm to differentiate between regions with distinct spatial
#' characteristics.
#'
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
#' results_ms_sf <- segm_mprofiles(
#'     image = image_sr,
#'     otb   = otblink,
#'     size  = 5,
#'     start = 3,
#'     step  = 20,
#'     sigma = 1
#' )
#' }
segm_mprofiles <- function(image,
                           otb,
                           size   = 5L,
                           start  = 1L,
                           step   = 1L,
                           sigma  = 1,
                           mode            = "vector",
                           vector_neighbor = FALSE,
                           vector_stitch   = TRUE,
                           vector_minsize  = 1L,
                           vector_simplify = 0.1,
                           vector_tilesize = 1024L,
                           mask            = NULL

) {

    ## 0. Manage errors

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
    cmd <- link2GI::parseOTBFunction(algo = "Segmentation", gili = otb)

    ## 3. Update parameters
    cmd$input_in       <- image.path
    cmd$filter         <- "mprofiles"
    cmd$filter.mprofiles.size  <- size
    cmd$filter.mprofiles.start <- start
    cmd$filter.mprofiles.sigma <- sigma
    cmd$filter.mprofiles.step  <- step

    ## 4. Vector or raster mode ?
    cmd$mode <- mode
    if (mode == "vector") {
        segm.out.path            <- tempfile(fileext = ".shp")
        cmd$mode.vector.out      <- segm.out.path
        cmd$mode.vector.inmask   <- mask
        cmd$mode.vector.neighbor <- tolower(vector_neighbor)
        cmd$mode.vector.stitch   <- tolower(vector_stitch)
        cmd$mode.vector.minsize  <- vector_minsize
        cmd$mode.vector.tilesize  <- vector_tilesize
        cmd$mode.vector.simplify <- vector_simplify
        if (inherits(mask, "SpatRaster")) {
            mask.path <- tempfile(fileext = ".tiff")
            terra::writeRaster(mask, mask.path)
            cmd$mode.vector.inmask   <- mask.path
        }
    } else {
        segm.out.path       <- tempfile(fileext = ".tiff")
        cmd$mode.raster.out <- segm.out.path

    }

    ## 5. Run algorithm
    segm <- link2GI::runOTB(
        otbCmdList = cmd,
        gili       = otb
    )

    ## Results
    return(segm)

}
