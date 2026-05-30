<template>
  <div class="travel-record-section">
    <div class="section-header">
      <span class="section-title">补录行程</span>
      <el-button v-if="!isViewMode" type="primary" size="small" @click="handleAdd">
        <el-icon><Plus /></el-icon>
        补录行程
      </el-button>
    </div>

    <div class="section-content">
      <el-table :data="travelRecords" border>
        <el-table-column prop="reimburserName" label="出行人员" width="120" />
        <el-table-column label="出差日期" width="200">
          <template #default="{ row }">
            {{ `${row.departureDate} 至 ${row.arrivalDate}` }}
          </template>
        </el-table-column>
        <el-table-column label="行程" width="200">
          <template #default="{ row }">
            {{ `${row.departureCityName}-${row.arrivalCityName}` }}
          </template>
        </el-table-column>
        <el-table-column prop="description" label="行程说明" min-width="200" show-overflow-tooltip />
        <el-table-column v-if="!isViewMode" label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="primary" link @click="handleCopy(row)">复制</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
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
import { Plus } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { useReimbursementPageMode } from '@/composables/useReimbursementPageMode'
import type { TravelRecord } from '@/types/reimbursement'
import TravelRecordModal from './TravelRecordModal.vue'

const store = useReimbursementStore()
const { isViewMode } = useReimbursementPageMode()

const modalVisible = ref(false)
const modalMode = ref<'add' | 'edit' | 'copy'>('add')
const currentRecord = ref<TravelRecord | null>(null)

const travelRecords = computed(() => store.currentReimbursement?.travelRecords || [])

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
  padding: 12px 20px;
  border-bottom: 1px solid #ebeef5;
}

.section-title {
  font-size: 16px;
  font-weight: bold;
  color: #303133;
}

.section-content {
  padding: 20px;
}
</style>
