GPUVerify Docker image
======================

This repository contains the ``DockerFile`` and other associated files
for building a Docker container from the latest [GPUVerify](https://gpuverify.codeplex.com/) code.

Building
--------

```
$ cd /path/to/this/repository
$ docker build -t "gpuverify" .
```

Running
-------

This will give you a shell into the container.

```
$ docker run -ti --rm gpuverify /bin/bash
```

To actually verify some kernels you'll probably want to add
some volumes (``-v`` flag to ``docker run``) so GPUVerify has
access to some kernels on your system.
