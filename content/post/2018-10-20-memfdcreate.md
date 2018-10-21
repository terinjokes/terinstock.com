+++
date = "2018-10-20 23:21:27Z"
title = "memfd_create: Temporary in-memory files with Go and Linux"
description = "Showing how to create temporary files entirely in memory using Go on Linux"
+++

My [MIDI Player] project requires interfacing with libraries and system calls
that don't yet have Go equivalents. A few of these C libraries expect to be
invoked with file paths or file descriptors.

[MIDI Player]: {{< ref "2018-09-17-hardware-midi-player-1.md" >}}

If the data is already available as a file on a mounted disk, this is fine,
I can pass the path or descriptor that already exists. I run into a problem,
however, as soon as I want to work with data that isn't directly backed by
a file, such as after being manipulated by the program, or having been unpacked
from a container format.

There's a simple way to get a file path: create a temporary file somewhere.
This requires having a writable filesystem mounted, and cleaning up the files
when no longer required. On a device that's intended to be used as an
appliance, I don't have anywhere writable.

In Linux 3.17 and later, I have another option [`memfd_create(2)`][memfd_create]:

> memfd_create() creates an anonymous file and returns a file descriptor that
> refers to it. The file behaves like a regular file, and so can be modified,
> truncated, memory-mapped, and so on. However, unlike a regular file, it lives
> in RAM and has a volatile backing storage. Once all references to the file are
> dropped, it is automatically released.

[memfd_create]: https://jlk.fjfi.cvut.cz/arch/manpages/man/core/man-pages/memfd_create.2.en

This checks the boxes for most of my requirements: a file descriptor to
something that acts like a normal file, backed by memory, doesn't require any
writable mount points, and automatically cleans up files when closed.

The system call is available in the Go [`x/sys/unix`][unix] package, along with
a few companion calls.

[unix]: https://godoc.org/golang.org/x/sys/unix


```go
package main

import (
	"fmt"

	"golang.org/x/sys/unix"
)

// memfile takes a file name used, and the byte slice
// containing data the file should contain.
//
// name does not need to be unique, as it's used only
// for debugging purposes.
//
// It is up to the caller to close the returned descriptor.
func memfile(name string, b []byte) (int, error) {
	fd, err := unix.MemfdCreate(name, 0)
	if err != nil {
		return 0, fmt.Errorf("MemfdCreate: %v", err)
	}

	err = unix.Ftruncate(fd, int64(len(b)))
	if err != nil {
		return 0, fmt.Errorf("Ftruncate: %v", err)
	}

	data, err := unix.Mmap(fd, 0, len(b), unix.PROT_READ|unix.PROT_WRITE, unix.MAP_SHARED)
	if err != nil {
		return 0, fmt.Errorf("Mmap: %v", err)
	}

	copy(data, b)

	err = unix.Munmap(data)
	if err != nil {
		return 0, fmt.Errorf("Munmap: %v", err)
	}

	return fd, nil
}

```

Some libraries require a file path instead of a file descriptor. Fortunately,
we can turn a file descriptor into a path by way of the proc filesystem using
the symlinks in the /proc/self/fd directory.

```go
package main

import (
	"fmt"
	"log"
	"os"
)

func main() {
	fd, err != memfile("hello", []byte("hello world!"))
	if err != nil {
		log.Fatalf("memfile: %v", err)
	}

	// filepath to our newly created in-memory file descriptor
	fp := fmt.Sprintf("/proc/self/fd/%d", fd)

	// create an *os.File, should you need it
	// alternatively, pass fd or fp as input to a library.
	f := os.NewFile(uintptr(fd), fp)
	defer f.Close()
}
```

Eventually, I'll replace these C libraries with Go packages that operate on
`io.Reader`, and this workaround will become unnecessary. Until then, I'm glad
the option is available.
