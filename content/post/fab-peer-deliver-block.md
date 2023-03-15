---
categories:
- 学习
date: "2020-06-15"
tags:
- Go
- Hyperledger Fabric
title: Hyperledger Fabric peer block 的交付流程详解
---

本文基于 `hyperldeger fabric 1.4.7` 进行代码追踪讲解

假设场景描述:

1. peer 重启场景
2. peer 有 user channel
3. peer 使用的是 goleveldb
4. peer 的 `core.peer.gossip.orgLeader` 为 `true`

## 流程简介

初始化账本根据账本中保存的 `channel id` 创建通道实例, 并初始化与之对等的 `gossip` 服务, 用
来接收对应通道的最新的 配置或交易 `block`, 接收到 `block` 后, 经过 `Verify`, `Validate`,
`Validate RW sets` 三个验证步骤, 提交给 `Ledger Commiter` 进行写入文件, 并将当前通道的
`blkMgrInfo` 更新到最新状态

## 源码追踪

伊始: main -> node.Cmd -> startCmd -> nodeStartCmd -> serve

### peer.Initialize

文件: `core/peer/peer.go:241`

初始化 ledgermgmt, 里面做的事情太多了, 要讲清楚有点困难建议大家自己去看看, 里面主要做的就是
各种初始化工作

```go
// /var/hyperledger/production/ledgersData 下有这些东西, 这里面的工作跟此目录有关
// chains/index goleveldb: 保存了所有通道的最新状态信息
// fileLock goleveldb: 用于锁程序的,文章最末尾有介绍
// historyLeveldb goleveldb: 保存历史交易的
// ledgerProvider goleveldb: 保存的是 chain ids, 也就是通道id
// pvtdataStore goleveldb: 存储私有数据库
// stateLeveldb goleveldb: 世界状态数据库, 可以替换为 couchdb

// 这两个我不确定没有细追
// configHistory 看名字应该是保存了 config block 相关的东西.
// bookkeeper 不知道.
ledgermgmt.Initialize(&ledgermgmt.Initializer{
    CustomTxProcessors:            ConfigTxProcessors,
    PlatformRegistry:              pr,
    DeployedChaincodeInfoProvider: deployedCCInfoProvider,
    MembershipInfoProvider:        membershipProvider,
    MetricsProvider:               metricsProvider,
})

// 就是通过 /var/hyperledger/production/ledgersData/ledgerProvider 获取的 id 列表
ledgerIds, err := ledgermgmt.GetLedgerIDs()
...
for _, cid := range ledgerIds {

    // 打开对应通道的账本, 例如打开 block 的最新文件, 加载最新的账本信息等
    if ledger, err = ledgermgmt.OpenLedger(cid); err != nil {
        ...
    }

    // 获取最新的交易块, 通过交易块获取最新的配置块的 number, 在通过 number 查询到最新的配置块
    // 有兴趣可以往下追一追看看
    if cb, err = getCurrConfigBlockFromLedger(ledger); err != nil {
        ...
    }

    // 创建通道实例, 传了 通道id, 账本实例, 最新的配置块等.
    if err = createChain(cid, ledger, cb, ccp, sccp, pm); err != nil {
        ...
    }

    InitChain(cid)
}

func createChain(
    cid string,
    ledger ledger.PeerLedger,
    cb *common.Block,
    ccp ccprovider.ChaincodeProvider,
    sccp sysccprovider.SystemChaincodeProvider,
    pm txvalidator.PluginMapper,
) error {
    // 初始化 gossip 服务用到的配置, vscc, 等相关资源初始化, 有兴趣的可以看看这个函数,
    // 这里就不做介绍了
    ...
    // 初始化 gossip service 方法
    service.GetGossipService().InitializeChannel(bundle.ConfigtxValidator().ChainID(), oac, service.Support{
        Validator:            validator,
        Committer:            c,
        Store:                store,
        Cs:                   simpleCollectionStore,
        IdDeserializeFactory: csStoreSupport,
        CapabilityProvider:   cp,
    })
    ...
    return nil
}
```

### service.gossipServiceImpl.InitializeChannel

文件: `gossip/service/gossip_service.go:273`

`gossip service` 的作用是管理 `gossip client`, 每个 `channel` 会启动一个 `gossip client`
每个 `gossip client` 会启动一个 `deliver block`

在 `InitializeChannel` 主要是初始化工作的

1. 初始化 `private data fetcher`
2. 初始化 `coordinator`
3. 初始化 `gossip` 参数

