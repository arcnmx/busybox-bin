# busybox-bin

[![travis-badge][]][travis]

Builds statically linked `busybox` binaries with all features enabled.
`ssl_helper` is also included so that it may download over HTTPS.


## Download

Visit [releases](https://github.com/arcnmx/busybox-bin/releases) for the
latest builds.


## Known Bugs

- The build scripts for i686 with musl libc are currently broken.
- The glibc binaries will fail to resolve remote hostnames if nss/glibc/etc.
  isn't configured properly on your system. This is by design and will not be
  fixed upstream; avoiding these binaries is recommended.


[travis-badge]: https://img.shields.io/travis/arcnmx/busybox-bin/master.svg?style=flat-square
[travis]: https://travis-ci.org/arcnmx/busybox-bin
