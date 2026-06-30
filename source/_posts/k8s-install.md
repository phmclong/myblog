---
title: Install k8s với kubeadm
date: 2026-06-28 20:00:00
tags: [DevOps, k8s]
categories:
  - DevOps
---

# I. Lời nói đầu

Note lại quá trình triển khai 1 k8s cluster nho nhỏ với 1 controlplane + 2 worker.

Tôi ko triển khai ở quy mô lớn nên ko dùng `kubespray` hay `ansible`.

# II. Tổng quan kiến trúc

> Hệ điều hành: 3 máy đều sử dụng RHEL 9.x
> Kubernetes: v1.36.  
> Runtime: containerd.  
> CNI: Cilium, VXLAN.  
> CSI: Ceph
> Ingress: F5 NGINX Ingress

| Vai trò       | Hostname               | IP         |
| ------------- | ---------------------- | ---------- |
| Control Plane | `k8s-sec-controlplane` | `10.0.1.1` |
| Worker 1      | `k8s-sec-worker-1`     | `10.0.1.2` |
| Worker 2      | `k8s-sec-worker-1`     | `10.0.1.3` |

# III. Chuẩn bị

## 3.1. Đặt hostname

Trên Control Plane:

```bash
sudo hostnamectl set-hostname k8s-sec-controlplane
```

Trên Worker 1:

```bash
sudo hostnamectl set-hostname k8s-sec-worker-1
```

Trên Worker 2:

```bash
sudo hostnamectl set-hostname k8s-sec-worker-2
```

Kiểm tra:

```bash
hostnamectl --static
```

## 3.2 Update RHEL và tắt swap

```bash
sudo dnf update -y
sudo swapoff -a
```

Tắt swap vĩnh viễn:

```bash
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
sudo systemctl daemon-reload

swapon --show
free -h
```

`swapon --show` không trả kết quả là đúng.

Nếu `dnf update` vừa nâng kernel, reboot node trước khi đi tiếp:

```bash
sudo reboot
```

## 3.3. Hardening với SELinux

Bật SELinux ở chế độ `permissive`:

```bash
getenforce

sudo setenforce 0
sudo sed -ri 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

getenforce
```

Kết quả mong muốn:

```text
Permissive
```

Không đặt `SELINUX=disabled`; `permissive` vẫn ghi audit log và dễ troubleshoot hơn.

## 3.4 Kernel modules và sysctl

Chuẩn bị kernel networking cho Kubernetes giúp Pod, Service và CNI (Calico, Cilium...) có thể định tuyến và áp dụng firewall/network policy đúng cách.

### 3.4.1. Load kernel modules

```bash
sudo tee /etc/modules-load.d/k8s.conf >/dev/null <<'EOF'
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

Tác dụng:

- `overlay`: hỗ trợ **OverlayFS**, cơ chế filesystem mà container runtime như containerd/Docker thường dùng để tạo layer image và filesystem cho container.
- `br_netfilter`: cho phép các gói tin đi qua Linux bridge được xử lý bởi cơ chế firewall của Linux (`iptables`/`nftables`).

Hai lệnh này load module **ngay tại thời điểm chạy**.

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

File `/etc/modules-load.d/k8s.conf` giúp hai module này được **tự động load lại sau mỗi lần reboot**.

### 3.4.2. Cấu hình sysctl cho network Kubernetes

```bash
sudo tee /etc/sysctl.d/k8s.conf >/dev/null <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```

Dòng `sudo sysctl --system` đọc và áp dụng các file cấu hình sysctl. Dòng `/etc/sysctl.d/k8s.conf` giúp cấu hình có hiệu lực ngay và vẫn được giữ sau khi reboot.

Xác nhận hai kernel module đã được load.

```bash
lsmod | grep -E 'overlay|br_netfilter'
sysctl net.ipv4.ip_forward
```

Kiểm tra thấy `net.ipv4.ip_forward = 1` là cấu hình đã nhận, node đã được phép route/forward traffic IPv4.

Ý nghĩa:

| Cấu hình                                  | Tác dụng                                                                                                                                                              |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `net.bridge.bridge-nf-call-iptables = 1`  | Cho phép traffic IPv4 đi qua Linux bridge được kiểm tra bởi `iptables`. Quan trọng để kube-proxy, NetworkPolicy và firewall rule hoạt động đúng.                      |
| `net.bridge.bridge-nf-call-ip6tables = 1` | Tương tự nhưng áp dụng cho traffic IPv6.                                                                                                                              |
| `net.ipv4.ip_forward = 1`                 | Cho phép máy Linux chuyển tiếp gói tin giữa các network interface. Node Kubernetes cần điều này để chuyển traffic giữa Pod, Service, node khác và mạng ngoài cluster. |

Ví dụ: Pod A gửi traffic đến Pod B nằm trên node khác. Node phải có khả năng **forward packet** sang interface/network phù hợp. Nếu `ip_forward = 0`, traffic có thể bị chặn ngay tại node.

# IV. Cài container runtime

Sử dụng **containerd** làm **container runtime**. Tiến hành cài đặt **containerd** trên cả 3 node.

## 4.1 Kiểm tra xung đột package

```bash
rpm -q podman runc containerd containerd.io || true
```

Nếu node đang chạy Podman/container workload, không gỡ vội. Hãy chuyển workload sang node khác hoặc chọn runtime CRI-O thay vì containerd.

Với node mới, chuyên dụng cho Kubernetes:

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y containerd.io
```

