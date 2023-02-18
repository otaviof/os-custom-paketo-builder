FROM docker.io/paketobuildpacks/builder:base

ENV \
     DOCKER_CONFIG="/home/cnb/.docker" \
     CNB_USER_ID="1000" \
     CNB_GROUP_ID="1000"

USER 0

RUN \
     # installing sudo pakage, the "base" CNB comes without any extra packages installed thus
     # reassuring the required pacakge is present
     apt-get update && apt-get -y install sudo && \
     rm -rf "/var/cache/{apt,debconf}"

RUN \
     # making sure the script can use sudo without password, the user must not have a password set
     # and also needs to be part of the `sudo` group
     passwd -d cnb && usermod -aG sudo cnb && \
     # creating the dot-docker configuration directory, owned by the cnb user
     mkdir -pv "${DOCKER_CONFIG}" && chown -Rv ${CNB_USER_ID}:${CNB_GROUP_ID} "${DOCKER_CONFIG}"

COPY build.sh /

# default mount point for OpenShift git-clone init-container
VOLUME [ "/tmp/build" ]

USER ${CNB_USER_ID}

ENTRYPOINT [ "/build.sh" ]
