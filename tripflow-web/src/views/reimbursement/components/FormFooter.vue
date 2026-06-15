<template>
  <div class="form-footer">
    <el-button @click="handleClose">关闭</el-button>
    <el-button
      v-if="!isViewMode && !isVoided"
      type="primary"
      @click="handleSubmit"
      :loading="submitting"
    >提交</el-button>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { useReimbursementPageMode } from '@/composables/useReimbursementPageMode'
import { DocumentStatus } from '@/types/reimbursement'

const router = useRouter()
const store = useReimbursementStore()
const { isViewMode } = useReimbursementPageMode()
const submitting = ref(false)

const isVoided = computed(() => store.currentReimbursement?.status === DocumentStatus.VOIDED)

const isNewPage = computed(() => !store.currentReimbursement?.id)

function handleClose() {
  if (isViewMode.value) {
    router.back()
    return
  }

  if (isNewPage.value) {
    ElMessageBox.confirm(
      '请选择操作：',
      '关闭确认',
      {
        type: 'warning',
        confirmButtonText: '暂存',
        cancelButtonText: '关闭',
        distinguishCancelAndClose: true,
        closeOnClickModal: false,
      },
    ).then(async () => {
      // confirm = 暂存
      try {
        await store.saveReimbursement()
        ElMessage.success('暂存成功')
        router.push('/reimbursement')
      } catch {
        ElMessage.error('暂存失败')
      }
    }).catch((action) => {
      if (action === 'cancel') {
        // cancel = 关闭（丢弃数据）
        router.push('/reimbursement')
      }
      // close = 什么都不做
    })
    return
  }

  router.back()
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
  left: var(--sidebar-width, 220px);
  right: 0;
  background: white;
  padding: 16px 20px;
  border-top: 1px solid #ebeef5;
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  z-index: 10;
}
</style>
