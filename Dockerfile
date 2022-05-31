ARG DEBIAN_VERSION=bullseye
ARG PYTHON_VERSION=3
FROM docker.io/library/python:$PYTHON_VERSION-slim-$DEBIAN_VERSION AS python_base
ARG PREFIX=/app
ARG PUID=1000
ARG PGID=1000
ARG TIMEZONE=UTC
ARG LANGUAGE=en_US
ARG CHARSET=UTF-8
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
apt-get install --no-install-recommends -y ca-certificates locales netcat-openbsd tzdata wget && \
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
localedef -i $LANGUAGE -c -f $CHARSET -A /usr/share/locale/locale.alias $LANGUAGE.$CHARSET && \
groupadd --gid $PGID app && \
useradd --uid $PUID --gid $PGID --comment '' --home-dir /dev/shm --no-create-home --shell /bin/bash --no-log-init app && \
mkdir -p $PREFIX/bin $PREFIX/lib $PREFIX/static $PREFIX/config $PREFIX/data && \
chown -R $PUID:$PGID $PREFIX
ENV PATH=$PREFIX/bin:$PATH \
LD_LIBRARY_PATH=$PREFIX/lib \
HOME=/dev/shm \
XDG_RUNTIME_DIR=/dev/shm \
TMPDIR=/dev/shm \
LANG=$LANGUAGE.$CHARSET \
LANGUAGE=$LANGUAGE \
CHARSET=$CHARSET \
TZ=$TIMEZONE
WORKDIR $PREFIX

FROM python_base
RUN apt-get install --no-install-recommends -y nftables libcap2-bin && \
setcap -q cap_net_admin+ep /usr/sbin/nft && \
apt-get purge --auto-remove -y libcap2-bin && \
rm -rf /etc/nftables*
COPY ./main.py ./bin/nftables-exporter
COPY ./requirements.txt .
RUN pip install -r ./requirements.txt && rm ./requirements.txt
USER app
ENTRYPOINT ["nftables-exporter"]
HEALTHCHECK --interval=60s --timeout=3s CMD ["wget", "-q", "-O", "-", "http://127.0.0.1:9630/health"]
EXPOSE 9630/tcp
