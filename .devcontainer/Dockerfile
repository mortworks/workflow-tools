FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && \
    apt-get install -y hugo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
