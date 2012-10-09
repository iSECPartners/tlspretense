#!/bin/sh
# Sample script for setting up iptables/netfilter for use with PacketThief. It
# creates a NAT on the external interface, and it manually configures the
# internal interface. A more advanced setup with a DHCP server could make it
# easier by auto-configuring clients.
external=eth0
internal=eth1

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain


echo "Manually setup the internal network's nic"
ifconfig $internal 192.168.0.1 netmask 255.255.255.0 

echo "enabling packet forwarding"
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "applying basic iptables rules for NATing"
iptables -t nat -A POSTROUTING -o $external -j MASQUERADE

echo "Done! PacketThief will create and destroy the rules for redirecting traffic."
