<template>
  <div class="travel-record-section">
    <div class="section-header">
      <span class="section-title">补录行程</span>
      <div class="header-right">
        <el-button v-if="!isViewMode" type="primary" size="small" @click.stop="handleAdd">
          补录行程
        </el-button>
        <el-icon class="expand-icon" :class="{ expanded }" @click.stop="toggleExpanded">
          <ArrowDown />
        </el-icon>
      </div>
    </div>

    <div v-show="expanded" class="section-content">
      <el-table :data="travelRecords" border>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="reimburserName" label="出行人员" width="120" />
        <el-table-column label="出差日期" width="240">
          <template #default="{ row }">
            {{ `${row.departureDate} 至 ${row.arrivalDate}` }}
          </template>
        </el-table-column>
        <el-table-column label="行程" width="130">
          <template #default="{ row }">
            {{ `${row.departureCityName}-${row.arrivalCityName}` }}
          </template>
        </el-table-column>
        <el-table-column prop="description" label="行程说明" min-width="200" show-overflow-tooltip />
        <el-table-column v-if="!isViewMode" label="操作" width="120" align="center" fixed="right">
          <template #default="{ row }">
            <el-tooltip content="删除" placement="top">
              <el-button link type="danger" class="action-icon" @click="handleDelete(row)">
                <el-icon><Delete /></el-icon>
              </el-button>
            </el-tooltip>
            <el-tooltip content="编辑" placement="top">
              <el-button link type="primary" class="action-icon" @click="handleEdit(row)">
                <el-icon><EditPen /></el-icon>
              </el-button>
            </el-tooltip>
            <el-tooltip content="复制" placement="top">
              <el-button link type="primary" class="action-icon" @click="handleCopy(row)">
                <el-icon><CopyDocument /></el-icon>
              </el-button>
            </el-tooltip>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <TravelRecordModal
      v-model:visible="modalVisible"
      :record="currentRecord"
      :mode="modalMode"
      @save="handleSave"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Plus, ArrowDown, Delete, EditPen, CopyDocument } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { useReimbursementPageMode } from '@/composables/useReimbursementPageMode'
import type { TravelRecord } from '@/types/reimbursement'
import TravelRecordModal from './TravelRecordModal.vue'

const store = useReimbursementStore()
const { isViewMode } = useReimbursementPageMode()

const expanded = ref(true)
const modalVisible = ref(false)
const modalMode = ref<'add' | 'edit' | 'copy'>('add')
const currentRecord = ref<TravelRecord | null>(null)

const travelRecords = computed(() => store.currentReimbursement?.travelRecords || [])

function toggleExpanded() {
  expanded.value = !expanded.value
}

function handleAdd() {
  modalMode.value = 'add'
  currentRecord.value = null
  modalVisible.value = true
}

function handleEdit(record: TravelRecord) {
  modalMode.value = 'edit'
  currentRecord.value = { ...record }
  modalVisible.value = true
}

function handleCopy(record: TravelRecord) {
  modalMode.value = 'copy'
  currentRecord.value = { ...record }
  modalVisible.value = true
}

function handleDelete(record: TravelRecord) {
  ElMessageBox.confirm('确定要删除该行程吗？', '提示', { type: 'warning' }).then(() => {
    store.deleteTravelRecord(record.id)
    ElMessage.success('删除成功')
  })
}

function handleSave(record: Omit<TravelRecord, 'id'>) {
  if (modalMode.value === 'edit' && currentRecord.value) {
    store.updateTravelRecord(currentRecord.value.id, record)
    ElMessage.success('更新成功')
  } else {
    try {
      store.addTravelRecord(record)
      ElMessage.success('添加成功')
    } catch (error) {
      ElMessage.error(error instanceof Error ? error.message : '添加失败')
    }
  }
  modalVisible.value = false
}
</script>

<style scoped>
.travel-record-section {
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

.expand-icon.expanded {
  transform: rotate(180deg);
}

.section-content {
  padding: 20px;
}
</style>
