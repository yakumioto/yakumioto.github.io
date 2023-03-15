---
categories:
- 学习
date: "2020-01-15"
tags:
- Hyperledger Fabric
- Go
title: Fabric 中 etcdraft 共识讲解
---

为什么要通过 `etcdraft` 来进行共识?

我觉得有以下原因

1. `solo` 并不适合大多数场景, 例如: 组织A, 组织B, 都想在自己放置共识节点
2. `kafka` 虽然能满足以上需求, 但是 `kafka` 加上 `zookeeper` 需要额外部署并且实在是太重了, 不方便部署

所以基于 `etcdraft` 的共识来了, 解决了以上的痛点

重要的话说三遍!

千万不要错过文章中的源码部分, 里面有很多很多的注释!!!
千万不要错过文章中的源码部分, 里面有很多很多的注释!!!
千万不要错过文章中的源码部分, 里面有很多很多的注释!!!

## 核心接口

以下是我认为实现 etcdraft 共识核心的接口

```go
// ClusterServer 集群Server接口
type ClusterServer interface {
    Step(Cluster_StepServer) error
}

// ClusterClient 集群Client接口
type ClusterClient interface {
    Step(ctx context.Context, opts ...grpc.CallOption) (orderer.Cluster_StepClient, error)
}

// Handler 用于共识的两个接口
type Handler interface {
    OnConsensus(channel string, sender uint64, req *orderer.ConsensusRequest) error
    OnSubmit(channel string, sender uint64, req *orderer.SubmitRequest) error
}

// Consenter 共识排序接口
type Consenter interface {
    HandleChain(support ConsenterSupport, metadata *cb.Metadata) (Chain, error)
}

// Chain 共识核心的接口
type Chain interface {
    // 接收普通的交易消息
    Order(env *cb.Envelope, configSeq uint64) error
    // 接收配置消息
    Configure(config *cb.Envelope, configSeq uint64) error
    WaitReady() error
    Errored() <-chan struct{}
    Start()
    Halt()
}
```

## Orderer初始化

启动 `etcd` 节点是需要设置 `ETCD_NAME` 的, 也就是节点的 `ID`, 但是在启动 `Orderer` 的时候我们并没有做相关的设置, 我觉得设计很巧妙

