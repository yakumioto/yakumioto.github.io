---
title: 简历
date: 2020-03-04
type: cv
---

# **联系方式**

- 手机: 17610232333
- 邮箱: yaku.mioto@gmail.com

# **个人信息**

- 叶慧杰 / 男 / 1995
- 工作年限: 4年
- 技术博客: <https://mioto.me>
- Github: <https://github.com/yakumioto>
- 期望职位: 区块链高级工程师, Go高级工程师

# **工作经历**

## **北京量化健康科技有限公司** (2016/03 - 2018/03)

### 公司OA系统 (2016/03 - 2018/03)

- 运行环境: Kubernetes + MongoDB + Caddy
- 开发环境: Gland + Mac

**项目简介**:

此项目主要用于连接公司各个部门工作, 涉及 权限管理模块, 人员管理模块, 登录模块, 销售模块, 订单模块, 样品模块, 实验室模块 以及 库存管理模块等

**项目描述**:

1. 使用 Negroni 作为 RETSful API 框架
2. 使用 JWT 作为鉴权验证
3. 使用 RBAC 作为权限控制

学习成果: 

1. 通读了 Negroni 的源码, 对自己有很大的启发, 充分理解了 WEB Middleware 的工作原理
2. 深入了解了各类鉴权方式, 最终采用了无状态鉴权 JWT, 了解了 JWT 的原理等
3. 自行实现了 RBAC 的设计, 对权限控制有了进一步的了解

以上模块在工作期间都有涉及, 项目以 RESTful API Service 形式来给前端提供数据, 对我感触最大的部分就是权限管理模块, 让我充分理解了 WEB Middleware 的工作原理, 以及如何在 RESTful API Service 中实现由前端管理的的权限管理

### 公司灯控门禁系统 (2017/06 - 2017/08)

- 运行环境: RaspberryPi
- 开发环境: Gland + Mac

**项目简介**:

此项目在我去公司前就已经完成, 但是由于开发了OA系统, 就要集成到OA系统中, 转移工作由我负责, 期间涉及了 GPIO, NFC, 以及 DALI(灯控协议)

**项目描述**:

了解了如何 操作 GPIO, 以及 读取 NFC (主要用于读取公交卡中的ID, 作为员工唯一标识刷卡打开门禁), DALI 协议 将公司划分区域组来控制灯

---

## **蔷薇控股股份有限公司** (2018/03 - 至今)

### 正反保理系统区块链化 (2018/03 - 2018/11)

- 运行环境: Docker + Fabric@v1.2
- 开发环境: Gland + Linux

**项目简介**:

将公司原有的保理系统区块链化, 涉及项目设计, 合约编写, 以及部署

**项目描述**:

项目包含多个合约模块: 项目方案, 业务规则, 额度管理, 融资模块, 应收模块, 还款模块 等

### 招商银行行间对账区块链系统 (2019/11 -2019/01)

**项目简介**:

项目用于银行间实现快速对账功能, 实现在区块链上自动对账

**项目描述**:

项目包含 对账合约, 区块链网关, 前端, RESTful API 其中 智能合约 和 RESTful API 是我负责实现的

### Fabric TIDB 支持 (2019/03 - 2019/06)

**项目简介**:

修改 Fabric 源码, 以支持 TIDB

### 苏州银行农商贸溯源区块链系统 (2019/07 - 2019/09)

**项目简介**:

商品功能支持, 会员管理, 商品管理, 订单管理功能, 另外可以溯源商品

**项目描述**:

项目中我主要负责 智能合约部分, 有三个合约 会员管理, 商品管理, 订单管理(包含溯源) 功能

### 日照港口区块链调度系统 (2019/10 - 2019-11)

主要负责线上环境部署

### Fabric TPS 提升优化工作 (2020/03 - 至今)

负责研究 Fabric 源码, 并进行优化工作, 如 Orderer 的并行处理 Block, Peer 的 World State 优化, Peer 的 Block 交付流程优化 等

# **开源项目和作品**

## fabric-sdk-go

<https://github.com/hyperledger/fabric-sdk-go>

官方项目源码贡献, 贡献了 go sdk 支持 java, node 合约安装

## hlf-deploy

**项目简介**:

<https://github.com/yakumioto/alkaid/tree/v0.2.0>

**项目描述**:

项目最初为 hlf-deploy 用于快速部署网络的二进制工具, 项目的优点是操作简单, 一个二进制程序可以实现所有以下操作

1. 通道的 创建, 加入, 更新
2. 合约的 安装, 实例化, 更新, 调用, 查询
3. 组织的动态 加入, 更新, 删除

## Alkaid

**项目简介**:

<https://github.com/yakumioto/alkaid>

目的是实现一个可多方通讯的 BaaS 服务

**项目描述**:

实现一个基于 RESTful 的可跨网的 BaaS 服务, 两个 BaaS 之间可以基于 RESTful 进行通讯, 并组建一个网络

实现以下功能

1. 组织的管理
2. 证书的管理
3. 网络的管理
4. 合约的管理
5. 两个 BaaS 之间的 GRPC 调用

# **技术文章**

Fabric Peer Block 的交付流程详解: <https://mioto.me/2020/06/fab-peer-deliver-block/>
Fabric 中 etcdraft 共识讲解: <https://mioto.me/2020/01/etcdraft-exploration-in-fabric-orderer/>
Go Slice 原理解析: <https://mioto.me/2018/03/go-slice-analysis/>

# **技能清单**

以下均为我熟练使用的技能

- 语言: Go / Python
- Web框架: Negroni / Beego / Gin
- 区块链: Hyperledger Fabric
- 数据库: MySQL / PgSQL / SQLite / MongoDB
- 版本管理: Git
- CICD: Drone / Github Action
- 云: Docker / Docker Swarm / Kubernetes

# **致谢**

感谢您花时间阅读我的简历, 期待能有机会和您共事
