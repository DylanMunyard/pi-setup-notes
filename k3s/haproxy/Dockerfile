FROM haproxy:2.3
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

RUN apt-get update && \
    apt-get install build-essential libssl-dev lua5.3 liblua5.3-dev curl unzip -y

RUN curl -sLO https://luarocks.org/releases/luarocks-3.5.0.tar.gz && \
    tar zxf luarocks-3.5.0.tar.gz && \
    cd luarocks-3.5.0 && \
    ./configure && make && make install

RUN curl -sLO https://github.com/diegonehab/luasocket/archive/master.tar.gz && \
    tar zxf master.tar.gz && \
    cd luasocket-master && \
    make clean all install-both LUAINC=/usr/include/lua5.3/ >/dev/null

RUN eval "$(luarocks path)" && \
    luarocks install luaossl && \
    luarocks install lua-cjson 2.1.0-1 && \
    curl -sLO https://github.com/DylanMunyard/haproxy-lua-jwt/releases/download/0.2/haproxy-lua-jwt.tar && \
    tar xvf haproxy-lua-jwt.tar && rm haproxy-lua-jwt.tar && \
    cp -r haproxy-lua-jwt/lib/*.lua "/usr/local/share/lua/5.3/" && rm -rf haproxy-lua-jwt
    
COPY google-jwt-pems.json /usr/local/share/lua/5.3