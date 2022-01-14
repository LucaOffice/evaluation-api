
FROM rocker/r-ver:3.6.3

LABEL org.label-schema.license="Apache-2.0" \
      org.label-schema.vcs-url="https://github.com/tmobile/r-tensorflow-api" \
      org.label-schema.vendor="T-Mobile" \
      maintainer="Jacqueline Nolis (GitHub @jnolis)"
      
# update some packages, including sodium and apache2, then clean
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    file \
    libcurl4-openssl-dev \
    libedit2 \
    libssl-dev \
    lsb-release \
    psmisc \
    procps \
    wget \
    libxml2-dev \
    libpq-dev \
    libssh2-1-dev \
    ca-certificates \
    libglib2.0-0 \
	libxext6 \
	libsm6  \
	libxrender1 \
	bzip2 \
    apache2 \
    zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ 

# install miniconda, and set the appropriate path variables.
# install Python 3.7 (Miniconda) and Tensorflow Python packages then set path variables.
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py37_4.8.2-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc
ENV PATH /opt/conda/bin:$PATH

# install all needed python packages using the pip that links to miniconda (the default pip is for python 2.7)
RUN /opt/conda/bin/conda install tensorflow==2.0.0 h5py==2.10.0 numpy==1.19.2 && \
    /opt/conda/bin/conda install -c conda-forge transformers && \
    /opt/conda/bin/conda install importlib-metadata && \
    /opt/conda/bin/conda clean -tipsy

# let R know the right version of python to use
ENV RETICULATE_PYTHON /opt/conda/bin/python
ENV R_CONFIG_ACTIVE="test"

# copy the setup script, run it, then delete it
# this script mainly installs all needed R packages, which is done in R code
COPY src/setup.R /
RUN Rscript setup.R && rm setup.R

# copy all the other R files.
COPY src /src

WORKDIR /src
ENTRYPOINT ["Rscript","main.R"]
