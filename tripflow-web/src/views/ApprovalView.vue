<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { getWorkflowTasks } from '@/api/workflow'
import type { WorkflowTask } from '@/types/workflow'

const tasks = ref<WorkflowTask[]>([])
const loading = ref(false)

const approvalTasks = computed(() =>
  tasks.value.filter((t) => t.taskType === 'expense_approval'),
)

type TagType = 'success' | 'info' | 'warning' | 'danger' | 'primary'

const approvalStatusText: Record<string, string> = {
  pending: '待处理',
  approved: '已通过',
  rejected: '已驳回',
}

const approvalStatusType: Record<string, TagType> = {
  pending: 'warning',
  approved: 'success',
  rejected: 'danger',
}

function getApprovalStatusText(status: string) {
  return approvalStatusText[status] ?? status
}

function getApprovalStatusType(status: string): TagType {
  return approvalStatusType[status] ?? 'info'
}

onMounted(async () => {
  loading.value = true
  try {
    const { data } = await getWorkflowTasks()
    tasks.value = data
  } catch {
    ElMessage.error('加载审批任务失败')
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <el-card>
    <template #header>待我审批</template>
    <el-table v-loading="loading" :data="approvalTasks" stripe border>
      <el-table-column prop="title" label="任务" min-width="220" />
      <el-table-column prop="approvalStatus" label="审批状态" width="120">
        <template #default="{ row }">
          <el-tag :type="getApprovalStatusType(row.approvalStatus)">
            {{ getApprovalStatusText(row.approvalStatus) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="200">
        <template #default>
          <el-button type="primary" link disabled>通过</el-button>
          <el-button type="danger" link disabled>驳回</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>
</template>
