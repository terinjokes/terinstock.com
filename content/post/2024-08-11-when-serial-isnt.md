+++
date = "2024-08-11T18:35:11Z"
title = "When Serial Isn't RS-232, and Geocaching with the Garmin GPS 95"
description = "Connecting a Garmin GPS 95 to a Flipper Zero, the serial adventures along the way, and finding the Netherland's first Geocache."
[params]
  images = ["/media/76/bb71a42372de077a408a1f4ba6972a6870afe9fca186e9a748e730b1da560f:800.jpg"]
+++

{{< figure src="/media/76/bb71a42372de077a408a1f4ba6972a6870afe9fca186e9a748e730b1da560f:800.jpg"
           link="/media/76/bb71a42372de077a408a1f4ba6972a6870afe9fca186e9a748e730b1da560f.jpg"
           title="Found the first Dutch Geocache, Amsterdam Urban 1."
  >}}

Recently I picked up a box of early 1990s Garmin GPS receivers along with an
array of accessories. I cleaned up one receiver, a GPS 95, installed 4 new AA
batteries, and positioned it with a clear view of the sky. After an agonizing
long time searching for satellites it eventually received a full almanac and
made a GPS lock. It was pretty cool that it still works!

However there were two problems discovered while using the receiver. First,
while the longitude and latitude were accurate, the altitude was completely
wrong. Second, the receiver still thought it was in the 1990s. While the first
problem is inherent to GPS, we can fix the second issue!

The receiver has no control for changing the date or time: it relies almost
entirely on the GPS signal. Surely, the date being sent by GPS wasn't wrong. The
[GPSJAM] map did not show any interference anywhere near the Netherlands.

[GPSJAM]: https://gpsjam.org/?lat=48.11278&lon=4.65724&z=3.8&date=2024-08-08

{{< figure src="/media/b0/e6c1bd68a2caf3c05b0b90d2bf16217afb647275606757b9c8a929cbd10da6.png"
           link="https://gpsjam.org/?lat=48.11278&lon=4.65724&z=3.8&date=2024-08-08"
           title="No GPS jamming detected in the Netherlands."
  >}}

The "legacy" LNAV signal transmitted by GPS doesn't actually contain the date.
That is instead computed by the receiver based on two other signals transmitted:
a 10-bit week counter that is incremented once a week, and a 19-bit time of week
signal incremented every 1.5 seconds. This week counter rolls over every 1024
weeks (or approximately 19.6 years).[^1][^2] So a GPS receiver requires some
other way to know which week counter epoch to use.

