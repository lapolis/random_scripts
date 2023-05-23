#!/bin/sh

# v.0.21
# Fixed resume function for single hosts
# Added auto skip

# all target IPs need to be in ./tar.txt
# can also add the ./exc.txt with the IP to exclude
## both files need to exist!! ##

## add an arg to resume from a certain stage, example:
## sudo bash ./autoscan.sh 2

if [[ $# -eq 0 ]]
then
        resume=-1
else
        resume=$1
fi

stage0="T:80,443"
stage1="T:25,135,137,139,445,1433,3306,5432"
stage2="U:111,120,123,135-139,158,161-162"
stage3="U:7,9,17,19,37,49,53,67-69,80,88"
stage4="T:23,21,22,110,111,2049,3389,8080"
stage5="T:0,U:177,389,427,443,445,464,500,554,623,1433-1434,2048-2049,5060"
stage6="T:1-20,24,26-79,81-109,112-134"
stage7="T:136,138,140-442,444,446-1432"
stage8="T:1434-2048,2050-3305,3307-3388,3390-5431,5433-8079,8081-29999"
stage9="T:30000-65535"
stage10="U:626,631,996-999,1022-1023,1025-1030,1645-1646,1701,1718-1719,1812-1813,1900,2000,2222-2223,3283,3456,3703,4444,4500,5000,5060,5353,5632,9200,10000,17185,20031,30718,31337,32768-32769,32771,32815,33281,49152-49154,49156,49181-49182,49185-49186,49188,49190-49194,49200-49201,65024"
stages=($stage0 $stage1 $stage2 $stage3 $stage4 $stage5 $stage6 $stage7 $stage8 $stage9 $stage10)
mkdir machines 2>/dev/null
mkdir general 2>/dev/null
mkdir tmp 2>/dev/null
echo '' > ./tmp/specific_ips
ip4=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
echo "$ipv4" >> ./exc.txt

for X in "${!stages[@]}"
do
        if [[ $X -lt $resume ]]
        then
                echo "SKIPPING STAGE $X (forced)" >> ./tmp/stage
                continue
        fi

        if grep -q "ENDING STAGE $X" ./tmp/stage
        then
                echo "SKIPPING STAGE $X (auto)" >> ./tmp/stage
                continue
        fi
    
        echo "STARTING STAGE $X" >> ./tmp/stage
        echo "-------------------------------------- STARTING STAGE $X -------------------------------------------------"
        echo "-------------------------------------- STARTING STAGE $X -------------------------------------------------"
        echo "-------------------------------------- STARTING STAGE $X -------------------------------------------------"

        # fast option
        # nmap -p ${stages[$X]} --max-rtt-timeout 1250ms --min-rtt-timeout 100ms --initial-rtt-timeout 500ms --max-retries 1  -sS -Pn -n -sU -vv -iL ./targets.txt -oA general/stage$X-quick
        
        # if resuming a stage
        if [[ $X -eq $resume ]]
        then
                ## sS scan check if actually exists
                if [[ -f general/stage$X-sS-quick.xml ]]
                then
                        echo "RESUMING STAGE $X sS" >> ./tmp/stage
                        nmap --resume general/stage$X-sS-quick.xml
                else
                        echo "STARTING STAGE $X sS" >> ./tmp/stage
                        nmap -p ${stages[$X]} --max-retries 5  -sS -Pn -n -sU -vv -iL ./tar.txt -oA general/stage$X-sS-quick --excludefile ./exc.txt
                fi

                ## sT scan check if actually exists
                if [[ -f general/stage$X-sT-quick.xml ]]
                then
                        echo "RESUMING STAGE $X sT" >> ./tmp/stage
                        nmap --resume general/stage$X-sT-quick.xml
                else
                        echo "STARTING STAGE $X sT" >> ./tmp/stage
                        nmap -p ${stages[$X]} --max-retries 5  -sT -Pn -n -sU -vv -iL ./tar.txt -oA general/stage$X-sT-quick --excludefile ./exc.txt
                fi
        else
                # slightly quicker than a single scan at normal speed
                echo "STARTING STAGE $X sS" >> ./tmp/stage
                nmap -p ${stages[$X]} --max-retries 5  -sS -Pn -n -sU -vv -iL ./tar.txt -oA general/stage$X-sS-quick --excludefile ./exc.txt
                echo "STARTING STAGE $X sT" >> ./tmp/stage
                nmap -p ${stages[$X]} --max-retries 3  -sT -Pn -n -sU -vv -iL ./tar.txt -oA general/stage$X-sT-quick --excludefile ./exc.txt
        fi
        
        # very fast option
        # nmap -p ${stages[$X]} --min-rate 5000 --max-rtt-timeout 1250ms --min-rtt-timeout 100ms --initial-rtt-timeout 500ms --max-retries 1  -sS -Pn -n -sU -vv -iL ./targets.txt -oA general/stage$X-quick

        echo "STARTING SPECIFIC IPs STAGE $X" >> ./tmp/stage
        
        grep -h /open/ general/stage$X-*-quick.gnmap | cut -d' ' -f2 | sort -u > general/up.ip

        for IP in `cat general/up.ip`
        do
                PP=$(cat general/stage$X-*-quick.gnmap  | grep $IP | grep -oP '\d{1,5}/open/[tcpud]{3}' | awk '{if($3 =="tcp")print "T:"$1;else if($3 =="udp")print "U:"$1}' FS='/' | sort -u | xargs | tr ' ' ',')
                if grep -q "specific $IP" ./tmp/specific_ips
                then
                        if grep -q "DONE specific $IP" ./tmp/specific_ips
                        then
                                continue
                        else
                                nmap --resume machines/$IP-stage$X-open.xml
                        fi
                else
                        echo "STARTING specific $IP" >> ./tmp/specific_ips
                        nmap -p$PP $IP -A -sS -sC -sU -oA machines/$IP-stage$X-open -vv -Pn
                fi
                echo "DONE specific $IP" >> ./tmp/specific_ips
        done
        echo "ENDING STAGE $X" >> ./tmp/stage
done
