<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { getExpenseList } from '@/api/expense'
import type { ExpenseReport } from '@/types/expense'

const list = ref<ExpenseReport[]>([])
const loading = ref(false)

const statusMap: Record<ExpenseReport['status'], { label: string; type: '' | 'success' | 'warning' | 'danger' | 'info' }> = {
  draft: { label: '草稿', type: 'info' },
  pending: { label: '审批中', type: 'warning' },
  approved: { label: '已通过', type: 'success' },
  rejected: { label: '已驳回', type: 'danger' },
}

function expenseStatus(status: ExpenseReport['status']) {
  return statusMap[status]
}

onMounted(async () => {
  loading.value = true
  try {
    const { data } = await getExpenseList()
    list.value = data
  } catch {
    ElMessage.error('加载报销单失败')
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>差旅报销单</span>
        <el-button type="primary" disabled>新建报销（待实现）</el-button>
      </div>
    </template>

    <el-table v-loading="loading" :data="list" stripe border>
      <el-table-column prop="title" label="标题" min-width="180" />
      <el-table-column prop="tripDestination" label="目的地" width="120" />
      <el-table-column label="行程日期" min-width="200">
        <template #default="{ row }">
          {{ row.tripStartDate }} ~ {{ row.tripEndDate }}
        </template>
      </el-table-column>
      <el-table-column prop="amount" label="金额（元）" width="120" />
      <el-table-column prop="status" label="状态" width="110">
        <template #default="{ row }">
          <el-tag :type="expenseStatus(row.status).type">{{ expenseStatus(row.status).label }}</el-tag>
        </template>
      </el-table-column>
    </el-table>
  </el-card>
</template>

<style scoped>
.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
