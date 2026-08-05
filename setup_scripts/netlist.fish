#!/usr/bin/env fish

set -l iface (ip route get 1.1.1.1 | string match -r 'dev (\S+)' | tail -n1)

if test -z "$iface"
    echo "Could not determine network interface."
    exit 1
end

echo "Scanning on $iface..."
echo

set -l results (sudo arp-scan --localnet --interface=$iface --plain 2>/dev/null | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n)

for line in $results
    set -l fields (string split \t $line)
    set -l ip $fields[1]
    set -l mac $fields[2]
    set -l vendor $fields[3]

    # try mDNS first, then normal DNS
    set -l host (avahi-resolve -a $ip 2>/dev/null | string split \t | tail -n1)
    if test -z "$host"
        set host (getent hosts $ip | awk '{print $2}')
    end
    test -z "$host"; and set host "(unknown)"

    echo "$ip"
    echo "  - Hostname:     $host"
    echo "  - MAC Address:  $mac"
    echo "  - Manufacturer: $vendor"
    echo
end
