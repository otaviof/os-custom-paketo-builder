FROM docker.io/paketobuildpacks/builder:base

ENV \
     DOCKER_CONFIG="/home/cnb/.docker" \
     CNB_USER_ID="1000" \
     CNB_GROUP_ID="1000"

USER 0

COPY build.sh /

RUN \
     apt-get update && \
     apt-get -y install sudo && \
     rm -rf /var/cache/{apt,debconf}

RUN \
     passwd -d cnb && \
     usermod -aG sudo cnb && \
     mkdir -pv ${DOCKER_CONFIG} && \
     chown -Rv ${CNB_USER_ID}:${CNB_GROUP_ID} ${DOCKER_CONFIG}

USER ${CNB_USER_ID}

ENTRYPOINT [ "/build.sh" ]
