import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import {
  type Reimbursement,
  type ReimbursementQuery,
  DocumentStatus,
  REIMBURSEMENT_DOCUMENT_TYPE,
  type TravelRecord,
  type AllowanceInfo,
  type CostAllocation,
  type AllowanceCalendarItem,
} from '@/types/reimbursement'
import {
  generateAllowanceCalendar,
  checkTravelRecordOverlap,
  calculateEvenAllocation,
  calculateDaysBetween,
} from '@/utils/reimbursementUtils'
import { reimbursementApi } from '@/api/reimbursement'

export const useReimbursementStore = defineStore('reimbursement', () => {
  const reimbursementList = ref<Reimbursement[]>([])
  const currentReimbursement = ref<Reimbursement | null>(null)
  const loading = ref(false)
  const total = ref(0)
  const currentPage = ref(1)
  const pageSize = ref(10)
  const query = ref<ReimbursementQuery>({})
  const isViewMode = ref(false)

  const totalAllowanceAmount = computed(() => {
    if (!currentReimbursement.value) return 0
    return currentReimbursement.value.allowances.reduce(
      (sum, a) => sum + a.totalAllowanceAmount,
      0,
    )
  })

  const totalMealAmount = computed(() => {
    if (!currentReimbursement.value) return 0
    return currentReimbursement.value.allowances.reduce((sum, a) => {
      return sum + a.calendar.reduce((s, c) => s + (c.mealSelected ? c.mealAmount : 0), 0)
    }, 0)
  })

  const totalTransportAmount = computed(() => {
    if (!currentReimbursement.value) return 0
    return currentReimbursement.value.allowances.reduce((sum, a) => {
      return sum + a.calendar.reduce((s, c) => s + (c.transportSelected ? c.transportAmount : 0), 0)
    }, 0)
  })

  const totalCommunicationAmount = computed(() => {
    if (!currentReimbursement.value) return 0
    return currentReimbursement.value.allowances.reduce((sum, a) => {
      return (
        sum + a.calendar.reduce((s, c) => s + (c.communicationSelected ? c.communicationAmount : 0), 0)
      )
    }, 0)
  })

  const totalAllocationAmount = computed(() => {
    if (!currentReimbursement.value) return 0
    return currentReimbursement.value.costAllocations.reduce((sum, a) => sum + a.amount, 0)
  })

  const totalAllocationRatio = computed(() => {
    if (!currentReimbursement.value) return 0
    return currentReimbursement.value.costAllocations.reduce((sum, a) => sum + a.ratio, 0)
  })

  async function fetchReimbursements() {
    loading.value = true
    try {
      const { data } = await reimbursementApi.getList(
        query.value,
        currentPage.value,
        pageSize.value,
      )
      reimbursementList.value = data.list
      total.value = data.total
    } finally {
      loading.value = false
    }
  }

  async function fetchReimbursementDetail(id: string) {
    loading.value = true
    try {
      const { data } = await reimbursementApi.getDetail(id)
      currentReimbursement.value = data
    } finally {
      loading.value = false
    }
  }

  function syncTotalsToCurrent() {
    if (!currentReimbursement.value) return
    currentReimbursement.value.totalAllowanceAmount = totalAllowanceAmount.value
    currentReimbursement.value.totalMealAmount = totalMealAmount.value
    currentReimbursement.value.totalTransportAmount = totalTransportAmount.value
    currentReimbursement.value.totalCommunicationAmount = totalCommunicationAmount.value
  }

  function getSnapshot(): Reimbursement {
    if (!currentReimbursement.value) {
      throw new Error('报销单不存在')
    }
    syncTotalsToCurrent()
    return JSON.parse(JSON.stringify(currentReimbursement.value)) as Reimbursement
  }

  async function saveReimbursement(): Promise<Reimbursement> {
    const payload = getSnapshot()
    if (payload.id) {
      const { data } = await reimbursementApi.update(payload.id, payload)
      currentReimbursement.value = data
      return data
    }
    const { data } = await reimbursementApi.create(payload)
    currentReimbursement.value = data
    return data
  }

  async function submitReimbursement() {
    const saved = await saveReimbursement()
    await reimbursementApi.submit(saved.id)
    if (currentReimbursement.value) {
      currentReimbursement.value.status = DocumentStatus.COMPLETED
    }
  }

  async function deleteReimbursement(id: string) {
    await reimbursementApi.delete(id)
  }

  function newLocalId(prefix: string) {
    return `${prefix}_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`
  }

  function copyReimbursement(reimbursement: Reimbursement): Reimbursement {
    const travelIdMap = new Map<string, string>()
    const travelRecords = (reimbursement.travelRecords ?? []).map((r) => {
      const newId = newLocalId('travel')
      travelIdMap.set(r.id, newId)
      return { ...r, id: newId }
    })

    const copied: Reimbursement = {
      ...JSON.parse(JSON.stringify(reimbursement)),
      id: '',
      documentNo: '',
      status: DocumentStatus.DRAFT,
      createdAt: new Date().toISOString().split('T')[0]!,
      basicInfo: {
        ...reimbursement.basicInfo,
        title: reimbursement.basicInfo.title ? `${reimbursement.basicInfo.title}-副本` : '',
      },
      travelRecords,
      allowances: (reimbursement.allowances ?? []).map((a) => ({
        ...a,
        id: newLocalId('allowance'),
        travelRecordId: travelIdMap.get(a.travelRecordId) ?? a.travelRecordId,
        calendar: (a.calendar ?? []).map((c) => ({ ...c })),
      })),
      costAllocations: (reimbursement.costAllocations ?? []).map((a) => ({
        ...a,
        id: newLocalId('allocation'),
      })),
    }
    currentReimbursement.value = copied
    return copied
  }

  async function copyReimbursementFromId(id: string): Promise<Reimbursement> {
    await fetchReimbursementDetail(id)
    if (!currentReimbursement.value) {
      throw new Error('报销单不存在')
    }
    return copyReimbursement(currentReimbursement.value)
  }

  function createNewReimbursement() {
    currentReimbursement.value = {
      id: '',
      documentNo: '',
      documentType: REIMBURSEMENT_DOCUMENT_TYPE,
      status: DocumentStatus.DRAFT,
      createdAt: new Date().toISOString().split('T')[0]!,
      basicInfo: {
        title: '',
        reason: '',
        reimburserId: '',
        reimburserName: '',
        reimburserNo: '',
        departmentId: '',
        departmentName: '',
        departmentNo: '',
        companyId: '',
        companyName: '',
        companyNo: '',
        businessTypeId: '',
        businessTypeName: '',
        businessTypeNo: '',
      },
      travelRecords: [],
      allowances: [],
      costAllocations: [
        {
          id: `allocation_${Date.now()}`,
          companyId: '',
          companyName: '',
          companyNo: '',
          projectId: '',
          projectName: '',
          projectNo: '',
          ratio: 1,
          amount: 0,
        },
      ],
      remark: '',
      totalAllowanceAmount: 0,
      totalMealAmount: 0,
      totalTransportAmount: 0,
      totalCommunicationAmount: 0,
    }
  }

  function addTravelRecord(record: Omit<TravelRecord, 'id'>) {
    if (!currentReimbursement.value) return

    if (checkTravelRecordOverlap(currentReimbursement.value.travelRecords, record as TravelRecord)) {
      throw new Error('存在完全重叠的行程记录')
    }

    const newRecord: TravelRecord = {
      ...record,
      id: `travel_${Date.now()}`,
    }
    currentReimbursement.value.travelRecords.push(newRecord)

    const calendar = generateAllowanceCalendar(
      record.departureDate,
      record.arrivalDate,
      record.arrivalCityId,
    )

    const allowanceDays = calculateDaysBetween(record.departureDate, record.arrivalDate)
    const totalApplyAmount = calendar.reduce(
      (sum, c) => sum + c.mealAllowance + c.transportAllowance + c.communicationAllowance,
      0,
    )

    const newAllowance: AllowanceInfo = {
      id: `allowance_${Date.now()}`,
      travelRecordId: newRecord.id,
      reimburserId: record.reimburserId,
      reimburserName: record.reimburserName,
      departureDate: record.departureDate,
      arrivalDate: record.arrivalDate,
      allowanceDays,
      departureCity: record.departureCityName,
      arrivalCity: record.arrivalCityName,
      calendar,
      totalApplyAmount,
      totalAllowanceAmount: 0,
    }
    currentReimbursement.value.allowances.push(newAllowance)
  }

  function updateTravelRecord(id: string, record: Partial<TravelRecord>) {
    if (!currentReimbursement.value) return
    const index = currentReimbursement.value.travelRecords.findIndex((r) => r.id === id)
    if (index !== -1) {
      currentReimbursement.value.travelRecords[index] = {
        ...currentReimbursement.value.travelRecords[index]!,
        ...record,
      }

      const allowance = currentReimbursement.value.allowances.find((a) => a.travelRecordId === id)
      if (allowance && record.arrivalCityId) {
        allowance.calendar = generateAllowanceCalendar(
          record.departureDate || allowance.departureDate,
          record.arrivalDate || allowance.arrivalDate,
          record.arrivalCityId,
        )
      }
    }
  }

  function deleteTravelRecord(id: string) {
    if (!currentReimbursement.value) return
    currentReimbursement.value.travelRecords =
      currentReimbursement.value.travelRecords.filter((r) => r.id !== id)
    currentReimbursement.value.allowances = currentReimbursement.value.allowances.filter(
      (a) => a.travelRecordId !== id,
    )
  }

  function updateAllowanceCalendar(allowanceId: string, calendar: AllowanceCalendarItem[]) {
    if (!currentReimbursement.value) return
    const allowance = currentReimbursement.value.allowances.find((a) => a.id === allowanceId)
    if (allowance) {
      allowance.calendar = calendar
      allowance.totalAllowanceAmount = calendar.reduce((sum, c) => {
        let dayTotal = 0
        if (c.mealSelected) dayTotal += c.mealAmount
        if (c.transportSelected) dayTotal += c.transportAmount
        if (c.communicationSelected) dayTotal += c.communicationAmount
        return sum + dayTotal
      }, 0)
    }
  }

  function addCostAllocation() {
    if (!currentReimbursement.value) return
    currentReimbursement.value.costAllocations.push({
      id: `allocation_${Date.now()}`,
      companyId: '',
      companyName: '',
      companyNo: '',
      projectId: '',
      projectName: '',
      projectNo: '',
      ratio: 0,
      amount: 0,
    })
  }

  function updateCostAllocation(id: string, allocation: Partial<CostAllocation>) {
    if (!currentReimbursement.value) return
    const index = currentReimbursement.value.costAllocations.findIndex((a) => a.id === id)
    if (index !== -1) {
      currentReimbursement.value.costAllocations[index] = {
        ...currentReimbursement.value.costAllocations[index]!,
        ...allocation,
      }

      if (index > 0 && allocation.ratio !== undefined) {
        const allocations = currentReimbursement.value.costAllocations
        let sum = 0
        for (let i = 1; i < allocations.length; i++) {
          sum += allocations[i]!.ratio
        }

        if (sum > 1) {
          allocations[index]!.ratio = 0
          allocations[index]!.amount = 0
        } else {
          allocations[0]!.ratio = 1 - sum
          allocations[0]!.amount = totalAllowanceAmount.value * allocations[0]!.ratio
          allocations[index]!.amount = totalAllowanceAmount.value * allocation.ratio
        }
      }
    }
  }

  function deleteCostAllocation(id: string) {
    if (!currentReimbursement.value) return
    if (currentReimbursement.value.costAllocations.length <= 1) {
      throw new Error('至少保留一条分摊信息')
    }
    currentReimbursement.value.costAllocations =
      currentReimbursement.value.costAllocations.filter((a) => a.id !== id)

    const allocations = currentReimbursement.value.costAllocations
    let sum = 0
    for (let i = 1; i < allocations.length; i++) {
      sum += allocations[i]!.ratio
    }
    allocations[0]!.ratio = 1 - sum
    allocations[0]!.amount = totalAllowanceAmount.value * allocations[0]!.ratio
  }

  function evenAllocation() {
    if (!currentReimbursement.value) return
    const allocations = currentReimbursement.value.costAllocations
    if (allocations.length === 0) return

    const evenResults = calculateEvenAllocation(totalAllowanceAmount.value, allocations.length)
    allocations.forEach((a, i) => {
      a.ratio = evenResults[i]!.ratio
      a.amount = evenResults[i]!.amount
    })
  }

  function validateBeforeSubmit(): string[] {
    const errors: string[] = []
    if (!currentReimbursement.value) return ['报销单不存在']

    const { basicInfo, travelRecords, allowances, costAllocations } = currentReimbursement.value

    if (!basicInfo.title) errors.push('请填写报销标题')
    if (!basicInfo.reason) errors.push('请填写出差事由')
    if (!basicInfo.reimburserId) errors.push('请选择报销人')
    if (!basicInfo.departmentId) errors.push('请选择报销部门')
    if (!basicInfo.companyId) errors.push('请选择费用归属公司')
    if (!basicInfo.businessTypeId) errors.push('请选择业务类型')

    if (travelRecords.length === 0) errors.push('请至少添加一条补录行程')
    if (allowances.length === 0) errors.push('请至少添加一条补助信息')
    if (costAllocations.length === 0) errors.push('请至少添加一条分摊信息')

    if (totalAllocationRatio.value !== 1) errors.push('分摊比例合计必须为100%')
    if (Math.abs(totalAllocationAmount.value - totalAllowanceAmount.value) > 0.01) {
      errors.push('分摊金额合计必须等于补助总金额')
    }

    return errors
  }

  return {
    reimbursementList,
    currentReimbursement,
    loading,
    total,
    currentPage,
    pageSize,
    query,
    isViewMode,
    totalAllowanceAmount,
    totalMealAmount,
    totalTransportAmount,
    totalCommunicationAmount,
    totalAllocationAmount,
    totalAllocationRatio,
    fetchReimbursements,
    fetchReimbursementDetail,
    createNewReimbursement,
    copyReimbursement,
    copyReimbursementFromId,
    addTravelRecord,
    updateTravelRecord,
    deleteTravelRecord,
    updateAllowanceCalendar,
    addCostAllocation,
    updateCostAllocation,
    deleteCostAllocation,
    evenAllocation,
    validateBeforeSubmit,
    saveReimbursement,
    submitReimbursement,
    deleteReimbursement,
  }
})
