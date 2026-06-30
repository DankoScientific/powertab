FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    # build toolchain + PowerTab deps
    cmake g++ git ca-certificates \
    qt6-base-dev qt6-tools-dev qt6-tools-dev-tools qt6-l10n-tools \
    libboost-dev libboost-date-time-dev libboost-iostreams-dev \
    nlohmann-json3-dev libasound2-dev librtmidi-dev \
    libpugixml-dev libminizip-dev doctest-dev libgl1-mesa-dri \
    # headless GUI + web bridge
    xvfb x11vnc openbox novnc websockify \
    && rm -rf /var/lib/apt/lists/*

# Pin a release tag for true reproducibility (change as desired)
RUN git clone --depth 1 --branch 2.0.22 --recurse-submodules \
    https://github.com/powertab/powertabeditor.git /src
WORKDIR /src/build
RUN cmake .. && make -j"$(nproc)"

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 6080
VOLUME ["/tabs"]
CMD ["/usr/local/bin/start.sh"]
