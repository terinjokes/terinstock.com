+++
date = "2022-05-31T16:16:16Z"
title = "HPSS-Disassembly Progress Report (May 2022)"
description = "Progress report on the beginning of the HPSS-Disassembly project."
+++

## Introduction

{{< figure src="/media/ce/00bb21b49f9f4f766b4c3444d6f679f230a38970fd6b136474e5679264cc4c.png" caption="Title screen of _Harry Potter and the Sorcerer's Stone_ for the Game Boy Color" >}}

A little over 20 years ago the first movie in the _Harry Potter_ series, _Harry
Potter and the Sorcerer's Stone_ in the United States, was released by Warner
Bros. I had been caught up in the Harry Potter mania and received the movie tie-in
Game Boy Color game as a Christmas gift. I recall playing it for a while, before
my attention returned to the other hype machine of 2001: the _Pokémon_ series. 

{{< figure src="/media/73/0524f0dccdee9e9fca1e241c9d76f1ef7837d40ed029b4841c64a6675d9de5:800.jpg" caption="_Harry Potter and the Sorcerer's Stone_ on PC. Image credit Federico Dossena." alt="Harry Potter, Ron Weasley, and Hermione Granger running through a Hogwarts hallway in the PC version." link="https://www.fdossena.com/?p=hp1/i.md" target="_blank" >}}

The PlayStation and PC versions of the tie-in game are 3D action-puzzle games
where you play as the titular Harry Potter as he navigates around Hogwarts, the
grounds, the Forbidden Forest, and a side quest to Diagon Alley. The PlayStation
version is where we get the low-poly meme Hagrid from.

{{< figure src="/media/ff/34b0288d7ba9a34ad693fbef6d358d5e1b573546c2f9dbec7952e10902c495.png" caption="Harry Potter fighting bats in a Final Fantasy-inspired battle system." >}}

The Game Boy Color version was completely different: a top-down Role Playing
Game in the style of classic _Final Fantasy_. While you still play as Harry
Potter, it follows the plot of the book much more faithfully than the 3D
counterparts. There are some changes to adapt into a game: spells are learned
for combat, items can be equipped for buffs, and wizard cards can be collected
and used for combat effects.

