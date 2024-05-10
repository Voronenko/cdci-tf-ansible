FROM python:3.10-alpine3.16

ARG VCS_REF=master
ARG BUILD_DATE=unknown


# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.name="tf-with-ansible" \
      org.label-schema.url="https://hub.docker.com/repository/docker/voronenko/cdci-tf-ansible" \
      org.label-schema.vcs-url="https://github.com/Voronenko/cdci-tf-ansible" \
      org.label-schema.build-date=$BUILD_DATE

RUN apk --no-cache add \
        curl \
        jq


ARG GLIBC_VERSION=2.35-r0
ARG AWSCLI_VERSION=2.11.11

# install glibc compatibility for alpine
RUN apk --no-cache add \
        binutils \
        curl \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk \
    && apk add --no-cache --force-overwrite \
        glibc-${GLIBC_VERSION}.apk \
        glibc-bin-${GLIBC_VERSION}.apk \
        glibc-i18n-${GLIBC_VERSION}.apk \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && ln -sf /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 \
    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/current/dist/aws_completer \
        /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/current/dist/awscli/examples \
        glibc-*.apk \
    && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete \
    && apk --no-cache del \
        binutils \
        curl \
    && rm -rf /var/cache/apk/*


ENV DOCKER_CLI_EXPERIMENTAL=enabled

# Rust is required by cryptography module, starting 3.3.2.
RUN apk add --no-cache curl make bash git docker-cli && \
    rm -rf $HOME/.cache && \
    rm -rf /var/cache/apk/*

RUN curl -sLo /usr/bin/docker-compose  "https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-$(uname -s)-$(uname -m)" \
        && chmod +x /usr/bin/docker-compose

#ADD requirements.txt /tmp
RUN pip install ansible==2.9.6

#RUN apk add --no-cache py3-pip python3-dev libffi-dev openssl-dev curl gcc libc-dev make rust cargo bash git && \
#    pip3 install docker-compose awscli ansible==2.9.6 && \
#    apk del python3-dev libffi-dev openssl-dev libc-dev gcc

ENV PACKER_ZIP=https://releases.hashicorp.com/packer/1.5.4/packer_1.5.4_linux_amd64.zip
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

RUN 
