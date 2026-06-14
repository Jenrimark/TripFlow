<template>
  <div class="allowance-info-section">
    <div class="section-header" @click="toggleExpanded">
      <span class="section-title">
        补助信息
        <span class="total-days">{{ reimburserName }}：{{ totalDays }}天</span>
      </span>
      <el-icon class="expand-icon" :class="{ expanded }">
        <ArrowDown />
      </el-icon>
    </div>

    <div v-show="expanded" class="section-content">
      <el-alert
        title="1、请根据实际出差日期选择补助 2、出差期间当日有用餐安排的请自行核减当日餐补 3、出差期间当日有用车的，请自行核减当日交补"
        type="warning"
        show-icon
        :closable="false"
        class="allowance-alert"
      />

      <el-table :data="allowances" border>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="reimburserName" label="出行人" width="120" />
        <el-table-column label="出差日期" width="240">
          <template #default="{ row }">
            {{ `${row.departureDate} 至 ${row.arrivalDate}` }}
          </template>
        </el-table-column>
        <el-table-column prop="allowanceDays" label="补助天数" width="100" align="center" />
        <el-table-column label="行程" width="130">
          <template #default="{ row }">
            {{ `${row.departureCity}-${row.arrivalCity}` }}
          </template>
        </el-table-column>
        <el-table-column prop="arrivalCity" label="补助城市" width="120" />
        <el-table-column prop="totalApplyAmount" label="申请金额" width="120" align="right">
          <template #default="{ row }">
            {{ formatAmount(row.totalApplyAmount) }}
          </template>
        </el-table-column>
        <el-table-column prop="totalAllowanceAmount" label="补助金额" width="120" align="right">
          <template #default="{ row }">
            {{ formatAmount(row.totalAllowanceAmount) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="110" fixed="right">
          <template #default="{ row }">
            <el-button v-if="!isViewMode" type="primary" link @click="handleEdit(row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <AllowanceCalendarModal
      v-model:visible="modalVisible"
      :allowance="currentAllowance"
      @save="handleSave"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ArrowDown } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { useReimbursementPageMode } from '@/composables/useReimbursementPageMode'
import type { AllowanceInfo, AllowanceCalendarItem } from '@/types/reimbursement'
import { formatAmount } from '@/utils/reimbursementUtils'
import AllowanceCalendarModal from './AllowanceCalendarModal.vue'

const store = useReimbursementStore()
const { isViewMode } = useReimbursementPageMode()

const expanded = ref(true)
const modalVisible = ref(false)
const currentAllowance = ref<AllowanceInfo | null>(null)

const allowances = computed(() => store.currentReimbursement?.allowances || [])

const reimburserName = computed(() => {
  const first = allowances.value[0]
  return first?.reimburserName ?? ''
})

const totalDays = computed(() => {
  return allowances.value.reduce((sum, item) => sum + (item.allowanceDays ?? 0), 0)
})

function toggleExpanded() {
  expanded.value = !expanded.value
}

function handleEdit(allowance: AllowanceInfo) {
  currentAllowance.value = allowance
  modalVisible.value = true
}

function handleSave(calendar: AllowanceCalendarItem[]) {
  if (currentAllowance.value) {
    store.updateAllowanceCalendar(currentAllowance.value.id, calendar)
    ElMessage.success('保存成功')
  }
  modalVisible.value = false
}
</script>

<style scoped>
.allowance-info-section {
  background: white;
  border-radius: 4px;
  margin-bottom: 16px;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 20px;
  cursor: pointer;
  border-bottom: 1px solid #ebeef5;
}

.section-title {
  font-size: 16px;
  font-weight: bold;
  color: #303133;
}

.total-days {
  font-size: 14px;
  font-weight: normal;
  color: #409eff;
  margin-left: 16px;
}

.expand-icon {
  transition: transform 0.3s;
}

.expand-icon.expanded {
  transform: rotate(180deg);
}

.section-content {
  padding: 20px;
}

.allowance-alert {
  margin-bottom: 16px;
  --el-alert-bg-color: rgb(255, 247, 233);
  --el-alert-icon-color: rgb(255, 153, 1);
  --el-alert-title-color: #000;
}

.allowance-alert :deep(.el-alert__icon) {
  background-color: transparent;
}

.allowance-alert :deep(.el-alert__icon svg) {
  color: rgb(255, 153, 1);
}

.allowance-alert :deep(.el-alert__title) {
  color: #000 !important;
}
</style>
