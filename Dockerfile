FROM ubuntu:14.04
MAINTAINER Dan Liew <daniel.liew@imperial.ac.uk>

ENV BUGLE_REV=3b5185cd4ae4f3e7fc7a3b7a83d424689d7400a3 \
    LIBCLC_REV=233697 \
    LIBCLC_SVN_URL=http://llvm.org/svn/llvm-project/libclc/branches/release_35 \
    GPUVERIFY_REV=74c6d45ee4d9c379b6559614e80a1a37bab3e103

# Get keys, add repos and update apt-cache
RUN apt-get update && apt-get -y install wget && \
    wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key|apt-key add - && \
    echo 'deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.5 main' > /etc/apt/sources.list.d/llvm.list && \
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C504E590 && \
    echo 'deb http://ppa.launchpad.net/delcypher/gpuverify-smt/ubuntu trusty main' > /etc/apt/sources.list.d/smt.list && \
    wget -O - http://download.mono-project.com/repo/xamarin.gpg |apt-key add - && \
    echo "deb http://download.mono-project.com/repo/debian wheezy main" > /etc/apt/sources.list.d/mono-xamarin.list && \
    apt-get update

# Setup LLVM, Clang 3.5
RUN apt-get -y install llvm-3.5 llvm-3.5-dev llvm-3.5-tools clang-3.5 libclang-3.5-dev && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.5 10 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.5 10 && \
    update-alternatives --install /usr/bin/cc cc /usr/bin/clang 50 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 50 && \
    update-alternatives --install /usr/bin/opt opt /usr/bin/opt-3.5 50 && \
    update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-3.5 50

# Setup Mono
RUN apt-get -y install mono-xbuild \
                       libmono-microsoft-build-tasks-v4.0-4.0-cil \
                       mono-dmcs libmono-system-numerics4.0-cil \
                       libmono-system-windows4.0-cil \
                       libmono-corlib4.0-cil

# Setup Python
RUN apt-get -y --no-install-recommends install python python-dev python-pip && \
    ln -s /usr/bin/clang /usr/bin/x86_64-linux-gnu-gcc && \
    pip install psutil flask tornado pyyaml


# Setup Z3
RUN apt-get -y install z3=4.3.2-0~trusty1

# Install Other tools needed for build
RUN apt-get -y --no-install-recommends install cmake zlib1g-dev zlib1g mercurial git subversion make libedit-dev vim

# Add a non-root user
RUN useradd -m gv
USER gv
WORKDIR /home/gv

# Build Bugle
RUN mkdir bugle && cd bugle && mkdir build && \
    git clone git://github.com/mc-imperial/bugle.git src && \
    cd src/ && git checkout ${BUGLE_REV} && cd ../ && \
    cd build && \
    cmake -DLLVM_CONFIG_EXECUTABLE=/usr/bin/llvm-config-3.5 ../src && \
    make


# Libclc
RUN mkdir libclc && \
    cd libclc && \
    mkdir install && \
    svn co -r ${LIBCLC_REV} ${LIBCLC_SVN_URL} srcbuild && \
    cd srcbuild && \
    ./configure.py --with-llvm-config=/usr/bin/llvm-config-3.5 --prefix=/home/gv/libclc/install nvptx-- nvptx64-- && \
    make && \
    make install

# Build GPUVerify C# components
RUN hg clone https://hg.codeplex.com/gpuverify && \
    cd gpuverify && \
    hg update ${GPUVERIFY_REV} && \
    xbuild GPUVerify.sln && \
    ln -s /usr/bin/z3 Binaries/z3.exe

# Copy gvfindtools.py from context
ADD gvfindtools.py /home/gv/gpuverify/

# Put GPUVerify in PATH
RUN echo 'PATH=/home/gv/gpuverify:$PATH' >> /home/gv/.bashrc

# Setup GPUVerifyRise4Fun
ADD gpuverify-rise4fun-config.py /home/gv/gpuverify/utils/GPUVerifyRise4Fun/config.py
USER root
RUN chown gv: /home/gv/gpuverify/utils/GPUVerifyRise4Fun/config.py
# For logged data (these get copied into the volume when container is created)
RUN mkdir /data/ && mkdir /data/logged_kernels && mkdir /data/counters
RUN chown -R gv: /data
VOLUME /data
USER gv

# Entry point for GPUVerifyRise4Fun
EXPOSE 5000
ENTRYPOINT ["/usr/bin/python", "/home/gv/gpuverify/utils/GPUVerifyRise4Fun/production_server.py"]
CMD []
