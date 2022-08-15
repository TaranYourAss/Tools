import dns 
from dns import resolver
from datetime import datetime

def main():
    domain = input("Domain: ")
    
    result = dns.resolver.resolve(domain, 'NS')
    nameservers = []
    for nameserver in result:
        nameservers.append(nameserver.to_text())
    #print(nameservers)

    for nameserver in nameservers:
        print("----------------------------------------")
        print("[{}] Attempting Zone Transfer from {}".format(datetime.utcnow(), nameserver))
        results = dns.resolver.resolve(nameserver, 'A')
        result = str(results.rrset.to_text()).split('IN A')
        ip = result[1].strip()
        try:
            zone = dns.zone.from_xfr(dns.query.xfr(ip, domain))
        except Exception as e:
            print("[{}] {}".format(datetime.utcnow(), e))
            continue
        print("[{}] Zone Transfer Successful".format(datetime.utcnow()))
        print("[{}] Zone File Contents:".format(datetime.utcnow()))
        hosts = set(zone)
        for host in hosts:
            print("{}.{}".format(host, domain))

if __name__ == "__main__":
    main()
