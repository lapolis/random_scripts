#!/bin/bash

# ./get_hosts.sh 192.168.0.0/24

SS="$1"
FF=`echo $SS | tr '/' '-'`
sudo nmap -p22,139,445,80,443 -T5 $SS -oG "$FF"_nmap_NP.gnmap -Pn -vv
sudo nmap -v -sn $SS -T5 -oN "$FF"_nmap_PS.nmap -vv
grep -i "host is up" -B1 "$FF"_nmap_PS.nmap | grep report | rev | cut -d' ' -f1 | tr -d '()' | rev >> "$FF"_up.ip.tmp
grep /open/ "$FF"_nmap_NP.gnmap | cut -d' ' -f2 >> "$FF"_up.ip.tmp
cat "$FF"_up.ip.tmp | sort -u > "$FF"_up.ip
rm "$FF"_up.ip.tmp "$FF"_nmap_NP.gnmap "$FF"_nmap_PS.nmap
