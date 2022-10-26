FROM python:3.10-alpine3.16

ARG VCS_REF=master
ARG BUILD_DATE=unknown

# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.name="tf-with-ansible" \
      org.label-schema.url="https://hub.docker.com/repository/docker/voronenko/cdci-tf-ansible" \
      org.label-schema.vcs-url="https://github.com/Voronenko/cdci-tf-ansible" \
      org.label-schema.build-date=$BUILD_DATE

ENV DOCKER_CLI_EXPERIMENTAL=enabled

# Rust is required by cryptography module, starting 3.3.2.
RUN apk add --no-cache curl make bash git docker-cli && \
    pip3 install docker-compose awscli ansible==2.9.6 && \
    rm -rf $HOME/.cache

#RUN apk add --no-cache py3-pip python3-dev libffi-dev openssl-dev curl gcc libc-dev make rust cargo bash git && \
#    pip3 install docker-compose awscli ansible==2.9.6 && \
#    apk del python3-dev libffi-dev openssl-dev libc-dev gcc

ENV PACKER_ZIP=https://releases.hashicorp.com/packer/1.5.4/packer_1.5.4_linux_amd64.zip
RUN curl -sSLo /tmp/packer.zip $PACKER_ZIP && \
    unzip /tmp/packer.zip -d /usr/local/bin && \
    rm /tmp/packer.zip

RUN mkdir -p /etc/docker
RUN bash -c 'echo "{\"experimental\": true}" > /etc/docker/daemon.json'

RUN git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv && \
    echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> $HOME/.bash_profile && \
    ln -s ~/.tfenv/bin/* /usr/local/bin

COPY slacktee /usr/local/bin
RUN chmod +x /usr/local/bin
