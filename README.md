<h1 align="center">TripFlow · 差旅报销流程管理平台</h1>

<p align="center">
  <strong>企业级差旅报销单全生命周期管理，覆盖 草稿 → 提交 → 审批 → 作废 完整流程</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Java-17+-ED8B00?logo=openjdk&logoColor=white" alt="Java">
  <img src="https://img.shields.io/badge/Spring_Boot-3.5-6DB33F?logo=springboot&logoColor=white" alt="Spring Boot">
  <img src="https://img.shields.io/badge/Vue-3-4FC08D?logo=vuedotjs&logoColor=white" alt="Vue 3">
  <img src="https://img.shields.io/badge/Vite-8-646CFF?logo=vite&logoColor=white" alt="Vite">
  <img src="https://img.shields.io/badge/MySQL-8-4479A1?logo=mysql&logoColor=white" alt="MySQL">
  <img src="https://img.shields.io/badge/Redis-8-DC382D?logo=redis&logoColor=white" alt="Redis">
  <img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="License">
</p>

<p align="center">
  <a href="#-功能特性">功能</a> ·
  <a href="#-快速开始">快速开始</a> ·
  <a href="#-项目结构">结构</a> ·
  <a href="#️-功能模块">模块</a> ·
  <a href="#-api-概览">API</a> ·
  <a href="#-技术栈">技术栈</a> ·
  <a href="#-后续规划">规划</a>
</p>

---

## 📖 简介

**TripFlow** 是一套前后端分离的差旅报销管理系统，基于 **Spring Boot + Vue 3** 构建。

核心业务路径：

```text
报销人填写  ──保存草稿──►  提交报销单  ──审批流程──►  完成 / 作废
```

涵盖出差行程管理、补助自动计算（按城市类型 + 补助日历）、多部门费用分摊、乐观锁并发控制，以及实时提交进度反馈。后端集成 SpringDoc，启动即有 Swagger UI 接口文档；Redis 缓存与限流均支持无 Redis 时自动降级。

---

## ✨ 功能特性

| 模块 | 功能 | 亮点 |
|------|------|------|
| 📋 **报销单管理** | 新建、编辑、查看、删除、复制、作废 | 草稿自动暂存、状态驱动 UI、乐观锁并发控制（409 Conflict） |
| 🚗 **出差行程** | 精确到分钟的出发/到达时间 | 分钟级行程重叠检测、弹窗编辑、删除级联 |
| 💰 **出差补贴** | 按城市类型自动计算餐补/交通/通讯 | 补助日历可视化勾选、横向/纵向联动、批量更新 |
| 📊 **费用合计** | 按补助日历汇总各类金额 | 餐补 + 交通 + 通讯分类汇总，实时更新 |
| 💼 **费用分摊** | 按公司/项目分摊，支持均摊 | 首行自动补差、银行家舍入法、比例精确到四位小数 |
| ✅ **提交校验** | 基本信息、行程、补助、分摊全字段校验 | 实时进度弹窗、后端错误自动透传展示 |
| 📝 **备注管理** | 保存/清除备注 | 1000 字上限、确认弹框 |
| 📄 **接口文档** | SpringDoc / Swagger UI | 启动即可访问，OpenAPI 3.0 规范同步输出 |
| 🔒 **缓存与限流** | Redis 双删缓存 + @RateLimit 限流 | 未配置 Redis 时自动降级为内存缓存 / 不阻断请求 |

---

## 🚀 快速开始

### 环境要求

| 依赖 | 版本 |
|------|------|
| **Java** | 17+ |
| **Node.js** | `^20.19.0` 或 `>=22.12.0` |
| **MySQL** | 8.x |
| **Redis** | 8.x（可选，不安装自动降级） |
| **Maven** | 或使用 `tripflow-api/mvnw` |

### 1. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填写数据库与端口配置：

```bash
# --- MySQL ---
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=tripflow
MYSQL_USER=root
MYSQL_PASSWORD=你的密码

# --- 后端端口 ---
API_SERVER_PORT=8080

# --- Redis（可选，留空则自动降级） ---
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DATABASE=0
CACHE_TYPE=redis              # redis 或 simple（默认 simple）

# --- 前端开发代理 ---
VITE_API_PROXY_TARGET=http://localhost:8080
```

### 2. 初始化数据库

按顺序执行 SQL 脚本：

