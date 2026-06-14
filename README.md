# TripFlow

差旅报销与流程管理系统：报销单填报、补助计算、费用分摊、审批中心、流程看板。

设计依据见 [`docs/概要设计.md`](docs/概要设计.md)，数据库 ER 图见 [`docs/database-schema-mermaid.md`](docs/database-schema-mermaid.md)，页面原型见 [`docs/media/`](docs/media/)。

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Vue 3 · TypeScript · Vite 8 · Element Plus · Pinia · Vue Router |
| 后端 | Spring Boot 3.5 · Java 17 · MyBatis-Plus · Spring Data JPA |
| 数据库 | MySQL 8 |
| 缓存 | Redis 8（本地开发 / 云服务器均可，可选） |
| 工具 | Maven Wrapper · ESLint · Oxlint · Prettier |

## 项目结构

```
TripFlow/
├── .env.example              # 环境变量模板（复制为 .env）
├── tripflow-web/             # 前端 SPA
│   └── src/
│       ├── api/              # HTTP 接口封装
│       ├── composables/      # 组合式函数（主数据、页面模式等）
│       ├── data/             # 主数据本地兜底
│       ├── stores/           # Pinia 状态（reimbursementStore）
│       ├── types/            # TypeScript 类型定义
│       ├── utils/            # 补助计算、分摊、行程校验等
│       └── views/            # 页面与业务组件
├── tripflow-api/             # 后端 REST API
│   └── src/main/
│       ├── java/.../controller/   # REST 控制器
│       ├── java/.../service/      # 业务逻辑
│       ├── java/.../entity/       # 实体与 DTO
│       ├── java/.../mapper/       # MyBatis-Plus Mapper
│       └── resources/sql/         # 数据库初始化与种子脚本
├── scripts/                  # 辅助脚本（批量种子数据生成）
└── docs/                     # 概要设计、ER 图、原型图（本地文档）
```

## 环境要求

- **Node.js** `^20.19.0` 或 `>=22.12.0`
- **Java** 17+
- **MySQL** 8.x
- **Redis** 8.x（本地开发推荐；不安装则自动降级为内存缓存）
- **Maven**（或使用 `tripflow-api/mvnw`）

## 本地开发

### 1. 配置环境变量

在仓库根目录执行：

```bash
cp .env.example .env
```

编辑 `.env`，填写 MySQL 与端口配置：

```bash
MYSQL_HOST=localhost          # 本机或远程 ECS 地址
MYSQL_PORT=3306
MYSQL_DATABASE=tripflow
MYSQL_USER=root
MYSQL_PASSWORD=你的密码

REDIS_HOST=localhost          # 本地 Redis 或远程地址
REDIS_PORT=6379
REDIS_PASSWORD=               # 无密码留空
REDIS_DATABASE=0
CACHE_TYPE=redis              # redis=使用 Redis 缓存；simple=纯内存缓存

API_SERVER_PORT=8080
VITE_API_PROXY_TARGET=http://localhost:8080
```

后端从根目录 `.env` 加载配置（`spring.config.import`）；前端 Vite 开发服务器同样读取根目录 `.env` 中的 `VITE_*` 变量。

### 2. 初始化数据库

按顺序执行 SQL 脚本（均需指定 `-h`、`-u`、`-p`）：

```bash
# 1. 创建库、基础表（user / expense_report / workflow_task）及示例数据
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/init_tripflow.sql

# 2. 主数据表 + 报销单表结构 + 主数据种子（幂等，可重复执行）
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V2_reimbursement_schema.sql

# 3.（可选）3 条完整示例报销单
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V3_sample_reimbursement_data.sql

# 4.（可选）55 条批量种子数据，用于列表分页与联调
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V4_bulk_reimbursement_data.sql

# 5. 补录行程新增出发/到达精确时间字段（已有库需执行）
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V5_travel_record_datetime.sql
```

如需重新生成 V4 批量数据，可运行：

```bash
python3 scripts/generate_reimbursement_seed.py
```

### 3. 启动后端


确保 Redis 已运行（`redis-cli ping` 应返回 `PONG`）：

```bash
# macOS（Homebrew）
brew services start redis

# Linux（systemd）
sudo systemctl start redis


```
```bash
cd tripflow-api
./mvnw spring-boot:run
```