## 4.2 Cấu hình cgroup driver `systemd`

```bash
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

Khởi động và kiểm tra:

```bash
sudo systemctl enable --now containerd
sudo systemctl restart containerd

sudo systemctl status containerd --no-pager
grep -n 'SystemdCgroup' /etc/containerd/config.toml
```

Phải thấy:

```text
SystemdCgroup = true
```

Kiểm tra CRI socket:

```bash
sudo test -S /run/containerd/containerd.sock && echo "containerd CRI socket OK"
```

> Không khởi động dịch vụ `docker`; Kubernetes dùng trực tiếp containerd thông qua CRI socket `/run/containerd/containerd.sock`.

# V. Cài kubeadm, kubelet, kubectl, crictl

## 5.1 Khai báo Kubernetes RPM repository

```bash
cat <<'EOF' | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
```

## 5.2 Cài package

```bash
sudo dnf makecache

sudo dnf install -y \
  kubelet kubeadm kubectl cri-tools \
  --disableexcludes=kubernetes
```

Bật kubelet:

```bash
sudo systemctl enable --now kubelet
```

Kubelet có thể báo lỗi hoặc restart loop trước khi chạy `kubeadm init/join`; đây là trạng thái bình thường vì nó chưa có cấu hình cluster.

Cấu hình `crictl` để troubleshoot containerd:

```bash
sudo tee /etc/crictl.yaml >/dev/null <<'EOF'
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
```

Kiểm tra phiên bản:

```bash
kubeadm version
kubelet --version
kubectl version --client
crictl version
```

# VI. Set up Controlplane

## 6.1. Khởi tạo Control Plane

### 6.1.1. Pull image Kubernetes

```bash
sudo kubeadm config images pull \
  --cri-socket unix:///run/containerd/containerd.sock
```

### 6.1.2. Khởi tạo cluster

```bash
sudo kubeadm init \
  --apiserver-advertise-address=10.10.10.11 \
  --pod-network-cidr=172.20.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --cri-socket unix:///run/containerd/containerd.sock
```

Khi lệnh hoàn tất, lưu lại toàn bộ lệnh `kubeadm join ...` ở cuối output.

### 6.1.3. Cấu hình kubectl cho user đang đăng nhập

```bash
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
```

Kiểm tra:

```bash
kubectl get nodes
kubectl get pods -A
```

Lúc này Control Plane thường ở trạng thái `NotReady`; CoreDNS có thể `Pending` do chưa cài CNI.

Nếu mất join command:

```bash
kubeadm token create --print-join-command
```

## 6.2. Cài Helm trên Control Plane

```bash
curl -fsSL -o get_helm.sh \
  https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4

chmod 700 get_helm.sh
sudo ./get_helm.sh

helm version
```

Helm **đã được copy vào** `/usr/local/bin/helm`, nhưng thư mục `/usr/local/bin` chưa nằm trong biến môi trường `PATH` của user hiện tại.

Kiểm tra file đã có chưa:

```bash
ls -l /usr/local/bin/helm
```

Nếu thấy file `helm`, chạy ngay bằng đường dẫn đầy đủ:

```bash
/usr/local/bin/helm version
```

Sau đó thêm tạm thời vào `PATH` cho phiên shell hiện tại:

```bash
export PATH=$PATH:/usr/local/bin
helm version
```

Để giữ vĩnh viễn cho user `root`:

```bash
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc

helm version
```

Hoặc cách gọn hơn, tạo symbolic link vào `/usr/bin` vì thư mục này thường đã có trong `PATH`:

```bash
ln -s /usr/local/bin/helm /usr/bin/helm
helm version
```

Chỉ cần dùng **một** trong hai cách trên. Tôi khuyên dùng cách thêm `PATH`:

```bash
export PATH=$PATH:/usr/local/bin
helm version
```

# VII. Triển khai CNI

# VIII. Triển khai CSI
