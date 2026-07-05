kubectl get pods -n rook-ceph -w
kubectl get pods -n rook-ceph -w
kubectl get pods -n rook-ceph -w
kubectl get pods -n rook-ceph -w
kubectl get pods -n rook-ceph -w

ls
pwd

cat <<'EOF' > rook-ceph-cluster.yaml
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  cephVersion:
    image: quay.io/ceph/ceph:v20.2.2
    allowUnsupported: false
  dataDirHostPath: /var/lib/rook
  mon:
    count: 3
    allowMultiplePerNode: false
  mgr:
    count: 2
    allowMultiplePerNode: false
  placement:
    all:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: ceph-role
                  operator: In
                  values:
                    - storage
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
  storage:
    useAllNodes: false
    useAllDevices: false
    nodes:
      - name: k8s-sec-controlplane
        devices:
          - name: sdb
      - name: k8s-sec-worker-1
        devices:
          - name: sdb
      - name: k8s-sec-worker-2
        devices:
          - name: sdb
EOF

kubectl apply -f rook-ceph-cluster.yaml
kubectl get cephcluster -n rook-ceph -w
kubectl get cephcluster -n rook-ceph -w
k get no
kubectl get cephcluster -n rook-ceph -w
kubectl get cephcluster -n rook-ceph -w
kubectl get cephcluster -n rook-ceph
kubectl get cephcluster -n rook-ceph
kubectl get cephcluster -n rook-ceph -w

kubectl describe pod -n kube-system cilium-brlf7
kubectl describe pod -n kube-system cilium-qvjqm

systemctl status haproxy --no-pager -l
grep -nA12 -B3 'k8s-api-backend' /etc/haproxy/haproxy.cfg
ss -lntp | grep ':6443'
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}{"\n"}'

ls
helm -n kube-system get values cilium -a > /root/cilium-values-before-fix.yaml
ls
pwd
helm -n kube-system get values cilium -a > /home/sec/cilium-values-before-fix.yaml
history

export API_SERVER_IP=10.16.61.30
export API_SERVER_PORT=6443

helm upgrade cilium cilium/cilium \
  --namespace kube-system \
  --version 1.19.5 \
  --reuse-values \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=${API_SERVER_IP} \
  --set k8sServicePort=${API_SERVER_PORT}

kubectl get po
kubectl get po -A

service firewalld status
service firewalld stop

kubectl get po -A
kubectl get po -A -o wide

kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-

kubectl -n nginx-ingress get deploy nginx-ingress-controller -o yaml | \
  egrep -A20 'nodeSelector|affinity|tolerations|topologySpreadConstraints'

kubectl get nodes --show-labels
kubectl describe node k8s-sec-worker-1 | grep -i taints -A2
kubectl describe node k8s-sec-worker-2 | grep -i taints -A2

kubectl -n nginx-ingress rollout restart deploy/nginx-ingress-controller
kubectl -n nginx-ingress rollout status deploy/nginx-ingress-controller
kubectl -n nginx-ingress get pods -o wide

sudo reboot

helm upgrade cilium oci://quay.io/cilium/charts/cilium \
  --namespace kube-system \
  --version 1.19.5 \
  --reuse-values \
  --set kubeProxyReplacement=true \
  --set l2announcements.enabled=true \
  --set-string k8sServiceHost=10.16.61.30 \
  --set-string k8sServicePort=6443 \
  --set k8sClientRateLimit.qps=50 \
  --set k8sClientRateLimit.burst=100

k get no
history

service firewalld stop
sudo reboot

kubectl get po
systemctl disable firewalld
service firewalld stop
kubectl get po -A
kubectl get po -A

service kubelet status
kubectl get po -A
kubectl get po -A

curl 127.0.0.1:6443

kubectl get po -A
kubectl get po -A
kubectl get po -A
kubectl get po -A
kubectl get po -A
kubectl get po -A
kubectl get po -A
kubectl get po -A
kubectl get po -A
kubectl get po -A

service kubectl status
service kubelet status
service kubelet status
service kubelet status
service kubelet status
service kubelet status -l

ss -lntp | grep 6443
crictl ps -a | egrep 'kube-apiserver|etcd|kube-controller|kube-scheduler'
crictl ps -a | grep etcd
ss -lntp | grep 6443

grep server /etc/kubernetes/kubelet.conf
grep server /etc/kubernetes/admin.conf
grep server /etc/kubernetes/admin.conf

nano /etc/kubernetes/kubelet.conf
service kubelet restart

grep server /etc/kubernetes/admin.conf
service kubelet status

k get po
kubectl get po

