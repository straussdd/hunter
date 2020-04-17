FROM library/debian:stable-slim
COPY *.sh /tmp/

RUN /tmp/setup-container.sh \
  --package=ca-certificates:amd64 \
  --package=curl:amd64 \
  --package=hub:amd64 \
  --library=libsixel-dev \
  --library=libgstreamer-plugins-bad1.0-dev \
  --stub=libopencv-dev

RUN /tmp/setup-rust.sh
ENV PATH "/root/.cargo/bin:$PATH"
