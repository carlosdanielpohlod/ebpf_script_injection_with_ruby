FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bpfcc-tools \
    libbpfcc-dev \
    ruby \
    ruby-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN gem install rbbcc --no-document

WORKDIR /app
COPY *.rb .

CMD ["ruby", "tracer.rb"]
