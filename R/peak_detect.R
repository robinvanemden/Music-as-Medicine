library(wavelets)

peak_detect_wavelet <- function(df, thr = 12) {
  # 4-level decomposition is used with the Daubechie d4 wavelet.
  wavelet <- "d4"
  level <- 4L
  
  X <- as.numeric(df$heartrate)
  
  ecg_wav <-
    dwt(
      X,
      filter = wavelet,
      n.levels = level,
      boundary = "periodic",
      fast = TRUE
    )
  
  # Coefficients of the second level of decomposition are used for R peak detection.
  x <- ecg_wav@W$W2
  
  # Empty vector for detected R peaks
  R <- matrix(0, 1, length(x))
  
  # While loop for sweeping the L2 coeffs for local maxima.
  i <- 2
  while (i < length(x) - 1) {
    if ((x[i] - x[i - 1] >= 0) && (x[i + 1] - x[i] < 0) && x[i] > thr) {
      R[i] <- i
    }
    i <- i + 1
  }
  
  # Clear all zero values from R vector.
  R <- R[R != 0]
  Rtrue <- R * 4
  
  # Checking results on the original signal
  for (k in 1:length(Rtrue)) {
    if (Rtrue[k] > 10) {
      Rtrue[k] <-
        Rtrue[k] - 10 + (which.max(X[(Rtrue[k] - 10):(Rtrue[k] + 10)])) - 1
    } else {
      Rtrue[k] <- which.max(X[1:(Rtrue[k] + 10)])
    }
  }
  
  Rtrue <- unique(Rtrue)
  Rtrue_idx <- df$idx[Rtrue]
  
  # add peaks to df
  df$is_peak <- data.frame(df$idx %in% Rtrue_idx)
  
  df
}

delete_close_peaks <- function(df) {
  last_peak_time <- 0
  df <- df[order(-is_peak)]
  for (i in 1:dim(df)[1]) {
    if (df[i]$is_peak== TRUE) {
      peak_distance <- df[i]$ms -last_peak_time
      last_peak_time <- df[i]$ms
      if (peak_distance < 200){
        df[i]$is_peak <- FALSE
      }
    } else {
      df <- df[order(ms)]
      break
    }
  }
  df
}
