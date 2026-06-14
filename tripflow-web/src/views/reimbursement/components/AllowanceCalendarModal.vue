<template>
  <el-dialog
    :model-value="visible"
    @update:model-value="handleDialogUpdate"
    title="补助日历"
    width="1100px"
    :close-on-click-modal="false"
    class="allowance-calendar-dialog"
  >
    <div class="calendar-layout">
      <!-- 左侧：行程信息 -->
      <div class="calendar-sidebar">
        <div class="trip-type">
          出差类型
          <span class="trip-type-value">{{ businessTypeName || '-' }}</span>
        </div>

        <!-- 时间线 -->
        <div class="timeline">
          <div class="timeline-item">
            <div class="timeline-dot"></div>
            <div class="timeline-label">开始日期</div>
            <div class="timeline-value">{{ allowance?.departureDate || '-' }}</div>
          </div>
          <div class="timeline-item">
            <div class="timeline-badge">
              <span class="badge-route">{{ allowance?.departureCity || '-' }} - {{ allowance?.arrivalCity || '-' }}</span>
              <span class="badge-days">{{ allowance?.allowanceDays || 0 }}天</span>
            </div>
          </div>
          <div class="timeline-item">
            <div class="timeline-dot"></div>
            <div class="timeline-label">结束日期</div>
            <div class="timeline-value">{{ allowance?.arrivalDate || '-' }}</div>
          </div>
        </div>

        <!-- 补助汇总 -->
        <div class="sidebar-summary">
          <div class="summary-row">
            <span class="summary-label">补助金额</span>
            <span class="summary-currency">CNY</span>
            <span class="summary-value">{{ formatAmount(totalStandardAmount).replace('¥', '') }}</span>
          </div>
          <div class="summary-row">
            <span class="summary-label">标准总额</span>
            <span class="summary-currency">CNY</span>
            <span class="summary-value">{{ formatAmount(totalStandardAmount).replace('¥', '') }}</span>
          </div>
          <div class="summary-row">
            <span class="summary-label">补助金额</span>
            <span class="summary-currency">CNY</span>
            <span class="summary-value">{{ formatAmount(totalAllowanceAmount).replace('¥', '') }}</span>
          </div>
        </div>
      </div>

      <!-- 右侧：补助表格 -->
      <div class="calendar-main">
        <div class="main-header">
          <span class="main-title">出差补助</span>
          <el-checkbox v-model="isAllSelected" @change="handleSelectAll">全选</el-checkbox>
        </div>

        <div class="table-wrapper">
          <el-table :data="calendarData" :header-cell-style="{ background: '#f5f7fa', color: '#303133', fontWeight: 600 }">
            <el-table-column label="出差日期" width="100">
              <template #default="{ row, $index }">
                <div class="date-cell">
                  <span class="date-main">{{ row.date }}</span>
                  <span class="date-weekday">{{ row.weekday }}</span>
                </div>
              </template>
            </el-table-column>
            <el-table-column width="40" align="center" class-name="row-select-col">
              <template #default="{ row, $index }">
                <el-checkbox
                  v-model="row.allSelected"
                  @change="(val: boolean) => handleSelectDate($index, val)"
                />
              </template>
            </el-table-column>
            <el-table-column prop="arrivalCity" label="补助城市" width="100">
              <template #default>
                <div class="city-cell">
                  <el-icon :size="14" color="#409eff"><Location /></el-icon>
                  <span>{{ allowance?.arrivalCity || '-' }}</span>
                </div>
              </template>
            </el-table-column>
            <el-table-column label="餐费补助" min-width="160" align="center">
              <template #header>
                <div class="col-header">
                  <span class="col-title">餐费补助</span>
                  <el-checkbox v-model="isAllMealSelected" @change="handleSelectAllMeal" />
                </div>
              </template>
              <template #default="{ row }">
                <div class="allowance-cell">
                  <span class="standard-amount">CNY {{ row.mealAllowance.toFixed(2) }} / 天</span>
                  <div class="amount-input">
                    <el-checkbox
                      v-model="row.mealSelected"
                      @change="(val: boolean) => { row.mealAmount = val ? row.mealAllowance : 0 }"
                    />
                    <el-input-number
                      v-model="row.mealAmount"
                      :min="0"
                      :max="row.mealAllowance"
                      :disabled="!row.mealSelected"
                      size="small"
                      :step="1"
                    />
                  </div>
                </div>
              </template>
            </el-table-column>
            <el-table-column label="交通补助" min-width="160" align="center">
              <template #header>
                <div class="col-header">
                  <span class="col-title">交通补助</span>
                  <el-checkbox v-model="isAllTransportSelected" @change="handleSelectAllTransport" />
                </div>
              </template>
              <template #default="{ row }">
                <div class="allowance-cell">
                  <span class="standard-amount">CNY {{ row.transportAllowance.toFixed(2) }} / 天</span>
                  <div class="amount-input">
                    <el-checkbox
                      v-model="row.transportSelected"
                      @change="(val: boolean) => { row.transportAmount = val ? row.transportAllowance : 0 }"
                    />
                    <el-input-number
                      v-model="row.transportAmount"
                      :min="0"
                      :max="row.transportAllowance"
                      :disabled="!row.transportSelected"
                      size="small"
                      :step="1"
                    />
                  </div>
                </div>
              </template>
            </el-table-column>
            <el-table-column label="通讯补助" min-width="160" align="center">
              <template #header>
                <div class="col-header">
                  <span class="col-title">通讯补助</span>
                  <el-checkbox v-model="isAllCommunicationSelected" @change="handleSelectAllCommunication" />
                </div>
              </template>
              <template #default="{ row }">
                <div class="allowance-cell">
                  <span class="standard-amount">CNY {{ row.communicationAllowance.toFixed(2) }} / 天</span>
                  <div class="amount-input">
                    <el-checkbox
                      v-model="row.communicationSelected"
                      @change="(val: boolean) => { row.communicationAmount = val ? row.communicationAllowance : 0 }"
                    />
                    <el-input-number
                      v-model="row.communicationAmount"
                      :min="0"
                      :max="row.communicationAllowance"
                      :disabled="!row.communicationSelected"
                      size="small"
                      :step="1"
                    />
                  </div>
                </div>
              </template>
            </el-table-column>
          </el-table>
        </div>

        <!-- 无底部汇总 -->
      </div>
    </div>

    <template #footer>
      <div class="dialog-footer">
        <el-button @click="handleDialogUpdate(false)">取 消</el-button>
        <el-button type="primary" @click="handleSave">保 存</el-button>
      </div>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Location } from '@element-plus/icons-vue'
