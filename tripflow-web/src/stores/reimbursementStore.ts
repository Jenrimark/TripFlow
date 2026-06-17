import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
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
      console.log('[DEBUG-fetchReimbursements] API response:', JSON.stringify(data.list.slice(0, 2), null, 2))
      // 兜底: 确保 basicInfo 不为 null，避免模板渲染崩溃
      reimbursementList.value = data.list.map((item: any) => ({
        ...item,
        basicInfo: item.basicInfo ?? {},
      }))
      total.value = data.total
    } catch {
      reimbursementList.value = []
      total.value = 0
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
    // 确保保存前分摊金额与当前补助总额一致，避免旧值直接提交到后端
    if (currentReimbursement.value.costAllocations.length > 0) {
      recalcFromRatios()
      const total = totalAllowanceAmount.value
      currentReimbursement.value.costAllocations.forEach((a, i) => {
        if (i === 0) {
          a.amount = Math.round((total - currentReimbursement.value!.costAllocations.slice(1).reduce((s, x) => s + (x.amount ?? 0), 0)) * 100) / 100
        } else {
          a.amount = Math.floor(total * a.ratio * 100) / 100
        }
      })
    }
    const snapshot = JSON.parse(JSON.stringify(currentReimbursement.value)) as Reimbursement
    // 清理空字符串的可选字段
    for (const record of snapshot.travelRecords) {
      if (!record.departureDatetime) record.departureDatetime = null as any
      if (!record.arrivalDatetime) record.arrivalDatetime = null as any
    }
    // 过滤掉完全空的分摊记录（暂存时可能有默认的空记录）
    snapshot.costAllocations = snapshot.costAllocations.filter(a =>
      a.companyId || a.projectId || a.ratio > 0 || a.amount > 0
    )
    return snapshot
  }

  async function saveReimbursement(): Promise<Reimbursement> {
    const payload = getSnapshot()
    // 每次保存时更新提交日期
    payload.createdAt = new Date().toISOString().split('T')[0]!
    if (currentReimbursement.value) {
      currentReimbursement.value.createdAt = payload.createdAt
    }
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
    const errors = validateBeforeSubmit()
    if (errors.length > 0) {
      throw new Error(errors[0])
    }
    if (currentReimbursement.value) {
      currentReimbursement.value.createdAt = new Date().toISOString().split('T')[0]!
    }
    const saved = await saveReimbursement()
    await reimbursementApi.submit(saved.id, saved.version)
    if (currentReimbursement.value) {
      currentReimbursement.value.status = DocumentStatus.COMPLETED
    }
  }

  async function deleteReimbursement(id: string, version?: number) {
    await reimbursementApi.delete(id, version)
  }

  async function voidReimbursement(id: string, version: number) {
    await reimbursementApi.void(id, version)
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
      version: 0,
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

    const conflictRecord = checkTravelRecordOverlap(currentReimbursement.value.travelRecords, record as TravelRecord)
    if (conflictRecord) {
      throw new Error(`该出行人员在 ${conflictRecord.departureDate} ~ ${conflictRecord.arrivalDate} 已有行程，时间段存在重叠`)
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
      (sum, c) => {
        let dayTotal = 0
        if (c.mealSelected) dayTotal += c.mealAllowance
        if (c.transportSelected) dayTotal += c.transportAllowance
        if (c.communicationSelected) dayTotal += c.communicationAllowance
        return sum + dayTotal
      },
      0,
    )

    const totalAllowanceAmount = calendar.reduce(
      (sum, c) => {
        let dayTotal = 0
        if (c.mealSelected) dayTotal += c.mealAmount
        if (c.transportSelected) dayTotal += c.transportAmount
        if (c.communicationSelected) dayTotal += c.communicationAmount
        return sum + dayTotal
      },
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
      totalAllowanceAmount,
    }
    currentReimbursement.value.allowances.push(newAllowance)

    // 补助金额变更后，同步重算所有分摊行的金额
    if (currentReimbursement.value.costAllocations.length > 0) {
      recalcFromRatios()
    }
  }

  function updateTravelRecord(id: string, record: Partial<TravelRecord>) {
    if (!currentReimbursement.value) return
    const existing = currentReimbursement.value.travelRecords.find((r) => r.id === id)
    if (!existing) return

    // 构造更新后的完整记录，用于校验重叠
    const updatedRecord = { ...existing, ...record }
    // 排除自身，检查与其他记录是否有重叠
    const otherRecords = currentReimbursement.value.travelRecords.filter((r) => r.id !== id)
    const conflictRecord = checkTravelRecordOverlap(otherRecords, updatedRecord)
    if (conflictRecord) {
      throw new Error(`该出行人员在 ${conflictRecord.departureDate} ~ ${conflictRecord.arrivalDate} 已有行程，时间段存在重叠`)
    }

    const index = currentReimbursement.value.travelRecords.findIndex((r) => r.id === id)
    if (index !== -1) {
      currentReimbursement.value.travelRecords[index] = {
        ...currentReimbursement.value.travelRecords[index]!,
        ...record,
      }

      const allowance = currentReimbursement.value.allowances.find((a) => a.travelRecordId === id)
      if (allowance) {
        if (record.arrivalCityId || record.departureCityName || record.arrivalCityName) {
          allowance.departureCity = record.departureCityName || allowance.departureCity
          allowance.arrivalCity = record.arrivalCityName || allowance.arrivalCity
        }
        if (record.departureDate || record.arrivalDate) {
          allowance.departureDate = record.departureDate || allowance.departureDate
          allowance.arrivalDate = record.arrivalDate || allowance.arrivalDate
          allowance.allowanceDays = calculateDaysBetween(allowance.departureDate, allowance.arrivalDate)
        }
        if (record.arrivalCityId || record.departureDate || record.arrivalDate) {
          allowance.calendar = generateAllowanceCalendar(
            allowance.departureDate,
            allowance.arrivalDate,
            record.arrivalCityId || currentReimbursement.value.travelRecords.find((r) => r.id === id)?.arrivalCityId || '',
          )
          allowance.totalApplyAmount = allowance.calendar.reduce(
            (sum, c) => {
              let dayTotal = 0
              if (c.mealSelected) dayTotal += c.mealAllowance
              if (c.transportSelected) dayTotal += c.transportAllowance
              if (c.communicationSelected) dayTotal += c.communicationAllowance
              return sum + dayTotal
            },
            0,
          )
          allowance.totalAllowanceAmount = allowance.calendar.reduce(
            (sum, c) => {
              let dayTotal = 0
              if (c.mealSelected) dayTotal += c.mealAmount
              if (c.transportSelected) dayTotal += c.transportAmount
              if (c.communicationSelected) dayTotal += c.communicationAmount
              return sum + dayTotal
            },
            0,
          )
        }
      }
    }

    // 补助金额变更后，同步重算所有分摊行的金额
    if (currentReimbursement.value.costAllocations.length > 0) {
      recalcFromRatios()
    }
  }

  function deleteTravelRecord(id: string) {
    if (!currentReimbursement.value) return
    currentReimbursement.value.travelRecords =
      currentReimbursement.value.travelRecords.filter((r) => r.id !== id)
    currentReimbursement.value.allowances = currentReimbursement.value.allowances.filter(
      (a) => a.travelRecordId !== id,
    )

    // 补助金额变更后，同步重算所有分摊行的金额
    if (currentReimbursement.value.costAllocations.length > 0) {
      recalcFromRatios()
    }
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
      allowance.totalApplyAmount = calendar.reduce((sum, c) => {
        let dayTotal = 0
        if (c.mealSelected) dayTotal += c.mealAllowance
        if (c.transportSelected) dayTotal += c.transportAllowance
        if (c.communicationSelected) dayTotal += c.communicationAllowance
        return sum + dayTotal
      }, 0)
    }
    // 补助金额变更后，同步重算所有分摊行的金额
    if (currentReimbursement.value.costAllocations.length > 0) {
      recalcFromRatios()
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
    // 新增空行后重算，确保首行金额随补助总额更新
    if (currentReimbursement.value.costAllocations.length > 1) {
      recalcFromRatios()
    }
  }

  /** 根据 ratio 重新计算所有行的 ratio（显示用）和 amount */
  function recalcFromRatios() {
    if (!currentReimbursement.value) return
    const allocations = currentReimbursement.value.costAllocations
    const total = totalAllowanceAmount.value

    // 第一行 ratio = 1 - sum(其余行ratio)
    let othersSum = 0
    for (let i = 1; i < allocations.length; i++) {
      othersSum += allocations[i]!.ratio
    }
    // 四舍五入到8位小数，消除浮点误差
    allocations[0]!.ratio = Math.round((1 - othersSum) * 1e8) / 1e8

    // 金额按 ratio 计算，最后一分钱差额给第一行
    let othersAmountSum = 0
    for (let i = 1; i < allocations.length; i++) {
      allocations[i]!.amount = Math.floor(total * allocations[i]!.ratio * 100) / 100
      othersAmountSum += allocations[i]!.amount
    }
    allocations[0]!.amount = Math.round((total - othersAmountSum) * 100) / 100
  }

  function updateCostAllocation(id: string, allocation: Partial<CostAllocation>) {
    if (!currentReimbursement.value) return
    const index = currentReimbursement.value.costAllocations.findIndex((a) => a.id === id)
    if (index === -1) return

    currentReimbursement.value.costAllocations[index] = {
      ...currentReimbursement.value.costAllocations[index]!,
      ...allocation,
    }

    // 用户改了 ratio（百分比输入框），直接重算
    if (index > 0 && allocation.ratio !== undefined) {
      const ratio = allocation.ratio
      const allocations = currentReimbursement.value.costAllocations

      let othersSum = 0
      for (let i = 1; i < allocations.length; i++) {
        if (i !== index) othersSum += allocations[i]!.ratio
      }
      if (othersSum + ratio > 1) {
        allocations[index]!.ratio = 0
        allocations[index]!.amount = 0
        ElMessage.error('比例之和不能超过100%')
      } else {
        recalcFromRatios()
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

    recalcFromRatios()
  }

  function evenAllocation() {
    if (!currentReimbursement.value) return
    const allocations = currentReimbursement.value.costAllocations
    if (allocations.length === 0) return

    const n = allocations.length
    const evenRatio = 1 / n

    allocations.forEach((a) => {
      a.ratio = evenRatio
    })

    recalcFromRatios()
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

    // 校验所有行程是否有同一人员日期重叠
    for (let i = 0; i < travelRecords.length; i++) {
      for (let j = i + 1; j < travelRecords.length; j++) {
        if (travelRecords[i]!.reimburserId === travelRecords[j]!.reimburserId) {
          const overlap = checkTravelRecordOverlap(
            [travelRecords[i]!],
            travelRecords[j]!,
          )
          if (overlap) {
            errors.push(`行程记录存在重复：${travelRecords[j]!.reimburserName} 在 ${overlap.departureDate} ~ ${overlap.arrivalDate} 已有行程`)
            break
          }
        }
      }
    }

    if (allowances.length === 0) errors.push('请至少添加一条补助信息')
    if (costAllocations.length === 0) errors.push('请至少添加一条分摊信息')

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
    voidReimbursement,
  }
})
