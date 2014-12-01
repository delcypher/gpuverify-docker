GPUVerify Docker image
======================

This repository contains the ``DockerFile`` and other associated files
for building a Docker container from the latest [GPUVerify](https://gpuverify.codeplex.com/) code.

Running
-------

First obtain the image from the DockerHub. If you don't want to do this see "Building"

```
$ docker pull delcypher/gpuverify-docker
```

Now you can gain access to a shell inside the container (note ``--rm`` removes
the container when you exit it).

```
$ docker run -ti --rm delcypher/gpuverify-docker /bin/bash
```

To actually verify some kernels you'll probably want to add
some volumes (``-v`` flag to ``docker run``) so GPUVerify has
access to some kernels on your system.

Building
--------

If you'd rather not used the pre-built image from the [DockerHub](https://registry.hub.docker.com/u/delcypher/gpuverify-docker/)
Then you can build it locally on your system by doing the following.

```
$ cd /path/to/this/repository
$ docker build -t "delcypher/gpuverify-docker" .
```
