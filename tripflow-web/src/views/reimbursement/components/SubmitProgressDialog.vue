<template>
  <el-dialog
    v-model="visible"
    title="提交"
    width="400px"
    :close-on-click-modal="false"
    :close-on-press-escape="false"
    :show-close="false"
    align-center
    destroy-on-close
  >
    <div class="submit-progress-content">
      <p class="status-text" :class="{ 'success-text': status === 'success', 'error-text': status === 'error' }">
        {{ status === 'processing' ? '正在校验中...' : status === 'success' ? '提交成功' : errorMessage }}
      </p>
      <el-progress
        :percentage="progress"
        :stroke-width="10"
        :status="status === 'success' ? 'success' : status === 'error' ? 'exception' : undefined"
      />
    </div>
    <template #footer>
      <el-button :disabled="status === 'processing'" :type="status === 'processing' ? 'info' : 'primary'" @click="handleConfirm">
        确认
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const visible = ref(false)
const status = ref<'processing' | 'success' | 'error'>('processing')
const progress = ref(0)
const errorMessage = ref('')

let resolvePromise: ((value: 'success' | 'error') => void) | null = null

function open(): Promise<'success' | 'error'> {
  visible.value = true
  status.value = 'processing'
  progress.value = 0
  errorMessage.value = ''

  return new Promise<'success' | 'error'>((resolve) => {
    resolvePromise = resolve
  })
}

function setProgress(value: number) {
  progress.value = Math.min(100, Math.max(0, value))
}

function setSuccess() {
  status.value = 'success'
  progress.value = 100
}

function setError(message: string) {
  status.value = 'error'
  errorMessage.value = message
  progress.value = 100
}

function handleConfirm() {
  visible.value = false
  if (status.value === 'success') {
    resolvePromise?.('success')
  } else {
    resolvePromise?.('error')
  }
  resolvePromise = null
}

defineExpose({ open, setProgress, setSuccess, setError })
</script>

<style scoped>
.submit-progress-content {
  padding: 16px 0;
  text-align: center;
}

.status-text {
  font-size: 16px;
  margin-bottom: 16px;
  color: #606266;
  min-height: 24px;
}

.success-text {
  color: #67c23a;
}

.error-text {
  color: #f56c6c;
}
</style>
