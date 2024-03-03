#Consul v1.10.6
#go version go1.15.9 linux/amd64

FROM registry.astralinux.ru/library/alse:1.7.3 AS builder

COPY consul_sources_v1.10.6.tar.gz  /consul_sources_v1.10.6.tar.gz
COPY golang_v1.15.9_dependencies.tar.gz   /golang_v1.15.9_dependencies.tar.gz

RUN tar -xzvf /consul_sources_v1.10.6.tar.gz -C /
RUN tar -xzvf /golang_v1.15.9_dependencies.tar.gz -C ~/

RUN set -eux && \
    apt-get update && \
    apt-get install make git golang-go -y
RUN cd /app/consul && make dev
RUN go version
RUN /app/consul/bin/consul version

FROM registry.astralinux.ru/library/alse:1.7.3

# Create a consul user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN addgroup consul && \
    adduser --system --group consul #Adding new user `consul'  with group `consul'

RUN apt-get update && \
    apt-get install sudo

COPY --from=builder /app/consul/bin/consul /usr/local/bin

# The /consul/data dir is used by Consul to store state. The agent will be started
# with /consul/config as the configuration directory so you can add additional
# config files in that location.
RUN mkdir -p /consul/data && \
    mkdir -p /consul/config && \
    chown -R consul:consul /consul

# set up nsswitch.conf for Go's "netgo" implementation which is used by Consul,
# otherwise DNS supercedes the container's hosts file, which we don't want.
RUN test -e /etc/nsswitch.conf || echo 'hosts: files dns' > /etc/nsswitch.conf

# Expose the consul data directory as a volume since there's mutable state in there.
VOLUME /consul/data

# Server RPC is used for communication between Consul clients and servers for internal
# request forwarding.
EXPOSE 8300

# Serf LAN and WAN (WAN is used only by Consul servers) are used for gossip between
# Consul agents. LAN is within the datacenter and WAN is between just the Consul
# servers in all datacenters.
EXPOSE 8301 8301/udp 8302 8302/udp

# HTTP and DNS (both TCP and UDP) are the primary interfaces that applications
# use to interact with Consul.
EXPOSE 8500 8600 8600/udp

COPY /docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["bash", "/usr/local/bin/docker-entrypoint.sh"]
#'bash' так как иначе не запустится docker-entrypoint.sh
#и будет ошибка  Bad substitution

# By default you'll get an insecure single-node development server that stores
# everything in RAM, exposes a web UI and HTTP endpoints, and bootstraps itself.
# Don't use this configuration for production.
CMD ["agent", "-dev", "-client", "0.0.0.0"]