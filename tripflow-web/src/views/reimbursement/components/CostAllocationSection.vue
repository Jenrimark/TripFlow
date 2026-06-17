<template>
  <div class="cost-allocation-section">
    <div class="section-header">
      <span class="section-title">
        费用归属及分摊
        <span class="total-amount">分摊金额：{{ formatAmount(store.totalAllowanceAmount) }}</span>
      </span>
      <div class="header-right">
        <el-button v-if="!isViewMode" type="primary" size="small" @click.stop="handleAdd">添加一行</el-button>
        <el-icon class="expand-icon" :class="{ expanded }" @click.stop="toggleExpanded">
          <ArrowDown />
        </el-icon>
      </div>
    </div>

    <div v-show="expanded" class="section-content">
      <el-table :data="allocations" border show-summary :summary-method="getSummary">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="费用归属" width="300">
          <template #default="{ row }">
            <el-select
              v-model="row.companyId"
              filterable
              placeholder="请选择"
              :disabled="isViewMode"
              @change="(val: string) => handleCompanyChange(row, val)"
            >
              <el-option
                v-for="company in companies"
                :key="company.reimCompanyId"
                :label="company.reimCompanyName"
                :value="company.reimCompanyId"
              />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="项目" width="300">
          <template #default="{ row }">
            <el-select
              v-model="row.projectId"
              filterable
              placeholder="请选择"
              :disabled="isViewMode"
              @change="(val: string) => handleProjectChange(row, val)"
            >
              <el-option
                v-for="project in projects"
                :key="project.projectId"
                :label="project.projectName"
                :value="project.projectId"
              />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column width="180" align="right">
          <template #header>
            <el-tooltip v-if="!isViewMode" content="均摊" placement="top">
              <el-button link type="primary" class="action-icon" @click.stop="handleEvenAllocation">
                <el-icon><Refresh /></el-icon>
              </el-button>
            </el-tooltip>
            分摊比例
          </template>
          <template #default="{ row, $index }">
            <el-input
              v-model="row.ratioDisplay"
              :disabled="$index === 0 || isViewMode"
              @change="(val: string) => handleRatioChange($index, val)"
            >
              <template #append>%</template>
            </el-input>
          </template>
        </el-table-column>
        <el-table-column label="金额" width="180" align="right">
          <template #default="{ row }">
            <span class="amount">{{ formatAmount(row.amount) }}</span>
          </template>
        </el-table-column>
        <el-table-column v-if="!isViewMode" label="操作" width="100" fixed="right">
          <template #default="{ row, $index }">
            <el-tooltip content="删除" placement="top">
              <el-button link type="danger" class="action-icon" @click="handleDelete(row, $index)">
                <el-icon><Delete /></el-icon>
              </el-button>
            </el-tooltip>
          </template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch, nextTick, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { useReimbursementPageMode } from '@/composables/useReimbursementPageMode'
import type { CostAllocation } from '@/types/reimbursement'
import type { TableColumnCtx } from 'element-plus'
import { ArrowDown, Delete, Refresh } from '@element-plus/icons-vue'
import { formatAmount } from '@/utils/reimbursementUtils'
import { useReimbursementMasterData } from '@/composables/useReimbursementMasterData'

const store = useReimbursementStore()
const { isViewMode } = useReimbursementPageMode()
const { companies, projects, loadMasterData } = useReimbursementMasterData()

const expanded = ref(true)

function toggleExpanded() {
  expanded.value = !expanded.value
}

const allocations = computed(() => {
  if (!store.currentReimbursement) return []
  const items = store.currentReimbursement.costAllocations
  // 第2行起：ratio × 100 保留两位小数
  const result = items.map((a) => ({
    ...a,
    ratioDisplay: (a.ratio * 100).toFixed(2),
  }))
  // 第1行：强制 100% - 其他行百分数之和，保证显示总和恰好 100%
  if (result.length > 0) {
    let othersPercentSum = 0
    for (let i = 1; i < result.length; i++) {
      othersPercentSum += parseFloat(result[i]!.ratioDisplay)
    }
    result[0] = { ...result[0]!, ratioDisplay: (100 - othersPercentSum).toFixed(2) }
  }
  return result
})