import type { AllowanceInfo, AllowanceCalendarItem } from '@/types/reimbursement'
import { formatAmount } from '@/utils/reimbursementUtils'

type CalendarRow = AllowanceCalendarItem & { allSelected: boolean }

const props = defineProps<{
  visible: boolean
  allowance: AllowanceInfo | null
  businessTypeName?: string
}>()

const emit = defineEmits<{
  'update:visible': [value: boolean]
  save: [calendar: AllowanceCalendarItem[]]
}>()

const calendarData = ref<CalendarRow[]>([])

function handleDialogUpdate(value: boolean) {
  emit('update:visible', value)
}

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

// 每天标准补助总额
const dayStandardTotal = computed(() => {
  if (calendarData.value.length === 0) return 0
  const first = calendarData.value[0]!
  return first.mealAllowance + first.transportAllowance + first.communicationAllowance
})

// 标准总额 = 每天标准 × 天数
const totalStandardAmount = computed(() => {
  return dayStandardTotal.value * (props.allowance?.allowanceDays || calendarData.value.length)
})

// 实际补助金额
const totalAllowanceAmount = computed(() => {
  return calendarData.value.reduce((sum, item) => {
    let dayTotal = 0
    if (item.mealSelected) dayTotal += item.mealAmount
    if (item.transportSelected) dayTotal += item.transportAmount
    if (item.communicationSelected) dayTotal += item.communicationAmount
    return sum + dayTotal
  }, 0)
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
        allSelected: item.mealSelected || item.transportSelected || item.communicationSelected,
      }))
    }
  },
  { immediate: true },
)
</script>

