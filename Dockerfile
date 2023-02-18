FROM docker.io/paketobuildpacks/builder:base

ENV \
     CNB_USER_ID="1000" \
     CNB_GROUP_ID="1000"

USER 0

RUN \
     # installing sudo pakage, the "base" CNB comes without any extra packages installed thus
     # reassuring the required pacakge is present
     apt-get update && apt-get -y install sudo && rm -rf "/var/cache/{apt,debconf}" && \
     # making sure the script can use sudo without password, the user must not have a password set
     # and also needs to be part of the `sudo` group
     passwd -d cnb && usermod -aG sudo cnb

COPY build.sh /

# default mount point for OpenShift git-clone init-container data
VOLUME [ "/tmp/build" ]

USER ${CNB_USER_ID}

ENTRYPOINT [ "/build.sh" ]
