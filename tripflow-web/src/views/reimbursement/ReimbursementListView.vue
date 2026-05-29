<template>
  <div class="reimbursement-list">
    <div class="page-header">
      <h1>报销单列表</h1>
      <el-button type="primary" @click="handleCreate">
        <el-icon><Plus /></el-icon>
        新增
      </el-button>
    </div>

    <div class="query-section">
      <el-form :model="queryForm" inline>
        <el-form-item label="报销单号">
          <el-input v-model="queryForm.documentNo" placeholder="请输入报销单号" clearable />
        </el-form-item>
        <el-form-item label="标题">
          <el-input v-model="queryForm.title" placeholder="请输入标题" clearable />
        </el-form-item>
        <el-form-item label="事由">
          <el-input v-model="queryForm.reason" placeholder="请输入事由" clearable />
        </el-form-item>
        <el-form-item label="费用归属公司">
          <el-select
            v-model="queryForm.companyIds"
            multiple
            collapse-tags
            placeholder="请选择"
          >
            <el-option
              v-for="company in companies"
              :key="company.reimCompanyId"
              :label="company.reimCompanyName"
              :value="company.reimCompanyId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="报销部门">
          <el-select
            v-model="queryForm.departmentIds"
            multiple
            collapse-tags
            placeholder="请选择"
          >
            <el-option
              v-for="dept in departments"
              :key="dept.reimDepartmentId"
              :label="dept.reimDepartmentName"
              :value="dept.reimDepartmentId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="报销人">
          <el-select
            v-model="queryForm.reimburserIds"
            multiple
            collapse-tags
            filterable
            placeholder="请输入姓名或工号"
          >
            <el-option
              v-for="person in reimbursers"
              :key="person.reimburserId"
              :label="`${person.reimburserName}(${person.reimburserNo})`"
              :value="person.reimburserId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="业务类型">
          <el-tree-select
            v-model="queryForm.businessTypeIds"
            :data="businessTypes"
            :props="{ label: 'businessTypeName', value: 'businessTypeId' }"
            multiple
            check-strictly
            placeholder="请选择"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">搜索</el-button>
          <el-button @click="handleClear">清除</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="table-section">
      <el-table :data="store.reimbursementList" v-loading="store.loading" stripe border>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-dropdown @command="(cmd: string) => handleCommand(cmd, row)">
              <span class="el-dropdown-link">
                编辑
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </span>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="edit">编辑</el-dropdown-item>
                  <el-dropdown-item command="copy">复制</el-dropdown-item>
                  <el-dropdown-item command="export">导出</el-dropdown-item>
                  <el-dropdown-item command="delete" divided>删除</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </template>
        </el-table-column>
        <el-table-column prop="documentNo" label="报销单号" width="150">
          <template #default="{ row }">
            <el-link type="primary" @click="handleView(row)">
              {{ row.documentNo }}
            </el-link>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="单据状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="报销人" width="150">
          <template #default="{ row }">
            {{ `${row.basicInfo.reimburserName}(${row.basicInfo.reimburserNo})` }}
          </template>
        </el-table-column>
        <el-table-column label="报销部门" width="180">
          <template #default="{ row }">
            {{ `${row.basicInfo.departmentName}(${row.basicInfo.departmentNo})` }}
          </template>
        </el-table-column>
        <el-table-column prop="basicInfo.companyName" label="费用归属公司" width="150" />
        <el-table-column prop="basicInfo.businessTypeName" label="业务类型" width="120" />
        <el-table-column prop="basicInfo.title" label="报销标题" min-width="200">
          <template #default="{ row }">
            <el-link type="primary" @click="handleView(row)">
              {{ row.basicInfo.title }}
            </el-link>
          </template>
        </el-table-column>
        <el-table-column prop="basicInfo.reason" label="报销事由" min-width="150" />
        <el-table-column prop="totalAllowanceAmount" label="补助金额" width="120" align="right">
          <template #default="{ row }">
            {{ formatAmount(row.totalAllowanceAmount) }}
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="120" />
      </el-table>

      <div class="pagination-section">
        <el-pagination
          v-model:current-page="store.currentPage"
          v-model:page-size="store.pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="store.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, ArrowDown } from '@element-plus/icons-vue'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { DocumentStatus, type Reimbursement } from '@/types/reimbursement'
