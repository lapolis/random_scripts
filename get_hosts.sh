#!/bin/bash

# ./get_hosts.sh 192.168.0.0/24

SS="$1"
FF=`echo $SS | tr '/' '-'`
nmap -p22,139,445,80,443 -T5 $SS -oG "$FF"_nmap_NP.gnmap -Pn -vv
# nmap --script broadcast-ping -T5 $SS -oG "$FF"_nmap_BP.gnmap -Pn -vv
arp-scan -I eth1 $SS | tee -a "$FF".arp
nmap -v -sP $SS -T5 -oN "$FF"_nmap_PS.nmap -vv
grep -i "host is up" -B1 "$FF"_nmap_PS.nmap | grep report | rev | cut -d' ' -f1 | tr -d '()' | rev >> "$FF"_up.ip.tmp
grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$FF".arp >> "$FF"_up.ip.tmp
grep /open/ "$FF"_nmap_NP.gnmap | cut -d' ' -f2 >> "$FF"_up.ip.tmp
cat "$FF"_up.ip.tmp | sort -u > "$FF"_up.ip
rm "$FF"_up.ip.tmp # "$FF"_nmap_NP.gnmap "$FF"_nmap_PS.nmap
