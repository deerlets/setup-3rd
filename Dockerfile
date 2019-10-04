FROM alpine

RUN sed -ie 's#http.*/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
#RUN echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/main" > /etc/apk/repositories
#RUN echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/community" >> /etc/apk/repositories
#RUN echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/edge/testing" >> /etc/apk/repositories

# env
ENV LD_LIBRARY_PATH=/usr/local/lib64

RUN apk update
RUN apk add bash vim git tmux
RUN apk add gcc g++ gdb cmake make libtool automake autoconf linux-headers
RUN apk add musl-dbg
RUN apk add zlib-dev readline-dev openssl-dev
RUN apk add zeromq-dev libuv-dev libwebsockets-dev
RUN apk add curl-dev curl
RUN apk add db-dev db-utils
RUN apk add sqlite-dev
RUN apk add cmocka-dev
RUN apk add json-c-dev
RUN apk add py-six py2-six py3-six
RUN apk add python nodejs npm

RUN git clone https://github.com/yonzkon/sedi.git /root/.sedi
RUN ln -sf .sedi/etc/.bash_profile /root/.bash_profile
RUN ln -sf .sedi/etc/.bash_profile /root/.bashrc
RUN ln -sf .sedi/etc/.tmux.conf /root/.tmux.conf
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# nlohmann
COPY nlohmann.tar.gz /
RUN ["sh", "-c", "mkdir -p /usr/local/include && tar -xzf /nlohmann.tar.gz -C /usr/local/include/"]

# setup-3rd
COPY setup-3rd.sh /
RUN ["sh", "-c", "/setup-3rd.sh /usr/local"]
#RUN ["sh", "-c", "cp -a /usr/local/lib64/* /usr/local/lib/"]

# clean
RUN ["sh", "-c", "rm -rf /setup-3rd.sh /nlohmann.tar.gz /usr/local/3rd"]

EXPOSE 8080
WORKDIR /root/workspace
