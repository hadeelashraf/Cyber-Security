#!/bin/bash

url=$1


if [ ! -d "$url" ]; then
	mkdir $url
fi

if [ ! -d "$url/recon" ]; then
	mkdir $url/recon
fi

# if [ ! -d "$url/recon/screenshots" ]; then
# 	mkdir $url/recon/screenshots
# fi

if [ ! -d "$url/recon/aquatone" ]; then
	mkdir $url/recon/aquatone
fi

if [ ! -d "$url/recon/whatweb-nmap" ]; then
	mkdir $url/recon/whatweb-nmap
fi

echo "[+] Harvesting host information with theHarvester using urlscan API ..."
theHarvester -d $1 -b urlscan > $url/recon/theharvester.txt

echo "[+] Harvesting Root Domains with amass ..."
amass intel -whois -d $url > $url/recon/rootdomains.txt

echo "[+] Harvesting subdomains with assetfinder ..."
assetfinder --subs-only $url > $url/recon/subdomains.txt

echo "[+] Double checking the subdomains with amass ..."
amass enum -d $url >> $url/recon/subdomains.txt
sort -u $url/recon/subdomains.txt > $url/recon/final-subdomains.txt
rm $url/recon/subdomains.txt

echo "[+] Probing for alive domains with httprobe ..."
cat $url/recon/final-subdomains.txt | sort -u | httprobe --prefer-https | sort -u > $url/recon/alive.txt
cat $url/recon/alive.txt | sed 's/https\?:\/\///' | sort -u > $url/recon/alive-subs-only.txt

# echo "[+] Taking Screenshots from alive domains with gowitness ..."
# gowitness file -f $url/recon/alive.txt -P $url/recon/screenshots
# gowitness report export -f report.zip

echo "[+] Visual Inspection of the live domains with aquatone ..."
cat $url/recon/alive-subs-only.txt | aquatone -ports large -out $url/recon/aquatone

echo "[+] Searching for potential takeover subdomains with subjack..."
subjack -w $url/recon/alive-subs-only.txt -t 100 -timeout 30 -o $url/recon/subs-takeover.txt -ssl -c  ~/go/src/subjack/fingerprints.json

echo "[+] Scraping URLs from the Wayback Machine with waybackurls ..."
cat $url/recon/final-subdomains.txt | waybackurls > $url/recon/wayback-output1.txt
sort -u $url/recon/wayback-output1.txt > $url/recon/wayback-output.txt
rm $url/recon/wayback-output1.txt

echo "[+] Scanning each live domain using whatweb and nmap ..."
for sub in $(cat $url/recon/alive-subs-only.txt); do
	if (! -d "$url/recon/whatweb-nmap/$sub" );then mkdir $url/recon/whatweb-nmap/$sub; fi
	nmap $sub -A -T4 -Pn -sV > $url/recon/whatweb-nmap/$sub/nmap-output.txt; sleep 3
	whatweb --info-plugins -t 50 $sub > $url/recon/whatweb-nmap/$sub/whatweb-plugins.txt; sleep 3
	whatweb -t 50 -v -a 3 $sub > $url/recon/whatweb-nmap/$sub/whatweb-output.txt; sleep 3
done
