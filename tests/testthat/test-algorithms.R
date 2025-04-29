

# 1. set up ---------------------------------------------------------------

## load packages
library(link2GI)
library(terra)

## load sample image
image_sr <- rast(system.file("raster/pnoa.tiff", package = "OTBsegm"))

## crop for short running test
image_crop_sr <- crop(image_sr, ext(621000, 621050, 4708385, 4708435))

## connect to OTB (change to your directory)
otblink <- link2GI::linkOTB(searchLocation = "C:/OTB/")

# 2. Test meanshift -------------------------------------------------------

## apply segmentation
results_ms_sf <- segm_meanshift(
    image    = image_crop_sr,
    otb      = otblink,
    spatialr = 10,
    ranger   = 50,
    maxiter  = 2,
    minsize  = 10
)


## test meanshift
test_that("Meanshift is sf", {
  expect_s3_class(results_ms_sf, "sf")
})

test_that("Meanshift has rows", {
    expect_gt(nrow(results_ms_sf), 0)
})

test_that("Meanshift has same extent as input", {
    expect_equal(
        as.vector(ext(image_crop_sr)),
        as.vector(ext(results_ms_sf))
    )
})

# 3. Test watershed -------------------------------------------------------

## apply segmentation
results_ws_sf <- segm_watershed(
    image  = image_crop_sr,
    otb    = otblink,
    thresh = .1,
    level  = .2
)


## test meanshift
test_that("Watershed is sf", {
    expect_s3_class(results_ws_sf, "sf")
})

test_that("Watershed has rows", {
    expect_gt(nrow(results_ws_sf), 0)
})

test_that("Watershed has same extent as input", {
    expect_equal(
        as.vector(ext(image_crop_sr)),
        as.vector(ext(results_ws_sf))
    )
})

# 4. Test mprofiles -------------------------------------------------------

## apply segmentation
results_mprofiles_sf <- segm_mprofiles(
    image = image_crop_sr,
    otb   = otblink,
    size  = 5,
    start = 3,
    step  = 20,
    sigma = 1
)


## test meanshift
test_that("Morphological profiles is sf", {
    expect_s3_class(results_mprofiles_sf, "sf")
})

test_that("Morphological profiles has rows", {
    expect_gt(nrow(results_mprofiles_sf), 0)
})

test_that("Morphological profiles has same extent as input", {
    expect_equal(
        as.vector(ext(image_crop_sr)),
        as.vector(ext(results_mprofiles_sf))
    )
})

# 5. Test LSMS ------------------------------------------------------------

## apply segmentation
results_lsms_sf <- segm_lsms(
    image = image_crop_sr,
    otb   = otblink,
    spatialr = 5,
    ranger   = 25,
    minsize  = 10
)


## test meanshift
test_that("LSMS is sf", {
    expect_s3_class(results_lsms_sf, "sf")
})

test_that("LSMS has rows", {
    expect_gt(nrow(results_lsms_sf), 0)
})

test_that("LSMS has same extent as input", {
    expect_equal(
        as.vector(ext(image_crop_sr)),
        as.vector(ext(results_lsms_sf))
    )
})
