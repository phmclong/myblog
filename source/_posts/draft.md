# Tutorial cấu hình Network, CNI Cilium, LoadBalancer và Ingress Kubernetes

## 0. Mô hình IP cần thống nhất trước khi thao tác

Trong lịch sử cấu hình, các IP được sử dụng như sau:

```text
Control plane 1:        10.16.61.30
Control plane 2:        10.16.61.31
Control plane 3:        10.16.61.32

API VIP HAProxy:        10.16.61.62
API VIP port:           16443

Ingress LoadBalancer:   10.16.61.63

Mạng quản trị SSH:      10.2.15.0/24
Network interface:      ens33
```

> Lưu ý: trong history từng có IP `10.16.31.61` và `10.16.61.61`. Đây không phải IP LoadBalancer cuối cùng đã khai báo cho HAProxy Ingress. IP LoadBalancer đúng trong file values là `10.16.61.63`.

---

# PHẦN B — Kiểm tra Kubernetes API HAProxy và Keepalived

Lịch sử cho thấy API VIP dự kiến là:

```text
10.16.61.62:16443
```

## Step 5. Kiểm tra VIP đang nằm trên node nào

```bash
ip -4 addr show dev ens33 | grep '10.16.61.62' || echo 'VIP NOT PRESENT'
```

Node nào có output `10.16.61.62` là node đang giữ VIP của Keepalived.

---

## Step 6. Kiểm tra HAProxy và Keepalived

```bash
systemctl status haproxy keepalived --no-pager -l
```

Kiểm tra HAProxy đang listen cổng API VIP:

```bash
ss -lntp | egrep ':(6443|16443)\b'
```

Kiểm tra cấu hình backend API server:

```bash
grep -nA12 -B3 'k8s-api-backend' /etc/haproxy/haproxy.cfg
```

Cấu hình backend cần có đủ ba API server:

```text
10.16.61.30:6443
10.16.61.31:6443
10.16.61.32:6443
```

---

## Step 7. Kiểm tra health API server

```bash
for url in \
  https://127.0.0.1:6443/readyz \
  https://10.16.61.30:6443/readyz \
  https://10.16.61.62:16443/readyz; do
  echo "===== $url ====="
  curl -k -sS --connect-timeout 3 --max-time 10 "$url" || echo "FAILED"
  echo
done
```

Kết quả đúng cần có:

```text
ok
```

Đặc biệt cần kiểm tra API VIP:

```bash
curl -k https://10.16.61.62:16443/readyz
```

---

# PHẦN C — Kiểm tra và chuẩn hóa endpoint Kubernetes

## Step 8. Kiểm tra endpoint mà kubectl đang sử dụng

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}{"\n"}'
```

Kiểm tra endpoint của kubelet:

```bash
grep 'server:' /etc/kubernetes/kubelet.conf
grep 'server:' /etc/kubernetes/bootstrap-kubelet.conf
grep 'server:' /etc/kubernetes/admin.conf
```

Với mô hình HA, endpoint nên thống nhất là:

```text
https://10.16.61.62:16443
```

> Không nên để Cilium, kubelet hoặc kubectl trỏ cố định vào riêng `10.16.61.30:6443`, vì khi control plane `.30` lỗi, các node khác vẫn có thể hoạt động nhưng CNI sẽ mất đường gọi API.

---

# PHẦN D — Backup và kiểm tra cấu hình Cilium hiện tại

## Step 9. Backup toàn bộ Cilium Helm values

```bash
helm -n kube-system get values cilium -a > /root/cilium-values-before-fix.yaml
```

Hoặc lưu tại thư mục người dùng:

```bash
helm -n kube-system get values cilium -a > /home/sec/cilium-values-before-fix.yaml
```

Kiểm tra các cấu hình quan trọng:

```bash
helm -n kube-system get values cilium -a | \
egrep 'kubeProxyReplacement|k8sServiceHost|k8sServicePort|l2announcements|routingMode|tunnelProtocol|devices|mtu'
```

---

## Step 10. Kiểm tra pod Cilium

```bash
kubectl -n kube-system get pods -o wide | grep cilium
```

Kiểm tra endpoint Cilium:

```bash
kubectl get ciliumendpoints.cilium.io -A
```

Kiểm tra node:

```bash
kubectl get nodes -o wide
kubectl describe node k8s-sec-worker-2 | \
egrep -i "Ready|NetworkUnavailable|Kubelet|Cilium|taint|condition" -A5
```

---

# PHẦN E — Cấu hình Cilium kube-proxy replacement và L2 Announcement

Lịch sử đã dùng các tham số:

```text
kubeProxyReplacement=true
l2announcements.enabled=true
k8sClientRateLimit.qps=50
k8sClientRateLimit.burst=100
```

Tuy nhiên lịch sử từng trỏ Cilium vào `10.16.61.30:6443`. Tutorial này dùng API VIP HA là `10.16.61.62:16443`.

## Step 11. Upgrade Cilium bằng endpoint API HA

```bash
helm upgrade cilium oci://quay.io/cilium/charts/cilium \
  --namespace kube-system \
  --version 1.19.5 \
  --reuse-values \
  --set kubeProxyReplacement=true \
  --set l2announcements.enabled=true \
  --set-string k8sServiceHost=10.16.61.62 \
  --set-string k8sServicePort=16443 \
  --set k8sClientRateLimit.qps=50 \
  --set k8sClientRateLimit.burst=100
