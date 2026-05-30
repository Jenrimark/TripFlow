<template>
  <div class="remark-section">
    <div class="section-header">
      <span class="section-title">备注信息</span>
      <el-button v-if="!store.isViewMode" type="danger" size="small" @click="handleClear">删除备注</el-button>
    </div>

    <div class="section-content">
      <el-input
        v-model="remark"
        type="textarea"
        placeholder="请输入备注信息"
        maxlength="1000"
        show-word-limit
        :rows="4"
        :disabled="store.isViewMode"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useReimbursementStore } from '@/stores/reimbursementStore'

const store = useReimbursementStore()

const remark = computed({
  get: () => store.currentReimbursement?.remark || '',
  set: (value) => {
    if (store.currentReimbursement) {
      store.currentReimbursement.remark = value
    }
  },
})

function handleClear() {
  ElMessageBox.confirm('确定要删除备注信息吗？', '提示', { type: 'warning' }).then(() => {
    if (store.currentReimbursement) {
      store.currentReimbursement.remark = ''
      ElMessage.success('删除成功')
    }
  })
}
</script>

<style scoped>
.remark-section {
  background: white;
  border-radius: 4px;
  margin-bottom: 16px;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
  border-bottom: 1px solid #ebeef5;
}

.section-title {
  font-size: 16px;
  font-weight: bold;
  color: #303133;
}

.section-content {
  padding: 20px;
}
</style>