import { formatAmount } from '@/utils/reimbursementUtils'
import { useReimbursementMasterData } from '@/composables/useReimbursementMasterData'

const router = useRouter()
const store = useReimbursementStore()
const { companies, departments, reimbursers, businessTypes, loadMasterData } =
  useReimbursementMasterData()

const queryForm = ref({
  documentNo: '',
  title: '',
  reason: '',
  companyIds: [] as string[],
  departmentIds: [] as string[],
  reimburserIds: [] as string[],
  businessTypeIds: [] as string[],
})

type TagType = 'success' | 'info' | 'warning' | 'danger' | 'primary'

function getStatusType(status: DocumentStatus): TagType {
  const types: Record<DocumentStatus, TagType> = {
    [DocumentStatus.DRAFT]: 'info',
    [DocumentStatus.COMPLETED]: 'success',
    [DocumentStatus.VOIDED]: 'danger',
  }
  return types[status]
}

function getStatusText(status: DocumentStatus) {
  const texts: Record<DocumentStatus, string> = {
    [DocumentStatus.DRAFT]: '草稿',
    [DocumentStatus.COMPLETED]: '已完成',
    [DocumentStatus.VOIDED]: '已作废',
  }
  return texts[status]
}

function handleSearch() {
  store.query = { ...queryForm.value }
  store.currentPage = 1
  store.fetchReimbursements()
}

function handleClear() {
  queryForm.value = {
    documentNo: '',
    title: '',
    reason: '',
    companyIds: [],
    departmentIds: [],
    reimburserIds: [],
    businessTypeIds: [],
  }
  handleSearch()
}

function handleCreate() {
  store.createNewReimbursement()
  router.push('/reimbursement/new')
}

function handleView(row: Reimbursement) {
  router.push(`/reimbursement/${row.id}`)
}

function handleCommand(command: string, row: Reimbursement) {
  switch (command) {
    case 'edit':
      router.push(`/reimbursement/${row.id}/edit`)
      break
    case 'copy':
      handleCopy(row)
      break
    case 'export':
      handleExport(row)
      break
    case 'delete':
      handleDelete(row)
      break
  }
}

function handleCopy(row: Reimbursement) {
  void row
  ElMessageBox.confirm('确定要复制该报销单吗？', '提示', { type: 'info' }).then(() => {
    ElMessage.success('复制成功')
  })
}

function handleExport(row: Reimbursement) {
  void row
  ElMessage.success('导出成功')
}

function handleDelete(row: Reimbursement) {
  ElMessageBox.confirm('确定要删除该报销单吗？删除后无法恢复。', '警告', {
    type: 'warning',
    confirmButtonText: '确定',
    cancelButtonText: '取消',
  }).then(async () => {
    try {
      await store.deleteReimbursement(row.id)
      await store.fetchReimbursements()
      ElMessage.success('删除成功')
    } catch {
      ElMessage.error('删除失败')
    }
  })
}

function handleSizeChange() {
  store.fetchReimbursements()
}

function handleCurrentChange() {
  store.fetchReimbursements()
}

onMounted(async () => {
  await loadMasterData()
  store.fetchReimbursements()
})
</script>

<style scoped>
.reimbursement-list {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h1 {
  margin: 0;
  font-size: 20px;
}

.query-section {
  background: #f5f7fa;
  padding: 20px;
  border-radius: 4px;
  margin-bottom: 20px;
}

.table-section {
  background: white;
  border-radius: 4px;
}

.pagination-section {
  display: flex;
  justify-content: flex-end;
  padding: 20px;
}

.el-dropdown-link {
  cursor: pointer;
  color: #409eff;
}
</style>