如果你启动过 [fabric-samples/first-network](https://github.com/hyperledger/fabric-samples/tree/release-1.4/first-network) 你应该知道里面的 `configtx.yaml`, 用于生成 `genesis.blok`

`genesis.block` 中可以设置 `OrdererType`, 以及 `EtcdRaft` 相关的配置

```yaml
...
Profiles:
    SampleMultiNodeEtcdRaft:
        ...
        Orderer:
            <<: *OrdererDefaults
            OrdererType: etcdraft
            EtcdRaft:
                Consenters:
                - Host: orderer.example.com
                  Port: 7050
                  ClientTLSCert: crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
                  ServerTLSCert: crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
                - Host: orderer2.example.com
                  Port: 7050
                ...
            Addresses:
                - orderer.example.com:7050
                - orderer2.example.com:7050
                ...
...
```

如果你做过添加组织的操作, 或者反序列化过 `genesis.block`, 就可以看到这个 `block` 中的 `json` 数据

数据做过删减, 只抽出了需要讲解的地方, 如下

```json
{
    "data":{
        "data":[
            {
                "payload":{
                    "config":{
                        "channel_group":{
                            "groups":{
                                "Orderer":{
                                    "values":{
                                        "ConsensusType":{
                                            "value":{
                                                "metadata":{
                                                    "consenters":[
                                                        {
                                                            "client_tls_cert":"client tls cert",
                                                            "host":"orderer.example.com",
                                                            "port":7050,
                                                            "server_tls_cert":"server tls cert"
                                                        },
                                                        {
                                                            "client_tls_cert":"client tls cert",
                                                            "host":"orderer2.example.com",
                                                            "port":7050,
                                                            "server_tls_cert":"server tls cert"
                                                        }
                                                    ],
                                                    "options":{
                                                        "election_tick":10,
                                                        "heartbeat_tick":1,
                                                        "max_inflight_blocks":5,
                                                        "snapshot_interval_size":20971520,
                                                        "tick_interval":"500ms"
                                                    }
                                                },
                                                "state":"STATE_NORMAL",
                                                "type":"etcdraft"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                },
                "signature":null
            }
        ]
    },
    "header":{

    },
    "metadata":{

    }
}
```

在 `Orderer` 启动之处, 会去读取 `system channel` 最新的配置块, 如果没有则会读取 `genesis.blok`

判断其中的 `ConsensusType` 如果是 `etcdraft`, 就会使用 `clusterGRPCServer` 并传入 `initializeMultichannelRegistrar(...)` 中

`initializeMultichannelRegistrar(...)` 会再次判断 `ConsensusType` 如果是 `etcdraft` 就会通过 `initializeEtcdraftConsenter(...)` 初始化 `etcdraft` 的 `Consenter` 实例对象

同时也会初始化 `cluster.Service`, 它实现了 `ClusterServer` 核心接口

最后将 所有的 `consenters` 传入 `multichannel.Initialize` 并在其中进行初始化

在 `multichannel.Initialize` 会调用 `etcdraft.Consenter` 的 `HandleChain()` 也就是上面说的核心接口

```go
// orderer/common/server/main.go
func Start(cmd string, conf *localconfig.TopLevel) {
    // 读取 genesis.blok
    bootstrapBlock := extractBootstrapBlock(conf)
    ...
    // 创建 LedgerFactory, 如果不存在 system channel 的配置块返回 nil
    lf, _ := createLedgerFactory(conf, metricsProvider)
    sysChanLastConfigBlock := extractSysChanLastConfig(lf, bootstrapBlock)
    // 选择引导块, 在 sysChanLastConfigBlock 和 bootstrapBlock 块中选择, 如果 sysChanLastConfigBlock 不为 nil, 则优先返回
    clusterBootBlock := selectClusterBootBlock(bootstrapBlock, sysChanLastConfigBlock)
    ...
    // 判断 clusterBootBlock 中的共识类型如果是 `etcdraft` 就进行集群的初始化工作
    clusterType := isClusterType(clusterBootBlock)
    ...
    // 初始化多通道
    manager := initializeMultichannelRegistrar(clusterBootBlock, r, clusterDialer, clusterServerConfig, clusterGRPCServer, conf, signer, metricsProvider, opsSystem, lf, tlsCallback)
}

// orderer/common/server/main.go
func initializeMultichannelRegistrar(...) *multichannel.Registrar {
    genesisBlock := extractBootstrapBlock(conf)
    ...
    registrar := multichannel.NewRegistrar(*conf, lf, signer, metricsProvider, callbacks...)
    ...
    // 加载 solo, kafka 共识
    consenters["solo"] = solo.New()
    var kafkaMetrics *kafka.Metrics
    consenters["kafka"], kafkaMetrics = kafka.New(conf.Kafka, metricsProvider, healthChecker)
    ...
    // 判断是否是 `etcdraft` 共识, 如果是就将 etcdraft 的实例也加入到 consenters 中
    if isClusterType(bootstrapBlock) {
        initializeEtcdraftConsenter(consenters, conf, lf, clusterDialer, bootstrapBlock, ri, srvConf, srv, registrar, metricsProvider)
    }
    registrar.Initialize(consenters)
    return registrar
}

// orderer/common/multichannel/registrar.go
func (r *Registrar) Initialize(consenters map[string]consensus.Consenter) {
    r.consenters = consenters
    existingChains := r.ledgerFactory.ChainIDs()

    for _, chainID := range existingChains {
        ...
        // 这里判断是否是 system channel
        if _, ok := ledgerResources.ConsortiumsConfig(); ok {
            ...
            chain := newChainSupport(
                r,
                ledgerResources,
                r.consenters,
                r.signer,
                r.blockcutterMetrics,
            )
            ...
            defer chain.start()
        } else {
            ...
        }
    }
...
}

// orderer/common/multichannel/chainsupport.go
func newChainSupport(...) *ChainSupport {
    ...
    // 这里会根据 ledger 获取 ConsensusType 选择最终要用到的共识算法, 根据本文会选出 `etcdraft`
    consenterType := ledgerResources.SharedConfig().ConsensusType()
    consenter, ok := consenters[consenterType]
    ...
    // 调用 HandleChain
    cs.Chain, err = consenter.HandleChain(cs, metadata)
    ...
    return cs
}
```

## EtcdRaft初始化

代码从现在起就进入了 `etcdraft` 中的核心部分, 里面可以看到系统是如何自动设置 `raftID` 的, 始于 `HandleChain`, 终于...

在 `HandleChain` 中会取出当前 `channel` 也就是 `system channel` 最新的配置信息并获取 `ConsensusMetadata` 也就是上面 `json` 中的 `channel_group.groups.Orderer.ConsensusType.value.metadata`

这是一个数组, 系统会根据当前 `orderer` 所设置的证书在这个数组中的 `index` 来设置 `raftID`, 妙啊,真是妙啊!

在这个方法中会初始化 `cluster.RPC`, 没错这个东西实现了上面所说 `ClusterClient` 核心接口, 也就是说  `ClusterServer` 和 `ClusterClient` 是一对多关系

最终调用 `etcdraft.NewChain(...)` 进行 `etcdraft.Chain` 的创建, `etcdraft.Chain` 实现了 `Chain` 这个核心接口

到此, 上面所说的核心接口已全部出现了

```go
// orderer/consensus/etcdraft/consenter.go
func (c *Consenter) HandleChain(support consensus.ConsenterSupport, metadata *common.Metadata) (consensus.Chain, error) {
    // 获取 ConsensusMetadata
    m := &etcdraft.ConfigMetadata{}
    if err := proto.Unmarshal(support.SharedConfig().ConsensusMetadata(), m); err != nil {
        return nil, errors.Wrap(err, "failed to unmarshal consensus metadata")
    }
    ...
    consenters := map[uint64]*etcdraft.Consenter{}
    for i, consenter := range m.Consenters {
        consenters[blockMetadata.ConsenterIds[i]] = consenter
    }
    // 设置ID
    id, err := c.detectSelfID(consenters)
    ...
    // 初始化 cluster.RPC 每一个 chan 都会有个 rpc, 也印证了我上面说的, cluster.server 和 cluster.client 是一对一关系
    rpc := &cluster.RPC{
        Timeout:       c.OrdererConfig.General.Cluster.RPCTimeout,
        Logger:        c.Logger,
        Channel:       support.ChainID(),
        Comm:          c.Communication,
        StreamsByType: cluster.NewStreamsByType(),
    }

    return NewChain(
        support,
        opts,
        c.Communication,
        rpc,
        func() (BlockPuller, error) { return newBlockPuller(support, c.Dialer, c.OrdererConfig.General.Cluster) },
        func() {
            c.InactiveChainRegistry.TrackChain(support.ChainID(), nil, func() { c.CreateChain(support.ChainID()) })
        },
        nil,
    )
}

// orderer/consensus/etcdraft/chan.go
func NewChain(...) (*Chain, error) {
    ...
    // 此方法基本都是初始化工作, 需要注意的是 rpc 给了 chan
    c := &Chain{
        configurator:     conf,
        rpc:              rpc,
        channelID:        support.ChainID(),
        raftID:           opts.RaftID,
        ...
    }
    ...
    // raft 的配置文件, 也是从 block 中获取的.
    config := &raft.Config{
        ...
    }
    // node, 里面有 raft 的 node
    c.Node = &node{
        ...
    }

    return c, nil
}
```

## EtcdRaft启动

这里又要回到 `newChainSupport()` 中了, 这里就复制那边的代码了, 在此函数退出的时候 `defer chain.start()` 会调用 `start` 的方法

里面会启动 `etcdraft` 中的 `node.start()` 在里面又会启动 `etcd` 中的 `node.start()`.

```go
// orderer/consensus/etcdraft/chan.go
func (c *Chain) Start() {
    ...
    // 启动了 etcdraft.Node
    c.Node.start(c.fresh, isJoin)
    ...
    // serveRequest 是个核心的函数, 在里面会做 raft 的角色切换等一堆的操作
    go c.serveRequest()

    es := c.newEvictionSuspector()

    interval := DefaultLeaderlessCheckInterval
    if c.opts.LeaderCheckInterval != 0 {
        interval = c.opts.LeaderCheckInterval
    }

    c.periodicChecker = &PeriodicCheck{
        Logger:        c.logger,
        Report:        es.confirmSuspicion,
        CheckInterval: interval,
        Condition:     c.suspectEviction,
    }
    c.periodicChecker.Run()
}

// orderer/consensus/etcdraft/node.go
func (n *node) start(fresh, join bool) {
    ...
    var campaign bool
    // 是否是新节点标记位
    if fresh {
        // 是否是新加入标记位
        if join {
            raftPeers = nil
            n.logger.Info("Starting raft node to join an existing channel")
        } else {
            n.logger.Info("Starting raft node as part of a new channel")

            // determine the node to start campaign by selecting the node with ID equals to:
            //                hash(channelID) % cluster_size + 1
            sha := sha256.Sum256([]byte(n.chainID))
            number, _ := proto.DecodeVarint(sha[24:])
            if n.config.ID == number%uint64(len(raftPeers))+1 {
                campaign = true
            }
        }
        // 最终会启动 raft 的 node.
        // 有点像设置配置文件.
        // raftPeers, 对应的就是 ETCD_INITIAL_CLUSTER
        n.Node = raft.StartNode(n.config, raftPeers)
    } else {
        n.logger.Info("Restarting raft node")
        n.Node = raft.RestartNode(n.config)
    }

    go n.run(campaign)
}
```

## 一笔交易

`Chain` 接口中的 `Order(...)` 方法, 用于接收普通交易消息

当一个消息进入 Order 方法中后, 会将消息封装成 `orderer.SubmitRequest` 并发送

在 `Chain.Submit(...)` 方法中, 会先消息在封装 `orderer.submit` 并存入 `chan Chain.submitC` 通道中

在判断 `leader` 是否是当前节点, 如果不是, 就会把数据通过 `rpc` 发送给 `leader`

`Chain.rpc` 是一个实现了 `ClusterClient` 可以用于将消息发送到其他的 orderer

```flow
st=>start
e=>end
opOrder=>operation: Order(...)
condLeader=>condition: IsLeader
opRPC=>operation: rpc.SendSubmit(...)

st->opOrder->condLeader(no)->opRPC->e
condLeader(yes)->e
```

```go
// orderer/consensus/etcdraft/chain.go
func (c *Chain) Order(env *common.Envelope, configSeq uint64) error {
    c.Metrics.NormalProposalsReceived.Add(1)
    // 这里将 env, configSeq 以及 channelID 封装成了 SubmitRequest 并发给了 Submit 方法
    return c.Submit(&orderer.SubmitRequest{LastValidationSeq: configSeq, Payload: env, Channel: c.channelID}, 0)
}

// orderer/consensus/etcdraft/chain.go
func (c *Chain) Submit(req *orderer.SubmitRequest, sender uint64) error {
    ...
    // 获取一个 chan 用于接收网络当前的 leader
    leadC := make(chan uint64, 1)
    select {
    // 这个 case 就是将 req, 以及用于接收 leader 的 chan, 再次封装发给了 Chain 中的 chan submitC
    case c.submitC <- &submit{req, leadC}:
        // 等待 submitC 被处理, 并返回 leader 的 id
        lead := <-leadC
        // 如果没有 leader 就报错
        if lead == raft.None {
            c.Metrics.ProposalFailures.Add(1)
            return errors.Errorf("no Raft leader")
        }

        // 如果自己不是 leader, 就会将消息发给 leader.
        if lead != c.raftID {
            if err := c.rpc.SendSubmit(lead, req); err != nil {
                c.Metrics.ProposalFailures.Add(1)
                return err
            }
        }
    ...
    return nil
}
```

## 一个块的同步

这个方法, 我认为算是 `etcdraft` 核心方法了, 有兴趣的小伙伴可以深究一下这个方法

里面涉及到了 `Leader`, `Follower` 的角色切换, 共识等实现

这里还是跟着上一步继续向下深究, 在交易消息到达 `Leader` 后就要开始共识了

如果节点是 `Leader` 则会进行排序

```go
// orderer/consensus/etcdraft/chain.go
func (c *Chain) serveRequest() {
    ...
    // 下方会使用到里面的协程
    becomeLeader := func() (chan<- *common.Block, context.CancelFunc) {
        ...
        ctx, cancel := context.WithCancel(context.Background())
        go func(ctx context.Context, ch <-chan *common.Block) {
            for {
                select {
                case b := <-ch:
                    data := utils.MarshalOrPanic(b)
                    // 这里会丢给 raft node 进行同步 block, 里面的处理非常复杂.., 属于 raft 中的东西了, 这里就不细追了.
                    if err := c.Node.Propose(ctx, data); err != nil {
                        c.logger.Errorf("Failed to propose block [%d] to raft and discard %d blocks in queue: %s", b.Header.Number, len(ch), err)
                        return
                    }
                    c.logger.Debugf("Proposed block [%d] to raft consensus", b.Header.Number)

                case <-ctx.Done():
                    c.logger.Debugf("Quit proposing blocks, discarded %d blocks in the queue", len(ch))
                    return
                }
            }
        }(ctx, ch)
        return ch, cancel
    }
    ...
    for {
        select {
        case s := <-submitC:
            // leader 进行出块操作, 如果未符合要求,比如大小不够, 就会 pending
            batches, pending, err := c.ordered(s.req)
            if err != nil {
                c.logger.Errorf("Failed to order message: %s", err)
                continue
            }
            if pending {
                startTimer() // no-op if timer is already started
            } else {
                stopTimer()
            }

            // 生成生成 block 并将 block 传给 propC, propC 是一个 chan 结构, 所以会给上面的协程做处理
            c.propose(propC, bc, batches...)

            if c.configInflight {
                c.logger.Info("Received config transaction, pause accepting transaction till it is committed")
                submitC = nil
            } else if c.blockInflight >= c.opts.MaxInflightBlocks {
                c.logger.Debugf("Number of in-flight blocks (%d) reaches limit (%d), pause accepting transaction",
                    c.blockInflight, c.opts.MaxInflightBlocks)
                submitC = nil
            }
            ...
        case <-timer.C():
            ticking = false

            batch := c.support.BlockCutter().Cut()
            if len(batch) == 0 {
                c.logger.Warningf("Batch timer expired with no pending requests, this might indicate a bug")
                continue
            }

            c.logger.Debugf("Batch timer expired, creating block")
            c.propose(propC, bc, batch) // we are certain this is normal block, no need to block
        }
    }
}
```

## 一个块的存储

根据 `raft` 共识同步消息的流程是  `uncommitted` -> `committed` 两个阶段, 都会在上面完成

如果是 `committed` 就会去写块

```go
// orderer/consensus/etcdraft/chain.go
func (c *Chain) serveRequest() {
    ...
    // 下方会使用到里面的协程
    becomeLeader := func() (chan<- *common.Block, context.CancelFunc) {
        ...
        ctx, cancel := context.WithCancel(context.Background())
        go func(ctx context.Context, ch <-chan *common.Block) {
            for {
                select {
                case b := <-ch:
                    data := utils.MarshalOrPanic(b)
                    // 这里会丢给 raft node 进行同步 block, 里面的处理非常复杂.., 属于 raft 中的东西了, 这里就不细追了.
                    if err := c.Node.Propose(ctx, data); err != nil {
                        c.logger.Errorf("Failed to propose block [%d] to raft and discard %d blocks in queue: %s", b.Header.Number, len(ch), err)
                        return
                    }
                    c.logger.Debugf("Proposed block [%d] to raft consensus", b.Header.Number)

                case <-ctx.Done():
                    c.logger.Debugf("Quit proposing blocks, discarded %d blocks in the queue", len(ch))
                    return
                }
            }
        }(ctx, ch)
        return ch, cancel
    }
    ...
    for {
        select {
        ...
        case app := <-c.applyC:
            ...
            // 这里面会讲 raftlog 中的 block 落地.
            c.apply(app.entries)
            ...
        }
    }
}

// orderer/consensus/etcdraft/chain.go
func (c *Chain) apply(ents []raftpb.Entry) {
    ...
    for i := range ents {
        // 只有两种类型 EntryNormal, EntryConfChange, block 消息是 EntryNormal
        switch ents[i].Type {
        case raftpb.EntryNormal:
            ...
            block := utils.UnmarshalBlockOrPanic(ents[i].Data)
            // 这里就会写入 block 了
            c.writeBlock(block, ents[i].Index)
            c.Metrics.CommittedBlockNumber.Set(float64(block.Header.Number))
        ...
        case raftpb.EntryConfChange:
            ...
        }

        if ents[i].Index > c.appliedIndex {
            c.appliedIndex = ents[i].Index
        }
    }

    if c.accDataSize >= c.sizeLimit {
        b := utils.UnmarshalBlockOrPanic(ents[position].Data)

        select {
        case c.gcC <- &gc{index: c.appliedIndex, state: c.confState, data: ents[position].Data}:
            c.logger.Infof("Accumulated %d bytes since last snapshot, exceeding size limit (%d bytes), "+
                "taking snapshot at block [%d] (index: %d), last snapshotted block number is %d, current nodes: %+v",
                c.accDataSize, c.sizeLimit, b.Header.Number, c.appliedIndex, c.lastSnapBlockNum, c.confState.Nodes)
            c.accDataSize = 0
            c.lastSnapBlockNum = b.Header.Number
            c.Metrics.SnapshotBlockNumber.Set(float64(b.Header.Number))
        default:
            c.logger.Warnf("Snapshotting is in progress, it is very likely that SnapshotIntervalSize is too small")
        }
    }

    return
}
```
