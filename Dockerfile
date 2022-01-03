FROM alpine:3.12 AS builder

RUN apk update
RUN apk add g++ gcc cmake cmake make git bash perl linux-headers autoconf automake m4 libtool elfutils-dev libelf-static patch binutils openssl openssl-libs-static openssl-dev
RUN git clone --depth=1 https://github.com/falcosecurity/falco.git /source-static/falco
RUN mkdir -p /build-static/release && \
            cd /build-static/release && \
            cmake -DCPACK_GENERATOR=TGZ -DBUILD_BPF=Off -DBUILD_DRIVER=Off -DCMAKE_BUILD_TYPE=Release -DUSE_BUNDLED_DEPS=On -DMUSL_OPTIMIZED_BUILD=On -DFALCO_ETC_DIR=/etc/falco /source-static/falco
RUN cd /build-static/release && \
            make -j4 all
RUN cd /build-static/release && \
            make -j4 package
RUN mkdir -p /tmp/packages && cp /build-static/release/*.tar.gz /tmp/packages
RUN cp /tmp/packages/*.tar.gz /target.tar.gz

FROM alpine:3.14.2 

COPY --from=builder  /target.tar.gz /
RUN apk update
RUN apk add stunnel socat # Falco's SSL support needs love
RUN tar -xzvf /target.tar.gz -C / --strip-components=1
RUN rm target.tar.gz

ENTRYPOINT [ "sh" ]
