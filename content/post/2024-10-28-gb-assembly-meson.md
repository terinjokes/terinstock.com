+++
date = "2024-10-28T02:31:00Z"
lastmod = "2024-10-29T12:46:46Z"
title = "Assembling a Game Boy Game with Meson"
description = "Adding a new 'language' to the Meson build system for RGBDS."
[params]
  images = ["/media/52/1726b132b398a4215c6b7a75f6d5e1226da4a3b7817414768800533764ada6.png"]
+++

I've been working on a Game Boy game off-and-on for the last few months (hopefully more details about this soon!). Up until recently I was building the game with GNU Make, but I was frustrated with configuring Make's prerequisites for accurate dependency tracking. Often I'd change a file included by my target, but Make wasn't rebuilding appropriately.

I started looking at other build systems to solve this problem. I really liked how approachable [Meson][meson]'s build rules where, and also that it supported projects composed of multiple languages. This is useful to me as parts of my toolchain for handling assets, and converting them to a format usable on the Game Boy, are written in higher level languages. If I change the code of part of that toolchain, the build system knows what assets need to processed and what parts of the game need to be relinked, automatically.

[meson]: https://mesonbuild.com/

There's just one problem: Meson doesn't support the Game Boy. However, that's never stopped me before!

{{< figure src="/media/52/1726b132b398a4215c6b7a75f6d5e1226da4a3b7817414768800533764ada6.png"
           link="/media/52/1726b132b398a4215c6b7a75f6d5e1226da4a3b7817414768800533764ada6.png"
           title="Technology is incredible!"
  >}}

I've created [a fork][meson-fork] of Meson that adds support for using [RGBDS][] to assemble and link Game Boy games. This was surprisingly easy to do, which is a testament for both the Meson and RGBDS projects. In Meson I added a new "language" `rgbds` which sets up `rgbasm` as the compiler/assembler and `rgblink` as the linker. A ROM can be built just by calling the `executable` function.

[meson-fork]: https://github.com/terinjokes/meson/commit/722c207c31148c5ff7e6b382548c972d1ff1a3f4
[RGBDS]: https://rgbds.gbdev.io/

```meson
project('rgbds-test', 'rgbds')

executable('rgbdstest.gb', 'src/main.asm',
           include_directories: ['include'],
           link_language: 'rgbds')
```

Then Meson can be initialized to assemble to the Game Boy's CPU and the game built.[^1] You can notice that Meson configures `rgbasm` to output dependency tracking metadata, which `ninja` uses for fast rebuilds.

[^1]: While this is the technically correct thing to do, it seems a bit much here as the only system RGBDS can compile to is the Sharp SM8320.

```console
$ ../../../meson.py setup --cross-file crossfile.ini --wipe build
The Meson build system
Version: 1.6.0
Source dir: /home/terin/Development/github.com/mesonbuild/meson/test cases/rgbds/1 basic
Build dir: /home/terin/Development/github.com/mesonbuild/meson/test cases/rgbds/1 basic/build
Build type: cross build
Project name: rgbds-test
Project version: undefined
Rgbds compiler for the host machine: rgbasm (rgbds 0.8.0)
Rgbds linker for the host machine: rgblink rgblink 0.8.0
Compiler for language rgbds for the build machine not found.
Build machine cpu family: x86_64
Build machine cpu: x86_64
Host machine cpu family: sm83
Host machine cpu: sm8320
Target machine cpu family: sm83
Target machine cpu: sm8320
Build targets in project: 1

rgbds-test undefined

  User defined options
    Cross files: crossfile.ini

Found ninja-1.12.1 at /usr/bin/ninja

$ ninja -C build -v
ninja: Entering directory `build'
[1/2] rgbasm -I../include -I.. -I. -Irgbdstest.gb.p -M rgbdstest.gb.p/src_main.asm.o.d -MQ rgbdstest.gb.p/src_main.asm.o -o rgbdstest.gb.p/src_main.asm.o ../src/main.asm
[2/2] rgblink  -o rgbdstest.gb rgbdstest.gb.p/src_main.asm.o

$ ninja -C build -t deps
rgbdstest.gb.p/src_main.asm.o: #deps 2, deps mtime 1730079958938870943 (VALID)
    ../src/main.asm
    ../include/hardware.inc
```

Game Boy ROM files have a header that needs to be set correctly so real hardware will play the cartridge, and emulators know what cartridge type to emulate. Since this header contains two checksums, usually it's configured using the `rgbfix` tool rather than being hardcoded in assembly. Unfortunately, I haven't figured out a good way for `executable` to automatically call this tool with the correct parameters after the rom is linked, but the tool can be invoked as a `custom_target`.

```meson
project('rgbds-test', 'rgbds')