```

Theo dõi rollout:

```bash
kubectl -n kube-system rollout status daemonset/cilium
kubectl -n kube-system get pods -o wide | grep cilium
```

> Không restart hoặc reboot tất cả node cùng lúc sau khi upgrade Cilium. Thực hiện lần lượt để tránh làm cluster mất hoàn toàn networking.

---

# PHẦN F — Cấu hình Cilium LoadBalancer IP Pool

## Step 12. Kiểm tra pool hiện tại

```bash
kubectl get ciliumloadbalancerippools.cilium.io
kubectl get ciliumloadbalancerippools.cilium.io -o yaml
```

Nếu chưa có pool cho Ingress VIP `10.16.61.63`, tạo file:

```bash
cat <<'EOF' > cilium-lb-pool.yaml
apiVersion: cilium.io/v2
kind: CiliumLoadBalancerIPPool
metadata:
  name: ingress-lb-pool
spec:
  blocks:
    - start: 10.16.61.63
      stop: 10.16.61.63
EOF
```

Apply:

```bash
kubectl apply -f cilium-lb-pool.yaml
```

Kiểm tra lại:

```bash
kubectl get ciliumloadbalancerippools.cilium.io -o yaml
```

> IP `10.16.61.63` không được trùng IP node, DHCP range, API VIP `.62`, hoặc một thiết bị khác trong LAN.

---

# PHẦN G — Cấu hình Cilium L2 Announcement Policy

Bật `l2announcements.enabled=true` chưa đủ. Cần có `CiliumL2AnnouncementPolicy` để Cilium biết Service và node nào được quyền trả lời ARP cho VIP.

## Step 13. Label các worker làm ingress node

```bash
kubectl label node k8s-sec-worker-1 ingress-ready=true
kubectl label node k8s-sec-worker-2 ingress-ready=true
```

Kiểm tra:

```bash
kubectl get nodes --show-labels
```

---

## Step 14. Tạo L2 Announcement Policy

```bash
cat <<'EOF' > cilium-l2-ingress-policy.yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: ingress-l2-policy
spec:
  serviceSelector:
    matchLabels:
      app.kubernetes.io/name: haproxy-kubernetes-ingress
  nodeSelector:
    matchLabels:
      ingress-ready: "true"
  interfaces:
    - ^ens33$
  loadBalancerIPs: true
EOF
```

Apply policy:

```bash
kubectl apply -f cilium-l2-ingress-policy.yaml
```

Kiểm tra:

```bash
kubectl get ciliuml2announcementpolicy -A
kubectl get ciliuml2announcementpolicy ingress-l2-policy -o yaml
```

Lịch sử có kiểm tra các thành phần sau:

```bash
kubectl get ciliuml2announcementpolicy -A
kubectl get ciliumbgppeeringpolicy -A 2>/dev/null
kubectl get ciliumbgpadvertisement -A 2>/dev/null
```

Mục đích là xác định cluster đang dùng L2 Announcement hay BGP để quảng bá IP LoadBalancer.

---

# PHẦN H — Cài HAProxy Kubernetes Ingress

## Step 15. Thêm Helm repository

```bash
helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm repo update
```

Tạo thư mục làm việc:

```bash
mkdir -p ~/ha_proxy
cd ~/ha_proxy
```

---

## Step 16. Tạo file values cho HAProxy Ingress

```bash
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
```

Ý nghĩa:

```text
replicaCount: 3
→ Chạy ba HAProxy Ingress Controller pods.

