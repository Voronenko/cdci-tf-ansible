FROM docker:latest

ARG VCS_REF=master
ARG BUILD_DATE=unknown

# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.name="tf-with-ansible" \
      org.label-schema.url="https://hub.docker.com/repository/docker/voronenko/cdci-tf-ansible" \
      org.label-schema.vcs-url="https://github.com/Voronenko/cdci-tf-ansible" \
      org.label-schema.build-date=$BUILD_DATE

# Rust is required by cryptography module, starting 3.3.2.
RUN apk add --no-cache py3-pip python3-dev libffi-dev openssl-dev curl gcc libc-dev make rust cargo bash && \
    pip3 install docker-compose awscli ansible==2.9.6

COPY slacktee /usr/local/bin
RUN chmod +x /usr/local/bin
