<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { getWorkflowTasks } from '@/api/workflow'
import type { WorkflowTask } from '@/types/workflow'

const tasks = ref<WorkflowTask[]>([])
const loading = ref(false)

const columns = [
  { key: 'todo' as const, title: '待办' },
  { key: 'in_progress' as const, title: '进行中' },
  { key: 'done' as const, title: '已完成' },
]

const grouped = computed(() =>
  columns.map((col) => ({
    ...col,
    items: tasks.value.filter((t) => t.kanbanStatus === col.key),
  })),
)

onMounted(async () => {
  loading.value = true
  try {
    const { data } = await getWorkflowTasks()
    tasks.value = data
  } catch {
    ElMessage.error('加载看板任务失败')
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div v-loading="loading" class="kanban">
    <div v-for="col in grouped" :key="col.key" class="column">
      <h3>{{ col.title }} ({{ col.items.length }})</h3>
      <el-card v-for="task in col.items" :key="task.id" class="task-card" shadow="hover">
        <p class="task-title">{{ task.title }}</p>
        <el-tag size="small">{{ task.taskType === 'expense_approval' ? '报销审批' : '通用' }}</el-tag>
      </el-card>
      <el-empty v-if="col.items.length === 0" description="暂无任务" :image-size="60" />
    </div>
  </div>
</template>

<style scoped>
.kanban {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.column {
  background: #fff;
  border-radius: 8px;
  padding: 12px;
  min-height: 320px;
  border: 1px solid #e2e8f0;
}

.column h3 {
  margin: 0 0 12px;
  font-size: 15px;
}

.task-card {
  margin-bottom: 10px;
}

.task-title {
  margin: 0 0 8px;
  font-weight: 600;
}
</style>
