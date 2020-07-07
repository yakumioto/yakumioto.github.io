---
title: 简历
date: 2020-03-04
type: cv
---

## **联系方式**

- 手机: 17610232333
- 邮箱: yaku.mioto@gmail.com

## **个人信息**

- 叶慧杰 / 男 / 1995
- 工作年限: 4年
- 技术博客: <https://mioto.me>
- Github: <https://github.com/yakumioto>
- 期望职位: 区块链高级工程师, Go高级工程师

## **工作经历**

### **北京量化健康科技有限公司** (2016/03 - 2018/03)

#### 公司OA系统 (2016/03 - 2018/03)

此项目主要用于连接公司各个部门工作, 涉及 权限管理模块, 人员管理模块, 登录模块, 销售模块, 订单模块, 样品模块, 实验室模块 以及 库存管理模块等

**项目描述**:

1. 使用 Negroni 作为 RETSful API Service 框架
2. 使用 JWT 作为鉴权验证中间件
3. 使用 RBAC 作为权限控制中间件
4. 基于 Dockerfile 进行容器创建
5. 基于 Kubernetes 进行集群部署
6. 使用 Caddy 进行负载均衡

#### 公司灯控门禁系统 (2017/06 - 2017/08)

此项目在我去公司前就已经完成, 但是由于开发了OA系统, 就要集成到OA系统中, 转移工作由我负责, 期间涉及了 GPIO, NFC, 以及 DALI(灯控协议)

**项目描述**:

1. 使用 Negroni 作为 RETSful API Service 框架
2. 使用 GPIO 控制 NFC 模块
3. 使用 DALI 协议与灯控模组通讯
4. 使用 RaspbeeryPI + DFRobot NFC 进行部署

---

### **蔷薇控股股份有限公司** (2018/03 - 至今)

#### 正反保理系统区块链化 (2018/03 - 2018/11)

将公司原有的保理系统区块链化, 涉及项目设计, 合约编写, 以及部署

**项目描述**:

1. 开发了 项目方案, 业务规则, 额度管理, 融资模块, 应收模块, 还款 等多个智能合约
2. 使用 CouchDB 作为 World State, 更好的应付业务的复杂度
3. 使用 Chaincode Event 和外部系统进行交互
4. 基于 Kubernetes 进行网络部署

#### 招商银行行间对账区块链系统 (2019/11 -2019/01)

项目用于银行间实现快速对账功能, 实现在区块链上自动对账

项目包含 对账合约, 区块链网关, 前端, RESTful API 服务

**项目描述**:

1. 行间对账合约, 甲方和乙方银行同时上传订单进行特定(自定义)的字段校验, 并自动标记对账状态
2. 基于 RESTful API 提供服务, 通过 区块链网关 获取 区块链网络 中的数据并在前端进行数据展示
3. 基于 Docker Swarm 进行网络以及前后端的部署

#### Fabric TIDB 支持 (2019/03 - 2019/06)

实现 Fabric World State 接口, 以支持 TIDB 数据库

**项目描述**:

1. 使用 SQL 进行通讯, 意味着同时支持 MySQL, MariaDB, PostgreSQL
2. 实现了 VersionedDB 所有接口, 支持 Rich query

#### 苏州银行农商贸溯源区块链系统 (2019/07 - 2019/09)

商品功能支持, 会员管理, 商品管理, 订单管理功能, 另外可以溯源商品

**项目描述**:

1. 开发了 会员管理, 商品管理, 订单管理 合约
2. 使用 Docker Swarm 进行部署

#### 日照港口区块链调度系统 (2019/10 - 2019-11)

主要负责线上环境部署

**项目描述**:

1. 由于涉及的机器较多, 稳定性要求, 所以采用了 Docker Swarm 进行网络部署
2. 实现了一套基于 Bash 的自动化脚本, 包含 创建网络, 启动网络, 停止网络, 删除网络(用于开发环境)

#### Fabric TPS 提升优化工作 (2020/03 - 至今)

负责优化 Fabric 源码, 以提升 TPS

**项目描述**:

1. Orderer Kafka 中传输的 Payload 大小 以减轻网络传输的压力
2. Orderer 的并行处理, 当接受到消息后就交由一个 Goroutine 进行处理, 以保证最大的 CPU 利用率
3. Peer 中的 World State 使用了基于 Map 的数据结构并将数据始终保存在内存中对大化减少网络以及磁盘的消耗
4. Peer Block 交付时进行区块的缓存, 避免向下传递导致的多次反序列化造成的 CPU 损耗

## **开源项目和作品**

### fabric-sdk-go

官方项目源码贡献

<https://github.com/hyperledger/fabric-sdk-go>

**项目描述**:

1. 支持 Java 合约的安装, 实例化, 升级
2. 支持 Node 合约的安装, 实例化, 升级

### hlf-deploy

用于快速部署网络的二进制工具, 项目的优点是操作简单, 一个二进制程序可以实现所有以下操作

<https://github.com/yakumioto/alkaid/tree/v0.2.0>

**项目描述**:

1. 支持通道的 创建, 加入, 更新
2. 支持合约的 安装, 实例化, 更新, 调用, 查询
3. 支持组织的动态 加入, 更新, 删除

### Alkaid (开发中)

**项目简介**:

实现一个可多方交互的 BaaS 服务

基于 RESTful 的可跨网的 BaaS 服务, 两个 BaaS 之间可以基于 RESTful 进行通讯, 并组建一个网络

<https://github.com/yakumioto/alkaid>

**项目描述**:

1. 组织的管理
2. 证书的管理
3. 网络的管理
4. 合约的管理
5. 两个 BaaS 之间的 GRPC 调用

## **其他技能**

1. Kubernetes 集群的搭建与使用
2. 基于 Github 的 CI/CD 流程, 编写过 Github Action 的应用
3. 基于 Drone 的 CI/CD 流程, 编写过 Drone 的应用在  DockerHub 上有 4k 的下载量
4. 部署过私有的 Docker 镜像仓库, 基于 registry
5. 部署过私有的 Git 仓库, 基于 Gogs, 与 Drone 和 Dockers Registry 组合形成一套完整的敏捷开发

## **技术文章**

Fabric Peer Block 的交付流程详解: <https://mioto.me/2020/06/fab-peer-deliver-block/>
Fabric 中 etcdraft 共识讲解: <https://mioto.me/2020/01/etcdraft-exploration-in-fabric-orderer/>
Go Slice 原理解析: <https://mioto.me/2018/03/go-slice-analysis/>

## **技能清单**

以下均为我熟练使用的技能

- 系统: Linux(5年) / Mac(2年)
- 语言: Go / Python
- Web框架: Negroni / Beego / Gin
- 区块链: Hyperledger Fabric
- 数据库: MySQL / PgSQL / SQLite / MongoDB
- 版本管理: Git
- CICD: Drone / Github Action
- 云: Docker / Docker Swarm / Kubernetes

## **致谢**

感谢您花时间阅读我的简历, 期待能有机会和您共事
