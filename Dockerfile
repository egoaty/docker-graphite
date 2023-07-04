ARG DISTRO=ubuntu
FROM $DISTRO

ENV GRAPHITE_ROOT /opt/graphite

ARG GRAPHITEWEB_VERSION=""
ARG GRAPHITEWEB_GITHUB_PROJECT="graphite-project/graphite-web"
ARG GRAPHITEWEB_SRC_ROOT="/opt/src/graphite"

ARG WHISPER_VERSION=""
ARG WHISPER_GITHUB_PROJECT="graphite-project/whisper"
ARG WHISPER_SRC_ROOT="/opt/src/whisper"

ARG CARBON_VERSION=""
ARG CARBON_GITHUB_PROJECT="graphite-project/carbon"
ARG CARBON_SRC_ROOT="/opt/src/carbon"


RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get dist-upgrade -q -y && \
  \
  ln -fs /usr/share/zoneinfo/Europe/Vienna /etc/localtime && \
  apt-get install -y tzdata && \
  dpkg-reconfigure --frontend noninteractive tzdata && \
  \
  apt-get install -y curl python3 python3-pip python3-cairo python3-gunicorn gunicorn libffi8 nginx &&\
  apt-get install -y git jq python3-dev python3-cairo-dev libffi-dev gcc musl-dev python-wheel-common &&\
  \
  mkdir -p /run/nginx && \
  sed -i 's/^user nginx/user graphite/' /etc/nginx/nginx.conf && \
  \
  PYTHON_SITE_PACKAGES=$( python3 -c 'import site; print(site.getsitepackages()[0])' )  && \
  export PYTHONPATH="/opt/graphite/lib/:/opt/graphite/webapp/" && \
  \
  \
  install -d -m 0755 "${WHISPER_SRC_ROOT}" && \
  if [ "${WHISPER_VERSION}" != "" ]; then \
    echo "-- Selecting whisper version ${WHISPER_VERSION} --" && \
    WHISPER_RELEASE_TARBALL=$( curl -s "https://api.github.com/repos/${WHISPER_GITHUB_PROJECT}/releases" | jq -r '.[] | select( .name == "'"${WHISPER_VERSION}"'" ) | .tarball_url ' ); \
  else \
    WHISPER_VERSION=$( curl -s "https://api.github.com/repos/${WHISPER_GITHUB_PROJECT}/releases/latest" | jq -r '.name' ); \
    echo "-- Selecting whisper latest version ${WHISPER_VERSION} --" && \
    WHISPER_RELEASE_TARBALL=$( curl -s "https://api.github.com/repos/${WHISPER_GITHUB_PROJECT}/releases/latest" | jq -r '.tarball_url' ); \
  fi && \
  curl -s -L -H "Accept: application/vnd.github.v3+json" "${WHISPER_RELEASE_TARBALL}" | tar -xz -C "${WHISPER_SRC_ROOT}" --strip-components=1 && \  
  cd "${WHISPER_SRC_ROOT}" && \
  pip3 install . && \
  python3 setup.py install  && \
  cd - && \
  \
  \
  install -d -m 0755 "${CARBON_SRC_ROOT}" && \
  if [ "${CARBON_VERSION}" != "" ]; then \
    echo "-- Selecting carbon version ${CARBON_VERSION} --" && \
    CARBON_RELEASE_TARBALL=$( curl -s "https://api.github.com/repos/${CARBON_GITHUB_PROJECT}/releases" | jq -r '.[] | select( .name == "'"${CARBON_VERSION}"'" ) | .tarball_url ' ); \
  else \
    CARBON_VERSION=$( curl -s "https://api.github.com/repos/${CARBON_GITHUB_PROJECT}/releases/latest" | jq -r '.name' ); \
    echo "-- Selecting graphite-web latest version ${CARBON_VERSION} --" && \
    CARBON_RELEASE_TARBALL=$( curl -s "https://api.github.com/repos/${CARBON_GITHUB_PROJECT}/releases/latest" | jq -r '.tarball_url' ); \
  fi && \
  curl -s -L -H "Accept: application/vnd.github.v3+json" "${CARBON_RELEASE_TARBALL}" | tar -xz -C "${CARBON_SRC_ROOT}" --strip-components=1 && \
  cd "${CARBON_SRC_ROOT}" && \
  pip3 install . && \
  python3 setup.py install && \
  cd - && \
  \
  \
  install -d -m 0755 "${GRAPHITEWEB_SRC_ROOT}" && \
  if [ "${GRAPHITEWEB_VERSION}" != "" ]; then \
    echo "-- Selecting graphite-web version ${GRAPHITEWEB_VERSION} --" && \
    GRAPHITEWEB_RELEASE_TARBALL=$( curl -s "https://api.github.com/repos/${GRAPHITEWEB_GITHUB_PROJECT}/releases" | jq -r '.[] | select( .name == "'"${GRAPHITEWEB_VERSION}"'" ) | .tarball_url ' ); \
  else \
    GRAPHITEWEB_VERSION=$( curl -s "https://api.github.com/repos/${GRAPHITEWEB_GITHUB_PROJECT}/releases/latest" | jq -r '.name' ); \
    echo "-- Selecting graphite-web latest version ${GRAPHITEWEB_VERSION} --" && \
    GRAPHITEWEB_RELEASE_TARBALL=$( curl -s "https://api.github.com/repos/${GRAPHITEWEB_GITHUB_PROJECT}/releases/latest" | jq -r '.tarball_url' ); \
  fi && \
  curl -s -L -H "Accept: application/vnd.github.v3+json" "${GRAPHITEWEB_RELEASE_TARBALL}" | tar -xz -C "${GRAPHITEWEB_SRC_ROOT}" --strip-components=1 && \
  cd "${GRAPHITEWEB_SRC_ROOT}" && \
  pip3 install . && \
  python3 setup.py install  && \
  cd - && \
  \
  \
  cd /opt/graphite/conf && \
  for file in *.example; do mv -- "${file}" "${file%.example}"; done && \
  cd - && \
  cp /opt/src/graphite/webapp/manage.py /opt/graphite/webapp/ && \
  \
  \
  rm -rf /opt/src && \
  apt-get remove --purge -y git jq python3-dev python3-cairo-dev libffi-dev gcc musl-dev python-wheel-common &&\
  apt-get clean -q -y --force-yes && \
  apt-get autoclean -q -y --force-yes


COPY root/ /

VOLUME ["/opt/graphite/storage"]

EXPOSE 80/tcp
EXPOSE 2003/tcp
EXPOSE 2004/tcp

CMD /run.sh
