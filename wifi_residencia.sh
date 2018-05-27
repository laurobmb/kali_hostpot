#!/bin/bash
#airmon-ng check
#apt install aircrack-ng
#apt install hostapd
#apt install dnsmasq
#apt install isc-dhcp-server

declare -r arquivo_res="/etc/hostapd/hostapd.conf"
declare -r arquivo_dns="/etc/dnsmasq.conf"
declare -r interface_wifi="wlx0013ef8028b1"
interface_inernet="enp0s20u1"

ifconfig $interface_wifi >/dev/null
if [ $? == 0 ]; then echo "Interface WIFI OK"; VAR=1; else echo "Interface WIFI OFF"; exit 1; fi

res(){
cat << EOF > $arquivo_res
### Wireless network interface ###
interface=$interface_wifi
driver=nl80211
ssid=Minha WIFI Minhas regras
hw_mode=g
channel=4
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
auth_algs=3
ieee80211n=1
wmm_enabled=1
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=medeirosnet2018
rsn_pairwise=CCMP
EOF
}

dns(){
cat << EOF > $arquivo_dns
log-facility=/var/log/dnsmasq.log
#address=/#/10.5.5.1
#address=/google.com/10.5.5.1
interface=$interface_wifi
dhcp-range=10.5.5.10,10.5.5.1OO,12h
dhcp-option=3,10.5.5.1
dhcp-option=6,10.5.5.1
#no-resolv
log-queries
EOF

cat << EOF > $arquivo_res
interface=$interface_wifi
driver=nl80211
ssid=FreeWifi
channel=1
# Yes, we support the Karma attack.
#enable_karma=1
EOF

}

firewall(){
	iptables -t nat -A POSTROUTING -o $interface_inernet -j MASQUERADE;
	iptables -A FORWARD -i usb0 -o $interface_wifi -m state --state RELATED,ESTABLISHED -j ACCEPT;
        iptables -A FORWARD -i wlan0 -o $interface_inernet -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT;
        iptables-save > /etc/iptables.ipv4.nat;
}


case "$1" in
	comp)
		killall wpa_supplicant;
		firewall;
		sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/hostapd/hostapd.conf#' /etc/init.d/hostapd
		sed -i 's#^INTERFACESv4=.*#INTERFACESv4="'$interface_wifi'"#' /etc/default/isc-dhcp-server
		systemctl restart isc-dhcp-server.service;
		systemctl stop dnsmasq.service;
		res;
		hostapd $arquivo_res;;
	atk)
		killall wpa_supplicant;
		firewall;
		dns;                
		systemctl restart dnsmasq.service
		hostapd $arquivo_res;;
	stop)	       
		systemctl stop isc-dhcp-server;
		systemctl stop dnsmasq.service;
		iptables -F;
		iptables -F -t nat;
		rm -f $arquivo_res
		rm -f $arquivo_dns
		iptables -t nat -F;;
	*) 
		echo "ERROR";
		echo "usage {comp|atk|stop}";;
esac
