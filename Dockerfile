# 第一阶段: 构建依赖和工具
FROM osgeo/gdal:ubuntu-small-3.5.2 AS builder

# 设置apt源
RUN sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list \
    && sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list

# 禁用时区设置
ENV DEBIAN_FRONTEND=noninteractive

# 安装编译环境和工具
RUN apt-get update && apt-get install -y git pip build-essential libboost-dev \
    libboost-filesystem-dev libboost-iostreams-dev libboost-program-options-dev \
    libboost-system-dev liblua5.1-0-dev libprotobuf-dev libshp-dev libsqlite3-dev \
    protobuf-compiler rapidjson-dev

# 源码编译安装tilemaker
RUN mkdir -p /tmp/tilemaker \
    && git clone https://gitee.com/dxnima/tilemaker.git /tmp/tilemaker
WORKDIR /tmp/tilemaker
RUN make && make install

# 源码编译安装tippecanoe
RUN mkdir -p /tmp/tippecanoe \
    && git clone https://gitee.com/dxnima/tippecanoe.git /tmp/tippecanoe
WORKDIR /tmp/tippecanoe
RUN make && make install

# 第二阶段: 最终镜像
FROM osgeo/gdal:ubuntu-small-3.5.2

# 设置apt源
RUN sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list \
    && sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list

# 安装依赖和工具
RUN apt-get update && apt-get install -y pip osmium-tool \
    liblua5.1-0 libboost-filesystem1.71.0 libboost-iostreams1.71.0 \
    libprotobuf17 libshp2 \
    && rm -rf /var/lib/apt/lists/* \
    # 安装nodejs (16.x)
    && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get update && apt-get -y install nodejs

# TODO: 设置代理
ENV HTTP_PROXY=http://172.29.32.1:7890

# 安装dem2terrain
RUN npm i dem2terrain -g \
    # pip安装mbutil、rio-rgbify、ogr2osm
    && pip install -i https://pypi.tuna.tsinghua.edu.cn/simple \
    mbutil rio-rgbify lxml protobuf==3.20.1 ogr2osm

# 从第一阶段复制构建好的工具和依赖
COPY --from=builder /usr/local/bin/tilemaker /usr/local/bin/tilemaker
COPY --from=builder /usr/local/bin/tippecanoe /usr/local/bin/tippecanoe

# data为主目录
WORKDIR /data

# 卸载不需要的包减小镜像体积
RUN apt-get -y remove --purge pip curl \
    && apt-get -y autoremove
