---
categories:
- 学习
date: "2018-02-22 13:53:59"
tags:
- Go
title: 基于 Go 的 RESTful API 怎么设计权限控制
---

其实 `RESTful API` 实现权限控制的方法很多很多, 比如在每个 `Handler` 中进行判断, 但是这种写法会导致工作量无限增加, 万一增加了其他的角色还要不停的更改源码, 所以要以尽量优雅的方式来实现这个部分. 比如 `Middleware` 的方式.

<!--more-->

## 资源的分类

`/zoos`  算一个资源
`/employees` 也是一个资源

但是这些资源又有一些不一样的地方.

栗子:

`GET /zoos` 想看动物园的列表, 所有人都可以看, 也不需要登录.
`PATCH /zoos/ID` 更新某个动物园的信息, 只有员工才可以更改, 必须要登录.
`GET /employees` 想看员工列表, 只有是员工, 且还是管理员的人才能看, 必须要登录.

所以资源是有分类的:

我归为以下两类.

1. 角色资源 (Role Resources)
2. 公共资源 (Public Resources)

**角色资源**: 属于某个角色所有, 只有访问的人属于这个角色才能进行访问. 例: 人事部门 才能对 `/employees` 资源进行增删改查.
**公共资源**: 游客,工作人员, 管理人员 都可以进行操作的资源.

## 角色 用户 权限 权限组之间的关系

用户: 有哪些角色.
角色: 有哪些权限组 权限.
权限组: 一部分权限的集合(可有可无的一部分, 如果前端每次操作都需要一个一个的去添加权限,为何不把权限打包成一个权限组呢?)
权限: 可以控制访问的资源.

用户与角色的关系: `一对多` 一个用户可以拥有多个权限. 例如:一个用户既是动物园的员工, 也是动物园的管理者.
角色与权限权限组的关系: `一对多` 一个角色可以有多个权限组 权限. 例如:管理员 拥有 employees权限组 zoos部分权限.
用户与权限权限组的关系: `一对多` 一个用户也可以拥有角色之外的权限权限组. (毕竟有些人就是这么特殊,不考虑不行啊!!)

## 表的设计

以下列出的字段只是权限控制中必须的字段, 可以在原先表结构中添加即可.

### Resource

|    Nmae     |  Type  |                       Description                        |
| :---------: | :----: | :------------------------------------------------------: |
|    Name     | string |                         资源名称                         |
| Description | string |                         资源描述                         |
|  Identity   | string | 资源唯一标识符 (一般可直接使用URL作为唯一标识符后面细讲) |

### Permission

|    Nmae     |  Type  |           Description            |
| :---------: | :----: | :------------------------------: |
| ResourceID  | string |              资源ID              |
|    Name     | string |             权限名称             |
| Description | string |             权限描述             |
|   Method    | string |           HTTP请求方法           |
|   Effect    | string | 作用于自己还是全部 (Allow&Owner) |

### PermissionGroup

|     Nmae      |   Type   | Description |
| :-----------: | :------: | :---------: |
|     Name      |  string  | 权限组名称  |
|  Description  |  string  | 权限组描述  |
| PermissionsID | []string |  权限集合   |

### Role

|        Nmae        |   Type   | Description |
| :----------------: | :------: | :---------: |
|        Name        |  string  |  角色名称   |
|    Description     |  string  |  角色描述   |
|   PermissionsID    | []string |  权限列表   |
| PermissionGroupsID | []string | 权限组列表  |

### User

|     Nmae      |   Type   | Description |
| :-----------: | :------: | :---------: |
|    RolesID    | []string |  角色列表   |
| PermissionsID | []string |  权限列表   |

以上所有的表都设计完了, 如果你仔细看上面表的顺序你会发现一点, 他们都是一对多的每一个 `Resource` 都是根.

注: **Resource 一对多 Permission 一对多 PermissionGroup 一对多 Role 一对多 Role**