默认地址：`http://localhost:8080`

### 4. 启动前端

```bash
cd tripflow-web
npm install
npm run dev
```

默认地址：`http://localhost:5173`。开发环境请求以 `/api` 前缀发出，由 Vite 代理转发至后端（去掉 `/api` 前缀）。

### 5. 构建与检查（可选）

```bash
# 前端生产构建
cd tripflow-web && npm run build

# 前端类型检查 / Lint
npm run type-check
npm run lint

# 后端测试
cd tripflow-api && ./mvnw test
```

## 功能模块

### 差旅报销（`/reimbursement`）

核心业务模块，前后端均已实现完整 CRUD 与表单联动。

**列表页**

- 多条件查询：报销单号、标题、事由、费用归属公司、报销部门、报销人、业务类型（树形多选）
- 分页展示，支持查看 / 编辑 / 删除 / 复制 / 手工推送
- 单据状态标签：草稿(0) / 已完成(1) / 已作废(2)

**详情页**（新建 `/reimbursement/new` · 编辑 `/reimbursement/:id/edit` · 只读 `/reimbursement/:id`）

| 区块 | 说明 |
|------|------|
| 基本信息 | 标题、事由、报销人、部门、公司、业务类型 |
| 补录行程 | 出发/到达城市与日期，支持弹框编辑，校验行程重叠 |
| 补助信息 | 按城市类型自动计算餐补/交通/通讯标准，含补助日历勾选 |
| 费用合计 | 汇总各补助类别金额 |
| 费用分摊 | 按公司/项目分摊，支持均摊与比例校验 |
| 备注 | 自由文本 |
| 底部操作 | 保存草稿、提交、作废 |

**补助标准**（前端 `reimbursementUtils.ts`，依据概要设计）

| 城市类型 | 餐补 | 交通 | 通讯 |
|----------|------|------|------|
| 一线 | 100 | 40 | 40 |
| 二线 | 80 | 40 | 40 |
| 三线 | 50 | 40 | 40 |

**主数据**：公司、部门、员工、业务类型（树形）、城市、项目；API 不可用时前端自动降级至 `masterDataFallback.ts` 本地数据。

**数据存储**：报销单主表 `reimbursement` 以 JSON 存储完整表单快照（`content` 字段），同时规范化写入行程、补助、补助日历、费用分摊等子表，便于查询与扩展。

### 其他页面

| 路由 | 说明 |
|------|------|
| `/` | 工作台：报销单总数、草稿数量、看板待办统计 |
| `/approvals` | 审批中心：展示 `expense_approval` 类型工作流任务 |
| `/kanban` | 流程看板：待办 / 进行中 / 已完成三列 |

## API 概览

所有接口由前端以 `/api` 前缀访问，Vite 代理后实际路径如下。

| 模块 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 主数据 | GET | `/master/companies` | 费用归属公司 |
| 主数据 | GET | `/master/departments` | 报销部门 |
| 主数据 | GET | `/master/reimbursers` | 报销人（含部门信息） |
| 主数据 | GET | `/master/business-types` | 业务类型（树形） |
| 主数据 | GET | `/master/cities` | 城市 |
| 主数据 | GET | `/master/projects` | 项目 |
| 报销单 | GET | `/reimbursement` | 分页列表（支持多条件筛选） |
| 报销单 | GET | `/reimbursement/{id}` | 详情 |
| 报销单 | POST | `/reimbursement` | 创建 |
| 报销单 | PUT | `/reimbursement/{id}` | 更新 |
| 报销单 | DELETE | `/reimbursement/{id}` | 删除 |
| 报销单 | POST | `/reimbursement/{id}/submit` | 提交（草稿 → 已完成） |
| 报销单 | POST | `/reimbursement/{id}/void` | 作废 |
| 流程 | GET | `/workflow/tasks` | 工作流任务列表 |
| 用户 | GET | `/user/list` | 用户列表 |
| 报销 | GET | `/expense/list` | 早期 expense_report 示例数据 |

## 后端架构要点