I had entirely forgotten about this game until YouTube channel
[Flandrew](https://www.youtube.com/channel/UC9i9MfllgUd2Z6gSEGK3Vaw) put out a
comparison of every version of _Harry Potter and the Philosopher's Stone_[^1],
jogging back a flood of forgotten memories.

Picking it up again, I was excited by how colorful, expansive, and smooth the
game felt, especially compared to Pokémon titles of the time. I decided I would
learn more about how the game ticked.

## Disassembly Beginnings

Disassembling Game Boy games isn't new; _Pokémon Red and Blue_ has been
[completely reverse engineered](https://github.com/pret/pokered) (this has
prompted projects disassembling the rest of the Pokémon series). Other classics,
such as [_Zelda: Link's Awakening
DX_](https://github.com/zladx/LADX-Disassembly), have also been in progress for
years.

I've [started a project](https://github.com/terinjokes/HPSS-Disassembly) to
disassemble _Harry Potter and the Sorcerer's Stone_ for the Game Boy Color. My
goal is to document the techniques used to develop Game Boy games during the
final years of the hardware lifecycle. I'm also planning on taking techniques
learned from this project forward towards disassembling the sequel, _Harry
Potter and the Chamber of Secrets_, which also holds the distinction of being
the last Game Boy Color game released in North America.[^2]

As I've never worked on disassembling a game before, I had to start from
scratch. Fortunately, the Game Boy homebrew development scene is quite active,
so modern tools are available to help get started.

### mgbdis, the disassembler

To begin understanding what's happening "behind the curtain" we need to turn the
binary code the Game Boy Color CPU executes back into assembly code.

Unfortunately, the labels and symbols are not preserved in the binary code, so
we'll never be able to reproduce the exact structure the original game
developers had for the game. However, we can use computers to make best guesses
as a starting point, and use logic and reason (and our own guesses) to craft a
structure back on top.

I used Matt Currie's [mgbdis](https://github.com/mattcurrie/mgbdis) disassembler
to begin this task. _Sorcerer's Stone_ is a 4 MiB game, so disassembling took a
while, but it ended up creating 256 files each representing 16 KiB of bankable
memory. I also attempted to use Matt's emulator, [Beaten Dying
Moon](https://mattcurrie.com/bdm/), to automate generating a symbol file to aid
in separating executing code from data like images, but it did not seem very
successful.

### RGBDS, the assembler and linker

![RGBDS logo](/media/96/3a82c9766776a2b8fcc77552b1f34d9f8a5befae96de65d1fec70f074510f9.png)

Once we have disassembled the game (even with our imperfect results) in order to
get back to a playable game again we'll need an assembler and linker.
Fortunately we have [RGBDS](https://rgbds.gbdev.io/), an open source toolchain
dating back to the 1990s.

RGBDS's assembler, [`rgbasm`](https://rgbds.gbdev.io/docs/v0.5.2/rgbasm.1),
takes the assembly files as inputs and turned them into object files. It's
likely down the road we'll have object files containing code that are logically
related to each other, but for now we assemble each bank into it's own object
file.

RGBDS's linker, [`rgblink`](https://rgbds.gbdev.io/docs/v0.5.2/rgblink.1),
collects the object files together and decides how to combine them together into
a Game Boy ROM. As the code is "fixed" in memory, the primary responsibility of
the linker in this project is to resolve symbol references across object files,
so the correct memory locations can be written into the ROM. As we cleanup the
assembly files, the linker will likely become more important.

RGBDS includes a header fixer,
[`rgbfix`](https://rgbds.gbdev.io/docs/v0.5.2/rgbfix.1), used to generate a
valid Game Boy header. The original hardware uses information in this header as
checksums, to setup compatibility modes, and to implement basic DRM with the
"Nintendo" logo. When the game was disassembled this header was partially
decoded as instructions, and partially as data. It was removed and replaced by
padding so `rgbfix` could be used instead. This allows for greater flexability
in generating debug builds later, as the tool can generate the correct checksums
later.

One other included tool is RGBDS's image converter,
[`rgbgfx`](https://rgbds.gbdev.io/docs/v0.5.2/rgbgfx.1). This is a tool for
storing graphics as PNGs instead of `2bpp`, an encoding more suitable for the
Game Boy's hardware. `mgbdis` did not separate the game's images into individual
files, so we won't be using it for now, but it will be indespensible later once
we've extracted the images.

The RGBDS project also documents [the object file
format](https://rgbds.gbdev.io/docs/v0.5.2/rgbds.5), allowing for project
specific tools to be written (if that proves to be necessary). Since _Sorcerer's
Stone_ is a JRPG, there is a lot of dialog, menus, and world building, resulting
in lots of text. The game also supports 11 different languages, farther
multiplying the amount of text. I suspect we might need tooling to easily handle
all of it.

### gup, the recursive build system

After disassembling a game, mgbdis generates a basic GNU Make-compatible
Makefile. This Makefile calls `rgbasm` over a single assembly file "game.asm"
that simply includes all the banks. For a small game this might work, but for a
large game like _Sorcerer's Stone_ re-assembling the entire game each rebuild
was actually taking a significant amount of time. It would be far better to only
reassemble the files that changed, and the targets that depend on that file.

I've switched the project to using [gup](https://github.com/timbertson/gup), a
recursive build system inspired by Daniel J. Bernstein's
[redo](https://cr.yp.to/redo.html). In gup, targets are executable scripts
written in any language, and they can discover and register their own
dependencies.

In HPSS-Disassembly, gup assembles banks by calling [a
script](https://github.com/terinjokes/HPSS-Disassembly/blob/7cf6b905052180b0f86adf24c4c9b4a2a5aca5b4/scripts/as)
that calls `rgbasm` and registers each file it lists as a dependency with gup.
When a file is changed, gup knows it only needs to rebuild banks that included
it the previous build. This makes the testing iteration cycle extremely fast.

## Disassembly Progress

I've written a lot of words here about the progress made on project
infrastructure. What have I actually accomplished on the disassembly side? Since
this is my first month working on the project, I'm afraid I haven't accomplished
too much.

### Ready? Let's Start

{{< figure src="/media/54/634c2d974d0a1fa20ac746942cee8e85844405b6032ed7cfb40456370043b9.png" caption="Error displayed when the game is inserted into a system not compatible with the Game Boy Color." >}}

As _Harry Potter and the Sorcerer's Stone_ is a Game Boy Color-only game, the
very first thing it does is check to see if it's running on a Game Boy
Color-compatible system. When it jumps to `Start` it compares the value left in
the `a` register by the system boot ROM to `$11`. If the zero flag is set, it
later jumps to code to show an error message.

```asm
Start::
    and a                       ; clear flags
    cp BOOTUP_A_CGB             ; is Game Boy Color?

    ld a, $00                   ; set a to 0
    jr nz, .notGBC              ; if not GBC:
    inc a                       ;   increment a (a=1)

.notGBC:
    ldh [$ef], a                ; save GBC value
    ld sp, $cfff                ; setup stack pointer
    ldh a, [$ef]
    or a
    call z, Unknown_Non_GBC     ; call if not GBC
```

As this code saves the GBC status into High RAM, instead of directly jumping to
code to display the error message, I wonder if at some point in development the
game was targetting compatibility with the earlier Game Boy systems.

### --floop-flatten

What do you do if you want quickly copy contiguous memory from multiple parts of
the game, but part of the game needs to copy a different number of bytes, and
you also want to keep the number of CPU cycles to a minimum? One approach taken
by the _Sorcerer's Stone_'s developers is to flatten the loop. You can call the
[same 3 instructions 32
times](https://github.com/terinjokes/HPSS-Disassembly/blob/dedcb131ea/src/bank_000.asm#L5980-L6168),
then call into the code at whatever point has the required number of iterations
remaining.

Fortunately, `rgbasm` is a macro assembler, allowing us to refactor this logic
to generate the assembly for us, while also generating more readable names.

```asm
FOR V, 32, 0, -1                ; loop from 32 to 0, decrementing each time
CopyHL2DE_{d:V}:                ; generate a label we can reference from other code
    ld a, [hl+]                 ; load the byte pointed to by hl into a,
                                ;     and also increment hl
    ld [de], a                  ; load a into the byte referenced by de
    inc de                      ; increment de
ENDR
```

This reduced over 200 lines of code into a much more manageable 6!

## What's Next

I've still have a lot of tasks ahead. Some immediate tasks to start working on:

* Begin extracting tiles into bitmaps, and convert and assemble on-the-fly
  during builds.
* Work on extracting text into forms that can be easier to work with, especially
  for translators.
* Label and comment even more code.

In [the first blog
post](https://kemenaran.winosx.com/posts/special-effects-in-zelda-links-awakening)
for disassembling _Zelda: Link's Awakening DX_, Pierre writes:

> Reverse-engineering assembly code is quite slow, but I'll try to post some
> findings on this blog.

The statement is just as true here as it was all those years ago. We'll see how
this goes!

[^1]: Flandrew must be from outside the United States of America.

[^2]: [According to
    Wikipedia](https://en.wikipedia.org/wiki/List_of_Game_Boy_Color_games) five
    games released after _Chamber of Secrets_ in other markets, 1 in Germany, 1
    in Korea, and 3 in Japan, including the last licensed game _Doraemon no
    Study Boy: Kanji Yomikaki Master_.
