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

涵盖出差行程管理、补助自动计算（按城市类型 + 补助日历）、多部门费用分摊、乐观锁并发控制，以及实时提交进度反馈。后端集成 SpringDoc，启动即有 Swagger UI 接口文档。

---

## ✨ 功能特性

| 模块 | 功能 | 亮点 |
|------|------|------|
| 📋 **报销单管理** | 新建、编辑、查看、删除、作废 | 草稿自动暂存、状态驱动 UI、乐观锁并发控制 |
| 🚗 **出差行程** | 精确到秒的出发/到达时间 | 分钟级行程重叠检测、弹窗编辑自动保存与撤回 |
| 💰 **出差补贴** | 按城市类型自动计算餐补/交通/通讯 | 补助日历可视化勾选、按勾选项汇总金额 |
| 📊 **费用分摊** | 按比例或均摊分配到多部门 | 分数精确比例存储、提交前校验总和 |
| ✅ **提交校验** | 业务类型、行程重叠、补贴完整性检查 | 实时进度弹窗、后端错误自动透传展示 |
| 📄 **接口文档** | SpringDoc / Swagger UI | 启动即可访问，OpenAPI 规范同步输出 |
| 🔒 **缓存与限流** | Redis 可选缓存 + 接口限流 | 未配置 Redis 时自动降级为内存缓存 |

---

## 🖼️ 界面预览

> 页面原型截图详见 [`docs/media/`](docs/media/)

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
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=tripflow
MYSQL_USER=root
MYSQL_PASSWORD=你的密码

REDIS_HOST=localhost          # 可选，留空则使用内存缓存
REDIS_PORT=6379
CACHE_TYPE=redis              # redis 或 simple

API_SERVER_PORT=8080
VITE_API_PROXY_TARGET=http://localhost:8080
```

### 2. 初始化数据库

按顺序执行 SQL 脚本：

```bash
# 基础表与示例数据
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/init_tripflow.sql

# 主数据表 + 报销单表结构（幂等）
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V2_reimbursement_schema.sql

# 可选：示例报销单
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V3_sample_reimbursement_data.sql

# 可选：批量种子数据
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V4_bulk_reimbursement_data.sql