- **双 ORM 共存**：Spring Data JPA（`ddl-auto=update`）管理基础表；MyBatis-Plus 负责报销模块 CRUD 与分页
- **报销服务分层**：`ReimbursementServiceImpl` 协调校验（`ReimbursementValidator`）与子表同步（`ReimbursementChildRecordService`）
- **跨域**：`CorsConfig` 允许前端开发端口访问
- **配置外置**：数据库连接、端口等全部来自根目录 `.env`

## 文档

| 文件 | 内容 |
|------|------|
| [`docs/概要设计.md`](docs/概要设计.md) | 业务背景、状态机、页面字段、补助规则 |
| [`docs/database-schema-mermaid.md`](docs/database-schema-mermaid.md) | 数据库 ER 图（Mermaid） |
| [`docs/media/`](docs/media/) | 页面原型截图 |
| [`tripflow-web/README.md`](tripflow-web/README.md) | 前端子项目说明 |

## 远程 MySQL（阿里云 ECS 等）

若使用云端 MySQL：

1. 安全组开放 **3306** 端口（建议限制来源 IP）
2. MySQL 配置 `bind-address = 0.0.0.0`，创建远程用户并授权
3. 将 `.env` 中 `MYSQL_HOST` 改为 ECS 公网/内网地址
4. 在本地执行上述 SQL 初始化脚本时加上对应 `-h` 参数


## 本地 Redis

Redis 用于缓存主数据、报销单列表和 IP 限流。代码已做降级处理：Redis 不可用时自动回退到内存缓存，限流拦截器放行请求。

**本地开发（推荐）**

```bash
# macOS
brew install redis
brew services start redis

# Ubuntu / Debian
sudo apt install redis-server
sudo systemctl start redis
```

`.env` 中 `REDIS_HOST=localhost`，`CACHE_TYPE=redis`。

**云服务器**

若将 Redis 部署到 ECS（如 `8.134.34.169`），需：

1. 安装 Redis 并设置密码（`requirepass`）
2. 安全组开放 **6379** 端口（建议限制来源 IP）
3. `.env` 中 `REDIS_HOST=8.134.34.169`，`REDIS_PASSWORD=你的密码`


## 更新日志

### 2025-06-15 报销单样式规范 & 交互优化

**页面规范调整**

- 报销单标题改为「差旅费用报销单」，日期前增加「提单日期」前缀
- 内容区宽度修复：移除 `el-main` 默认 padding，恢复 1200px 宽度
- 分区标题高度统一为 36px（padding 12px → 10px），保留加粗

**表格优化**

- 补录行程、补助信息、费用归属及分摊三张表格最左侧新增序号列
- 出差日期列宽 200px → 240px，行程列宽 200px → 130px，确保日期单行显示
- 费用归属及分摊表格列宽拉伸，撑满整行
- 费用归属及分摊表格底部新增总计行（总计 / 100% / CNY X.XX），橙黄底色、透明边框
- 费用归属及分摊第一行恢复可编辑（移除 `$index === 0` 禁用限制）
- 补助信息标题右侧新增「姓名：X天」总天数统计

**交互优化**

- 补录行程、费用归属及分摊新增展开/收起按钮（与其他分区一致）
- 「均摊」按钮移至分摊比例表头左侧（link 样式，14px）
- 补录行程按钮去掉 `+` 图标
- 新增行程弹窗宽度 600px → 720px，label 宽度 100px → 120px，表单项间距加大

**提示框样式统一**

- 补助信息、新增行程弹窗的提示框统一样式：浅黄底 rgb(255,247,233)、橙色感叹号 rgb(255,153,1)、黑色文字

**新增行程：出发到达日期合并 & 精确到秒**

- 出发日期、到达日期两个字段合并为「出发到达日期」一个 datetimerange 选择器，精确到秒
- 表格显示仍只展示日期部分（不显示时间）
- 新增 SQL 迁移脚本 `V5_travel_record_datetime.sql`，云数据库已同步
- Entity / DTO / Service 同步新增 `departureDatetime`、`arrivalDatetime` 字段

**其他**

- 备注信息字数上限 1000 → 500
- 操作列 `fixed="right"` 宽度 100px → 110px（补齐右侧 gutter）

## 后续规划

- [ ] 用户登录与权限（employee / manager / finance）
- [ ] 多级审批流配置与审批操作
- [ ] 看板拖拽与状态流转
- [ ] 附件上传与发票查验
- [ ] 与财务/费控系统对接
