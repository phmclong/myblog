echo '===== VIP / HAPROXY ====='
ip -4 addr show dev ens33 | grep '10.16.61.62' || echo 'VIP NOT PRESENT'
systemctl --no-pager --full status haproxy keepalived | sed -n '1,80p'
grep -nE 'bind|server cp' /etc/haproxy/haproxy.cfg

mkdir ha_proxy
cd ha_proxy/

cat > values-haproxy-ingress.yaml <<'EOF'
controller:
  kind: Deployment
  replicaCount: 3
  ingressClass: haproxy
  service:
    type: LoadBalancer
    annotations:
      lbipam.cilium.io/ips: "10.16.61.63"
  config:
    timeout-connect: "5s"
    timeout-client: "50s"
    timeout-server: "50s"
defaultBackend:
  enabled: true
EOF

helm upgrade --install haproxy-kubernetes-ingress \
  haproxytech/kubernetes-ingress \
  --namespace haproxy-ingress \
  --create-namespace \
  -f values-haproxy-ingress.yaml

iptables -P INPUT DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

for ip in $NODES; do
  iptables -A INPUT -s $ip -j ACCEPT
done

iptables -A INPUT -p tcp -s 10.2.15.0/24 --dport 22 -j ACCEPT

# Lưu ý: IP 10.16.31.61 có vẻ là typo.
iptables -A INPUT -d 10.16.31.61 -p tcp -m multiport --dports 80,443 -j ACCEPT

iptables-save > /etc/sysconfig/iptables

service firewalld start
systemctl enable firewalld

for ip in 10.16.61.30 10.16.61.31 10.16.61.32 10.16.61.62; do
  firewall-cmd --permanent \
    --add-rich-rule="rule family=ipv4 source address=$ip accept"
done

firewall-cmd --permanent \
  --add-rich-rule='rule family=ipv4 source address=10.2.15.0/24 port port=22 protocol=tcp accept'

firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload


iptables -L INPUT -n -v --line-numbers | grep -E '10.16.61.61|DROP|policy'
iptables -I INPUT 3 -d 10.16.61.61 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -L INPUT -n -v --line-numbers
iptables-save > /etc/sysconfig/iptables

firewall-cmd --permanent \
  --add-rich-rule='rule family=ipv4 destination address=10.16.61.61 port port=80 protocol=tcp accept'

firewall-cmd --permanent \
  --add-rich-rule='rule family=ipv4 destination address=10.16.61.61 port port=443 protocol=tcp accept'

firewall-cmd --reload
firewall-cmd --list-rich-rules
iptables -L INPUT -n -v --line-numbers | grep -E '80|443|DROP'

iptables -D INPUT 13

iptables -I INPUT 1 \
  -d 10.16.61.61 \
  -p tcp \
  -m multiport \
  --dports 80,443 \
  -j ACCEPT

iptables -L INPUT -n -v --line-numbers | grep '10.16.61.61'

kubectl get svc -A | grep -iE 'ingress|nginx'
kubectl get ciliumloadbalancerippool 2>/dev/null

clear

kubectl get ciliuml2announcementpolicy -A
kubectl get ciliumbgppeeringpolicy -A 2>/dev/null
kubectl get ciliumbgpadvertisement -A 2>/dev/null

iptables -L -n | grep -i cilium | head
iptables -L INPUT -n -v --line-numbers

iptables -D INPUT 14
iptables -D INPUT 4

iptables -I INPUT 2 -p tcp -m multiport --dports 32409,31865 -j ACCEPT
iptables -I INPUT 2 -p tcp -m multiport --dports 80,443 -j ACCEPT

service firewalld stop

systemctl disable firewalld