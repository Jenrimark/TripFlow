<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { reimbursementApi } from '@/api/reimbursement'
import { getWorkflowTasks } from '@/api/workflow'
import { DocumentStatus } from '@/types/reimbursement'

const reimbursementCount = ref(0)
const draftCount = ref(0)
const kanbanTodoCount = ref(0)
const loading = ref(false)

onMounted(async () => {
  loading.value = true
  try {
    const [reimbursementRes, taskRes] = await Promise.all([
      reimbursementApi.getList({}, 1, 500),
      getWorkflowTasks(),
    ])
    reimbursementCount.value = reimbursementRes.data.total
    draftCount.value = reimbursementRes.data.list.filter(
      (item) => item.status === DocumentStatus.DRAFT,
    ).length
    kanbanTodoCount.value = taskRes.data.filter((t) => t.kanbanStatus === 'todo').length
  } catch {
    ElMessage.warning('无法连接后端，请先启动 tripflow-api 并初始化数据库')
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div v-loading="loading" class="dashboard">
    <el-row :gutter="16">
      <el-col :span="8">
        <el-card shadow="hover">
          <p class="label">报销单总数</p>
          <p class="value">{{ reimbursementCount }}</p>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="hover">
          <p class="label">草稿报销</p>
          <p class="value warn">{{ draftCount }}</p>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="hover">
          <p class="label">看板待办</p>
          <p class="value">{{ kanbanTodoCount }}</p>
        </el-card>
      </el-col>
    </el-row>

    <el-alert
      class="hint"
      title="TripFlow 骨架已就绪"
      type="info"
      description="后续可在此扩展：报销填报、多级审批、看板拖拽、与财务系统对接等能力。"
      show-icon
      :closable="false"
    />
  </div>
</template>

<style scoped>
.dashboard {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.label {
  margin: 0;
  color: #64748b;
  font-size: 14px;
}

.value {
  margin: 8px 0 0;
  font-size: 32px;
  font-weight: 700;
}

.value.warn {
  color: #d97706;
}

.hint {
  margin-top: 8px;
}
</style>