ingressClass: haproxy
→ Các Ingress khai báo ingressClassName: haproxy sẽ được HAProxy xử lý.

type: LoadBalancer
→ Kubernetes tạo Service LoadBalancer.

lbipam.cilium.io/ips: 10.16.61.63
→ Yêu cầu Cilium cấp đúng VIP 10.16.61.63 cho Service này.
```

---

## Step 17. Cài đặt HAProxy Ingress

```bash
helm upgrade --install haproxy-kubernetes-ingress \
  haproxytech/kubernetes-ingress \
  --namespace haproxy-ingress \
  --create-namespace \
  -f values-haproxy-ingress.yaml
```

Theo dõi rollout:

```bash
kubectl -n haproxy-ingress rollout status deployment/haproxy-kubernetes-ingress
kubectl -n haproxy-ingress get pods -o wide
```

Kiểm tra Service và External IP:

```bash
kubectl -n haproxy-ingress get svc
kubectl -n haproxy-ingress describe svc haproxy-kubernetes-ingress
```

Kết quả mong đợi:

```text
EXTERNAL-IP: 10.16.61.63
```

Lịch sử cũng có kiểm tra tổng hợp:

```bash
kubectl get svc -A
kubectl get svc -A | grep -iE 'ingress|nginx'
```

---

# PHẦN I — Firewall: cách làm an toàn hơn

Trong history có các lệnh:

```bash
iptables -P INPUT DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

và các lệnh trộn giữa `iptables` và `firewalld`. Không nên áp dụng lại nguyên trạng vì:

- Có lệnh sử dụng sai IP `10.16.31.61`.
- Có lúc dùng `.61`, trong khi Ingress VIP là `.63`.
- Có thao tác mở NodePort cố định `32409`, `31865`.
- Có thao tác bật/tắt `firewalld` xen lẫn với `iptables`.
- `iptables -D INPUT 13` hoặc `iptables -D INPUT 14` có thể xóa nhầm rule khi thứ tự chain đã thay đổi.

## Step 18. Chọn một cơ chế firewall

Khuyến nghị dùng `firewalld`, không trộn với iptables thủ công.

Kiểm tra firewall hiện tại:

```bash
firewall-cmd --list-all
firewall-cmd --list-rich-rules
```

---

## Step 19. Mở SSH từ mạng quản trị

```bash
firewall-cmd --permanent \
  --add-rich-rule='rule family=ipv4 source address=10.2.15.0/24 port port=22 protocol=tcp accept'
```

---

## Step 20. Mở HTTP/HTTPS cho HAProxy Ingress

Do Cilium L2 có thể chuyển VIP `.63` giữa các worker, mở cổng 80/443 trên các worker có label `ingress-ready=true`.

```bash
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
```

Kiểm tra:

```bash
firewall-cmd --list-ports
```

---

## Step 21. Không mở NodePort cho client nếu đã dùng LoadBalancer VIP

Các lệnh sau từng được dùng để mở NodePort:

```bash
iptables -I INPUT 2 -p tcp -m multiport --dports 32409,31865 -j ACCEPT
```

Không cần dùng lại nếu client truy cập qua:

```text
http://10.16.61.63
https://10.16.61.63
```

NodePort chỉ nên mở khi có yêu cầu đặc biệt về test hoặc thiết kế network.

---

# PHẦN J — Kiểm tra trạng thái cluster sau cấu hình

## Step 22. Kiểm tra Kubernetes node và pod

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
kubectl get ingressclasses.networking.k8s.io
```

---

## Step 23. Kiểm tra Cilium datapath

```bash
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose
```

Kiểm tra Cilium health:

```bash
kubectl -n kube-system exec ds/cilium -- cilium-health status
```

Kiểm tra Service mapping:

```bash
kubectl -n kube-system exec ds/cilium -- \
  cilium-dbg service list | grep 10.16.61.63
