FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git wget curl ca-certificates pkg-config \
    libssl-dev libxml2-dev libsqlite3-dev uuid-dev libjansson-dev \
    libedit-dev libcurl4-openssl-dev libncurses5-dev libnewt-dev \
    libspeexdsp-dev libsrtp2-dev libopus-dev liblua5.4-dev \
    libbluetooth-dev libglib2.0-dev bluez \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
RUN wget -O asterisk.tar.gz https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22.6.0.tar.gz \
 && tar xzf asterisk.tar.gz \
 && cd asterisk-22.6.0 \
 && ./configure --with-srtp \
 && make menuselect.makeopts \
 && menuselect/menuselect --enable res_srtp menuselect.makeopts \
 && make -j"$(nproc)" \
 && make install \
 && make samples \
 && make config \
 && ldconfig

RUN git clone https://github.com/zozidalom/asterisk-chan /usr/src/asterisk-chan \
 && cd /usr/src/asterisk-chan \
 && ./bootstrap \
 && ./configure \
 && make -j"$(nproc)" \
 && make install \
 && ldconfig

CMD ["/usr/sbin/asterisk", "-f", "-U", "root", "-G", "root"]
