<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

const activeMenu = computed(() => {
  if (route.path.startsWith('/reimbursement')) return '/reimbursement'
  return route.path
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
    <el-aside width="220px" class="aside">
      <div class="brand">
        <span class="brand-mark">TF</span>
        <div>
          <strong>TripFlow</strong>
          <p>差旅报销 · 流程审批</p>
        </div>
      </div>
      <el-menu :default-active="activeMenu" router>
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
        <h2>{{ route.meta.title }}</h2>
      </el-header>
      <el-main class="main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<style scoped>
.layout {
  --sidebar-width: 220px;
  min-height: 100vh;
}

.aside {
  position: relative;
  z-index: 20;
  background: #0f172a;
  color: #e2e8f0;
  border-right: 1px solid #1e293b;
}

.brand {
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 20px 16px;
  border-bottom: 1px solid #1e293b;
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
}

.brand p {
  margin: 4px 0 0;
  font-size: 12px;
  color: #94a3b8;
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
}

.header h2 {
  margin: 0;
  font-size: 18px;
}

.main {
  background: #f8fafc;
}
</style>