<style scoped>
/* ===== 对话框整体 ===== */
.calendar-layout {
  display: flex;
  gap: 20px;
  min-height: 450px;
}

/* ===== 左侧边栏 ===== */
.calendar-sidebar {
  width: 240px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
}

.trip-type {
  font-size: 15px;
  color: #303133;
  font-weight: 600;
  margin-bottom: 24px;
}

.trip-type-value {
  margin-left: 12px;
  color: rgb(240, 138, 63);
  font-weight: 600;
}

/* 时间线 */
.timeline {
  position: relative;
  padding: 0;
  margin-bottom: 32px;
}

.timeline-item {
  display: flex;
  align-items: center;
  gap: 12px;
  min-height: 32px;
  position: relative;
}

.timeline-item:not(:last-child)::after {
  content: '';
  position: absolute;
  left: 5px;
  top: 18px;
  bottom: -14px;
  width: 2px;
  background: #409eff;
}

.timeline-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #409eff;
  flex-shrink: 0;
  z-index: 1;
}

.timeline-label {
  font-size: 13px;
  color: #909399;
}

.timeline-value {
  font-size: 13px;
  color: #303133;
  margin-left: auto;
}

.timeline-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #409eff;
  color: #fff;
  border-radius: 16px;
  padding: 4px 12px;
  font-size: 13px;
  margin-left: 0;
}

.badge-route {
  color: #fff;
  font-weight: 500;
}

.badge-days {
  background: rgba(255, 255, 255, 0.3);
  padding: 1px 8px;
  border-radius: 10px;
  font-size: 12px;
  font-weight: 600;
}

/* 补助汇总 */
.sidebar-summary {
  border: 1px solid #ebeef5;
  border-radius: 8px;
  padding: 16px;
  margin-top: auto;
}

.summary-row {
  display: flex;
  align-items: center;
  padding: 8px 0;
}

.summary-row + .summary-row {
  border-top: 1px solid #f0f2f5;
}

.summary-label {
  font-size: 13px;
  color: #606266;
  width: 70px;
  flex-shrink: 0;
}

.summary-currency {
  font-size: 12px;
  color: #909399;
  margin-right: 8px;
}

.summary-value {
  font-size: 18px;
  font-weight: 700;
  color: rgb(240, 138, 63);
}

/* ===== 右侧内容 ===== */
.calendar-main {
  flex: 1;
  min-width: 0;
}

.main-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.main-title {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

.table-wrapper {
  overflow-x: auto;
}

/* 表格列头 */
.col-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.col-title {
  font-weight: 600;
}

/* 日期列 */
.date-cell {
  display: flex;
  flex-direction: column;
  line-height: 1.6;
}

.date-main {
  font-size: 13px;
  color: #303133;
}

.date-weekday {
  font-size: 12px;
  color: #909399;
}

/* 城市列 */
.city-cell {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

/* 补助单元格 */
.allowance-cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.standard-amount {
  font-size: 12px;
  color: rgb(240, 138, 63);
  white-space: nowrap;
}

.amount-input {
  display: flex;
  align-items: center;
  gap: 6px;
}

/* ===== 对话框样式覆盖 ===== */
.allowance-calendar-dialog :deep(.el-dialog__header) {
  border-bottom: 1px solid #ebeef5;
  padding-bottom: 14px;
}

.allowance-calendar-dialog :deep(.el-dialog__body) {
  padding: 20px 24px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

:deep(.row-select-col .cell) {
  padding: 0 4px;
}

</style>
