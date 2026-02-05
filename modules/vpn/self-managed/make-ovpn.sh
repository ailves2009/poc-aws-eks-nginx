#!/bin/bash
# filepath: /etc/openvpn/make-ovpn.sh

# Usage: sudo ./make-ovpn.sh <client_name> <EC2_PUBLIC_IP> [порт]
# Example: sudo ./make-ovpn.sh jetson-10 vpn.tst-pltechotwin.xyz 443

CLIENT="$1"
SERVER_IP="$2"
PORT="${3:-443}" # default 443

if [[ -z "$CLIENT" || -z "$SERVER_IP" ]]; then
  echo "Usage: $0 <client_name> <server_ip> [port]"
  exit 1
fi

CA=/etc/openvpn/server/ca.crt
CRT=/etc/openvpn/clients/${CLIENT}.crt
KEY=/etc/openvpn/clients/${CLIENT}.key
OVPN=/etc/openvpn/clients/ovpn/${CLIENT}.ovpn

if [[ ! -f "$CA" || ! -f "$CRT" || ! -f "$KEY" ]]; then
  echo "One or more certificate files not found for $CLIENT"
  exit 2
fi

mkdir -p /etc/openvpn/clients/ovpn

cat > "$OVPN" <<EOF
client
dev tun
proto udp
remote $SERVER_IP $PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3

<ca>
$(cat "$CA")
</ca>
<cert>
$(awk '/BEGIN/,/END/' "$CRT")
</cert>
<key>
$(awk '/BEGIN/,/END/' "$KEY")
</key>
EOF

echo "Created $OVPN"