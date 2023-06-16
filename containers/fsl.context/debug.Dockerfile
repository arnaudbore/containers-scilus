# syntax=docker.io/docker/dockerfile:1.5.0

FROM base-image as debug

WORKDIR /
RUN mkdir -p /fsl_build

WORKDIR /fsl_build
COPY --chmod=666 fsl_conda_env.yml .

RUN ls -lha

ADD --link --chmod=755 https://github.com/MShekow/directory-checksum/releases/download/v1.4.1/directory-checksum_1.4.1_linux_amd64 /usr/local/bin/directory-checksum

RUN directory-checksum --max-depth=4 .
