FROM nfcore/base:1.10.2
LABEL authors="Marcos Cámara Donoso & Christina Chatzipantsiou" \
      description="Docker image containing all software requirements for the lifebit-ai/phenowrangle pipeline"

RUN apt-get update && \
    apt-get install -y \
              build-essential \
              git \
              unzip \
              autoconf \
              zlib1g-dev \
              libbz2-dev \
              liblzma-dev \
              libcurl4-gnutls-dev \
              libssl-dev \
              libgsl0-dev \
              libperl-dev \
              libxt-dev \
              speedtest-cli \
              procps

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/phenowrangle/bin:$PATH

RUN mkdir /opt/bin
COPY bin/* /opt/bin/

RUN find /opt/bin/ -type f -iname "*.R" -exec chmod +x {} \;

RUN touch .Rprofile
RUN touch .Renviron

ENV PATH="$PATH:/opt/bin/"

USER root

WORKDIR /data/

CMD ["bash"]