```bash
# 基础表与示例数据
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/init_tripflow.sql

# 主数据表 + 报销单表结构（幂等）
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V2_reimbursement_schema.sql

# 可选：3 条示例报销单
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V3_sample_reimbursement_data.sql

# 可选：55 条批量种子数据（由 scripts/generate_reimbursement_seed.py 生成）
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V4_bulk_reimbursement_data.sql

# 行程精确时间字段迁移（已有库需执行）
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V5_travel_record_datetime.sql

# 行程时间字段回填（已有库需执行）
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V6_backfill_travel_datetime.sql
```

### 3. 启动后端

```bash
cd tripflow-api
./mvnw spring-boot:run
```

> 默认端口 `8080`，Swagger UI：`http://localhost:8080/swagger-ui.html`

### 4. 启动前端

```bash
cd tripflow-web
npm install
npm run dev
```

> 默认地址 `http://localhost:5173`，开发环境请求通过 Vite 代理转发至后端

---

## 📁 项目结构

```
TripFlow/
├── tripflow-web/                          # 前端 SPA（Vue 3 + Vite 8）
│   └── src/
│       ├── api/                           # HTTP 接口封装（Axios）
│       │   ├── request.ts                 #   Axios 实例 + 响应拦截器
│       │   ├── reimbursement.ts           #   报销单 CRUD + 提交/作废
│       │   ├── master.ts                  #   主数据查询 + 业务类型树构建
│       │   ├── user.ts                    #   用户接口
│       │   └── workflow.ts               #   工作流任务接口
│       ├── composables/                   # 组合式函数
│       ├── stores/                        # Pinia 状态管理
│       │   └── reimbursementStore.ts      #   报销单全局状态（含校验逻辑）
│       ├── types/                         # TypeScript 类型定义
│       ├── utils/                         # 补助计算、分摊、行程校验
│       ├── data/                          # 主数据本地降级数据
│       ├── router/                        # 路由定义
│       └── views/                         # 页面与业务组件
│           ├── reimbursement/             #   报销单模块
│           │   ├── ReimbursementListView.vue      # 列表页
│           │   ├── ReimbursementDetailView.vue    # 详情页（新建/编辑/查看）
│           │   └── components/            #     10 个子组件
│           ├── DashboardView.vue          #   工作台
│           ├── ApprovalView.vue           #   审批中心
│           └── KanbanView.vue             #   流程看板
├── tripflow-api/                          # 后端 REST API（Spring Boot 3.5）
│   └── src/main/java/.../
│       ├── controller/                    # 7 个 REST 控制器（31 个端点）
│       ├── service/                       # 业务逻辑层
│       │   └── reimbursement/             #   报销单专项服务
│       │       ├── ReimbursementValidator.java           # 校验规则
│       │       ├── ReimbursementChildRecordService.java  # 子表同步
│       │       ├── ReimbursementAllowanceGenerationService.java  # 补助生成
│       │       └── ReimbursementCacheService.java        # 双删缓存
│       ├── mapper/                        # MyBatis-Plus 数据访问（13 个 Mapper）
│       ├── entity/                        # JPA / MyBatis-Plus 实体（13 个）
│       ├── dto/                           # 数据传输对象
│       ├── config/                        # 配置类（CORS、缓存、限流、MyBatis-Plus）
│       ├── annotation/                    # 自定义注解（@RateLimit）
│       └── exception/                     # 异常处理（乐观锁冲突 409）
├── openapi.json                           # OpenAPI 3.0 接口定义（SpringDoc 自动生成）
├── scripts/                               # 辅助脚本
│   ├── generate_reimbursement_seed.py     #   批量种子数据 SQL 生成
│   └── generate_selftest_report_v3.py     #   开发自测报告 Word 生成
└── docs/                                  # 项目交付物
```

---

## 📦 功能模块

### 差旅报销 `/reimbursement`

**列表页** — 多条件查询 + 分页展示，支持查看 / 编辑 / 删除 / 复制，状态标签：草稿 · 已完成 · 已作废

**详情页**

| 区块 | 说明 |
|------|------|
| 基本信息 | 标题、事由、报销人、部门、公司、业务类型（树形选择，仅选叶子节点） |
| 补录行程 | 出发/到达城市与精确到分钟的时间，弹框编辑，同行人时间重叠检测 |
| 补助信息 | 按城市类型自动计算标准，补助日历勾选，横向/纵向联动 |
| 费用合计 | 按勾选项汇总餐补 + 交通 + 通讯各类金额 |
| 费用分摊 | 按公司/项目分摊，均摊 + 精确比例，首行自动补差，银行家舍入 |
| 备注 | 自由文本（上限 1000 字） |
| 底部操作 | 保存草稿、提交（含进度弹窗）、作废 |

