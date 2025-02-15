FROM python:3.11-alpine3.21 AS builder

ENV AWSCLI_VERSION=2.24.5

RUN apk add --no-cache \
    curl \
    make \
    cmake \
    gcc \
    g++ \
    libc-dev \
    libffi-dev \
    openssl-dev \
    && curl https://awscli.amazonaws.com/awscli-${AWSCLI_VERSION}.tar.gz | tar -xz \
    && cd awscli-${AWSCLI_VERSION} \
    && ./configure --prefix=/opt/aws-cli/ --with-download-deps \
    && make \
    && make install

FROM python:3.11-alpine3.21

ARG VCS_REF=master
ARG TFENV_VERSION=3.0.0
ARG BUILD_DATE=unknown

ARG GLIBC_VERSION=2.35-r1
ARG AWSCLI_VERSION=2.0.30

COPY --from=builder /opt/aws-cli/ /opt/aws-cli/

# Metadata
LABEL   org.opencontainers.image.title="tf-with-ansible" \
        org.opencontainers.image.url="https://hub.docker.com/repository/docker/voronenko/cdci-tf-ansible" \
        org.opencontainers.image.source="https://github.com/Voronenko/cdci-tf-ansible" \
        org.opencontainers.image.created=$BUILD_DATE \
        org.opencontainers.image.authors="Vyacheslav Voronenko <git@voronenko.info>" \
        org.opencontainers.image.description="Ansible helper image over official Python with ansible and tfenv installed ontop" \
        org.opencontainers.image.version.python="3.11.11" \
        org.opencontainers.image.version.poetry="2.0.1" \
        org.opencontainers.image.version.tfenv="3.0.0"

ENV POETRY_VERSION=2.0.1
ENV POETRY_HOME="/opt/poetry"
ENV POETRY_VIRTUALENVS_CREATE=false
ENV PATH="$POETRY_HOME/bin:/opt/aws-cli/bin/:$PATH"

# Rust is required by cryptography module, starting 3.3.2.
RUN apk add --no-cache curl make bash git docker-cli jq groff && \
    rm -rf $HOME/.cache && \
    rm -rf /var/cache/apk/*

RUN curl -sSL https://install.python-poetry.org | python3 - && \
    poetry --version

# docker-compose
ENV DOCKER_CLI_EXPERIMENTAL=enabled

RUN curl -sLo /usr/bin/docker-compose  "https://github.com/docker/compose/releases/download/v2.33.0/docker-compose-$(uname -s)-$(uname -m)" \
        && chmod +x /usr/bin/docker-compose

#RUN apk --no-cache add \
#        binutils \
#    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
#    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
#    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
#    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk \
#    && apk add --no-cache --force-overwrite \
#        glibc-${GLIBC_VERSION}.apk \
#        glibc-bin-${GLIBC_VERSION}.apk \
#        glibc-i18n-${GLIBC_VERSION}.apk \
#    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
#    && ln -sf /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 \
#    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip -o awscliv2.zip \
#    && unzip awscliv2.zip \
#    && aws/install \
#    && rm -rf \
#        awscliv2.zip \
#        aws \
#        /usr/local/aws-cli/v2/current/dist/aws_completer \
#        /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
#        /usr/local/aws-cli/v2/current/dist/awscli/examples \
#        glibc-*.apk \
#    && apk --no-cache del \
#        binutils \
#    && rm -rf /var/cache/apk/*

COPY ./pyproject.toml ./poetry.lock /tmp/
RUN cd /tmp && poetry install --no-root --no-interaction --no-ansi
ENV PACKER_ZIP=https://releases.hashicorp.com/packer/1.12.0/packer_1.12.0_linux_amd64.zip
RUN curl -sSLo /tmp/packer.zip $PACKER_ZIP && \
    unzip /tmp/packer.zip -d /usr/local/bin && \
    rm -rf /tmp/packer.zip

RUN mkdir -p /etc/docker
RUN bash -c 'echo "{\"experimental\": true}" > /etc/docker/daemon.json'

RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv && \
    echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> $HOME/.bash_profile && \
    ln -s ~/.tfenv/bin/* /usr/local/bin

COPY slacktee /usr/local/bin
RUN chmod +x /usr/local/bin

