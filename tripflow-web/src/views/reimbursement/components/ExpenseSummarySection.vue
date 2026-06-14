<template>
  <div class="expense-summary-section">
    <div class="section-header" @click="toggleExpanded">
      <span class="section-title">费用合计</span>
      <el-icon class="expand-icon" :class="{ expanded }">
        <ArrowDown />
      </el-icon>
    </div>

    <div v-show="expanded" class="section-content">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="补助总金额">
          <span class="amount">{{ formatAmount(store.totalAllowanceAmount) }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="餐费补助">
          <span class="amount">{{ formatAmount(store.totalMealAmount) }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="交通补助">
          <span class="amount">{{ formatAmount(store.totalTransportAmount) }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="通讯补助">
          <span class="amount">{{ formatAmount(store.totalCommunicationAmount) }}</span>
        </el-descriptions-item>
      </el-descriptions>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ArrowDown } from '@element-plus/icons-vue'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { formatAmount } from '@/utils/reimbursementUtils'

const store = useReimbursementStore()
const expanded = ref(true)

function toggleExpanded() {
  expanded.value = !expanded.value
}
</script>

<style scoped>
.expense-summary-section {
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

.expand-icon {
  transition: transform 0.3s;
}

.expand-icon.expanded {
  transform: rotate(180deg);
}

.section-content {
  padding: 20px;
}

.amount {
  font-weight: bold;
  color: #409eff;
}
</style>
