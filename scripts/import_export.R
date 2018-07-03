##############################################################################################################
#
#       Project:     Music as Medicine, Pilot two
#       URL:         https://pavlov.tech/2018/06/29/syncing-bobbi-music-as-medicine/
#       Purpose:     First exploration of Music as Medicine ECG data
#       Date:        2018-07-03
#       Author:      Robin van Emden, http://pavlov.tech
#       Affiliation: Jheronimus Academy of Data Science, http://jads.nl
#
##############################################################################################################


# A first fast and frugal exploratory Bobbi MaM import/export script

library(here)
library(tuneR)
library(data.table)
library(signal)

source("qrs_detect.R")
source("peak_detect.R")
source("utils.R")

setwd(here::here("scripts"))


################################### import files #############################################################


# music was precut to between beeps with audacity - length: 0 to 4139.022 seconds
# here, we load resulting WAV between 17 to 24 minutes - that is, the first musical intermezzo

# load and plot music

music <- readWave("../music/music-as-medicine-cut-to-beeps.wav", from = 17, to = 24, units = "minutes")
plot(music)

# load ECG data

subject_list <- list()

files = list.files(path = "../ecg/", pattern="*.csv")
for (i in 1:length(files)) 

  # for now, we work with two data frames seperately 
  
  assign(paste0("subject_",i), fread(paste0("../ecg/",files[i]), sep=";"))

  # for future analyses:
  
  subject_list[[gsub("*.csv$", "", files[i])]] <- 
  fread(paste0("../ecg/",files[i]), sep=";")
  
# delete empty column

subject_2$V14 = NULL
subject_3$V14 = NULL

# add an index

subject_2$idx <- seq.int(nrow(subject_2))
subject_3$idx <- seq.int(nrow(subject_3))


################################### filter ecg ###############################################################


# invert polarity participant 3

subject_3$heartrate <- -1* subject_3$heartrate

# basic high pass filtering

highpass <- butter(2, 0.001, type="high")
subject_2$heartrate <- filter(highpass, x=subject_2$heartrate)
subject_3$heartrate <- filter(highpass, x=subject_3$heartrate)

# minimal low pass filtering

lowpass <- butter(2, 0.4, type="low")
subject_2$heartrate <- filter(lowpass, x=subject_2$heartrate)
subject_3$heartrate <- filter(lowpass, x=subject_3$heartrate)

subject_2 <- peak_detect_wavelet(subject_2, 10)
subject_3 <- peak_detect_wavelet(subject_3, 10)


################################### cut to beeps #############################################################


# find the start and end beeps

s2start = min(which(subject_2$mx > 4000))
s3start = min(which(subject_3$mx < -4000))
s3end = max(which(subject_3$mx > -1000))

# remove all past first and before last beeps

subject_2 <- subject_2[idx>=s2start]
subject_3 <- subject_3[idx>=s3start & idx<=s3end]

# start ms at zero

subject_2$ms <- subject_2$ms - subject_2$ms[1]
subject_3$ms <- subject_3$ms - subject_3$ms[1]

# add a "seconds" column

subject_2$seconds <- subject_2$ms/1000
subject_3$seconds <- subject_3$ms/1000


###################################  scale data to audio beeps ###############################################


# scale ECG data to *exactly* length of audio recording between beeps 
#
# nice and clean way:
#
# subject_2$seconds <- lin_map(subject_3$seconds, 0, max_audio)
# subject_3$seconds <- lin_map(subject_3$seconds, 0, max_audio)
#
# but for current analysis, we miss some data
# so here, we get a scale factor from s3 and apply to s3 and s2


# get max subject_3 

max_s3 <- max(subject_3$second)
max_audio <- 4139.022

# calculate scale factor

scale_factor <- max_audio/max_s3

# apply scale factor to both subjects

subject_3$seconds <- subject_3$seconds * scale_factor
subject_2$seconds <- subject_2$seconds * scale_factor


###################################  save between beeps ECG data #############################################


fwrite(subject_2[,c("seconds","heartrate")], "../export/subject_2_hr_between_beeps.csv")
fwrite(subject_3[,c("seconds","heartrate")], "../export/subject_3_hr_between_beeps.csv")
fwrite(subject_3[,c("seconds","mx")], "../export/subject_3_mx_between_beeps.csv")


###################################  plot first musical intermezzo ###########################################


start <- 17*1000*60  
end   <- 24*1000*60  

subject_2 <- subject_2[ms>start & ms<end]
subject_3 <- subject_3[ms>start & ms<end]

subject_2 <- qrs_detect(subject_2,120,30)
subject_3 <- qrs_detect(subject_3,120,30)

subject_2 <- delete_close_peaks(subject_2)
subject_3 <- delete_close_peaks(subject_3)

# set start ms and seconds to zero

subject_2$ms <- subject_2$ms - subject_2$ms[1]
subject_3$ms <- subject_3$ms - subject_3$ms[1]

subject_2$seconds <- subject_2$seconds - subject_2$seconds[1]
subject_3$seconds <- subject_3$seconds - subject_3$seconds[1]

# plot overview of HR and MX to check if all seems right

plot(subject_2$seconds/60, subject_2$mx, type = "l")
plot(subject_3$seconds/60, subject_3$mx, type = "l")

plot(subject_2$seconds/60, subject_2$heartrate, type = "l")
points(subject_2[is_peak == TRUE]$seconds/60,subject_2[is_peak == TRUE]$heartrate, col = "red")
plot(subject_3$seconds/60, subject_3$heartrate, type = "l")
points(subject_3[is_peak == TRUE]$seconds/60,subject_3[is_peak == TRUE]$heartrate, col = "red")


###################################  ECG close up plot #######################################################


start <- 2*1000*60
end   <- 2.3*1000*60

plot(subject_2[ms>start & ms<end]$seconds, subject_2[ms>start & ms<end]$heartrate, type = "l")
points(subject_2[ms>start & ms<end & is_peak == TRUE]$seconds,
       subject_2[ms>start & ms<end & is_peak == TRUE]$heartrate, col = "red")

plot(subject_3[ms>start & ms<end]$seconds, subject_3[ms>start & ms<end]$heartrate, type = "l")
points(subject_3[ms>start & ms<end & is_peak == TRUE]$seconds,
       subject_3[ms>start & ms<end & is_peak == TRUE]$heartrate, col = "red")


###################################  save first musical intermezzo ###########################################


fwrite(subject_2[,c("seconds","heartrate")], "../export/subject_2_hr_between_17_24.csv")
fwrite(subject_3[,c("seconds","heartrate")], "../export/subject_3_hr_between_17_24.csv")

fwrite(subject_2[is_peak==TRUE][,c("seconds","heartrate")], "../export/subject_2_peaks_between_17_24.csv")
fwrite(subject_3[is_peak==TRUE][,c("seconds","heartrate")], "../export/subject_3_peaks_between_17_24.csv")


###################################  PySpike export ##########################################################


s2 <- subject_2[is_peak == TRUE][, "seconds"]
s3 <- subject_3[is_peak == TRUE][, "seconds"]

spikes <- t(as.matrix (Cbind(s2,s3)))

write.table(spikes, file = "../export/spikes.txt", row.names = FALSE, col.names = FALSE, na = "")


