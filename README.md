# nap

This repository includes the source code and automation to build and test a tiny program that calls the "sleep" system call.

The executable can be mounted into minimal or scratch containers that have no shell or even standard libraries (no libc, etc).

It is written in assembly language to be as compact as possible. When fully assembled and linked, it weighs about 800-900 bytes depending on the linker options.

Read the [full story](https://tech.spscommerce.com/2021/04/15/introducing-nap-an.html) on the SPS Tech Blog!

## But why?

Our team at SPS Commerce manages Kubernetes clusters that run software for several internal teams. 

We've performed hundreds of tests where we deploy rolling upgrades to live services under heavy load. These tests revealed something surprising: We would occasionally see a *very* brief window of time where the client would receive an EoF socket error.

It turns out that a pod can terminate *before* the service removes the endpoint. This can happen any time a pod is terminating (due to a rolling deployment, a node eviction, scale-down event, etc.)

To solve this, we configured "preStop" hooks on all of our pods to ensure the service can remove the endpoint before the listening application receives the signal to terminate.

We found that a simple and effective solution is just to pause during the preStop hook. Even a few seconds seems more than adequate.

And the simplest way to do that is to just run "/bin/sleep".

But we sometimes deploy minimal containers that do not have shells, utilities or even the standard libraries (e.g. libc). This means we need to mount or inject our own program, and that program must be statically linked.

We mount the binary through a Kubernetes ConfigMap, which imposes a 1-megabyte limit on the program size. That rules out creating a statically linked Go program, which includes a runtime and libraries.

Furthermore, we wanted the binary to be available to every service (i.e. every namespace). That means duplicating the ConfigMap (and binary data) all over the place.

So we optimized for size. And then, well, we kept optimizing.

## But ... why??

Why not C? Calling "sleep" in C requires linking to libc. Static-linking yields a 120kb binary. Technically small enough, but surely we can do better.

Digging deeper, we can invoke the "nanosleep" system call in C, which requires linking to time.h. The code gets more complicated, but this gives us a 40kb binary.

From here, we could keep descending the deep, dark staircase of abstraction, inching closer to the metal while linking to smaller and smaller libraries to optimize our code. Or we could just talk to the machine in its native tongue.

Making a system call in assembly language is actually very simple: Move a few values into a few registers and invoke interrupt 0x80. 

You'll notice our program isn't that simple. We also parse an optional command-line argument and print a few helpful messages to stdout.

But you didn't think we'd go this far without having some fun, did you? :)

## Usage

```
nap [seconds]
```

The command-line argument is optional. By default, the program will sleep for 10 seconds.

## Alternatives

If we had to do this again, we would probably look into [TinyGo](https://tinygo.org/). 

Yet another approach would be a hybrid solution in C with a dash of in-line assembly to make the system call itself.