grep server /etc/kubernetes/admin.conf
grep server /etc/kubernetes/kubelet.conf
grep server /etc/kubernetes/admin.conf

service firewalld status
ip a

# Đây là một dòng IP:port được nhập, không phải command hợp lệ.
10.16.61.62:16443

curl -k https://10.16.61.30:6443/readyz
curl -k https://10.16.61.30:6443/version
curl -k https://10.16.61.30:6443/readyz
curl -k https://10.16.61.30:6443/version

systemctl restart kubelet
journalctl -u kubelet -f -l

grep server /etc/kubernetes/admin.conf
nano /etc/kubernetes/kubelet.conf
systemctl restart kubelet
journalctl -u kubelet -f -l

kubectl get po
curl 10.16.61.30:6443 -k

ss -lntp | egrep '6443|2379|2380'
crictl ps -a | egrep 'kube-apiserver|etcd|kube-controller|kube-scheduler'
ls -l /etc/kubernetes/manifests/

crictl logs a05589c0b182e | tail -200

APISERVER_ID=$(crictl ps -a --name kube-apiserver -q | head -1)
echo $APISERVER_ID
crictl logs "$APISERVER_ID" | tail -300

ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  endpoint health -w table

ETCD_ID=$(crictl ps --name etcd -q | head -1)
echo $ETCD_ID
crictl logs "$ETCD_ID" | tail -300

k get po
k get po -A

nano /etc/kubernetes/kubelet.conf
service kubelet restart
k get po -A

swapon --show
sudo sed -i.bak '/\bswap\b/s/^/#/' /etc/fstab
reboot

ls
history
k get no
k get no

grep 'server:' /etc/kubernetes/admin.conf

for url in \
  https://127.0.0.1:6443/readyz \
  https://10.16.61.30:6443/readyz \
  https://10.16.61.62:16443/readyz; do
  echo "===== $url ====="
  curl -k -sS --connect-timeout 3 --max-time 10 "$url" || echo "FAILED"
  echo
done

echo '===== SERVICES ====='
systemctl --no-pager --full status containerd kubelet | sed -n '1,80p'

echo
echo '===== LISTEN PORTS ====='
ss -lntp | egrep ':(6443|2379|2380|16443)\b' || true

echo
echo '===== STATIC POD CONTAINERS ====='
crictl ps -a | egrep 'kube-apiserver|etcd|kube-controller-manager|kube-scheduler' || true

echo
echo '===== MANIFESTS ====='
ls -lh /etc/kubernetes/manifests/

echo
echo '===== RESOURCE ====='
uptime
free -h
df -hT / /var/lib/etcd
du -sh /var/lib/etcd 2>/dev/null || true

echo
echo '===== KUBELET LOG ====='
journalctl -u kubelet -n 150 --no-pager

echo '===== API SERVER LOCAL ====='
curl -k --noproxy '*' -sS --connect-timeout 3 --max-time 15 \
  https://127.0.0.1:6443/livez?verbose || echo FAILED

curl -k --noproxy '*' -sS --connect-timeout 3 --max-time 15 \
  https://127.0.0.1:6443/readyz?verbose || echo FAILED

echo
echo '===== APISERVER LOG ====='
APISERVER_ID=$(crictl ps --name kube-apiserver -q | head -1)
echo "$APISERVER_ID"
crictl logs --tail=200 "$APISERVER_ID"

echo
echo '===== VIP / HAPROXY ====='
ip -4 addr show dev ens33 | grep '10.16.61.62' || echo 'VIP NOT PRESENT'
systemctl --no-pager --full status haproxy keepalived | sed -n '1,80p'
grep -nE 'bind|server cp' /etc/haproxy/haproxy.cfg

echo
echo '===== KUBELET API ENDPOINT ====='
grep 'server:' /etc/kubernetes/kubelet.conf /etc/kubernetes/bootstrap-kubelet.conf

echo '===== APISERVER CONTAINERS ====='
crictl ps -a | grep kube-apiserver

echo
echo '===== APISERVER LOGS: current + previous exited ====='
for id in $(crictl ps -a --name kube-apiserver -q | head -5); do
  echo
  echo "========== $id =========="
  crictl inspect "$id" | \
    egrep -i '"state"|"reason"|"exitCode"|"finishedAt"|"startedAt"' | head -20
  echo '----- LOG -----'
  crictl logs --tail=250 "$id"
done

echo '===== ETCD CONTAINERS ====='
crictl ps -a | grep etcd

echo
echo '===== ETCD LOG ====='
for id in $(crictl ps -a --name etcd -q | head -3); do
  echo
  echo "========== $id =========="
  crictl inspect "$id" | \
    egrep -i '"state"|"reason"|"exitCode"|"finishedAt"|"startedAt"' | head -20
  crictl logs --tail=300 "$id"
