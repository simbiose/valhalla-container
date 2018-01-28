FROM krallin/ubuntu-tini:latest
MAINTAINER leite <leite@simbio.se>

ENV TERM=vt100 \
    DATA_DIR=${DATA_DIR:-"/data/valhalla"} \
    CONF_FILE=${CONF_FILE:-"/etc/valhalla/valhalla.json"} \
    TILE_DIR=${TILE_DIR:-"/data/valhalla/tiles"} \
    CACHE_MEM=${CACHE_MEM:-"100000000"} \
    MAX_DIS=${MAX_DIS:-"20000000.0"} \
    CHECK_EVERY=${CHECK_EVERY:-36} \
    PBFS=${PDFS:-"south-america-latest,central-america-latest,north-america/mexico-latest"}

ADD etc /etc

RUN . /etc/lsb-release && echo \
        "deb http://ppa.launchpad.net/valhalla-core/valhalla/ubuntu ${DISTRIB_CODENAME} main" \
        >> /etc/apt/sources.list \
      && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
        --recv-keys 7F6D2BE86C319507A095CCE7AA079323BE7DC7A9 \
      && apt-get update -y \
      && apt-get install -y --no-install-recommends busybox daemontools nginx \
        cron curl axel python software-properties-common valhalla-bin osmctools upx jq \
      && busybox --install \
      && mkdir -p ${DATA_DIR} && mkdir /etc/valhalla \
      && { for bin in /usr/bin/valhalla*; do upx -9 $bin; done; } \
      && valhalla_build_config --mjolnir-tile-dir ${TILE_DIR} \
        --mjolnir-tile-extract ${TILE_DIR}/tiles.tar >${CONF_FILE} \
      && /etc/bootstrap setup \
      && apt-get autoremove -y \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 8080

WORKDIR /opt

ENTRYPOINT ["/usr/local/bin/tini", "--", "/etc/bootstrap"]
