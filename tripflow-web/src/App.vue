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
        <svg class="brand-icon" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
          <rect width="64" height="64" rx="14" fill="#2563eb"/>
          <path d="M12 50 Q36 42 52 18" fill="none" stroke="rgba(255,255,255,0.35)" stroke-width="3" stroke-linecap="round"/>
          <circle cx="12" cy="50" r="3.5" fill="white" fill-opacity="0.8"/>
          <circle cx="52" cy="18" r="3.5" fill="white" fill-opacity="0.8"/>
          <g transform="translate(34,30) rotate(-40)"><path d="M0,-12 L4,-4 L12,0 L4,2 L3,8 L0,4 L-3,8 L-4,2 L-12,0 L-4,-4 Z" fill="white"/></g>
        </svg>
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
        <template v-if="!collapsed">
          <div class="collapse-btn" @click="collapsed = true">
            <el-icon :size="16"><Fold /></el-icon>
          </div>
        </template>
        <template v-else>
          <div class="header-brand" @click="collapsed = false">
            <svg class="header-brand-icon" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
              <rect width="64" height="64" rx="14" fill="#2563eb"/>
              <path d="M12 50 Q36 42 52 18" fill="none" stroke="rgba(255,255,255,0.35)" stroke-width="3" stroke-linecap="round"/>
              <circle cx="12" cy="50" r="3.5" fill="white" fill-opacity="0.8"/>
              <circle cx="52" cy="18" r="3.5" fill="white" fill-opacity="0.8"/>
              <g transform="translate(34,30) rotate(-40)"><path d="M0,-12 L4,-4 L12,0 L4,2 L3,8 L0,4 L-3,8 L-4,2 L-12,0 L-4,-4 Z" fill="white"/></g>
            </svg>
            <span class="header-brand-name">TripFlow</span>
          </div>
        </template>
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

.brand-icon {
  width: 40px;
  height: 40px;
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

.header-brand {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-right: 12px;
  flex-shrink: 0;
  cursor: pointer;
  user-select: none;
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
  margin-right: 12px;
}

.collapse-btn:hover {
  color: #0f172a;
  background: #e2e8f0;
}

.header-brand-icon {
  width: 28px;
  height: 28px;
}

.header-brand-name {
  font-size: 15px;
  font-weight: 700;
  background: linear-gradient(135deg, #38bdf8, #6366f1);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
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

.main {
  background: #f8fafc;
  padding-left: 0;
  padding-right: 0;
}
</style>
