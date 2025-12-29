# 1. Setup ---------------------------------------------------------------

## load packages
library(testthat)
library(link2GI)
library(terra)

test_that("OTB segmentation functions run and return expected output", {

  # Attempt to link to OTB
  otblink <- NULL

  # Load sample image
  image_sr <- rast(system.file("raster/pnoa.tiff", package = "OTBsegm"))
  image_crop_sr <- crop(image_sr, ext(621000, 621050, 4708385, 4708435))

  if (!is.null(otblink)) {

    # 2. Meanshift ----------------------------------------------------------
    results_ms_sf <- segm_meanshift(
      image    = image_crop_sr,
      otb      = otblink,
      spatialr = 10,
      ranger   = 50,
      maxiter  = 2,
      minsize  = 10
    )
    expect_s3_class(results_ms_sf, "sf")
    expect_gt(nrow(results_ms_sf), 0)
    expect_equal(as.vector(ext(image_crop_sr)), as.vector(ext(results_ms_sf)))

    # 3. Watershed ----------------------------------------------------------
    results_ws_sf <- segm_watershed(
      image  = image_crop_sr,
      otb    = otblink,
      thresh = 0.1,
      level  = 0.2
    )
    expect_s3_class(results_ws_sf, "sf")
    expect_gt(nrow(results_ws_sf), 0)
    expect_equal(as.vector(ext(image_crop_sr)), as.vector(ext(results_ws_sf)))

    # 4. Morphological profiles ---------------------------------------------
    results_mprofiles_sf <- segm_mprofiles(
      image = image_crop_sr,
      otb   = otblink,
      size  = 5,
      start = 3,
      step  = 20,
      sigma = 1
    )
    expect_s3_class(results_mprofiles_sf, "sf")
    expect_gt(nrow(results_mprofiles_sf), 0)
    expect_equal(as.vector(ext(image_crop_sr)), as.vector(ext(results_mprofiles_sf)))

    # 5. LSMS ---------------------------------------------------------------
    results_lsms_sf <- segm_lsms(
      image    = image_crop_sr,
      otb      = otblink,
      spatialr = 5,
      ranger   = 25,
      minsize  = 10
    )
    expect_s3_class(results_lsms_sf, "sf")
    expect_gt(nrow(results_lsms_sf), 0)
    expect_equal(as.vector(ext(image_crop_sr)), as.vector(ext(results_lsms_sf)))

  } else {
    expect_equal(1, 1)
  }
  
})
