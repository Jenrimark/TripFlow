import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { DocumentStatus } from '@/types/reimbursement'

export function useReimbursementPageMode() {
  const route = useRoute()
  const store = useReimbursementStore()

  const isViewMode = computed(() => {
    if (route.name === 'reimbursement-detail') return true
    return store.currentReimbursement?.status === DocumentStatus.VOIDED
  })

  return { isViewMode }
}
