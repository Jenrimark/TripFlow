import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'dashboard',
      component: () => import('@/views/DashboardView.vue'),
      meta: { title: '工作台' },
    },
    {
      path: '/expenses',
      name: 'expenses',
      component: () => import('@/views/ExpenseListView.vue'),
      meta: { title: '差旅报销' },
    },
    {
      path: '/approvals',
      name: 'approvals',
      component: () => import('@/views/ApprovalView.vue'),
      meta: { title: '审批中心' },
    },
    {
      path: '/kanban',
      name: 'kanban',
      component: () => import('@/views/KanbanView.vue'),
      meta: { title: '流程看板' },
    },
    {
      path: '/reimbursement',
      name: 'reimbursement-list',
      component: () => import('@/views/reimbursement/ReimbursementListView.vue'),
      meta: { title: '报销单列表' },
    },
    {
      path: '/reimbursement/new',
      name: 'reimbursement-new',
      component: () => import('@/views/reimbursement/ReimbursementDetailView.vue'),
      meta: { title: '新建报销单' },
    },
    {
      path: '/reimbursement/:id',
      name: 'reimbursement-detail',
      component: () => import('@/views/reimbursement/ReimbursementDetailView.vue'),
      meta: { title: '报销单详情' },
    },
    {
      path: '/reimbursement/:id/edit',
      name: 'reimbursement-edit',
      component: () => import('@/views/reimbursement/ReimbursementDetailView.vue'),
      meta: { title: '编辑报销单' },
    },
  ],
})

export default router
