# tripflow-web

TripFlow 前端，基于 Vue 3 + TypeScript + Vite + Element Plus + Pinia。

完整项目说明见仓库根目录 [`README.md`](../README.md)。

## 开发

在仓库根目录配置好 `.env` 后：

```sh
npm install
npm run dev
```

开发服务器默认 `http://localhost:5173`。`VITE_API_PROXY_TARGET` 指向后端地址，请求以 `/api` 前缀代理转发。

## 页面路由

| 路由 | 页面 | 模式 |
|------|------|------|
| `/` | 工作台 | — |
| `/reimbursement` | 报销单列表 | — |
| `/reimbursement/new` | 新建报销单 | 编辑 |
| `/reimbursement/:id` | 报销单详情 | 只读 |
| `/reimbursement/:id/edit` | 编辑报销单 | 编辑 |
| `/approvals` | 审批中心 | — |
| `/kanban` | 流程看板 | — |

## 目录结构

```
src/
├── api/                    # 接口封装（master、reimbursement、workflow、user）
├── composables/            # 组合式函数（主数据加载、页面模式）
├── data/                   # 主数据本地兜底
├── stores/                 # Pinia 状态（reimbursementStore）
├── types/                  # TypeScript 类型
├── utils/                  # 工具函数（补助计算、分摊、行程校验）
└── views/
    ├── DashboardView.vue
    ├── ApprovalView.vue
    ├── KanbanView.vue
    └── reimbursement/      # 报销模块
        ├── ReimbursementListView.vue
        ├── ReimbursementDetailView.vue
        └── components/     # 基本信息、行程、补助、分摊、备注、底部操作
```

## 脚本

| 命令 | 说明 |
|------|------|
| `npm run dev` | 开发服务器 |
| `npm run build` | 生产构建（含类型检查） |
| `npm run preview` | 预览构建产物 |
| `npm run type-check` | Vue/TS 类型检查 |
| `npm run lint` | Oxlint + ESLint |
| `npm run format` | Prettier 格式化 |

构建产物输出至 `dist/`。
