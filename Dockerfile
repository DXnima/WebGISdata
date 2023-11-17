# 从gdal 3.5.2开始构建
FROM osgeo/gdal:ubuntu-small-3.5.2

# 设置apt源
RUN sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list
RUN sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list

# 禁用时区设置
ENV DEBIAN_FRONTEND=noninteractive

# 安装编译环境
RUN apt-get update && apt-get install -y git pip build-essential libboost-dev \
    libboost-filesystem-dev libboost-iostreams-dev libboost-program-options-dev \
    libboost-system-dev liblua5.1-0-dev libprotobuf-dev libshp-dev libsqlite3-dev \
    protobuf-compiler rapidjson-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装工具
RUN apt-get update && apt-get install -y osmium-tool

# 安装 Node.js（16.x）
# RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
#     apt-get -y install nodejs

# 安装mbutil
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple mbutil

# 安装rio-rgbify
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple rio-rgbify

# 安装ogr2pbf
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple lxml protobuf==3.20.1
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple ogr2pbf

# 源码编译安装tilemaker
RUN mkdir -p /tmp/tilemaker
RUN git clone https://gitee.com/dxnima/tilemaker.git /tmp/tilemaker
WORKDIR /tmp/tilemaker
RUN make && make install

# 源码编译安装tippecanoe
RUN mkdir -p /tmp/tippecanoe
RUN git clone https://gitee.com/dxnima/tippecanoe.git /tmp/tippecanoe
WORKDIR /tmp/tippecanoe
RUN make && make install

# data为主目录
WORKDIR /data

# 卸载不需要的包减小镜像体积
RUN rm -rf /tmp/tilemaker \
    && rm -rf /tmp/tippecanoe \
    && apt-get -y remove --purge git pip git pip build-essential \
    && apt-get -y autoremove