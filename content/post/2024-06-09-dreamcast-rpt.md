+++
date = "2024-06-09T16:46:00Z"
title = "A modern, universal, Dreamcast power supply"
description = "Adapting the Mean Well RPT-6003 power supply as a modern replacement for the Dreamcast"
+++

I have fond memories of playing the Dreamcast growing up, of many hours trying
to figure out *Ecco the Dolphin* in the days before ubiquitous home internet. A
few years ago I picked up a Dreamcast and installed an optical disc emulator
(ODE), and had a good time revisiting old games from my childhood. As a huge fan
of *Jet Set Radio Future* on the original Xbox, it was fun to play *Jet Grind
Radio* for the first time.

When I moved to the Netherlands I shipped over my consoles, including the
Dreamcast. Unlike most of my other consoles, the Dreamcast used an internal
power supply that was region-specific. As I had a North American console, it was
expecting 120V while the power system in the Netherlands is 240V.

For convenience I didn’t want the bulk of a step-down converter whenever and
wherever I wanted to play Dreamcast games. So I set out to replace the power
supply instead.

# Replacement Power Supplies

At first I looked at replacing the power supply with a SEGA OEM power supply for
the European region. Unfortunately, I was unable to find a power supply on its
own on eBay or the Dutch auction website Marktplaats, nor a “for parts”
Dreamcast. Most of my options were system bundles, which made this approach
uneconomical since I’d still need to replace the capacitors on the power supply.

I also looked at the [PicoDreamcast], which uses the PicoPSU and an external 12V
DC power brick. However, I wanted to avoid the extra bulk of an external power
brick. This also ruled out the similar [DreamPSU].

[PicoDreamcast]: https://github.com/chriz2600/PicoDreamcast
[DreamPSU]: https://handheldlegend.com/en-nl/products/dreampsu-power-supply-for-sega-dreamcast

# Mean Well RPT-6003

Discouraged by my options, I happened across 3DprintRC’s [/r/Dreamcast
post][first-post] discussing the near perfect fit of Mean Well’s RPT-6003 power
supply in the Dreamcast. This is a modern universal power supply designed by a
company well-known for making high quality power supplies, and it provides all
the voltages needed by the Dreamcast.

[first-post]: https://old.reddit.com/r/dreamcast/comments/fq0kax/mean_well_internal_dreamcast_universal_power/

3DprintRC later posted a [follow-up][second-post] showing the RPT-6003 being
used by cutting up the original power supply.  Unfortunately, my Dreamcast had a
different revision of the power supply which did not allow for such a clean cut.

[second-post]: https://old.reddit.com/r/dreamcast/comments/jcku13/clean_and_powerful_psu_for_the_dreamcast_by/


# Dreamcast RPT-6003

{{< figure src="/media/0d/7fd0804dd5d48764ac66e9a598c5601680b396d9ed50cbdfb4bbb37da4de47:800.jpg"
           link="/media/0d/7fd0804dd5d48764ac66e9a598c5601680b396d9ed50cbdfb4bbb37da4de47.jpg"
           title="A populated Dreamcast RPT board."
  >}}

{{< figure src="/media/80/b96f087b73c15b78d58aee4b8428a0fb65ac2ab5dd236bfcc5175db4e60836:800.jpg"
           link="/media/80/b96f087b73c15b78d58aee4b8428a0fb65ac2ab5dd236bfcc5175db4e60836.jpg"
           title="Dreamcast RPT installed alongside the RPT-6003 in a Dreamcast"
  >}}

I designed the [Dreamcast RPT], a small board that interfaces the RPT-6003 with
the Dreamcast’s AC connector and power button. In my design I focused on being
able to reuse many components already found on the OEM power supply, as well as
documenting widely available modern alternatives.[^1]

[Dreamcast RPT]: https://github.com/terinjokes/dreamcast-rpt

I had boards manufactured here in Europe with [AISLER] and they arrived a few
days later, looking great! It slotted into the Dreamcast case with no issue and
worked the first time. 🥳

[AISLER]: https://aisler.net

I’ve released the board as open hardware under the CERN-OHL-W 2.0 license. I
designed it in [Horizon EDA], an open source PCB design suite. I’d love to see
others take and adapt the project. If you do, let me know what you build!

[Horizon EDA]: (https://horizon-eda.org/)

[^1]: I’m still hoping to find a drop-in replacement for the AC connector. The
    connector interlocks with the case, which rules out most without a case
    modification.
