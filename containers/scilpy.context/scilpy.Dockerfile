# syntax=docker/dockerfile:1.4

FROM scilpy-base as scilpy

LABEL maintainer=SCIL

ARG BLAS_NUM_THREADS
ARG PYTHON_VERSION
ARG SCILPY_VERSION
ARG VTK_INSTALL_PATH
ARG VTK_VERSION

ENV PYTHON_PACKAGE_DIR=${PYTHON_PACKAGE_DIR:-site-packages}
ENV PYTHON_VERSION=${PYTHON_VERSION:-3.10}
ENV SCILPY_VERSION=${SCILPY_VERSION:-master}
ENV OPENBLAS_NUM_THREADS=${BLAS_NUM_THREADS:-1}
ENV VTK_INSTALL_PATH=${VTK_INSTALL_PATH:-/vtk}
ENV VTK_VERSION=${VTK_VERSION:-8.2.0}

WORKDIR /
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
    apt-get update && apt-get install -y \
        git \
        libblas-dev \
        libfreetype6-dev \
        liblapack-dev \
        wget \
        unzip && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /
ADD https://github.com/scilus/scilpy/archive/${SCILPY_VERSION}.zip scilpy.zip
RUN unzip scilpy.zip && \
    ZIP_NAME=$(echo ${SCILPY_VERSION} | tr / -) && \
    mv scilpy-${ZIP_NAME} scilpy && \
    rm scilpy.zip

WORKDIR /scilpy
RUN SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True python${PYTHON_VERSION} -m pip install -e . && \
    python${PYTHON_VERSION} -m pip cache purge

RUN sed -i '41s/.*/backend : Agg/' /usr/local/lib/python${PYTHON_VERSION}/${PYTHON_PACKAGE_DIR}/matplotlib/mpl-data/matplotlibrc && \
    cp -r /scilpy/data /usr/local/lib/python${PYTHON_VERSION}/${PYTHON_PACKAGE_DIR}/ && \
    apt-get -y remove \
        git \
        wget \
        unzip && \
    apt-get -y autoremove

WORKDIR /
RUN ( [ -f "VERSION" ] || touch VERSION ) && \
    echo "Scilpy => ${SCILPY_VERSION}\n" >> VERSION


FROM scilpy as scilpy-test
ADD tests/ /tests/

WORKDIR /tests
RUN python3 -m pytest