## 权限中间件

以 [negroni](https://github.com/urfave/negroni) 为例中间件执行是有顺序的, 根据加载的先后分别执行.

权限中间件一般位于验证中间件之后, 以下的流程图是以我当前项目为例画出的流程图.

```flow
st=>start: Start
ed=>end: End
OPmiddlewareBefore=>operation: Before Middleware
OPmiddlewareAuth=>operation: Auth Middleware
1. QueryTokenAuth
2. HeaderTokenAuth
3. JWTTokenAuth
CDauth=>condition: Logined?
OPnoLolin=>operation: Redirect /login
OPmiddlewarePermission=>operation: Permission Middleware
CDpermission=>condition: Yes or No
OPnoPermission=>operation: Return HTTP Code 401
OPmiddlewareAfter=>operation: After Middleware

st->OPmiddlewareBefore->OPmiddlewareAuth->CDauth
CDauth(no)->OPnoLolin->OPmiddlewareBefore
CDauth(yes)->OPmiddlewarePermission->CDpermission
CDpermission(no)->OPnoPermission
CDpermission(yes)->OPmiddlewareAfter->ed
```

以下流程图是 `Permission Middleware` 内部的具体流程

```flow
st=>start: Start
ed=>end: End
OPgetResource=>operation: Get Resource
conditions:
1. url
OPgetPermission=>operation: Get Permission
conditions:
1. resourceID
2. http method
OPgetPermissionGroup=>operation: Get PermissionGroup
conditions:
1. permissionID
OPgetRole=>operation: Get Role
conditions:
1. permissionID || PermissionGroupID
CDResource=>condition: Yes or No
OPnoResource=>operation: Return HTTP Code 404
CDpermission=>condition: Yes or No
OPnoPermission=>operation: Return HTTP Code 500
CDpermissionGroup=>condition: Yes or No
OPnoPermissionGroup=>operation: Return HTTP Code 500
CDrole=>condition: Yes or No
OPnoRole=>operation: Return HTTP Code 500
OPvalidUserPermission=>operation: Valid User Permission
CDvalidUserPermission=>condition: Yes or No
OPuserNoPermission=>operation: Return HTTP Code 401

st->OPgetResource->CDResource
CDResource(no)->OPnoResource
CDResource(yes)->OPgetPermission->CDpermission
CDpermission(no)->OPnoPermission
CDpermission(yes)->OPgetPermissionGroup->CDpermissionGroup
CDpermissionGroup(no)->OPnoPermissionGroup
CDpermissionGroup(yes)->OPgetRole->CDrole
CDrole(no)->OPnoRole
CDrole(yes)->OPvalidUserPermission->CDvalidUserPermission
CDvalidUserPermission(no)->OPuserNoPermission
CDvalidUserPermission(yes)->ed
```

## 资源唯一标识符

这里讲一下为什么使用以及如何使用 `URL` 作为唯一标识符.

这里以 `/users` API 为例. 分别对应他的操作有

GET /users - 获取用户列表
GET /users/{id} - 获取具体用户的信息.
POST /users - 创建一个用户
PATCH /users/{id} - 更新一个用户的信息
PATCH /users/{id}/password - 更新用户密码
DELETE /users/{id} - 删除一个用户

假设现在有两个角色分别是 `普通用户`, `管理员`

资源表其实有两个 `/users`, `/users/`

`/users/` 普通用户有权限 `/users` 普通用户没有权限

所以 `URL` 作为资源唯一标识符到 第一层就可以了. 后面的可变的值如 `/users/{id}` 的 `id` 部分并不需要考虑.

以上, 如有疑问欢迎提出, 如果大神看出了缺陷也请告知哈~~

## 参考

- [RESTful API 设计指南](http://www.ruanyifeng.com/blog/2014/05/restful_api.html)
- [基于RESTful API 怎么设计用户权限控制？](https://www.jianshu.com/p/db65cf48c111)