# 行程精确时间字段迁移（已有库需执行）
mysql -h localhost -u root -p < tripflow-api/src/main/resources/sql/V5_travel_record_datetime.sql
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
├── tripflow-web/                  # 前端 SPA（Vue 3 + Vite）
│   └── src/
│       ├── api/                   # HTTP 接口封装
│       ├── composables/           # 组合式函数
│       ├── stores/                # Pinia 状态管理
│       ├── types/                 # TypeScript 类型定义
│       ├── utils/                 # 补助计算、分摊、行程校验
│       ├── router/                # 路由定义
│       └── views/                 # 页面与业务组件
│           ├── reimbursement/     # 报销单模块
│           ├── DashboardView.vue  # 工作台
│           ├── ApprovalView.vue   # 审批中心
│           └── KanbanView.vue     # 流程看板
├── tripflow-api/                  # 后端 REST API（Spring Boot）
│   └── src/main/java/.../
│       ├── controller/            # REST 控制器
│       ├── service/               # 业务逻辑
│       ├── mapper/                # MyBatis-Plus 数据访问
│       ├── entity/                # JPA 实体
│       ├── dto/                   # 数据传输对象
│       ├── config/                # 配置类
│       ├── annotation/            # 自定义注解
│       └── exception/             # 异常处理
├── openapi.json                   # OpenAPI 接口定义
├── scripts/                       # 辅助脚本
└── docs/                          # 概要设计、ER 图、原型图
```

---

## 📦 功能模块

### 差旅报销 `/reimbursement`

**列表页** — 多条件查询 + 分页展示，支持查看 / 编辑 / 删除 / 复制，状态标签：草稿 · 已完成 · 已作废

**详情页**

| 区块 | 说明 |
|------|------|
| 基本信息 | 标题、事由、报销人、部门、公司、业务类型 |
| 补录行程 | 出发/到达城市与精确时间，弹框编辑，行程重叠检测 |
| 补助信息 | 按城市类型自动计算标准，补助日历勾选 |
| 费用合计 | 按勾选项汇总各补助类别金额 |
| 费用分摊 | 按公司/项目分摊，均摊 + 精确分数比例 |
| 备注 | 自由文本（上限 1000 字） |
| 底部操作 | 保存草稿、提交（含进度弹窗）、作废 |

**补助标准**

| 城市类型 | 餐补 | 交通 | 通讯 |
|----------|------|------|------|
| 一线 | 100 | 40 | 40 |
| 二线 | 80 | 40 | 40 |
| 三线 | 50 | 40 | 40 |

### 其他页面

| 路由 | 说明 |
|------|------|
| `/` | 工作台 — 报销单总数、草稿数量、看板待办统计 |
| `/approvals` | 审批中心 — 工作流任务展示 |
| `/kanban` | 流程看板 — 待办 / 进行中 / 已完成 |

---

## 🔌 API 概览

| 模块 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 主数据 | `GET` | `/master/companies` | 费用归属公司 |
| 主数据 | `GET` | `/master/departments` | 报销部门 |
| 主数据 | `GET` | `/master/reimbursers` | 报销人 |
| 主数据 | `GET` | `/master/business-types` | 业务类型（树形） |
| 主数据 | `GET` | `/master/cities` | 城市 |
| 主数据 | `GET` | `/master/projects` | 项目 |
| 报销单 | `GET` | `/reimbursement` | 分页列表 |
| 报销单 | `GET` | `/reimbursement/{id}` | 详情 |
| 报销单 | `POST` | `/reimbursement` | 创建 |
| 报销单 | `PUT` | `/reimbursement/{id}` | 更新 |
| 报销单 | `DELETE` | `/reimbursement/{id}` | 删除 |
| 报销单 | `POST` | `/reimbursement/{id}/submit` | 提交 |
| 报销单 | `POST` | `/reimbursement/{id}/void` | 作废 |
| 流程 | `GET` | `/workflow/tasks` | 工作流任务 |
| 用户 | `GET` | `/user/list` | 用户列表 |

> 前端以 `/api` 前缀访问，Vite 代理转发至后端。完整定义见 [`openapi.json`](openapi.json)。

---

## 🛠️ 技术栈

<table>
  <tr>
    <td><strong>后端</strong></td>
    <td>Java 17 · Spring Boot 3.5 · Spring Data JPA · MyBatis-Plus · SpringDoc</td>
  </tr>
  <tr>
    <td><strong>前端</strong></td>
    <td>Vue 3 · TypeScript · Vite 8 · Element Plus · Pinia · Vue Router</td>
  </tr>
  <tr>
    <td><strong>数据库</strong></td>
    <td>MySQL 8</td>
  </tr>
  <tr>
    <td><strong>缓存</strong></td>
    <td>Redis 8（可选，自动降级）</td>
  </tr>
  <tr>
    <td><strong>工具</strong></td>
    <td>Maven Wrapper · ESLint · Oxlint · Prettier</td>
  </tr>
</table>

**后端架构要点：**

- **双 ORM 共存** — JPA 管理基础表（`ddl-auto=update`），MyBatis-Plus 负责报销模块 CRUD 与分页
- **服务分层** — `ReimbursementServiceImpl` 协调校验（`ReimbursementValidator`）与子表同步（`ReimbursementChildRecordService`）
- **配置外置** — 数据库连接、端口等全部来自根目录 `.env`

---

## 📚 文档

| 文件 | 内容 |
|------|------|
| [`docs/概要设计.md`](docs/概要设计.md) | 业务背景、状态机、页面字段、补助规则 |
| [`docs/database-schema-mermaid.md`](docs/database-schema-mermaid.md) | 数据库 ER 图（Mermaid） |
| [`docs/media/`](docs/media/) | 页面原型截图 |
| [`openapi.json`](openapi.json) | OpenAPI 接口定义 |

---

## 📋 后续规划

- [ ] 用户登录与权限（employee / manager / finance）
- [ ] 多级审批流配置与审批操作
- [ ] 看板拖拽与状态流转
- [ ] 附件上传与发票查验
- [ ] 与财务/费控系统对接
