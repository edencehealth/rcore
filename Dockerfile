# for updates, see: https://github.com/adoptium/temurin8-binaries/releases
ARG TEMURIN_VERSION="jdk8u362-b09"
ARG JAVA_MAJOR_VERSION=8
ARG JAVA_HOME="/usr/lib/jvm/java-${JAVA_MAJOR_VERSION}-temurin"

FROM debian:bookworm-slim
LABEL maintainer="edenceHealth <info@edence.health>"

ARG AG="apt-get -yq --no-install-recommends"
ARG DEBIAN_FRONTEND="noninteractive"

# os-level dependencies
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
    --mount=type=cache,sharing=private,target=/var/lib/apt \
  set -eux; \
  # enable the above apt cache mount to work by preventing auto-deletion
  rm -f /etc/apt/apt.conf.d/docker-clean; \
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
    >/etc/apt/apt.conf.d/01keep-debs; \
  # apt installations
  $AG update; \
  $AG upgrade; \
  $AG install  \
    apt-transport-https \
    ca-certificates \
    curl \
    gcc \
    git \
    inetutils-ping \
    inetutils-traceroute \
    iproute2 \
    libcurl4-openssl-dev \
    libopenblas0-pthread \
    libssl-dev \
    libxml2-dev \
    locales \
    procps \
    r-base \
    r-base-dev \
    r-cran-docopt \
    r-cran-littler \
    r-cran-remotes \
    r-recommended \
  ;

# ready to import these global build args now
ARG TEMURIN_VERSION
ARG JAVA_MAJOR_VERSION
ARG JAVA_HOME
RUN --mount=type=cache,target=/downloads set -ex; \
  # we're supporting x86_64 and aarch64; the repo refers to "x86_64" as "x64"
  ARCH=$(arch); \
  if [ "$ARCH" = "x86_64" ]; then ARCH="x64"; fi; \
  # example: TEMURIN_VERSION="jdk8u362-b09" -> TEMURIN_SHORT_VERSION="8u362b09"
  TEMURIN_SHORT_VERSION=$(printf '%s' "${TEMURIN_VERSION##jdk}" | tr -d '-'); \
  TEMURIN_FILENAME="OpenJDK${JAVA_MAJOR_VERSION}U-jdk_${ARCH}_linux_hotspot_${TEMURIN_SHORT_VERSION}.tar.gz"; \
  TEMURIN_ARCHIVE="/downloads/${TEMURIN_FILENAME}"; \
  curl -sSL \
    -z "$TEMURIN_ARCHIVE" \
    -o "$TEMURIN_ARCHIVE" \
    "https://github.com/adoptium/temurin${JAVA_MAJOR_VERSION}-binaries/releases/download/${TEMURIN_VERSION}/${TEMURIN_FILENAME}"; \
  mkdir -p -- "$JAVA_HOME"; \
  tar -C "$JAVA_HOME" --strip-components=1 -xzf "$TEMURIN_ARCHIVE";

RUN  R CMD javareconf

# this is in a separate step so we don't clobber the above cache mounts
RUN set -eux; \
  $AG autoremove; \
  $AG autoclean; \
  $AG clean; \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/lib/dpkg/*-old \
    /var/cache/debconf/*-old \
    /var/cache/apt \
  ;

COPY txt2lock.R /bin/

FROM scratch

# import these args from the global arg scope
ARG TEMURIN_VERSION
ARG JAVA_MAJOR_VERSION
ARG JAVA_HOME

# set them in the container as runtime environment variables
ENV TEMURIN_VERSION=${TEMURIN_VERSION}
ENV JAVA_MAJOR_VERSION=${JAVA_MAJOR_VERSION}
ENV JAVA_HOME=${JAVA_HOME}

# default path from debian:bookworm-slim + 2 java bin dirs
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin:${JAVA_HOME}/jre/bin"

COPY --from=0 / /

# app-level dependencies
WORKDIR /app
ARG RENV_VERSION="" # for example "@0.14.0"
ENV RENV_PATHS_CACHE="/renv_cache"
RUN set -eux; \
  mkdir -p "${RENV_PATHS_CACHE}"; \
  chmod ugo+rwX "${RENV_PATHS_CACHE}"; \
  printf '%s\n' \
    'options(repos=structure(c(CRAN="https://cloud.r-project.org/")))' \
    >/root/.Rprofile; \
  R -e "remotes::install_github('rstudio/renv${RENV_VERSION}')";

# Create a non-root user with full access to the /app directory
ONBUILD ARG NONROOT_UID=65532
ONBUILD ARG NONROOT_GID=65532
ONBUILD RUN set -eux; \
  groupadd \
    -g "${NONROOT_GID}" \
    nonroot; \
  useradd \
    --create-home \
    --no-log-init \
    -g nonroot \
    -u "${NONROOT_UID}" \
    nonroot; \
  mkdir /output; \
  chown -R nonroot:nonroot /output/;

WORKDIR /app

# CMD from debian:bookworm-slim
CMD [ "bash" ]
