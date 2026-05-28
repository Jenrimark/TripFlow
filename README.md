# TripFlow

差旅报销与通用流程管理系统：报销填报、审批中心、流程看板。

## 项目结构

| 目录 | 说明 |
|------|------|
| `tripflow-web` | Vue 3 + Vite + Element Plus 前端 |
| `tripflow-api` | Spring Boot 3 + MyBatis-Plus 后端 |

## 本地开发环境配置

### 1. 配置环境变量

复制环境变量模板并填写配置：

```bash
cp .env.example .env
```

编辑 `.env` 文件，配置 ECS MySQL 连接信息：

```bash
# MySQL（阿里云 ECS）
MYSQL_HOST=你的ECS公网IP
MYSQL_PORT=3306
MYSQL_DATABASE=tripflow
MYSQL_USER=root
MYSQL_PASSWORD=你的MySQL密码

# 后端
API_SERVER_PORT=8080

# 前端
VITE_API_PROXY_TARGET=http://localhost:8080
```

### 2. 初始化数据库

确保 ECS 安全组已开放 3306 端口，然后创建数据库：

```bash
mysql -h 你的ECS公网IP -u root -p -e "CREATE DATABASE tripflow DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

### 3. 启动后端

```bash
cd tripflow-api
./mvnw spring-boot:run
```

默认端口：`8080`

### 4. 启动前端

```bash
cd tripflow-web
npm install
npm run dev
```

默认端口：`5173`，API 通过 Vite 代理到 `/api`。

---

## 阿里云 ECS MySQL 配置

如果还没有安装 MySQL，按以下步骤操作：

### 安装 MySQL

```bash
sudo apt update
sudo apt install mysql-server -y
sudo systemctl start mysql
sudo systemctl enable mysql
```

### 设置 root 密码

```bash
sudo mysql
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '你的密码';
FLUSH PRIVILEGES;
EXIT;
```

### 允许远程连接

编辑 MySQL 配置：

```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

找到 `bind-address = 127.0.0.1` 改为：

```
bind-address = 0.0.0.0
```

重启 MySQL：

```bash
sudo systemctl restart mysql
```

### 开放安全组端口

阿里云 ECS 控制台 → 安全组 → 入方向规则：
- 协议: TCP
- 端口: 3306
- 授权对象: 你的本地 IP 或 `0.0.0.0/0`

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
