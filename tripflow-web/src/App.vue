<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Fold, Expand } from '@element-plus/icons-vue'
import { useReimbursementStore } from '@/stores/reimbursementStore'

const route = useRoute()
const router = useRouter()
const collapsed = ref(true)
const reimbursementStore = useReimbursementStore()

const activeMenu = computed(() => {
  if (route.path.startsWith('/reimbursement')) return '/reimbursement'
  return route.path
})

const isReimbursementEditPage = computed(() => {
  return route.name === 'reimbursement-new' || route.name === 'reimbursement-edit'
})

const currentDate = computed(() => {
  return reimbursementStore.currentReimbursement?.createdAt || new Date().toISOString().split('T')[0]
})

const menuItems = [
  { path: '/', label: '工作台', icon: 'Odometer' },
  { path: '/reimbursement', label: '差旅报销', icon: 'Wallet' },
  { path: '/approvals', label: '审批中心', icon: 'CircleCheck' },
  { path: '/kanban', label: '流程看板', icon: 'Grid' },
]

function navigate(path: string) {
  router.push(path)
}
</script>

<template>
  <el-container class="layout">
    <el-aside :width="collapsed ? '0px' : '220px'" class="aside">
      <div class="brand" :class="{ 'brand--collapsed': collapsed }">
        <span class="brand-mark">TF</span>
        <div v-show="!collapsed" class="brand-text">
          <strong>TripFlow</strong>
          <p>差旅报销 · 流程审批</p>
        </div>
      </div>
      <el-menu :default-active="activeMenu" :collapse="collapsed" router>
        <el-menu-item
          v-for="item in menuItems"
          :key="item.path"
          :index="item.path"
          @click="navigate(item.path)"
        >
          {{ item.label }}
        </el-menu-item>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="header">
        <div class="collapse-btn" @click="collapsed = !collapsed">
          <el-icon :size="16">
            <Expand v-if="collapsed" />
            <Fold v-else />
          </el-icon>
        </div>
        <h2 v-if="!isReimbursementEditPage">{{ route.meta.title }}</h2>
        <template v-else>
          <h1 class="document-title">差旅费用报销单</h1>
          <span class="document-date">提单日期 {{ currentDate }}</span>
        </template>
      </el-header>
      <el-main class="main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<style scoped>
.layout {
  min-height: 100vh;
}

.aside {
  position: sticky;
  top: 0;
  height: 100vh;
  z-index: 20;
  background: #0f172a;
  color: #e2e8f0;
  border-right: 1px solid #1e293b;
  transition: width 0.25s ease;
  overflow: hidden;
  min-width: 0 !important;
}

.brand {
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 20px 16px;
  border-bottom: 1px solid #1e293b;
  white-space: nowrap;
}

.brand--collapsed {
  justify-content: center;
  padding: 20px 12px;
}

.brand-mark {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: linear-gradient(135deg, #38bdf8, #6366f1);
  color: #fff;
  font-weight: 700;
  flex-shrink: 0;
}

.brand p {
  margin: 4px 0 0;
  font-size: 12px;
  color: #94a3b8;
}

.brand-text {
  overflow: hidden;
}

.aside :deep(.el-menu) {
  border-right: none;
  background: transparent;
}

.aside :deep(.el-menu-item) {
  color: #cbd5e1;
}

.aside :deep(.el-menu-item.is-active) {
  background: #1e293b;
  color: #fff;
}

.header {
  display: flex;
  align-items: center;
  border-bottom: 1px solid #e2e8f0;
  background: #fff;
  position: sticky;
  top: 0;
  z-index: 10;
}

.header h2 {
  margin: 0;
  font-size: 18px;
  flex: 1;
  text-align: center;
}

.header-center {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 24px;
  flex: 1;
}

.document-title {
  font-size: 20px;
  font-weight: bold;
  color: #303133;
  margin: 0;
  text-align: center;
  flex: 1;
  padding-left: 5%;
}

.document-date {
  font-size: 14px;
  color: #606266;
  white-space: nowrap;
  flex-shrink: 0;
}

.collapse-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 4px;
  color: #64748b;
  cursor: pointer;
  transition: color 0.2s, background 0.2s;
  flex-shrink: 0;
}

.collapse-btn:hover {
  color: #0f172a;
  background: #e2e8f0;
}

.main {
  background: #f8fafc;
  padding-left: 0;
  padding-right: 0;
}
</style>
