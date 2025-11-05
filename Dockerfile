# ---------- builder ----------
FROM debian:bookworm AS build
ARG ASTERISK_VER=22.6.0
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential wget curl git pkg-config ca-certificates \
  libxml2-dev libncurses5-dev libnewt-dev libsqlite3-dev uuid-dev \
  libjansson-dev libssl-dev libedit-dev libcurl4-openssl-dev \
  libbluetooth-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
RUN curl -fSLO https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VER}.tar.gz
RUN tar xzf asterisk-${ASTERISK_VER}.tar.gz
WORKDIR /usr/src/asterisk-${ASTERISK_VER}

RUN ./configure --prefix=/usr --with-bluetooth
RUN make menuselect.makeopts && menuselect/menuselect --enable chan_mobile menuselect.makeopts
RUN make -j"$(nproc)" && make install && ldconfig

# ---------- runtime ----------
FROM debian:bookworm-slim
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libxml2 libncursesw6 libcurl4 \
  libjansson4 libsqlite3-0 libedit2 libssl3 libbluetooth3 tzdata ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/sbin/asterisk /usr/sbin/
COPY --from=build /usr/lib/asterisk /usr/lib/asterisk
COPY --from=build /usr/lib/libasterisk* /usr/lib/
RUN ldconfig

ENTRYPOINT ["/usr/sbin/asterisk"]
CMD ["-f","-U","root","-G","root"]
