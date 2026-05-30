import { computed } from 'vue'
import { useRoute } from 'vue-router'

export function useReimbursementPageMode() {
  const route = useRoute()

  const isViewMode = computed(() => route.name === 'reimbursement-detail')

  return { isViewMode }
}
