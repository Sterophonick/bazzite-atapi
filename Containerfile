## 1. BUILD ARGS
# These allow changing the produced image by passing different build args to adjust
# the source from which your image is built.
# Build args can be provided on the commandline when building locally with:
#   podman build -f Containerfile --build-arg FEDORA_VERSION=40 -t local-image

# SOURCE_IMAGE arg can be anything from ublue upstream which matches your desired version:
# See list here: https://github.com/orgs/ublue-os/packages?repo_name=main
# - "silverblue"
# - "kinoite"
# - "sericea"
# - "onyx"
# - "lazurite"
# - "vauxite"
# - "base"
#
#  "aurora", "bazzite", "bluefin" or "ucore" may also be used but have different suffixes.
ARG SOURCE_IMAGE="bazzite"

## SOURCE_SUFFIX arg should include a hyphen and the appropriate suffix name
# These examples all work for silverblue/kinoite/sericea/onyx/lazurite/vauxite/base
# - "-main"
# - "-nvidia"
# - "-asus"
# - "-asus-nvidia"
# - "-surface"
# - "-surface-nvidia"
#
# aurora, bazzite and bluefin each have unique suffixes. Please check the specific image.
# ucore has the following possible suffixes
# - stable
# - stable-nvidia
# - stable-zfs
# - stable-nvidia-zfs
# - (and the above with testing rather than stable)
ARG SOURCE_SUFFIX="-deck"

## SOURCE_TAG arg must be a version built for the specific image: eg, 39, 40, gts, latest
ARG SOURCE_TAG="testing"

### 2. SOURCE IMAGE
## this is a standard Containerfile FROM using the build ARGs above to select the right upstream image
FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}

### 3. MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

COPY build.sh /tmp/build.sh

# silly system file edits
COPY system_files /

RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    ostree container commit

# repos and coprs

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
        RMG && \
    ostree container commit

# install extra (normal) packages
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree install \
        sdrpp \
        vlc \
        imhex \
        qsynth \
        obs-studio \
        qpwgraph \
        execstack \
        mame \
        mame-tools \
        mame-data-software-lists \
        neverball-neverball \
        neverball-neverputt \
        supertuxkart \
        tuxpaint \
        xonotic \
        retroarch \
        kchmviewer \
        krdp \
        pam-kwallet \
        gparted \
        qdirstat \
        cpu-x \
        konsole && \
    ostree container commit

# remove packages i don't want
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    rpm-ostree override remove \
        filelight \
        ptyxis && \
    ostree container commit

# install extract-xiso
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    wget https://github.com/XboxDev/extract-xiso/releases/download/build-202501282328/extract-xiso_Linux.zip -O /tmp/xiso.zip && \
    unzip /tmp/xiso.zip -d /usr/bin && \
    rm /usr/bin/LICENSE.TXT && \
    ostree container commit

# edit /etc/os-release
RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    sed -i "s/VARIANT_ID=.*/VARIANT_ID=bazzite-atapi/" /usr/lib/os-release && \
    sed -i "s/\"image-name\":.*/\"image-name\": \"bazzite-atapi\",/" /usr/share/ublue-os/image-info.json && \
    ostree container commit

## TODO: maybe eventually make the emulators function with the local versions instead of the stupid-ahh flatpaks?

## NOTES:
# - /var/lib/alternatives is required to prevent failure with some RPM installs
# - All RUN commands must end with ostree container commit
#   see: https://coreos.github.io/rpm-ostree/container/#using-ostree-container-commit
