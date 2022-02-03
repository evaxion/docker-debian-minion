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
    #
    # missing packages in older debian versions
    #
    case "$(lsb_release -s --codename)" in
        stretch|jessie)
            apt-get -qq -y install apt-transport-https
        ;;
    esac
    #
    # cleaning
    #
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
    # configure salt debian repositories
    #
    case "$DEBIAN_CODENAME" in
        jessie)
            SALT_REPO_URL="https://archive.repo.saltproject.io/debian"
            SALT_REPO_KEY="https://archive.repo.saltproject.io/debian-salt-team-joehealy.gpg.key"
            # install gpg key
            curl -fsSL "$SALT_REPO_KEY" | apt-key add -
            # configure repositories
            echo "deb [arch=amd64] ${SALT_REPO_URL} ${DEBIAN_CODENAME}-saltstack main" | sudo tee /etc/apt/sources.list.d/salt.list
            echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
        ;;
        *)
            SALT_REPO_URL="https://repo.saltproject.io/py3/debian/${DEBIAN_RELEASE}/amd64/latest"
            SALT_REPO_KEY="${SALT_REPO_URL}/salt-archive-keyring.gpg"
            SALT_KEY_FILE="/usr/share/keyrings/salt-archive-keyring.gpg"
            # install gpg key
            curl -fsSL -o $SALT_KEY_FILE $SALT_REPO_KEY
            # configure repositories
            echo "deb [signed-by=$SALT_KEY_FILE arch=amd64] ${SALT_REPO_URL} ${DEBIAN_CODENAME} main" | sudo tee /etc/apt/sources.list.d/salt.list
        ;;
    esac
    #
    # install packages
    #   
    case "$DEBIAN_CODENAME" in
        jessie)
            # needed for backport repository itself needed for gitfs usage in salt
            echo 'Acquire::Check-Valid-Until false;' | tee -a /etc/apt/apt.conf.d/10-nocheckvalid 
            apt-get -qq -y update
            apt-get -qq -y install ${SALT_PACKAGES} python-git
            apt-get -qq -y install --only-upgrade -t jessie-backports python-git
            rm -rf /var/lib/apt/lists/*
        ;;
        *)
            apt-get -qq -y update
            apt-get -qq -y install ${SALT_PACKAGES}
            rm -rf /var/lib/apt/lists/*
        ;;
    esac
EOF

WORKDIR /root

RUN mkdir -m 600 /srv/salt \
    && mkdir -m 600 /srv/pillar

COPY files /

VOLUME [ "/srv/salt", "/srv/pillar" ]