rgbfix = find_program('rgbfix', required: true)

rom = executable('rgbdstest', 'src/main.asm',
                 include_directories: ['include'],
                 link_language: 'rgbds')

custom_target(output: 'rgbdstest.gb',
              input: rom,
              command: [
                rgbfix,
                '--title', 'EXAMPLE',
                '--old-licensee', '0x33',
                '--mbc-type', 'ROM',
                '--rom-version', '0',
                '--non-japanese',
                '--validate',
                '-',
              ],
              build_by_default: true,
              capture: true,
              feed: true)
```

This example also showcases using `custom_target` to interact with tools that need to be "feed" via stdin and where the results need to be "captured" on stdout, which is convenient as otherwise `rgbfix` edits the file in-place, which could cause issues later.

Since I'm not ready to release my game just yet, I've [modified pokered][pokered-fork] to use my fork of Meson. This builds the two image converters written in C, converts all the images to a format suitable for the Game Boy, and assembles and links with RGBDS. The resulting game matches the expected checksum.[^2]

[pokered-fork]: https://github.com/terinjokes/pokered/commit/3a2da2b7a9c738f3dfca144f2d12c1a9bcd1abba
[^2]: Adding support for compiling Pokémon Blue, as well as the debug and Virtual Console patches, have been left as an exercise for the reader.

```console
$ ninja -C build
ninja: Entering directory `build'
[1374/1374] Generating pokered.gbc with a custom command (wrapped by meson to capture output, to feed input)

$ shasum -c --ignore-missing ../roms.sha1
pokered.gbc: OK

$ jollygood -c sameboy build/pokered.gbc
i: Core: sameboy (SameBoy 0.16.5)
i: Video: OpenGL OpenGL ES 3.2 Mesa 24.1.7
i: Audio: 48000Hz Stereo, Speex 3
i: Emulated Input 1: gameboy1, Game Boy, 0 axes, 10 buttons
```

{{< figure src="/media/6e/e4eccf81b849f74b73eaf137948fa65269363a98bcb51d41ee1828c45b6ea45.png"
           link="/media/6e/e4eccf81b849f74b73eaf137948fa65269363a98bcb51d41ee1828c45b6ea45.png"
           title="Pokémon Red's start screen"
  >}}

I'll be submitting these changes to the upstream Meson project, in the off chance they're fans of the Game Boy.

---
*Edit 29 Oct:* I've [opened a PR][open-pr] to submit my changes to upstream Meson.

Meson has a concept of module, which are in-tree extensions to the core language to help handle common build tasks with large libraries, such as [compiling moc files][compiling-moc] in Qt projects. I've created a "rgbds" module which has a function run `rgbfix` to patch the ROM header, instead of needing to implement the above `custom_target` yourself.

```meson
rgbds = import('rgbds')
rgbds.fix('rgbdstest.gb', rom,
         title: 'EXAMPLE',
         mbc_type: 'ROM',
         fix_spec: 'lhg')
```

This module also adds a function with a barebones implementation of `rgbgfx`, the graphics converter from the RGBDS project. This was previously implemented as a `custom_target` in the pokered fork above.

```meson
pngs = [
  'bug',
  'plant',
  'snake',
  'quadruped',
]
foreach f : pngs
  gen = custom_target(output: '@0@_conv.png'.format(f),
                      input: '@0@.png'.format(f),
                      command: [rgbgfx, '-o', '@OUTPUT@', '@INPUT@'])
  gfx += custom_target(output: '@0@.2bpp'.format(f),
                       input: gen,
                       command: [tools_gfx, '-o', '@OUTPUT@', '@INPUT@'])
endforeach
```

The inner for loop can now use the rgbds module.

```meson
pngs = [
  'bug',
  'plant',
  'snake',
  'quadruped',
]
foreach f : pngs
  gen = rgbds.gfx('@0@_conv.2bpp'.format(f), '@0@.png'.format(f))
  gfx += custom_target(output: '@0@.2bpp'.format(f),
                       input: gen,
                       command: [tools_gfx, '-o', '@OUTPUT@', '@INPUT@'])
endforeach
```

The [meson branch][branch] of my pokered fork has been updated with these changes.

[open-pr]: https://github.com/mesonbuild/meson/pull/13831
[compiling-moc]: https://mesonbuild.com/Qt6-module.html#compile_moc
[branch]: https://github.com/terinjokes/pokered/tree/meson
