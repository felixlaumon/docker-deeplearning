FROM ubuntu:14.04

#####################################################
# Common Utilities
#####################################################
# noninteractive prevents grub from presenting a pop up and getting into a loop
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    # Basic tools
    apt-get install -y build-essential git curl wget bzip2 ca-certificates && \
    # For Anaconda
    apt-get install -y libglib2.0-0 libxext6 libsm6 libxrender1 && \
    # For Nvidia driver
    apt-get install -y linux-headers-$(uname -r) linux-image-$(uname -r) linux-image-extra-$(uname -r)

#####################################################
# Install CUDA 7.0 and Nvidia driver
#####################################################
# CUDA 7.5 is not stable on g2.2xlarge so use 7.0 instead
# https://devtalk.nvidia.com/default/topic/880246/cuda-7-5-unstable-on-ec2-/
# https://github.com/Kaixhin/dockerfiles/blob/master/cuda/cuda_v7.5/Dockerfile

ENV CUDA_RUN http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run

RUN cd /opt && \
    wget $CUDA_RUN && \
    chmod +x cuda_*_linux.run && \
    mkdir nvidia_installers && \
    ./cuda_*_linux.run -extract=`pwd`/nvidia_installers && \
    cd nvidia_installers && \
    ./NVIDIA-Linux-x86_64-*.run -s --no-kernel-module && \
    ./cuda-linux64-rel-*.run -noprompt && \
    rm /opt/cuda_*_linux.run && \
    rm -r /opt/nvidia_installers && \
    cd /

# Add to path
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64
ENV PATH=$PATH:/usr/local/cuda/bin

#####################################################
# cuDNN v3
#####################################################
# https://github.com/NVIDIA/nvidia-docker/blob/master/ubuntu-14.04/cuda/7.5/devel/cudnn3/Dockerfile
ENV CUDNN_DOWNLOAD_SUM 98679d5ec039acfd4d81b8bfdc6a6352d6439e921523ff9909d364e706275c2b
ENV CUDNN http://developer.download.nvidia.com/compute/redist/cudnn/v3/cudnn-7.0-linux-x64-v3.0-prod.tgz

RUN curl -fsSL $CUDNN -O && \
    echo "$CUDNN_DOWNLOAD_SUM cudnn-7.0-linux-x64-v3.0-prod.tgz" | sha256sum -c --strict - && \
    tar -xzf cudnn-7.0-linux-x64-v3.0-prod.tgz -C /usr/local && \
    rm cudnn-7.0-linux-x64-v3.0-prod.tgz && \
    ldconfig


#####################################################
# Anaconda
#####################################################
# https://github.com/ContinuumIO/docker-images/blob/master/anaconda/Dockerfile
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/archive/Anaconda2-2.4.1-Linux-x86_64.sh && \
    /bin/bash /Anaconda2-2.4.1-Linux-x86_64.sh -b -p /opt/conda && \
    rm /Anaconda2-2.4.1-Linux-x86_64.sh

ENV PATH /opt/conda/bin:$PATH


#####################################################
# Theano
#####################################################

RUN echo "[global]\ndevice=gpu\nfloatX=float32\n[nvcc]\nfastmath=True" > /root/.theanorc
