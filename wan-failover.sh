#!/bin/sh

. /lib/functions/network.sh

WAN_PROTO=$(uci -q get wan_proto.global.proto)
WAN_INTERFACE=""
ETHERNET_STATUS=0

log() {
        echo "[test] $@" > /dev/console
}

# Return
#   == 0 : PASS
#   != 0 : Failed
ping_tool(){
        SRC_IP=
        DST_IP=$1
        DEFAULT_GW=$2
        OUT_INF=$3

        PING_CNT=2
        PING_TIMEOUT=5

        SRC_IP=$(ifconfig $OUT_INF | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

        ip route add $DST_IP via $DEFAULT_GW src $SRC_IP dev $OUT_INF

        ping -I $OUT_INF -c $PING_CNT -W $PING_TIMEOUT $DST_IP > /dev/null
        ret=$?

        ip route del $DST_IP via $DEFAULT_GW src $SRC_IP dev $OUT_INF
        ip route flush cache
        echo $ret
}

dns_modify() {
        cp /tmp/resolv.conf.auto /tmp/resolv.conf.auto.back
        sed -n '/Interface wwan/,$p' /tmp/resolv.conf.auto > ./tmp/3g_dns
        cp /tmp/3g_dns ./tmp/resolv.conf.auto
}
check_wan_interface() {
        if [ "$WAN_PROTO" == "pppoe" ]; then
                WAN_INTERFACE="pppoe-wan"
        else
                WAN_INTERFACE="eth0.2"
        fi
}

while [ $ETHERNET_STATUS -eq 0 ]; do
        dns_modify
        check_wan_interface
        IP=$(ifconfig $WAN_INTERFACE 2>/dev/null | grep "inet addr" | cut -f2 -d: | awk '{print $1}')
        if [ -n "$IP" ]; then
                . /lib/functions/network.sh
                network_get_gateway gateway "wan"
                [ -n "$gateway" ] && ping_ret=$(ping_tool 8.8.8.8 $gateway $WAN_INTERFACE)
                if [ "$ping_ret" == "0" ]; then
                        /etc/init.d/3g_wan stop
                        ETHERNET_STATUS=1
                        ip route replace default via $gateway
                        /etc/init.d/dnsmasq restart
                        killall -9 oap-network-diagnosis.sh
                        /etc/init.d/network_diagnosis restart
                        uci set -q net_live_detect.config.doing="0"
                        uci commit net_live_detect
                        logset Net_restore Restore $WAN_PROTO
                fi
        fi
        sleep 10
done   