done

echo
echo '===== APISERVER -> ETCD PARAMETERS ====='
grep -nE -- '--etcd-servers|--etcd-cafile|--etcd-certfile|--etcd-keyfile' \
  /etc/kubernetes/manifests/kube-apiserver.yaml

echo
echo '===== ETCD TLS PARAMETERS ====='
grep -nE -- \
  '--listen-client-urls|--advertise-client-urls|--trusted-ca-file|--cert-file|--key-file|--client-cert-auth|--peer-trusted-ca-file|--peer-cert-file|--peer-key-file' \
  /etc/kubernetes/manifests/etcd.yaml

echo
echo '===== CERT DATES ====='
for f in \
  /etc/kubernetes/pki/etcd/ca.crt \
  /etc/kubernetes/pki/apiserver-etcd-client.crt \
  /etc/kubernetes/pki/etcd/server.crt \
  /etc/kubernetes/pki/etcd/peer.crt; do
  echo "----- $f -----"
  openssl x509 -in "$f" -noout -subject -issuer -dates
done

k get po
k get no

sudo firewall-cmd --list-all
firewall-cmd --list-all

kubeadm version
kubelet --version
kubectl version --client
crictl version

firewall-cmd --reload

for ip in 10.16.61.31 10.16.61.32; do
  echo "===== $ip ====="
  ping -c 2 -W 2 $ip || true
  nc -vz -w 3 $ip 22 || true
  nc -vz -w 3 $ip 2380 || true
  echo
done

k get po
k get po -A
ip a
reboot

ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  endpoint status --write-out=table

command -v etcdctl || true
crictl ps -a --name etcd
crictl logs 7fe377dea9aa6 | tail -n 100

ETCD_ID=$(crictl ps --name etcd -q | head -n1)

crictl exec -it "$ETCD_ID" sh -c '
ETCDCTL_API=3 etcdctl \
  --endpoints=https://10.16.61.30:2379,https://10.16.61.31:2379,https://10.16.61.32:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint status --write-out=table
'

k get no
history

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
systemctl enable --now containerd
systemctl enable --now kubelet
modprobe br_netfilter
modprobe overlay
sysctl -w net.bridge.bridge-nf-call-iptables=1
sysctl -w net.ipv4.ip_forward=1

kubectl get po
kubectl get po -A
ip a

kubectl get ingress
kubectl get ingress -A
kubectl get ingressclasses.networking.k8s.io
kubectl get ciliumendpoints.cilium.io
kubectl get ciliumendpoints.cilium.io -A

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
systemctl enable --now containerd
systemctl enable --now kubelet
modprobe br_netfilter
modprobe overlay
sysctl -w net.bridge.bridge-nf-call-iptables=1
sysctl -w net.ipv4.ip_forward=1

clear

kubectl get nodes -o wide
kubectl get pod -A
kubectl get svc -A

kubectl describe node k8s-sec-worker-2
kubectl describe node k8s-sec-worker-2 | \
  egrep -i "Ready|NetworkUnavailable|Kubelet|Cilium|taint|condition" -A5

kubectl -n kube-system get pod -o wide | egrep "cilium|k8s-sec-worker-2"
kubectl get nodes -o wide

helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm repo update

ls
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

NODES="10.16.61.30 10.16.61.31 10.16.61.32 10.16.61.62"

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

kubectl get nodes
kubectl get po -a
kubectl get po -A
kubectl get svc
kubectl get svc -a
kubectl get svc -a
kubectl get svc -A
kubectl get svc -A
kubectl get nodes
kubectl get nodes
kubectl get nodes -o wide

kubectl get ciliumloadbalancerippools.cilium.io
kubectl get ciliumloadbalancerippools.cilium.io -o yaml
k edit ciliumloadbalancerippools.cilium.io
kubectl get ciliumloadbalancerippools.cilium.io -o yaml

kubectl get nodes -o wide
k get svc -A
k get svc -A
k get svc -A
k get svc -A

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

# Có typo trong command gốc: "nods" thay vì "nodes".
kubectl get nods

kubectl get svc -a
kubectl get svc -A
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

# Có typo trong command gốc: "disble" thay vì "disable".
systemctl disble firewalld

systemctl disable firewalld

k
k get svc -A
kubectl get po -A
kubectl get po -A -o wide

kubectl -n haproxy-ingress describe svc haproxy-kubernetes-ingress
history | grep pool

kubectl get ciliumloadbalancerippools.cilium.io -o yaml
kubectl edit ciliumloadbalancerippools.cilium.io -o yaml