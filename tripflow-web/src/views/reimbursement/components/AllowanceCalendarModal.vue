<template>
  <el-dialog
    :model-value="visible"
    @update:model-value="$emit('update:visible', $event)"
    title="补助日历"
    width="1000px"
    :close-on-click-modal="false"
  >
    <div class="calendar-header">
      <div class="info-row">
        <span>出差类型：-</span>
        <span>开始日期：{{ allowance?.departureDate || '-' }}</span>
        <span>结束日期：{{ allowance?.arrivalDate || '-' }}</span>
        <span>行程天数：{{ allowance?.allowanceDays || 0 }}天</span>
      </div>
      <div class="info-row">
        <span>行程地点：{{ `${allowance?.departureCity || '-'}-${allowance?.arrivalCity || '-'}` }}</span>
        <span>申请金额：{{ formatAmount(totalApplyAmount) }}</span>
        <span>补助金额：{{ formatAmount(totalAllowanceAmount) }}</span>
      </div>
    </div>

    <div class="calendar-content">
      <el-table :data="calendarData" border>
        <el-table-column label="全选" width="60" align="center">
          <template #header>
            <el-checkbox v-model="isAllSelected" @change="handleSelectAll" />
          </template>
          <template #default="{ row, $index }">
            <el-checkbox
              v-model="row.allSelected"
              @change="(val: boolean) => handleSelectDate($index, val)"
            />
          </template>
        </el-table-column>
        <el-table-column prop="date" label="日期" width="120" />
        <el-table-column prop="weekday" label="星期" width="80" />
        <el-table-column label="餐费补助" width="150" align="center">
          <template #header>
            <div>
              <div>餐费补助</div>
              <el-checkbox v-model="isAllMealSelected" @change="handleSelectAllMeal" />
            </div>
          </template>
          <template #default="{ row }">
            <div class="allowance-cell">
              <el-checkbox
                v-model="row.mealSelected"
                :disabled="!row.allSelected && !row.mealSelected"
              />
              <el-input-number
                v-model="row.mealAmount"
                :min="0"
                :max="row.mealAllowance"
                :disabled="!row.mealSelected"
                size="small"
                style="width: 80px"
              />
            </div>
          </template>
        </el-table-column>
        <el-table-column label="交通补助" width="150" align="center">
          <template #header>
            <div>
              <div>交通补助</div>
              <el-checkbox v-model="isAllTransportSelected" @change="handleSelectAllTransport" />
            </div>
          </template>
          <template #default="{ row }">
            <div class="allowance-cell">
              <el-checkbox
                v-model="row.transportSelected"
                :disabled="!row.allSelected && !row.transportSelected"
              />
              <el-input-number
                v-model="row.transportAmount"
                :min="0"
                :max="row.transportAllowance"
                :disabled="!row.transportSelected"
                size="small"
                style="width: 80px"
              />
            </div>
          </template>
        </el-table-column>
        <el-table-column label="通讯补助" width="150" align="center">
          <template #header>
            <div>
              <div>通讯补助</div>
              <el-checkbox v-model="isAllCommunicationSelected" @change="handleSelectAllCommunication" />
            </div>
          </template>
          <template #default="{ row }">
            <div class="allowance-cell">
              <el-checkbox
                v-model="row.communicationSelected"
                :disabled="!row.allSelected && !row.communicationSelected"
              />
              <el-input-number
                v-model="row.communicationAmount"
                :min="0"
                :max="row.communicationAllowance"
                :disabled="!row.communicationSelected"
                size="small"
                style="width: 80px"
              />
            </div>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <template #footer>
      <el-button @click="$emit('update:visible', false)">取消</el-button>
      <el-button type="primary" @click="handleSave">保存</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { AllowanceInfo, AllowanceCalendarItem } from '@/types/reimbursement'
import { formatAmount } from '@/utils/reimbursementUtils'

type CalendarRow = AllowanceCalendarItem & { allSelected: boolean }

