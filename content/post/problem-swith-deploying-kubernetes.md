---
categories:
- 学习
date: "2019-05-29"
tags:
- Kubernetes
title: 部署 Kubernetes 遇到的问题
---

## Unable to update cni config: No networks found in /etc/cni/net.d

由于设置了代理导致的错误, `kubelet` 无法通过代理链接到 `kube-apiserve`

解决办法:

```bash
unset http_proxy https_proxy
# or
export no_proxy=<your_kube_apiserver_ip>
```

## port 10251 and 10252 are in use

多次 `init` 导致的错误

解决办法:

```bash
kubeadm reset
```

## ROLES  none

关于 `ROLES <none>` 的问题, 据说在 `kubeadm join` 的时候可以指定, 不过我每次都没看..

解决办法:

```bash
# 添加标签
kubectl label node {node name} node-role.kubernetes.io/{key}={value}
# example
kubectl label node host2 node-role.kubernetes.io/node2=node2

# 删除标签
kubectl label node {node name} node-role.kubernetes.io/{key}-
# example
kubectl label node host2 node-role.kubernetes.io/node2-
```

## 让 Master 也进行 Pod 调度

在开发环境上 `master` 也进行 `Pod` 调度是个不错的选择

```bash
# 允许调度 pod
kubectl taint node {node name} node-role.kubernetes.io/master-
# example
kubectl taint node host1 node-role.kubernetes.io/master-

# 禁止调度 pod
kubectl taint node {node name} node-role.kubernetes.io/master=master
# example
kubectl taint node host1 node-role.kubernetes.io/master=master
```

## 有时可能过了一段时间需要添加新的 `node`

```bash
# 生成一个 token
kubeadm token generate
# 获取证书的 hash 值
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
>    openssl dgst -sha256 -hex | sed 's/^.* //'
# kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
# example
kubeadm join --token xf96mj.aq2c5v14r62rf2aw 172.16.50.10:6443  --discovery-token-ca-cert-hash sha256:a18c59189884451f71305a0107d15b79a8ac091ef9a8b9e394cad5d4b9f18162
```
