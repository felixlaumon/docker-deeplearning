# docker-deeplearning

> For running deep neural net experiment on AWS EC2 g2.2xlarge / g2.8xlarge with
> Docker and Docker machine

This image includes

- Nvidia driver 346.46
- CUDA 7.0
- Anaconda 3.18.8 (Python 2.7.11)
- Preconfigured .theanorc to use GPU and float32 by default

## Useful Commands

### Preparing the host machine

The host machine needs to run the **same version** of the NVidia driver as inside the container. So I built an AMI based on the Ubuntu 14.04 HBM SSD AMI (ami-5c207736) by the following script.

    sudo su -
    apt-get update
    apt-get install -y build-essential
    apt-get install -y linux-headers-$(uname -r) linux-image-$(uname -r) linux-image-extra-$(uname -r)
    echo "blacklist nouveau\nblacklist lbm-nouveau\noptions nouveau modeset=0\nalias nouveau off\nalias lbm-nouveau off" > /etc/modprobe.d/blacklist-nouveau.conf 
    echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/nouveau-kms.conf
    update-initramfs -u
    reboot

    sudo su -
    cd /opt
    wget http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run
    chmod +x cuda_*_linux.run
    ./cuda_*_linux.run -extract=`pwd`/nvidia_installers
    cd nvidia_installers
    ./NVIDIA-Linux-x86_64-*.run -s
    ./cuda-linux64-rel-*.run -noprompt
    ./cuda-samples-linux-7.0.28-19326674.run -noprompt -cudaprefix=/usr/local/cuda
    cd /usr/local/cuda/samples/1_Utilities/deviceQuery
    make
    ./deviceQuery
    ls /dev | grep nvidia

    rm /opt/cuda_7.0.28_linux.run
    rm -r /opt/nvidia_installers

You should save the instance as an AMI so you can reuse it later.
    
To create a host using spot instance

    docker-machine create --driver amazonec2 \
        --amazonec2-ami ami-... \
        --amazonec2-access-key $AWS_ACCESS_KEY_ID \
        --amazonec2-secret-key $AWS_SECRET_ACCESS_KEY \
        --amazonec2-vpc-id vpc-... \
        --amazonec2-root-size 60 \
        --amazonec2-instance-type g2.2xlarge \
        --amazonec2-request-spot-instance \
        --amazonec2-spot-price 0.15 \
        aws01

To activate the newly created instance

    eval "$(docker-machine env aws01)"

To view all created hosts

    docker-machine ls

SSH into the instance and sanity check

    docker-machine ssh aws01
    nvidia-smi
    # Should see information about the GPU
    ls /dev | grep nvidia
    # Should see nvidia0 nvidiactl nvidia-uvm

If nvidia-uvm is not found
    
    docker-machine ssh aws01
    /usr/local/cuda/samples/1_Utilities/deviceQuery/deviceQuery
    ls /dev | grep nvidia
    exit

To terminate and remove the instance

    docker-machine rm aws01

### Running the image

To build this image

    docker build -t felixlaumon/deeplearning .

Make sure the GPU is working inside the container

    docker run -ti --device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm felixlaumon/deeplearning python -c "import theano"
    # Should see "Using gpu device 0: GRID K520"

Debug inside the container

    docker run -ti --device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm felixlaumon/deeplearning /bin/bash

To publish the image

    docker push felixlaumon/deeplearning

To start over

    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
    docker rmi $(docker images -q)
