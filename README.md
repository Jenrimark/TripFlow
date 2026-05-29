# TripFlow

差旅报销与流程管理系统：报销单填报、补助计算、费用分摊、审批中心、流程看板。

设计依据见 [`docs/概要设计.md`](docs/概要设计.md)，页面原型见 [`docs/media/`](docs/media/)。

## 项目结构

| 目录 | 说明 |
|------|------|
| `tripflow-web` | Vue 3 + Vite + Element Plus + Pinia 前端 |
| `tripflow-api` | Spring Boot 3 + MyBatis-Plus 后端 |
| `docs/` | 概要设计、原型图、实现计划 |

## 本地开发

### 1. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填写 MySQL 与端口配置：

```bash
MYSQL_HOST=你的MySQL地址
MYSQL_PORT=3306
MYSQL_DATABASE=tripflow
MYSQL_USER=root
MYSQL_PASSWORD=你的密码

API_SERVER_PORT=8080
VITE_API_PROXY_TARGET=http://localhost:8080
```

### 2. 初始化数据库

创建数据库并执行初始化脚本（顺序不可颠倒）：

```bash
mysql -h 你的MySQL地址 -u root -p < tripflow-api/src/main/resources/sql/init_tripflow.sql
mysql -h 你的MySQL地址 -u root -p < tripflow-api/src/main/resources/sql/V2_reimbursement_schema.sql
```

`V2_reimbursement_schema.sql` 为幂等脚本，可重复执行；包含主数据种子与报销单表结构。

### 3. 启动后端

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

默认地址：`http://localhost:5173`，开发环境 API 通过 Vite 代理到 `/api`。

## 功能模块

### 差旅报销（`/reimbursement`）

- **列表页**：多条件查询（报销单号、标题、事由、公司、部门、报销人、业务类型）、分页、编辑/复制/导出/删除
- **详情页**：基本信息、补录行程、补助信息（含补助日历）、费用合计、费用分摊、备注
- **单据状态**：草稿(0) / 已完成(1) / 已作废(2)
- **主数据**：公司、部门、员工、业务类型（树形）、城市、项目；API 不可用时前端自动使用本地兜底数据

### 其他页面

| 路由 | 说明 |
|------|------|
| `/` | 工作台：报销单统计、草稿数量、看板待办 |
| `/approvals` | 审批中心 |
| `/kanban` | 流程看板（待办 / 进行中 / 已完成） |

## API 概览

所有接口前缀为 `/api`（由前端代理转发）。

| 模块 | 路径 | 说明 |
|------|------|------|
| 主数据 | `GET /master/*` | companies、departments、reimbursers、business-types、cities、projects |
| 报销单 | `GET/POST/PUT/DELETE /reimbursement` | 列表、详情、创建、更新、删除 |
| 报销单 | `POST /reimbursement/{id}/submit` | 提交 |
| 报销单 | `POST /reimbursement/{id}/void` | 作废 |
| 流程 | `GET /workflow/tasks` | 工作流任务 |
| 用户 | `GET /user/list` | 用户列表 |

## 阿里云 ECS MySQL

若使用云端 MySQL，需确保安全组开放 **3306** 端口，并将 `bind-address` 设为 `0.0.0.0`。详细步骤见历史文档或自行按 MySQL 8 远程访问规范配置。

## 后续规划

- 用户登录与权限（employee / manager / finance）
- 多级审批流配置
- 看板拖拽与状态流转
- 附件上传与发票查验
