
FROM ubuntu:20.04@sha256:626ffe58f6e7566e00254b638eb7e0f3b11d4da9675088f4781a50ae288f3322

SHELL ["/bin/bash", "-c"]



# Install dart and other ubuntu packages
# Required packages for android studio:
# - https://developer.android.com/studio/install#64bit-libs
#   requires: libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386
# For flutter:
# - https://docs.flutter.dev/get-started/install/linux
#   (requires libglu1-mesa for `flutter test`)
# - desktop prereqs:
#   https://docs.flutter.dev/desktop#additional-linux-requirements
#   (clang, cmake, gtk dev headers, ninja, pkg-config)
USER root
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-transport-https       \
        ca-certificates           \
        curl                      \
        gnupg \
    && curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && curl -fsSL https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list | \
            tee /etc/apt/sources.list.d/dart_stable.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential           \
        clang                     \
        cmake                     \
        dart                      \
        file                      \
        git                       \
        lib32z1                   \
        libbz2-1.0:i386           \
        libc6:i386                \
        libglu1-mesa              \
        libgtk-3-dev              \
        libncurses5:i386          \
        libstdc++6:i386           \
        ninja-build               \
        openjdk-8-jdk             \
        pkg-config                \
        pv                        \
        sudo                      \
        unzip                     \
        wget                      \
        xz-utils                  \
        zip                       \
    && \
    apt-get clean && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    update-java-alternatives --set java-1.8.0-openjdk-amd64

ARG USER_NAME=user
ARG USER_ID=1001
ARG USER_GID=1001

RUN : "adding user" && \
  set -x; \
  addgroup --gid ${USER_GID} ${USER_NAME} && \
  adduser --home /home/${USER_NAME} --disabled-password --shell /bin/bash --gid ${USER_GID} --uid ${USER_ID} --gecos '' ${USER_NAME} && \
  echo "%${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USER_NAME}

# For Flutter SDK releases,
# see https://docs.flutter.dev/development/tools/sdk/releases

ARG FLUTTER_VERSION=2.8.1-stable
ARG FLUTTER_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}.tar.xz

# Install flutter

RUN \
    curl -s ${FLUTTER_URL} | tar xf - --xz -C $HOME

## android command-line tools: from
## https://developer.android.com/studio/index.html#command-tools
## Handy to have them in addition to studio (as the studio-supplied ones
## seem not to work great with e.g. openjdk 11).

ARG ANDROID_TOOLS_ZIP=commandlinetools-linux-7583922_latest.zip
ARG ANDROID_TOOLS_URL=https://dl.google.com/android/repository/${ANDROID_TOOLS_ZIP}
ARG ANDROID_TOOLS_CHECKSUM=124f2d5115eee365df6cf3228ffbca6fc3911d16f8025bebd5b1c6e2fcfa7faf

# see https://developer.android.com/studio/command-line/variables
ENV ANDROID_SDK_ROOT=/home/${USER_NAME}/Android/Sdk

WORKDIR /home/${USER_NAME}

RUN \
  wget -q $ANDROID_TOOLS_URL \
    && printf '%s  commandlinetools-linux-7583922_latest.zip' "$ANDROID_TOOLS_CHECKSUM" | sha256sum -c - \
    && mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
    && unzip -q commandlinetools-linux-*.zip -d /tmp \
    && rm -f commandlinetools-linux-*.zip \
    && mv /tmp/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest

RUN  \
      yes  | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "platform-tools" "build-tools;31.0.0" "platforms;android-31"

ENV ANDROID_STUDIO_LOC=/opt/android-studio
ENV PATH=/home/${USER_NAME}/flutter/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH:$ANDROID_STUDIO_LOC/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools:$PATH

##RUN yes     | sdkmanager "system-images;android-31;google_apis;x86_64"
##RUN echo no | avdmanager create avd -n avd28 -k "system-images;android-31;google_apis;x86_64"

# Install studio
ARG ANDROID_STUDIO_URL=https://dl.google.com/dl/android/studio/ide-zips/2020.3.1.26/android-studio-2020.3.1.26-linux.tar.gz
RUN  curl -s $ANDROID_STUDIO_URL | sudo tar xf - --gzip -C /opt

RUN \
  flutter config --android-studio-dir=$ANDROID_STUDIO_LOC \
  &&  yes | flutter doctor --android-licenses \
  && flutter doctor -v

## For Qt WebEngine on docker
#ENV QTWEBENGINE_DISABLE_SANDBOX 1
#

#RUN flutter/bin/flutter precache