**补助标准**

| 城市类型 | 餐补 | 交通 | 通讯 |
|----------|------|------|------|
| 一线城市（北京、上海） | 100 | 40 | 40 |
| 二线城市（武汉、杭州） | 80 | 40 | 40 |
| 三线城市（荆州） | 50 | 40 | 40 |

### 其他页面

| 路由 | 说明 |
|------|------|
| `/` | 工作台 — 报销单总数、草稿数量、看板待办统计 |
| `/approvals` | 审批中心 — 工作流任务展示（审批按钮待接入） |
| `/kanban` | 流程看板 — 待办 / 进行中 / 已完成三列 |

---

## 🔌 API 概览

共 **7 个 Controller、31 个端点**，前端以 `/api` 前缀访问，Vite 代理转发至后端。

### 主数据 `/master`（6 个端点）

| 方法 | 路径 | 说明 | 限流 |
|------|------|------|------|
| `GET` | `/master/companies` | 费用归属公司列表 | 120/60s |
| `GET` | `/master/departments` | 报销部门列表 | 120/60s |
| `GET` | `/master/reimbursers` | 报销人列表 | 120/60s |
| `GET` | `/master/business-types` | 业务类型列表（树形） | 120/60s |
| `GET` | `/master/cities` | 城市列表 | 120/60s |
| `GET` | `/master/projects` | 项目列表 | 120/60s |

### 报销单 `/reimbursement`（11 个端点）

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/reimbursement` | 分页列表（支持多条件筛选） |
| `GET` | `/reimbursement/{id}` | 报销单详情 |
| `GET` | `/reimbursement/{id}/expense-summary` | 费用合计汇总计算 |
| `POST` | `/reimbursement` | 创建报销单 |
| `PUT` | `/reimbursement/{id}` | 更新报销单 |
| `DELETE` | `/reimbursement/{id}` | 删除（带 version 乐观锁） |
| `POST` | `/reimbursement/{id}/submit` | 提交（带 version） |
| `POST` | `/reimbursement/{id}/void` | 作废（带 version） |
| `PUT` | `/reimbursement/{id}/remark` | 更新备注 |
| `DELETE` | `/reimbursement/{id}/remark` | 清除备注（带 version） |
| `POST` | `/reimbursement/{id}/allowances/generate` | 自动生成补助数据 |

### 补录行程 `/reimbursement/{id}/travel-records`（5 个端点）

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `.../travel-records` | 行程列表 |
| `GET` | `.../travel-records/{recordKey}` | 行程详情 |
| `POST` | `.../travel-records` | 新增行程 |
| `PUT` | `.../travel-records/{recordKey}` | 更新行程 |
| `DELETE` | `.../travel-records/{recordKey}` | 删除行程 |

### 补助日历 `/reimbursement/{id}/allowances/{aid}/calendar`（5 个端点）

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `.../calendar` | 日历列表 |
| `POST` | `.../calendar` | 新增日历项 |
| `PUT` | `.../calendar` | 批量更新日历 |
| `PUT` | `.../calendar/{calendarId}` | 更新单条日历 |
| `DELETE` | `.../calendar/{calendarId}` | 删除日历项 |

### 费用分摊 `/reimbursement/{id}/cost-allocations`（5 个端点）

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `.../cost-allocations` | 分摊列表 |
| `POST` | `.../cost-allocations` | 新增分摊 |
| `POST` | `.../cost-allocations/evenly-distribute` | 均摊分配 |
| `PUT` | `.../cost-allocations/{allocationKey}` | 更新分摊 |
| `DELETE` | `.../cost-allocations/{allocationKey}` | 删除分摊 |

### 其他（2 个端点）

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/user/list` | 用户列表 |
| `GET` | `/workflow/tasks` | 工作流任务列表 |

> 完整接口定义见 [`openapi.json`](openapi.json)，Swagger UI：`http://localhost:8080/swagger-ui.html`

---

## 🛠️ 技术栈

