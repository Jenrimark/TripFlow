<template>
  <div class="reimbursement-detail">
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
import { ref, computed, watch } from 'vue'
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

const isNewPage = computed(() => route.name === 'reimbursement-new')

async function loadPage() {
  if (isNewPage.value) {
    if (!store.currentReimbursement || store.currentReimbursement.id) {
      store.createNewReimbursement()
    }
    return
  }

  const id = route.params.id as string
  if (id) {
    await store.fetchReimbursementDetail(id)
  }
}

watch(() => route.fullPath, loadPage, { immediate: true })
</script>

<style scoped>
.reimbursement-detail {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  padding-bottom: 80px;
}

.form-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
</style>
