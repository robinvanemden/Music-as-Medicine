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

from __future__ import print_function

import matplotlib.pyplot as plt

import pyspike as spk

import csv

def t(l):
    return [list(i) for i in zip(*l)]

spike_trains = spk.load_spike_trains_from_txt("../export/spikes.txt", edges=(0, 420))

plt.figure()

f = spk.spike_sync_profile(spike_trains[0], spike_trains[1])
x, y = f.get_plottable_data()
plt.plot(x, y, '--ok', label="SPIKE-SYNC profile")
#print(f.x)
#print(f.y)
#print(f.mp)

print("Average:", f.avrg())

with open('../export/spike_sync.csv', 'w') as fw:
    writer = csv.writer(fw)
    writer.writerows(zip(x, y))

f = spk.spike_profile(spike_trains[0], spike_trains[1])
x, y = f.get_plottable_data()

with open('../export/spike_profile.csv', 'w') as fw:
    writer = csv.writer(fw)
    writer.writerows(t([x, y]))

plt.plot(x, y, '-b', label="SPIKE-profile")

plt.axis([0, 420, -0.1, 1.1])
plt.legend(loc="center right")

plt.figure()
plt.figure(figsize=(8,5))

plt.subplot(211)

f = spk.spike_sync_profile(spike_trains)
x, y = f.get_plottable_data()

with open('../export/spike_sync_profile.csv', 'w') as fw:
    writer = csv.writer(fw)
    writer.writerows(t([x, y]))


plt.plot(x, y, '-b', alpha=0.7, label="SPIKE-Sync profile")

x1, y1 = f.get_plottable_data(averaging_window_size=50)
plt.plot(x1, y1, '-k', lw=2.5, label="averaged SPIKE-Sync profile")

with open('../export/spike_sync_averaged.csv', 'w') as fw:
    writer = csv.writer(fw)
    writer.writerows(t([x1, y1]))

plt.subplot(212)

f_psth = spk.psth(spike_trains, bin_size=50.0)
x, y = f_psth.get_plottable_data()
plt.plot(x, y, '-k', alpha=1.0, label="PSTH")


with open('../export/spike_sync_averaged_last.csv', 'w') as fw:
    writer = csv.writer(fw)
    writer.writerows(t([x, y]))

print("Average:", f.avrg())

plt.show()