const props = defineProps<{
  visible: boolean
  allowance: AllowanceInfo | null
}>()

const emit = defineEmits<{
  'update:visible': [value: boolean]
  save: [calendar: AllowanceCalendarItem[]]
}>()

const calendarData = ref<CalendarRow[]>([])

const totalApplyAmount = computed(() => {
  return calendarData.value.reduce(
    (sum, item) => sum + item.mealAllowance + item.transportAllowance + item.communicationAllowance,
    0,
  )
})

const totalAllowanceAmount = computed(() => {
  return calendarData.value.reduce((sum, item) => {
    let dayTotal = 0
    if (item.mealSelected) dayTotal += item.mealAmount
    if (item.transportSelected) dayTotal += item.transportAmount
    if (item.communicationSelected) dayTotal += item.communicationAmount
    return sum + dayTotal
  }, 0)
})

const isAllSelected = computed({
  get: () => calendarData.value.length > 0 && calendarData.value.every((item) => item.allSelected),
  set: () => {},
})

const isAllMealSelected = computed({
  get: () => calendarData.value.length > 0 && calendarData.value.every((item) => item.mealSelected),
  set: () => {},
})

const isAllTransportSelected = computed({
  get: () =>
    calendarData.value.length > 0 && calendarData.value.every((item) => item.transportSelected),
  set: () => {},
})

const isAllCommunicationSelected = computed({
  get: () =>
    calendarData.value.length > 0 &&
    calendarData.value.every((item) => item.communicationSelected),
  set: () => {},
})

function handleSelectAll(val: boolean) {
  calendarData.value.forEach((item) => {
    item.allSelected = val
    if (val) {
      item.mealSelected = true
      item.transportSelected = true
      item.communicationSelected = true
      item.mealAmount = item.mealAllowance
      item.transportAmount = item.transportAllowance
      item.communicationAmount = item.communicationAllowance
    } else {
      item.mealSelected = false
      item.transportSelected = false
      item.communicationSelected = false
      item.mealAmount = 0
      item.transportAmount = 0
      item.communicationAmount = 0
    }
  })
}

function handleSelectDate(index: number, val: boolean) {
  const item = calendarData.value[index]!
  item.allSelected = val
  item.mealSelected = val
  item.transportSelected = val
  item.communicationSelected = val
  if (val) {
    item.mealAmount = item.mealAllowance
    item.transportAmount = item.transportAllowance
    item.communicationAmount = item.communicationAllowance
  } else {
    item.mealAmount = 0
    item.transportAmount = 0
    item.communicationAmount = 0
  }
}

function handleSelectAllMeal(val: boolean) {
  calendarData.value.forEach((item) => {
    item.mealSelected = val
    item.mealAmount = val ? item.mealAllowance : 0
  })
}

function handleSelectAllTransport(val: boolean) {
  calendarData.value.forEach((item) => {
    item.transportSelected = val
    item.transportAmount = val ? item.transportAllowance : 0
  })
}

function handleSelectAllCommunication(val: boolean) {
  calendarData.value.forEach((item) => {
    item.communicationSelected = val
    item.communicationAmount = val ? item.communicationAllowance : 0
  })
}

function handleSave() {
  emit(
    'save',
    calendarData.value.map(({ allSelected: _, ...item }) => item),
  )
}

watch(
  () => props.allowance,
  (newAllowance) => {
    if (newAllowance) {
      calendarData.value = newAllowance.calendar.map((item) => ({
        ...item,
        allSelected:
          item.mealSelected || item.transportSelected || item.communicationSelected,
      }))
    }
  },
  { immediate: true },
)
</script>

<style scoped>
.calendar-header {
  background: #f5f7fa;
  padding: 16px;
  border-radius: 4px;
  margin-bottom: 16px;
}

.info-row {
  display: flex;
  gap: 24px;
  margin-bottom: 8px;
}

.info-row:last-child {
  margin-bottom: 0;
}

.calendar-content {
  max-height: 400px;
  overflow-y: auto;
}

.allowance-cell {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}
</style>
