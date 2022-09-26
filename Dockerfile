FROM debian:bookworm-slim
LABEL maintainer="edenceHealth <info@edence.health>"

# os-level dependencies
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
    --mount=type=cache,sharing=private,target=/var/lib/apt \
  set -eux; \
  # enable the above apt cache mount to work by preventing auto-deletion
  rm -f /etc/apt/apt.conf.d/docker-clean; \
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
    >/etc/apt/apt.conf.d/01keep-debs; \
  # apt installations
  export \
    AG="apt-get -yq" \
    DEBIAN_FRONTEND="noninteractive" \
  ; \
  $AG update; \
  $AG upgrade; \
  $AG install --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gcc \
    git \
    libcurl4-openssl-dev \
    libopenblas0-pthread \
    libssl-dev \
    libxml2-dev \
    locales \
    openjdk-11-jdk-headless \
    r-base \
    r-base-dev \
    r-cran-docopt \
    r-cran-littler \
    r-cran-remotes \
    r-recommended \
  ; \
  R CMD javareconf

# this is in a separate step so we don't clobber the above cache mounts
RUN set -eux; \
  export \
    AG="apt-get -yq" \
    DEBIAN_FRONTEND="noninteractive" \
  ; \
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
