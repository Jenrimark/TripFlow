<template>
  <div class="form-footer">
    <el-button @click="handleClose">关闭</el-button>
    <el-button v-if="!store.isViewMode" type="primary" @click="handleSubmit" :loading="submitting">提交</el-button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useReimbursementStore } from '@/stores/reimbursementStore'

const router = useRouter()
const store = useReimbursementStore()
const submitting = ref(false)

function handleClose() {
  if (store.isViewMode) {
    router.back()
  } else {
    ElMessageBox.confirm('确定要关闭当前页面吗？未保存的数据将丢失。', '提示', {
      type: 'warning',
    }).then(() => {
      router.back()
    })
  }
}

async function handleSubmit() {
  const errors = store.validateBeforeSubmit()
  if (errors.length > 0) {
    ElMessage.error(errors[0]!)
    return
  }

  submitting.value = true
  try {
    await store.submitReimbursement()
    ElMessage.success('提交成功')
    router.push('/reimbursement')
  } catch {
    ElMessage.error('提交失败')
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.form-footer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  padding: 16px 20px;
  border-top: 1px solid #ebeef5;
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  z-index: 100;
}
</style>
