<template>
  <div class="form-footer">
    <el-button @click="handleClose">关闭</el-button>
    <el-button
      v-if="!isViewMode && !isVoided"
      type="primary"
      @click="handleSubmit"
      :loading="submitting"
    >提交</el-button>
    <SubmitProgressDialog ref="progressDialogRef" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { useReimbursementPageMode } from '@/composables/useReimbursementPageMode'
import { DocumentStatus } from '@/types/reimbursement'
import SubmitProgressDialog from './SubmitProgressDialog.vue'

const router = useRouter()
const store = useReimbursementStore()
const { isViewMode } = useReimbursementPageMode()
const submitting = ref(false)
const progressDialogRef = ref<InstanceType<typeof SubmitProgressDialog> | null>(null)

const isVoided = computed(() => store.currentReimbursement?.status === DocumentStatus.VOIDED)

const isNewPage = computed(() => !store.currentReimbursement?.id)

function handleClose() {
  if (isViewMode.value) {
    router.back()
    return
  }

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
    try {
      await store.saveReimbursement()
      ElMessage.success('暂存成功')
      router.push('/reimbursement')
    } catch {
      ElMessage.error('暂存失败')
    }
  }).catch((action) => {
    if (action === 'cancel') {
      router.push('/reimbursement')
    }
  })
}

async function handleSubmit() {
  if (submitting.value) return
  submitting.value = true

  const dialog = progressDialogRef.value
  if (!dialog) {
    submitting.value = false
    return
  }

  const resultPromise = dialog.open()
  const startTime = Date.now()

  // 进度条动画：根据实际耗时动态匀速走到 100%
  let animating = true
  const minDuration = 1000 // 最少 1 秒，保证观感
  let timer: ReturnType<typeof setInterval>

  function startProgressAnimation() {
    timer = setInterval(() => {
      const elapsed = Date.now() - startTime
      // 用 elapsed / minDuration 来控制速度，但不超过 95（留给完成时跳到 100）
      const target = Math.min((elapsed / minDuration) * 95, 95)
      dialog.setProgress(Math.floor(target))
      if (!animating) clearInterval(timer)
    }, 30)
  }

  function stopProgressAnimation() {
    animating = false
    clearInterval(timer)
    // 确保至少走完动画时间再显示结果
    const elapsed = Date.now() - startTime
    const remaining = Math.max(0, minDuration - elapsed)
    return new Promise<void>((resolve) => setTimeout(resolve, remaining))
  }

  startProgressAnimation()

  // 校验
  const errors = store.validateBeforeSubmit()
  if (errors.length > 0) {
    await stopProgressAnimation()
    dialog.setError(errors[0]!)
    submitting.value = false
    await resultPromise
    return
  }

  // 提交
  try {
    await store.submitReimbursement()
    await stopProgressAnimation()
    dialog.setSuccess()
  } catch (err: any) {
    await stopProgressAnimation()
    dialog.setError(err?.message || '提交失败')
  }

  submitting.value = false

  const result = await resultPromise
  if (result === 'success') {
    router.push('/reimbursement')
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
