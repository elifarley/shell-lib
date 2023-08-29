#!/bin/sh
ifmetric tun0 1200

# ArgoCD
ip route add 172.64.144.0/20 dev tun0
ip route add 104.17.224.0/19 dev tun0
ip route add 104.18.0.0/19 dev tun0
ip route add 104.18.32.0/20 dev tun0

ip route add 3.66.127.0/24 dev tun0
ip route add 13.228.252.0/24 dev tun0
ip route add 3.126.75.0/24 dev tun0

exit

http://www.microhowto.info/troubleshooting/troubleshooting_the_routing_table.html

ArgoCD
172.64.153.101 -> 172.64.144.0/20
104.18.34.155 ->
104.17.224.0/19
104.18.0.0/19
104.18.32.0/20

gmail: 142.250.185.69

ip r g 172.64.153.101
ip route get to 172.64.153.101 from 192.168.15.11 # iif wlo1
ip route get to 142.250.185.69 from 192.168.15.11 # iif wlo1

