+++
date = "2018-07-27T17:43:56Z"
title = "Black-box Serial Testing"
+++

Occasionally, we all end up working on a program that could, at best, be
described as a ball of mud. We want to refactor it into smaller, more testable
components, but we don’t want to risk breaking it in the process.

Enter the concept of “black-box testing”. In black-box testing, the
functionality of a program is tested by a tester, without the ability to
directly leverage implementation details of the program.

For some programs, all we need to do is give it input, and observe the output.
As the software grows in complexity, we may have to compare created files,
setup mock web servers, and test databases. Many the great author and many the
great blog have written on these problems.

The “ball of mud” side project I’m currently working on communicates over
a serial port. This presents a larger challenge for a tester: how can we
observe behavior of the application with the serial port from our test?
Pointing the program at a file won’t work, as it wants to connect to a remote
device and configure options, such as baud rate and parity bits.

The long evolutionary history of UNIX provides us with one solution. In the
early days of UNIX, the output from the computer was printed onto serially
connected teleprinter. When technology marched on, terminal emulators replaced
the physical teleprinter, and the functionality needed to create these
pseudo-teleprinters was added to the kernel.

As these teleprinters were originally serially connected, their modern virtual
forms retain their serial nature. 

In our test harness, we can create a new pseudo-teleprinter then pass the
emulated end to our program as the serial port. This example uses the Go test
harness, but equivalent functionality is available in most programming and
scripting languages, so you can use your favorite.

```go
package main

import (
	"io/ioutil"
	"os/exec"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/pkg/term/termios"
)

func TestCLI(t *testing.T) {
	// create and open the pseudo tty master, and the linked
	// child tty.
	pty, tty, err := termios.Pty()
	if err != nil {
		t.Errorf("unable to create pty: %s\n", err)
	}

	// execute our program, passing in the child tty name (eg, /dev/pts/1)
	// as our serial port paramater.
	cmd := exec.Command("ball-of-mud", "-serialport", tty.Name())
	output, err := cmd.Output()
	if err != nil {
		t.Errorf("error running ball-of-mud: %s\n", err)
	}

	// close the child tty. if we forget to do this the
	// master pseudo tty will wait for more data forever.
	tty.Close()

	// read all the written serial data from the master
	// pseudo tty. ReadAll reads until EOF or an error is
	// returned, but Linux sends EIO when attempting to read
	// from a master with no open children. So let's just
	// look for the error string.
	bytes, err := ioutil.ReadAll(pty)
	if err != nil && err.Error() != "read ptm: input/output error" {
		t.Errorf("error reading pty: %s\n", err)
	}

	// confirm we saw the expected text from standard out
	if diff := cmd.Diff("hello", string(output)); diff != "" {
		t.Errorf("unexpected output (-want +got):\n%s", diff)
	}

	// confirm we saw the expected bytes written to the serial device
	if diff := cmd.Diff([]byte{"world"}, bytes); diff != "" {
		t.Errorf("unexpected serial (-want +got):\n%s", diff)
	}
}

```

As the two parts of the pseudo-teleprinter are connected to each other, writes
to one will be readable from the other side. Thus duplex communication is
possible for more complex black-box tests.

This method isn’t entirely perfect. For example, on Linux, it’s not always
possible to observe the configured baud rate. Even with these limitations, it’s
still a helpful tool in our toolkit.

