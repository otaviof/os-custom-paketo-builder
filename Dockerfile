FROM docker.io/paketobuildpacks/builder:full

ENV \
     HOME="/workspace" \
     S2I_ARTIFACTS_DIR="/tmp/artifacts" \
     S2I_SRC_DIR="/tmp/src" \
     CNB_USER_ID="1000" \
     CNB_GROUP_ID="1000" \
     CNB_BASE_DIR="/data"

USER 0

COPY . /usr/libexec/builder

RUN  apt update && apt -y install jq && rm -rf /var/cache/{apt,debconf}

RUN chown -vR ${CNB_USER_ID}:${CNB_GROUP_ID} /cnb/lifecycle && \
     mkdir -p ${HOME} && chown -v ${CNB_USER_ID}:${CNB_GROUP_ID} ${HOME} && \
     mkdir -p ${CNB_BASE_DIR} && chown -v ${CNB_USER_ID}:${CNB_GROUP_ID} ${CNB_BASE_DIR} && \
     mkdir -p ${S2I_SRC_DIR} && chown -v ${CNB_USER_ID}:${CNB_GROUP_ID} ${S2I_SRC_DIR}

WORKDIR ${HOME}

USER ${CNB_USER_ID}

CMD ["/usr/libexec/builder/build.sh"]