<table>
  <tr>
    <td><strong>后端</strong></td>
    <td>Java 17 · Spring Boot 3.5.14 · Spring Data JPA · MyBatis-Plus 3.5.11 · SpringDoc 2.8.6</td>
  </tr>
  <tr>
    <td><strong>前端</strong></td>
    <td>Vue 3.5 · TypeScript 6 · Vite 8 · Element Plus 2.14 · Pinia 3 · Vue Router 5</td>
  </tr>
  <tr>
    <td><strong>数据库</strong></td>
    <td>MySQL 8（13 张业务表 + 7 个 SQL 迁移脚本）</td>
  </tr>
  <tr>
    <td><strong>缓存</strong></td>
    <td>Redis 8（可选，未配置时自动降级为内存缓存）</td>
  </tr>
  <tr>
    <td><strong>工具</strong></td>
    <td>Maven Wrapper · Lombok · ESLint · Oxlint · Prettier</td>
  </tr>
</table>

### 后端架构要点

- **双 ORM 共存** — JPA 管理基础表（`ddl-auto=update`），MyBatis-Plus 负责报销模块 CRUD 与分页
- **乐观锁并发控制** — 所有变更接口需携带 `version` 参数，MyBatis-Plus `@Version` + `OptimisticLockerInnerInterceptor`，冲突返回 409
- **JSON 快照存储** — 报销单 `content` 列保存完整文档 JSON，每次变更后重建
- **缓存双删模式** — 事务前清缓存 → 事务提交后再清 → 300ms 延迟再清，防止并发读填充旧数据
- **接口限流** — 自定义 `@RateLimit` 注解 + Redis 计数器，Redis 不可用时自动降级不阻断
- **服务分层** — `ReimbursementServiceImpl` 协调 `ReimbursementValidator`（校验）、`ReimbursementChildRecordService`（子表同步）、`ReimbursementCacheService`（缓存）
- **配置外置** — 数据库连接、端口等全部来自根目录 `.env`，通过 `spring.config.import` 加载

---

## 🗄️ 数据库

### 表结构

| 分类 | 表名 | 说明 |
|------|------|------|
| 主数据 | `reim_company` | 费用归属公司 |
| 主数据 | `reim_department` | 报销部门 |
| 主数据 | `reimburser` | 报销人（员工） |
| 主数据 | `business_type` | 业务类型（树形层级） |
| 主数据 | `city` | 城市（含城市类型：一线/二线/三线） |
| 主数据 | `project` | 项目 |
| 业务 | `reimbursement` | 报销单主表（含 `content` JSON 快照、`version` 乐观锁） |
| 业务 | `reimbursement_travel_record` | 补录行程（含分钟级 `departure_datetime`/`arrival_datetime`） |
| 业务 | `reimbursement_allowance` | 出差补助 |
| 业务 | `reimbursement_allowance_calendar` | 补助日历（按日勾选餐补/交通/通讯） |
| 业务 | `reimbursement_cost_allocation` | 费用分摊（按公司/项目） |
| 系统 | `user` | 用户表 |
| 系统 | `workflow_task` | 工作流任务 |

### 种子数据

- 5 家公司（胜意科技北京/上海/武汉/杭州/荆州分公司）
- 7 个部门（客户成功、企业消费、企业费控、集采、航旅、运营、营销事业部）
- 6 名报销人
- 14 种业务类型（树形层级）
- 5 个城市（一线/二线/三线各覆盖）
- 8 个项目
- 3 条示例报销单（已完成 / 草稿 / 已作废各 1 条）

---

## 📚 文档

| 文件 | 内容 |
|------|------|
| [`openapi.json`](openapi.json) | OpenAPI 3.0 接口定义（SpringDoc 自动生成，31 个端点） |
| [`docs/大作业.7z`](docs/) | 项目交付物（概要设计、ER 图、自测报告等） |
| [`scripts/generate_reimbursement_seed.py`](scripts/generate_reimbursement_seed.py) | 批量种子数据 SQL 生成脚本 |
| [`scripts/generate_selftest_report_v3.py`](scripts/generate_selftest_report_v3.py) | 开发自测报告 Word 文档生成脚本 |

---

## 📋 后续规划

- [ ] 用户登录与权限（employee / manager / finance）
- [ ] 多级审批流配置与审批操作
- [ ] 看板拖拽与状态流转
- [ ] 附件上传与发票查验
- [ ] 后端业务逻辑单元测试
- [ ] 与财务/费控系统对接
