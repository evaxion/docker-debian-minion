# syntax=docker/dockerfile:1.3-labs

ARG DEBIAN_RELEASE=11

FROM debian:${DEBIAN_RELEASE}

ARG SALT_PACKAGES="salt-minion"

RUN <<EOF
    echo 'upgrade system and install basic packages'
    set -e
    #
    # make dpkg less verbose
    #
    echo 'Dpkg::Use-Pty "0";' > /etc/apt/apt.conf.d/00usepty
    #
    # upgrade system
    #
    apt-get -qq update
    apt-get -qq -y upgrade
    #
    # install packages used to build this image
    #
    apt-get -qq -y install curl git sudo lsb-release
    case "$(lsb_release -s --codename)" in
        stretch)
            apt-get -qq -y install apt-transport-https
        ;;
    esac
    rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
    echo "install salt packages '${SALT_PACKAGES}'"
    set -ex
    #
    # extract debian version
    # - bullseye release return 11
    # - stretch release return 9.3
    #
    DEBIAN_RELEASE=$(lsb_release -s --release | cut -f1 -d".")
    DEBIAN_CODENAME=$(lsb_release -s --codename)
    #
    # configure salt repo
    #
    SALT_REPO_URL="https://repo.saltproject.io/py3/debian/${DEBIAN_RELEASE}/amd64/latest"
    SALT_REPO_KEY="${SALT_REPO_URL}/salt-archive-keyring.gpg"
    SALT_KEY_FILE="/usr/share/keyrings/salt-archive-keyring.gpg"
    curl -fsSL -o $SALT_KEY_FILE $SALT_REPO_KEY
    echo "deb [signed-by=$SALT_KEY_FILE arch=amd64] ${SALT_REPO_URL} ${DEBIAN_CODENAME} main" | sudo tee /etc/apt/sources.list.d/salt.list
    apt-get -qq -y update
    apt-get -qq -y install ${SALT_PACKAGES}
    rm -rf /var/lib/apt/lists/*
EOF

WORKDIR /root

RUN mkdir -m 600 /srv/salt \
    && mkdir -m 600 /srv/pillar

COPY files /

VOLUME [ "/srv/salt", "/srv/pillar" ]
