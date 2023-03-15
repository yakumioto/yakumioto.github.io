---
categories:
- 学习
date: "2020-06-27"
tags:
- Go
- Hyperledger Fabric
title: Hyperledger Fabric 加入通道时遇到 channel doesn't exist 问题
---

据同事说 node sdk@v2.x.x 版本中没有对网络操作相关的 API 实现, 所以只能自己照着 v1.4.x 版本的
手撸底层代码, 但是在实现 `JoinChain` 这个功能时出现了 `channel doesn't exist` 错误

## 原因

```json
// SignedProposal 部分结构
{
  "proposal_bytes": {
    "header": {
      "channel_header": {
        "channel_id": ""
      },
      "signature_header": {
        "creator": {
          "mspid": "",
          "id_bytes": ""
        }
      }
    },
    "payload": ""
  },
  "signature": ""
}
```

当 peer 收到 client 发来的 SignedProposal 时, 会进行签名校验

1. 根据 `proposal_bytes.header.channel_header.channel_id` 获取对应的 `mspMgmtMgr`, 如果此时通道不存在, 则会创建一个未经初始化的 `mspMgmtMgr`
2. 根据 `proposal_bytes.header.signature_header.creator.mspid` 获取对应的 `mspManagerImpl`, 但是由于 `mspMgmtMgr` 未初始化, 所以直接返回了 `channel doesn't exist`

## 源码追踪

重要的事情说三遍

注释!!!

注释!!!

注释!!!

```go
// core/endorser/endorser.go:423
// endorser server 的入口函数, GRPC 消息都会发到这个 handler 中进行处理
func (e *Endorser) ProcessProposal(ctx context.Context, signedProp *pb.SignedProposal) (*pb.ProposalResponse, error) {
    ...
    // 0 -- check and validate
    vr, err := e.preProcess(signedProp)
    if err != nil {
        resp := vr.resp
        return resp, err
    }
    ...
}

// core/endorser/endorser.go:348
// 做提前校验相关的工作, 比如验证这个消息是否是本人发送的等.
func (e *Endorser) preProcess(signedProp *pb.SignedProposal) (*validateResult, error) {
    ...
    // at first, we check whether the message is valid
    prop, hdr, hdrExt, err := validation.ValidateProposalMessage(signedProp)
    ...
}

// core/common/validation/msgvalidation.go:76
// 校验 Proposal message 的方法
func ValidateProposalMessage(signedProp *pb.SignedProposal) (*pb.Proposal, *common.Header, *pb.ChaincodeHeaderExtension, error) {
    if signedProp == nil {
        return nil, nil, nil, errors.New("nil arguments")
    }

    putilsLogger.Debugf("ValidateProposalMessage starts for signed proposal %p", signedProp)

    // 从 proposalBytes 中 反序列化出 *peer.Proposal 实例
    prop, err := utils.GetProposal(signedProp.ProposalBytes)
    if err != nil {
        return nil, nil, nil, err
    }

    // 从 prop.Header 反序列化得到 *common.Header
    hdr, err := utils.GetHeader(prop.Header)
    if err != nil {
        return nil, nil, nil, err
    }

    // 从 hdr 中反序列化得到  *common.ChannelHeader 和 *common.SignatureHeader
    chdr, shdr, err := validateCommonHeader(hdr)
    if err != nil {
        return nil, nil, nil, err
    }

    // 校验签名
    err = checkSignatureFromCreator(shdr.Creator, signedProp.Signature, signedProp.ProposalBytes, chdr.ChannelId)
    if err != nil {
        // log the exact message on the peer but return a generic error message to
        // avoid malicious users scanning for channels
        putilsLogger.Warningf("channel [%s]: %s", chdr.ChannelId, err)
        sId := &msp.SerializedIdentity{}
        err := proto.Unmarshal(shdr.Creator, sId)
        if err != nil {
            // log the error here as well but still only return the generic error
            err = errors.Wrap(err, "could not deserialize a SerializedIdentity")
            putilsLogger.Warningf("channel [%s]: %s", chdr.ChannelId, err)
        }
        return nil, nil, nil, errors.Errorf("access denied: channel [%s] creator org [%s]", chdr.ChannelId, sId.Mspid)
    }
    ...
}

// core/common/validation/msgvalidation.go:153
func checkSignatureFromCreator(creatorBytes []byte, sig []byte, msg []byte, ChainID string) error {
    ...
    // 通过获取身份解析器
    mspObj := mspmgmt.GetIdentityDeserializer(ChainID)
    if mspObj == nil {
        return errors.Errorf("could not get msp for channel [%s]", ChainID)
    }

    // 反系列化签名者的信息
    creator, err := mspObj.DeserializeIdentity(creatorBytes)
    if err != nil {
        return errors.WithMessage(err, "MSP error")
    }
    ...
}

// msp/mgmt/mgmt.go:184
// 这一步是出错的主要方法, 由于设置了 chainID 导致没有获取 LocalMSP
func GetIdentityDeserializer(chainID string) msp.IdentityDeserializer {
    if chainID == "" {
        return GetLocalMSP()
    }

    return GetManagerForChain(chainID)
}

// msp/mgmt/mgmt.go:85
func GetManagerForChain(chainID string) msp.MSPManager {
    m.Lock()
    defer m.Unlock()

    // 由于 chainID 当前并不存在, 所以会走 if 分支然后会创建一个新的 mspMgr 并返回,
    // 初始化 mspMgmtMgr 时 up 参数被设置为 false
    mspMgr, ok := mspMap[chainID]
    if !ok {
        mspLogger.Debugf("Created new msp manager for channel `%s`", chainID)
        mspMgmtMgr := &mspMgmtMgr{msp.NewMSPManager(), false}
        mspMap[chainID] = mspMgmtMgr
        mspMgr = mspMgmtMgr
    } else {
        ...
    }
    return mspMgr
}

// msp/mgmt/mgmt.go:68
// 在 GetManagerForChain 方法中被生成
// 在 checkSignatureFromCreator 方法中被调用, 且 up 被设置为了 false 所以返回了 error
func (mgr *mspMgmtMgr) DeserializeIdentity(serializedIdentity []byte) (msp.Identity, error) {
    if !mgr.up {
        return nil, errors.New("channel doesn't exist")
    }
    return mgr.MSPManager.DeserializeIdentity(serializedIdentity)
}
```

## 参考

<https://github.com/hyperledger/fabric/tree/v1.4.6>