/** 同步 store 中的真实比例到 DOM，解决 el-input 不随 computed 更新的问题 */
function syncAllRatioDisplays() {
  const storeAllocs = store.currentReimbursement?.costAllocations
  if (!storeAllocs) return
  const inputs = document.querySelectorAll(
    '.cost-allocation-section .el-table__body .el-input__inner',
  ) as NodeListOf<HTMLInputElement>
  // 用 allocations computed 中的 ratioDisplay，确保第1行显示补差值
  storeAllocs.forEach((_, i) => {
    if (inputs[i] && allocations.value[i]) {
      inputs[i].value = allocations.value[i]!.ratioDisplay
    }
  })
}

watch(
  () => store.currentReimbursement?.costAllocations,
  () => {
    nextTick(syncAllRatioDisplays)
  },
  { deep: true, flush: 'post' },
)

function getSummary({ columns, data }: { columns: TableColumnCtx<CostAllocation>[]; data: CostAllocation[] }) {
  const totalAmount = data.reduce((sum, row) => sum + (row.amount ?? 0), 0)
  return columns.map((col, index) => {
    if (index === 1) return '总计'
    if (index === 3) return '100%'
    if (index === 4) return `CNY ${store.totalAllowanceAmount.toFixed(2)}`
    return ''
  })
}

function handleCompanyChange(row: CostAllocation, companyId: string) {
  const company = companies.value.find((c) => c.reimCompanyId === companyId)
  if (company) {
    store.updateCostAllocation(row.id, {
      companyId,
      companyName: company.reimCompanyName,
      companyNo: company.reimCompanyNo,
    })
  }
}

function handleProjectChange(row: CostAllocation, projectId: string) {
  const project = projects.value.find((p) => p.projectId === projectId)
  if (project) {
    store.updateCostAllocation(row.id, {
      projectId,
      projectName: project.projectName,
      projectNo: project.projectNo,
    })
  }
}

function handleRatioChange(index: number, value: string) {
  const ratio = parseFloat(value) / 100
  if (isNaN(ratio) || ratio < 0 || ratio > 1) {
    const allocation = allocations.value[index]!
    store.updateCostAllocation(allocation.id, { ratio: 0 })
    nextTick(syncAllRatioDisplays)
    ElMessage.error('请输入有效的比例（0-100）')
    return
  }

  const allocation = allocations.value[index]!
  store.updateCostAllocation(allocation.id, { ratio })

  // 校验：第2行起合计比例不能超过100%，超过则清空当前输入
  const sumRatio = store.currentReimbursement?.costAllocations
    .filter((_, i) => i > 0)
    .reduce((sum, a) => sum + a.ratio, 0) ?? 0
  if (sumRatio > 1) {
    store.updateCostAllocation(allocation.id, { ratio: 0 })
    nextTick(syncAllRatioDisplays)
    ElMessage.error('分摊比例合计不能超过100%，已清空当前输入')
    return
  }
}

function handleAdd() {
  store.addCostAllocation()
}

function handleEvenAllocation() {
  store.evenAllocation()
  ElMessage.success('均摊完成')
}

function handleDelete(row: CostAllocation, index: number) {
  void index
  if (allocations.value.length <= 1) {
    ElMessage.warning('至少保留一条分摊信息')
    return
  }

  ElMessageBox.confirm('确定要删除该分摊信息吗？', '提示', { type: 'warning' }).then(() => {
    store.deleteCostAllocation(row.id)
    ElMessage.success('删除成功')
  })
}

onMounted(() => {
  loadMasterData()
})
</script>

<style scoped>
.cost-allocation-section {
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

.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.expand-icon {
  transition: transform 0.3s;
}

.expand-icon.expanded {
  transform: rotate(180deg);
}

.total-amount {
  font-size: 14px;
  font-weight: normal;
  color: #409eff;
  margin-left: 16px;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.section-content {
  padding: 20px;
}

.amount {
  font-weight: bold;
  color: #409eff;
}

.cost-allocation-section :deep(.el-table__footer-wrapper) td {
  background-color: rgb(254, 247, 234);
  border-right-color: transparent;
  border-bottom-color: transparent;
}

.cost-allocation-section :deep(.el-table__footer-wrapper) td:nth-child(2),
.cost-allocation-section :deep(.el-table__footer-wrapper) td:nth-child(4),
.cost-allocation-section :deep(.el-table__footer-wrapper) td:nth-child(5) {
  color: rgb(255, 153, 1);
  font-weight: bold;
}

.action-icon {
  width: 24px;
  height: 24px;
  padding: 0;
  margin: 0;
  font-size: 16px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.action-icon :deep(svg) {
  stroke-width: 2.5;
}
</style>
