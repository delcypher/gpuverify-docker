FROM ubuntu:14.04
MAINTAINER Dan Liew <daniel.liew@imperial.ac.uk>

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

# Setup Python
RUN apt-get -y --no-install-recommends install python python-dev python-pip && \
    ln -s /usr/bin/clang /usr/bin/x86_64-linux-gnu-gcc && \
    pip install psutil


# Setup CVC4
RUN apt-get -y install --no-install-recommends cvc4

# Install Other tools needed for build
RUN apt-get -y --no-install-recommends install cmake zlib1g-dev zlib1g mercurial git make libedit-dev vim

# Add a non-root user
RUN useradd -m gv
USER gv
WORKDIR /home/gv

# Build Bugle
RUN mkdir bugle && cd bugle && mkdir build && \
    git clone git://github.com/mc-imperial/bugle.git src && \
    cd src/ && git checkout feabc95ce0ada660c5a4728c85b47e6dc936254b && cd ../ && \
    cd build && \
    cmake -DLLVM_CONFIG_EXECUTABLE=/usr/bin/llvm-config-3.5 ../src && \
    make


# Libclc
RUN mkdir libclc && \
    cd libclc && \
    mkdir install && \
    git clone http://llvm.org/git/libclc.git srcbuild && \
    cd srcbuild && \
    git checkout ac887c4806de4b2d44048c8f30cf2712c79cc32d && \
    ./configure.py --with-llvm-config=/usr/bin/llvm-config-3.5 --prefix=/home/gv/libclc/install nvptx-- nvptx64-- && \
    make && \
    make install


USER root
# Setup Mono. We delay installing until now because we aren't installing
# all of mono so if the build breaks we want to able to change what mono
# components are installed without invalidating Docker's cache of the previous
# steps.
RUN apt-get -y install mono-xbuild \
                       libmono-microsoft-build-tasks-v4.0-4.0-cil \
                       mono-dmcs libmono-system-numerics4.0-cil \
                       libmono-system-windows4.0-cil \
                       libmono-corlib4.0-cil
USER gv

# Build GPUVerify C# components
RUN hg clone https://hg.codeplex.com/gpuverify && \
    cd gpuverify && \
    hg update c308dba98b9c277b160f186dd3e8facd9c87f3cf && \
    xbuild GPUVerify.sln && \
    ln -s /usr/bin/cvc4 Binaries/cvc4.exe

# Copy gvfindtools.py from context
ADD gvfindtools.py /home/gv/gpuverify/

# Put GPUVerify in PATH
RUN echo 'PATH=/home/gv/gpuverify:$PATH' >> ~/.bashrc

# Setup GPUVerifyRise4Fun
USER root
RUN pip install flask tornado
USER gv
ADD gpuverify-rise4fun-config.py /home/gv/gpuverify/utils/GPUVerifyRise4Fun/config.py
