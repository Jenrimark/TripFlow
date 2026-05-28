# TripFlow

差旅报销与通用流程管理系统：报销填报、审批中心、流程看板。

## 项目结构

| 目录 | 说明 |
|------|------|
| `tripflow-web` | Vue 3 + Vite + Element Plus 前端 |
| `tripflow-api` | Spring Boot 3 + MyBatis-Plus 后端 |

## 本地启动

### 1. 初始化数据库

在 MySQL 中执行：

```bash
mysql -u root -p < tripflow-api/src/main/resources/sql/init_tripflow.sql
```

按需修改 `tripflow-api/src/main/resources/application.properties` 中的数据库账号密码。

### 2. 启动后端

```bash
cd tripflow-api
./mvnw spring-boot:run
```

默认端口：`8080`

### 3. 启动前端

```bash
cd tripflow-web
npm install
npm run dev
```

默认端口：`5173`，API 通过 Vite 代理到 `/api`。

## 当前能力（骨架）

- 工作台统计：报销数量、待审批、看板待办
- 差旅报销列表（`GET /expense/list`）
- 审批中心（筛选 `expense_approval` 类型任务）
- 流程看板三列：待办 / 进行中 / 已完成

## 后续规划

- 报销单 CRUD 与附件上传
- 多级审批流配置
- 看板拖拽与状态流转
- 用户登录与权限（employee / manager / finance）
