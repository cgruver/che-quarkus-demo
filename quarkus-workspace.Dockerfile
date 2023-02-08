FROM registry.access.redhat.com/ubi9/ubi-minimal
ARG USER_HOME_DIR="/home/user"
ARG WORK_DIR="/projects"
ARG JAVA_PACKAGE=java-17-openjdk-devel
ARG USER_HOME_DIR="/home/user"
ARG WORK_DIR="/projects"
ENV HOME=${USER_HOME_DIR}
ENV BUILDAH_ISOLATION=chroot
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV MAVEN_HOME=/usr/share/maven
ENV MAVEN_CONFIG="${HOME}/.m2"
ENV GRAALVM_HOME=/usr/local/tools/graalvm
ENV JAVA_HOME=/etc/alternatives/jre_17_openjdk
COPY --from=quay.io/cgruver0/che/quarkus-tools:latest /tools/ /usr/local/tools
COPY --from=image-registry.openshift-image-registry.svc:5000/openshift/cli:latest /usr/bin/oc /usr/bin/oc
RUN microdnf --disableplugin=subscription-manager install -y openssl compat-openssl11 libbrotli git tar gzip zip unzip which shadow-utils bash zsh wget jq podman buildah skopeo glibc-devel zlib-devel gcc libffi-devel libstdc++-devel gcc-c++ glibc-langpack-en ca-certificates ${JAVA_PACKAGE}; \
  microdnf update -y ; \
  microdnf clean all ; \
  mkdir -p ${USER_HOME_DIR} ; \
  mkdir -p ${WORK_DIR} ; \
  mkdir -p /usr/local/bin ; \
  setcap cap_setuid+ep /usr/bin/newuidmap ; \
  setcap cap_setgid+ep /usr/bin/newgidmap ; \
  mkdir -p "${HOME}"/.config/containers ; \
  (echo '[storage]';echo 'driver = "vfs"') > "${HOME}"/.config/containers/storage.conf ; \
  touch /etc/subgid /etc/subuid ; \
  chmod -R g=u /etc/passwd /etc/group /etc/subuid /etc/subgid ; \
  echo user:20000:65536 > /etc/subuid  ; \
  echo user:20000:65536 > /etc/subgid ; \
  chgrp -R 0 /home ; \
  chmod -R g=u /home ${WORK_DIR}
USER 10001
ENV PATH=${PATH}:/usr/local/tools/bin
WORKDIR ${WORK_DIR}
