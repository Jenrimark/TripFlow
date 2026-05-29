<template>
  <div class="reimbursement-detail">
    <div class="document-header">
      <h1 class="document-title">报销单</h1>
      <span class="document-date">{{ currentDate }}</span>
    </div>

    <div class="form-content">
      <BasicInfoSection ref="basicInfoRef" />
      <TravelRecordSection />
      <AllowanceInfoSection />
      <ExpenseSummarySection />
      <CostAllocationSection />
      <RemarkSection />
    </div>

    <FormFooter />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import BasicInfoSection from './components/BasicInfoSection.vue'
import TravelRecordSection from './components/TravelRecordSection.vue'
import AllowanceInfoSection from './components/AllowanceInfoSection.vue'
import ExpenseSummarySection from './components/ExpenseSummarySection.vue'
import CostAllocationSection from './components/CostAllocationSection.vue'
import RemarkSection from './components/RemarkSection.vue'
import FormFooter from './components/FormFooter.vue'

const route = useRoute()
const store = useReimbursementStore()
const basicInfoRef = ref()

const currentDate = computed(() => {
  return store.currentReimbursement?.createdAt || new Date().toISOString().split('T')[0]
})

onMounted(async () => {
  const id = route.params.id as string
  if (id && id !== 'new') {
    await store.fetchReimbursementDetail(id)
  } else if (!store.currentReimbursement) {
    store.createNewReimbursement()
  }
})
</script>

<style scoped>
.reimbursement-detail {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  padding-bottom: 80px;
}

.document-header {
  position: sticky;
  top: 0;
  z-index: 10;
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  padding: 16px 0;
  border-bottom: 2px solid #303133;
  margin-bottom: 20px;
  background: #f8fafc;
}

.document-title {
  grid-column: 2;
  font-size: 20px;
  font-weight: bold;
  color: #303133;
  margin: 0;
  text-align: center;
}

.document-date {
  grid-column: 3;
  justify-self: end;
  font-size: 14px;
  color: #606266;
}

.form-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
</style>
