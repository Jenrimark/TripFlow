# tripflow-web

TripFlow 前端，基于 Vue 3 + TypeScript + Vite + Element Plus + Pinia。

## 开发

在项目根目录配置好 `.env` 后：

```sh
npm install
npm run dev
```

开发服务器默认 `http://localhost:5173`。`VITE_API_PROXY_TARGET` 指向后端地址，请求以 `/api` 前缀代理转发。

## 页面路由

| 路由 | 页面 |
|------|------|
| `/` | 工作台 |
| `/reimbursement` | 报销单列表 |
| `/reimbursement/new` | 新建报销单 |
| `/reimbursement/:id` | 报销单详情（只读） |
| `/reimbursement/:id/edit` | 编辑报销单 |
| `/approvals` | 审批中心 |
| `/kanban` | 流程看板 |

## 目录结构

```
src/
├── api/                    # 接口封装（master、reimbursement 等）
├── composables/            # 组合式函数（主数据加载）
├── data/                   # 主数据本地兜底
├── stores/                 # Pinia 状态（reimbursementStore）
├── types/                  # TypeScript 类型
├── utils/                  # 工具函数（补助计算、分摊等）
└── views/
    └── reimbursement/      # 报销模块页面与子组件
        ├── ReimbursementListView.vue
        ├── ReimbursementDetailView.vue
        └── components/     # 基本信息、行程、补助、分摊等分区
```

## 构建

```sh
npm run build
```

产物输出至 `dist/`。