```go
func (g *gossipServiceImpl) InitializeChannel(chainID string, oac OrdererAddressConfig, support Support) {
    ...
    // Delivery service might be nil only if it was not able to get connected
    // to the ordering service
    if g.deliveryService[chainID] != nil {
        // 根据 core.yaml 或者 环境变量设置的两个个值在下方有不同的启动方式
        leaderElection := viper.GetBool("peer.gossip.useLeaderElection")
        isStaticOrgLeader := viper.GetBool("peer.gossip.orgLeader")

        ...

        if leaderElection {
            logger.Debug("Delivery uses dynamic leader election mechanism, channel", chainID)
            g.leaderElection[chainID] = g.newLeaderElectionComponent(chainID, g.onStatusChangeFactory(chainID,
                support.Committer), g.metrics.ElectionMetrics)
        } else if isStaticOrgLeader {
            logger.Debug("This peer is configured to connect to ordering service for blocks delivery, channel", chainID)
            g.deliveryService[chainID].StartDeliverForChannel(chainID, support.Committer, func() {})
        } else {
            logger.Debug("This peer is not configured to connect to ordering service for blocks delivery, channel", chainID)
        }
    } else {
        logger.Warning("Delivery client is down won't be able to pull blocks for chain", chainID)
    }

}
```

### blocksprovider.blocksProviderImpl.DeliverBlocks

文件: `core/deliverservice/blocksprovider/blocksprovider.go:110`

获取到最新的 `gossip message`, 根据类型判断是否是区块, 然后调用 `VerifyBlock` 进行验, 最后在添加到账本中

```go
func (b *blocksProviderImpl) DeliverBlocks() {
    ...
    for !b.isDone() {
        ...
        switch t := msg.Type.(type) {
        case *orderer.DeliverResponse_Status:
            ...
        case *orderer.DeliverResponse_Block:
            ...
            if err := b.mcs.VerifyBlock(gossipcommon.ChainID(b.chainID), blockNum, marshaledBlock); err != nil {
                logger.Errorf("[%s] Error verifying block with sequence number %d, due to %s", b.chainID, blockNum, err)
                continue
            }

            ...
            if err := b.gossip.AddPayload(b.chainID, payload); err != nil {
                logger.Warningf("Block [%d] received from ordering service wasn't added to payload buffer: %v", blockNum, err)
            }
            ...
        default:
            logger.Warningf("[%s] Received unknown: %v", b.chainID, t)
            return
        }
    }
}
```

### state.GossipStateProviderImpl.commitBlock

文件: `gossip/state/state.go:805`

`block` 经过一层层的传递, 最终到了 `gossip state` 中, 这也是 `block` 在 `gossip` 中的最后一环

```go
func (s *GossipStateProviderImpl) commitBlock(block *common.Block, pvtData util.PvtDataCollections) error {
    ...
    // 将 block 和 pvtdata 交给 ledger 进行存储
    if err := s.ledger.StoreBlock(block, pvtData); err != nil {
        logger.Errorf("Got error while committing(%+v)", errors.WithStack(err))
        return err
    }
    ...
}
```

### privdata.coordinator.StoreBlock

文件: `gossip/privdata/coordinator.go:163`

在这里面会校验 `block` 的签名, 读写集等, 然后传给 `CommitWithPvtData` 方法

```go
func (c *coordinator) StoreBlock(block *common.Block, privateDataSets util.PvtDataCollections) error {
    ...

    validationStart := time.Now()
    err := c.Validator.Validate(block)
    c.reportValidationDuration(time.Since(validationStart))
    if err != nil {
        logger.Errorf("Validation failed: %+v", err)
        return err
    }

    ...

    // commit block and private data
    commitStart := time.Now()
    err = c.CommitWithPvtData(blockAndPvtData, &ledger.CommitOptions{})
    c.reportCommitDuration(time.Since(commitStart))
    if err != nil {
        return errors.Wrap(err, "commit failed")
    }

    ...

    return nil
}
```

### committer.LedgerCommitter.CommitWithPvtData

文件: `core/committer/committer_impl.go:87`

块会交给 `kvledger` 进行存储, 以下追踪就跟主题无关了, 我把方法列到下面, 有需求可以自己看

kvledger.kvLedger.CommitWithPvtData: `core/ledger/ledgerstorage/store.go:113`

fsblkstorage.fsBlockStore.AddBlock: `common/ledger/blkstorage/fsblkstorage/fs_blockstore.go:51`

fsblkstorage.blockfileMgr.addBlock: `common/ledger/blkstorage/fsblkstorage/blockfile_mgr.go:240`

## 额外收获

### fileLock

`Fabric` 中的 `ledger management` 有一个数据库叫做 `fileLock`, 最开始不理解为什么要这
么实现,后来读这部分 `UnLock` 的代码发现, 这是类似于一个君子协议的东西, `peer reset` 命令里
会打开该数据库, 如果失败就证明有其他程序在使用.

栗子:

`peer node start` 启动时会打开 `fileLock` 的数据库连接, 这时如果你想执行`peer reset`
 这个进程启动是也会去对 `fileLock` 创建连接, 但是会失败, `peer reset` 会终止.

### 参考

<https://github.com/hyperledger/fabric/tree/v1.4.7>
