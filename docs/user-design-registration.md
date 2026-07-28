# 用户设计注册技术说明

[English](user-design-registration.en.md)

首次接入请阅读[用户设计接入指南](user-guide.md)。本文说明设计 package、临时
Frame 测试和正式 registry 的技术契约。

## 身份分离

工程明确区分三类信息：

| 信息 | 来源 | 是否提交 |
| --- | --- | --- |
| package 名称、模块、源码和测试 | `designs/<name>/design.json` | 是 |
| Frame 测试临时 ID | 构建工具选择，记录在 `build/` | 否 |
| 最终硬件 design ID | 维护者写入 `designs/registry.json` | 是 |

因此用户 manifest 不需要 `id`，用户也不修改根 registry。

## 目录结构

```text
designs/
├── registry.json
└── counter32/
    ├── design.json
    ├── rtl/
    ├── tests/
    ├── include/     # 可选
    └── README.md
```

## Design manifest

`design.json` 支持：

| 字段 | 是否必需 | 含义 |
| --- | --- | --- |
| `name` | 是 | package 名称，在正式 registry 内唯一 |
| `module` | 是 | 用户顶层模块名 |
| `sources` | 是 | package 内按顺序排列的 `.v`/`.sv` 源码 |
| `include_dirs` | 否 | package 内 include 目录 |
| `defines` | 否 | 编译宏；`null` 表示无值宏 |
| `parameters` | 否 | 传给用户顶层的参数 |
| `ports` | 否 | 固定语义端口到实际端口名的映射 |
| `tests` | 测试时需要 | 命名的 `unit` 和 `frame` 测试 |
| `id` | 仅兼容旧包 | 新设计不要填写；正式 ID 以 registry 为准 |

所有路径都相对 package，不能越过目录边界。未知字段会被拒绝。标准端口为
`clock/reset/io_in/io_out/io_oe`；不同端口名通过 `ports` 映射。

## 用户验证

```sh
make user-lint
make user-test
make user-frame-test
make user-check
```

`find-user-design` 会从 `designs/*/design.json` 中排除已注册 package。只有一个候选
时自动选择；多个候选必须通过 `DESIGN=<path>` 指定。

独立 lint 和 unit test 只编译所选 package、生成 wrapper 和 TB。Frame 测试读取
正式 registry 的已占用 ID，为未注册 package 选择第一个空闲槽位，然后在
`build/designs/<name>/frame/` 中生成：

- `FrameDesignRegistry.sv`：本次测试专用 registry RTL；
- `user-designs.f` 和 `frame.f`：本次测试专用 filelist；
- `selected-id.txt`：注入 Frame TB 的实际 ID。

TB 通过编译宏 `FRAME_TEST_DESIGN_ID` 获得该 ID。临时内容不修改正式 registry，
也不应提交。

## 正式 registry

正式条目同时保存 ID 和 manifest 路径：

```json
{
  "designs": [
    {
      "id": 12,
      "manifest": "counter32/design.json"
    }
  ]
}
```

维护者运行：

```sh
make integrate-design DESIGN=designs/counter32 DESIGN_ID=12
```

该命令检查 ID、名称、模块和路径是否冲突，规范化并更新 registry，执行
`registry-generate/registry-check`，最后以正式 ID 运行 Frame 测试。分配结果属于
硬件外部选择协议，必须随生成的 `rtl/generated/FrameDesignRegistry.sv` 一起提交。

旧 registry 字符串条目和 manifest 内 `id` 暂时仍可读取；新条目必须使用对象格式，
如果旧 manifest ID 与 registry ID 不一致则拒绝构建。

## 生成和回归

- `design-build`：验证单个 package，生成 wrapper、测试 filelist 和临时 Frame
  registry；
- `find-user-design`：自动发现唯一未注册 package；
- `integrate-design`：由维护者分配最终 ID；
- `registry-filelist`：准备全部正式设计源码；
- `generate-registry`：按 ID 确定性生成正式 wrapper、实例和 `design_present`；
- `check-registry`：检查已提交生成 RTL 是否过期；
- `regression-fast`：遍历正式 registry 的所有测试。

正式设计必须同时声明 unit 和 frame test。ID 0 保留给 reference，用户 ID 范围为
1 到 127。名称、模块、ID 和 manifest 路径在正式 registry 内必须唯一。
