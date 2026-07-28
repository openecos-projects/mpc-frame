# 用户设计注册技术说明

[English](user-design-registration.en.md)

首次接入请先阅读[用户设计接入指南](user-guide.md)。本文保留 manifest、生成器和
registry 的详细技术契约。

用户设计必须能够在不编译 reference SoC、其他用户槽位和完整 128 槽 FrameTop
的情况下独立验证，完成后再进入 FrameTop 集成。

## 目录结构

```text
designs/
├── registry.json
└── 1/
    ├── design.json
    ├── rtl/
    ├── tests/
    ├── include/     # 可选
    └── README.md    # 可选
```

每个 `designs/<id>/design.json` 是该设计 package 的唯一配置来源。根目录的
`designs/registry.json` 只列出最终接入 FrameTop 的 package。未注册 package
仍然可以运行独立 lint 和 unit test。

## 设计清单（design manifest）

`design.json` 记录 design ID、名称、顶层模块、源码、include 路径、宏定义、参数、
可选端口映射和用户测试。所有路径都相对 package 目录，且不得越过该目录边界。

零配置顶层端口为 `clock`、`reset`、`io_in`、`io_out` 和 `io_oe`。使用其他端口名
时，必须在 `design.json` 的 `ports` 字段中声明映射。

实现使用 Python 3 标准库的 `json` 解析器，不依赖 PyYAML。未知字段会被拒绝，
避免拼写错误静默改变构建行为。

支持字段如下：

| 字段 | 是否必需 | 含义 |
| --- | --- | --- |
| `id` | 是 | 1 到 127 的用户槽位；0 保留给 reference |
| `name` | 是 | 根 registry 内唯一的 package 名称 |
| `module` | 是 | 用户实际顶层模块名 |
| `sources` | 是 | package 内按顺序排列的 `.v`/`.sv` 源码 |
| `include_dirs` | 否 | package 内 include 目录 |
| `defines` | 否 | 编译宏；值为 `null` 表示无值宏 |
| `parameters` | 否 | 传给用户顶层的参数 |
| `ports` | 否 | 固定语义端口到实际端口名的映射 |
| `tests` | 注册时必需 | 命名的 `unit` 或 `frame` 测试声明 |

标准端口名不需要 `ports` 字段。例如实际时钟名为 `clk_i` 时，可以声明：

```json
{
  "ports": {
    "clock": "clk_i"
  }
}
```

生成的 wrapper 对外仍使用固定名称 `clock`。

## 独立验证流程

```sh
make design-lint DESIGN=designs/<id>
make design-test DESIGN=designs/<id>
make design-test DESIGN=designs/<id> TEST=io
```

生成器会在 `build/designs/<id>/` 下创建临时 `UserDesignDut.sv`，提供固定 Frame
接口。独立命令只编译所选 package、生成的 wrapper 和指定 testbench，不编译
reference SoC、其他用户 package 或完整 FrameTop。

必须先运行 `design-lint`。Frame 集成测试会忽略双向 IO 拓扑产生的框架级
`UNOPTFLAT` 误报，因此用户 RTL 内部真实的组合环路应由独立 lint 发现。

## FrameTop 集成流程

```sh
make registry-generate
make registry-check
make design-frame-test DESIGN=designs/<id>
```

`design-frame-test` 要求 package 已列入根 registry，否则会在启动 Verilator 前
报告错误。

每个已注册 package 必须至少声明一个 `unit` 测试和一个 `frame` 测试。未注册
package 在开发早期可以省略测试，但只能运行当前 manifest 能支持的命令。

生成器读取 `registry.json` 并产生：

- `rtl/generated/FrameDesignRegistry.sv`：提交到 Git 的确定性生成 RTL；
- `build/generated/user-designs.f`：不提交的临时 filelist；
- 128 位 `design_present` 掩码：供 Frame 控制逻辑判断槽位是否存在。

生成的 registry 包含端口 adapter 和已注册实例。未注册槽位没有模块实例，数据和
输出使能为零，保持复位且不能打开门控时钟。`FrameTop` 只例化固定的
`FrameDesignRegistry`，不直接依赖用户模块名。

## 已实现行为

- `design-build` 校验单个 package，并生成隔离 wrapper 和 filelist。
- `registry-filelist` 校验所有已注册 package，并准备根临时 filelist。
- `generate-registry` 按 design ID 的确定顺序生成 wrapper、实例、tie-off 和
  `design_present`。
- `check-registry` 重新生成内容并与已提交 RTL 比较，不修改源码。
- manifest 校验会汇总所有发现的问题，然后以非零状态退出。
- 根回归从 registry 自动发现全部测试，新增 package 不需要修改根 Makefile。

CI 使用 check-only 模式拒绝过期的生成 RTL。

## 校验范围

校验覆盖 JSON 结构、ID 范围与唯一性、保留的 design 0、package 路径边界、源码、
include 和测试路径、模块名、端口映射、参数、宏定义、生成结果和确定性再生成。

## 验收条件

- package 不注册也能运行独立 lint 和测试；
- 临时 smoke design 能生成并通过 FrameTop；
- 输入、输出、复位、时钟门控和运行期选择锁定均有测试；
- 未注册槽位保持停钟、复位和高阻；
- 无效 manifest 给出可操作的错误；
- 重新生成结果确定且无差异；
- design 0 的 reference 回归保持通过。