```

---

## Step 24. Kiểm tra VIP từ một máy cùng LAN

Từ máy thuộc cùng subnet với cluster:

```bash
ping 10.16.61.63
curl -I http://10.16.61.63
curl -k -I https://10.16.61.63
```

Kiểm tra ARP:

```bash
arp -a | grep 10.16.61.63
```

Nếu VIP không phản hồi:

1. Kiểm tra `CiliumLoadBalancerIPPool`.
2. Kiểm tra `CiliumL2AnnouncementPolicy`.
3. Kiểm tra Service có đúng label selector hay không.
4. Kiểm tra `ens33` có phải interface LAN thực tế.
5. Kiểm tra firewall 80/443 trên worker.
6. Kiểm tra Cilium pod trên worker có Running hay không.

---

# PHẦN K — Quy trình xử lý khi API server không lên cổng 6443

Trong lịch sử từng có lỗi:

```text
curl: (7) Failed to connect to 10.16.61.30 port 6443: Connection refused
```

Khi gặp lỗi này, chạy theo thứ tự sau.

## Step 25. Kiểm tra cổng API server và etcd

```bash
ss -lntp | egrep ':(6443|2379|2380|16443)\b'
```

---

## Step 26. Kiểm tra static pods

```bash
crictl ps -a | \
egrep 'kube-apiserver|etcd|kube-controller-manager|kube-scheduler'
```

Kiểm tra manifest:

```bash
ls -lh /etc/kubernetes/manifests/
```

---

## Step 27. Kiểm tra kubelet

```bash
systemctl status kubelet --no-pager -l
journalctl -u kubelet -n 150 --no-pager
```

---

## Step 28. Kiểm tra log kube-apiserver và etcd

```bash
APISERVER_ID=$(crictl ps -a --name kube-apiserver -q | head -1)
crictl logs --tail=200 "$APISERVER_ID"
```

```bash
ETCD_ID=$(crictl ps --name etcd -q | head -1)
crictl logs --tail=300 "$ETCD_ID"
```

---

## Step 29. Kiểm tra etcd local health

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  endpoint health -w table
```

Kiểm tra cả cụm etcd:

```bash
ETCD_ID=$(crictl ps --name etcd -q | head -n1)

crictl exec -it "$ETCD_ID" sh -c '
ETCDCTL_API=3 etcdctl \
  --endpoints=https://10.16.61.30:2379,https://10.16.61.31:2379,https://10.16.61.32:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint status --write-out=table
'
```

---

# Luồng network cuối cùng sau khi hoàn thiện

```text
Client
  │
  │ HTTP / HTTPS
  ▼
10.16.61.63
Cilium LoadBalancer IP
  │
  │ Cilium L2 Announcement trả lời ARP
  ▼
Worker có label ingress-ready=true
  │
  ▼
HAProxy Ingress Controller
  │
  ▼
Kubernetes Service
  │
  ▼
Application Pod
```

Luồng quản trị cluster:

```text
kubectl / kubelet / Cilium Agent
  │
  ▼
10.16.61.62:16443
HAProxy + Keepalived API VIP
  │
  ▼
10.16.61.30:6443
10.16.61.31:6443
10.16.61.32:6443
```

# Checklist nghiệm thu cuối cùng

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl -n kube-system get pods -o wide | grep cilium

kubectl get ciliumloadbalancerippools
kubectl get ciliuml2announcementpolicy

kubectl -n haproxy-ingress get svc
kubectl -n haproxy-ingress get pods -o wide

curl -k https://10.16.61.62:16443/readyz
curl -I http://10.16.61.63
```

Kết quả đúng:

```text
- Tất cả node: Ready
- Cilium: Running trên toàn bộ node
- API VIP .62:16443 trả về ok
- HAProxy Ingress Service nhận EXTERNAL-IP .63
- Cilium LB pool có IP .63
- Cilium L2 policy tồn tại
- Client LAN truy cập được HTTP/HTTPS qua .63
```