[^1]: The week counter was expanded to 13-bits when using the newer CNAV signal, rolling over every 157 years.
[^2]: [GPS signals#Time](https://en.wikipedia.org/wiki/GPS_signals#Time)

The first GPS rollover occurred at midnight between 21-22 August 1999. This was
at the tail end of support for the GPS 95 receivers. Fortunately, Garmin
released a tool at the time "GPS EOW"[^3] that existed entirely to adjust the
time of the reciver's clock. This would allow the built-in logic to track the
date afterwards. The GPS 95 has now joined us in the 21st century.[^4]

[^3]: The most common version seems to be v1.20 ([local archive](https://share.terinstock.com/gpseow.zip)) ([Internet Archive](https://archive.org/details/GPSEOW))
[^4]: I've noticed the altitude is more accurate after the date was corrected, but I'm not sure why.

{{< figure src="/media/8e/5399a7f72c37eb9678edca573b1fd67c4640c023f4fb513d524c9ea1f3cd15:800.png"
           link="/media/8e/5399a7f72c37eb9678edca573b1fd67c4640c023f4fb513d524c9ea1f3cd15.png"
           title="GPS EOW, a very minimalist application for Windows 98."
  >}}

I started my Windows 98SE virtual machine[^5] and attached `/dev/ttyUSB0` as `COM1`
and started "GPS EOW". Except it complained that it couldn't communicate with
the receiver.

[^5]: The application should also work under WINE.

{{< figure src="/media/eb/8a5bd61d49f383e6418d71a2f3e88034fbfdc9cc59e52d1c973bab6c25ade7:800.png"
           link="/media/eb/8a5bd61d49f383e6418d71a2f3e88034fbfdc9cc59e52d1c973bab6c25ade7.png"
           title="GPS EOW was unable to connect to the GPS 95."
  >}}

After some fiddling, I switched to a different USB adapter and that worked
successfully.

Later, I wanted to try out [GPS for Flipper Zero], an application for the
Flipper Zero that decodes NMEA 0183 messages, with the GPS 95. I connected the
serial connection from the GPS receiver to the Flipper Zero as described, but
the application never saw any data.

[GPS for Flipper Zero]: https://github.com/ezod/flipperzero-gps

{{< figure src="/media/8e/a0b24c745855fa742127c21475a47a1712724a63b79c91794be33691ddc960.png"
           title="GPS for Flipper Zero reporting receiving no fix."
  >}}

Since I knew NMEA 0183 messages are ASCII, I switched to the [UART Terminal]
application. Instead of the expected NMEA, I saw complete gibberish.

[UART Terminal]: https://github.com/cool4uma/UART_Terminal

{{< figure src="/media/54/90d65f44728ae9331f37243dbee565d7b27c5ab4804b931c503b3f43161a70.png"
           title="The UART Terminal application displaying garbage."
  >}}

Those that have been around serial for a while are undoubtedly rushing to a
comment section to complain about the bone-headed move I just described. I may
have just destroyed the pins on my Flipper Zero. As we'll see in a bit, I lucked
out and did not.

The serial port on the PC platform uses RS-232, a loose standard going back to
the 1960s describing the electrical and timing of the signals, but not the
encoding of data. This is a bipolar signal ±25V where the data signal are
"inverted", that is a signal ≤-3V is a logical "1" and a signal ≥3V is a logical
"0". The range between -3V and 3V is undefined. The pins of a Flipper Zero are
at 3.3V, but is tolerant of signals up to 5V. If the GPS 95 was indeed sending
RS-232 levels that could have gone very wrong.

To better understand what was going on, I used the oscilloscope at the [Technologia Incognita][techinc] hackerspace. Fortunately, the GPS 95's serial was only going up to 5V, but also not using negative voltages at all. This reminded me of "TTL serial", the type of serial we use with microcontrollers and what the original USB serial adapter and the Flipper Zero expect. However, like the UART Terminal app, the UART decoder on the oscilloscope was also having difficulties decoding something useful from what should be NMEA.

{{< figure src="/media/6a/9d1f7bc0926653b4f1216ac01179165af246b704827860c6e44b2e99b4bc53:800.jpg"
           link="/media/6a/9d1f7bc0926653b4f1216ac01179165af246b704827860c6e44b2e99b4bc53.jpg"
           title="The Garmin GPS 95's serial data displayed on the Hantek DSO2D15 oscilloscope. Notice how it starts to decode randomly in the middle of the data; it has interpreted something else as the start bit."
  >}}

[techinc]: https://techinc.nl/

Besides the voltages used, there is another major difference between RS-232 and
"TTL serial". The latter signal is not inverted. Instead a zero level is a
logical "0", which a high level is a logical "1".

If you search online these are the two types of serial you'll see described
again and again. You might find the occasional reference to a third type that
was popular in the early 1990s. This serial type operates between 0-5V like "TTL
serial", but with inverted data lines like RS-232, allowing it to be connected
directly to a PC's serial port.[^6]

[^6]: While undefined in the RS-232 standard, most recievers on the PC platform considered zero voltage to be a logical "1", allowing this to work.

While I'm not aware of a name used at the time for this type of serial, this is
the type of serial used by the GPS 95. It is my understanding that portable
device manufacturers did not want to add an extra voltage rail just for the
serial port, but RS-232 drivers with integrated charge pumps weren't yet cheap
enough.

To be able to receive the NMEA data on my Flipper Zero I'd need to convert this
to "TTL serial"; that is invert the signal again so that a zero voltage is a
logical "0" and a positive voltage is a logical "1". I choose to use an
[SN74HC04N] inverter, a "jelly bean" part I already had on my bench from another
project.
    
[SN74HC04N]: https://www.ti.com/product/SN74HC04

{{< figure src="/media/8b/65caffbd262775a10597b016c60605c397a3bea785a024c94814bdfe7daa3b:800.jpg"
           link="/media/8b/65caffbd262775a10597b016c60605c397a3bea785a024c94814bdfe7daa3b.jpg"
           title="Flipper Zero connected to the Garmin GPS 95 through the inverter chip."
  >}}

With the circuit put together on a prototyping board, both the UART Terminal and
GPS for Flipper Zero applications worked correctly! Now I can connect the GPS 95
to any device expecting "TTL serial" without problems, which opens up some cool
ideas for future projects.

{{< figure src="/media/73/4570748a532dc30d6d46e39b2540b99ee55029aa99b2296d7b791686e1953c.png"
           title="The UART Terminal application with NMEA sentences."
  >}}
{{< figure src="/media/88/7d75fe32538ed79ada5432974b4d45f53fc82c6a6df938f5f6e857f1c6cb4c.png"
           title="GPS for Flipper Zero is able to decode the data too!"
  >}}
  
---

Today I set out to find the oldest hidden Geocache in the Netherlands,
[Amsterdam Urban 1][gc198]. While the Garmin GPS 95 is primarily for aviation,
complete with a database of airports, navigation waypoints, and frequencies last
updated in 1999, adding custom waypoints is well supported.

[gc198]: https://coord.info/GC198

{{< figure src="/media/cf/3a5340eec5ac9c617ba4d69dafffa05ee90098bb04355e30317fbce0c543c9:800.jpg"
           link="/media/cf/3a5340eec5ac9c617ba4d69dafffa05ee90098bb04355e30317fbce0c543c9.jpg"
           title="The GPS 95 navigating me across Vondelpark to the cache. Just about a quarter of a kilometer to go!"
  >}}
  
As the image at the top of this post shows, I was able to find the cache. Since
user waypoints can be synchronized with a PC, it would be interesting in the
future to write a program that can push a list of geocaches to the Garmin
GPS 95. I'll be typing them in manually in the meantime!
