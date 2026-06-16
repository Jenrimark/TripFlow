<template>
  <div class="reimbursement-list">
    <div class="page-header">
      <h1>报销单列表</h1>
    </div>

    <div class="query-section">
      <el-form :model="queryForm" label-width="96px" class="query-form">
        <div class="query-grid">
          <el-form-item label="报销单号" class="query-field">
            <el-input
              v-model="queryForm.documentNo"
              placeholder="请输入报销单号"
              clearable
            />
          </el-form-item>
          <el-form-item label="标题" class="query-field">
            <el-input v-model="queryForm.title" placeholder="请输入标题" clearable />
          </el-form-item>
          <el-form-item label="事由" class="query-field">
            <el-input v-model="queryForm.reason" placeholder="请输入事由" clearable />
          </el-form-item>
          <el-form-item label=" " class="query-field query-field--actions">
            <div class="query-actions">
              <el-button type="primary" @click="handleSearch">搜索</el-button>
              <el-button @click="handleClear">清除</el-button>
              <el-button type="primary" plain @click="handleCreate">
                <el-icon><Plus /></el-icon>
                新增
              </el-button>
            </div>
          </el-form-item>

          <el-form-item label="费用归属公司" class="query-field">
            <el-select
              v-model="queryForm.companyIds"
              multiple
              collapse-tags
              collapse-tags-tooltip
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
          <el-form-item label="报销部门" class="query-field">
            <el-select
              v-model="queryForm.departmentIds"
              multiple
              collapse-tags
              collapse-tags-tooltip
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
          <el-form-item label="报销人" class="query-field">
            <el-select
              v-model="queryForm.reimburserIds"
              multiple
              collapse-tags
              collapse-tags-tooltip
              filterable
              placeholder="请输入姓名或工号"
            >
              <el-option
                v-for="person in reimbursers"
                :key="person.reimburserId"
                :label="person.reimburserName ? `${person.reimburserName}(${person.reimburserNo || '-'})` : person.reimburserNo || '-'"
                :value="person.reimburserId"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="业务类型" class="query-field">
            <el-tree-select
              ref="businessTypeSelectRef"
              v-model="queryForm.businessTypeIds"
              :data="businessTypes"
              :props="{ label: 'businessTypeName', value: 'businessTypeId' }"
              multiple
              check-strictly
              collapse-tags
              collapse-tags-tooltip
              placeholder="请选择"
              @node-click="handleBusinessTypeNodeClick"
              @change="handleBusinessTypeChange"
            />
          </el-form-item>
        </div>
      </el-form>
    </div>

    <div class="table-section">
      <el-table
        :data="store.reimbursementList"
        v-loading="store.loading"
        stripe
        border
        class="reimbursement-table"
        style="width: 100%"
      >
        <el-table-column label="序号" width="60" align="center" fixed="left" :resizable="false">
          <template #default="{ $index }">
            {{ (store.currentPage - 1) * store.pageSize + $index + 1 }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center" fixed="left" :resizable="false">
          <template #default="{ row }">
            <div class="row-actions">
              <el-tooltip content="查看" placement="top">
                <el-button link type="primary" class="action-icon" @click="handleView(row)">
                  <el-icon><Document /></el-icon>
                </el-button>
              </el-tooltip>
              <el-tooltip content="编辑" placement="top">
                <el-button link type="primary" class="action-icon" @click="handleEdit(row)">
                  <el-icon><EditPen /></el-icon>
                </el-button>
              </el-tooltip>
              <el-dropdown trigger="click" @command="(cmd: string) => handleCommand(cmd, row)">
                <el-button link class="action-icon more-btn">
                  <el-icon><MoreFilled /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="delete">删除</el-dropdown-item>
                    <el-dropdown-item command="push">手工推送</el-dropdown-item>
                    <el-dropdown-item command="copy">复制</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </template>
        </el-table-column>
        <el-table-column
          prop="documentNo"
          label="报销单号"
          width="180"
          :resizable="false"
          class-name="col-document-no"
        >
          <template #default="{ row }">
            <el-link type="primary" class="document-no-link" @click="handleEdit(row)">
              {{ row.documentNo }}
            </el-link>
          </template>
        </el-table-column>
        <el-table-column
          prop="status"
          label="单据状态"
          width="100"
          align="center"
          header-align="center"
          :resizable="false"
        >
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column
          label="单据类型"
          width="120"
          :resizable="false"
          show-overflow-tooltip
        >
          <template #default="{ row }">
            {{ row.documentType || REIMBURSEMENT_DOCUMENT_TYPE }}
          </template>
        </el-table-column>
        <el-table-column label="报销人" min-width="150" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.basicInfo?.reimburserName ? `${row.basicInfo.reimburserName}(${row.basicInfo.reimburserNo || '-'})` : (row.basicInfo?.reimburserNo || '-') }}
          </template>
        </el-table-column>
        <el-table-column label="报销部门" min-width="200" show-overflow-tooltip>
          <template #default="{ row }">
            {{ row.basicInfo?.departmentName ? `${row.basicInfo.departmentName}(${row.basicInfo.departmentNo || '-'})` : (row.basicInfo?.departmentNo || '-') }}
          </template>
        </el-table-column>
        <el-table-column
          prop="basicInfo.companyName"
          label="费用归属公司"
          min-width="160"
          show-overflow-tooltip
        />
        <el-table-column
          prop="basicInfo.businessTypeName"
          label="业务类型"
          width="130"
          :resizable="false"
          show-overflow-tooltip
        />
        <el-table-column prop="basicInfo.title" label="报销标题" min-width="200" show-overflow-tooltip>
          <template #default="{ row }">
            <el-link type="primary" @click="handleEdit(row)">
              {{ row.basicInfo?.title }}
            </el-link>
          </template>
        </el-table-column>
        <el-table-column prop="basicInfo.reason" label="报销事由" min-width="150" show-overflow-tooltip />
        <el-table-column
          prop="totalAllowanceAmount"
          label="补助金额"
          width="120"
          align="right"
          header-align="right"
          :resizable="false"
        >
          <template #default="{ row }">
            {{ formatAmount(row.totalAllowanceAmount) }}
          </template>
        </el-table-column>
        <el-table-column
          prop="createdAt"
          label="创建时间"
          width="110"
          align="center"
          header-align="center"
          :resizable="false"
        />
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
import { Plus, Document, EditPen, MoreFilled } from '@element-plus/icons-vue'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { DocumentStatus, REIMBURSEMENT_DOCUMENT_TYPE, type Reimbursement } from '@/types/reimbursement'
import { formatAmount } from '@/utils/reimbursementUtils'
import { useReimbursementMasterData } from '@/composables/useReimbursementMasterData'
import { isLeafBusinessType } from '@/api/master'

const router = useRouter()
const store = useReimbursementStore()
const businessTypeSelectRef = ref()
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
  router.push({ name: 'reimbursement-detail', params: { id: row.id } })
}

function handleEdit(row: Reimbursement) {
  router.push({ name: 'reimbursement-edit', params: { id: row.id } })
}

function handleCommand(command: string, row: Reimbursement) {
  switch (command) {
    case 'copy':
      handleCopy(row)
      break
    case 'push':
      handleManualPush(row)
      break
    case 'delete':
      handleDelete(row)
      break
  }
}

async function handleCopy(row: Reimbursement) {
  try {
    await ElMessageBox.confirm('确定要复制该报销单吗？', '提示', { type: 'info' })
  } catch {
    return
  }

  try {
    await store.copyReimbursementFromId(row.id)
    ElMessage.success('复制成功')
    await router.push('/reimbursement/new')
  } catch {
    ElMessage.error('复制失败')
  }
}

function handleManualPush(row: Reimbursement) {
  void row
  ElMessage.success('推送成功')
}

async function handleDelete(row: Reimbursement) {
  if (row.status === DocumentStatus.VOIDED) {
    ElMessageBox.confirm('确定要删除该报销单吗？删除后无法恢复。', '警告', {
      type: 'warning',
      confirmButtonText: '确定',
      cancelButtonText: '取消',
    }).then(async () => {
      try {
        await store.deleteReimbursement(row.id, row.version)
        await store.fetchReimbursements()
        ElMessage.success('删除成功')
      } catch {
        ElMessage.error('删除失败')
      }
    })
    return
  }

  try {
    await ElMessageBox.confirm(
      '请选择对该报销单的操作：',
      '提示',
      {
        type: 'warning',
        confirmButtonText: '作废',
        cancelButtonText: '删除',
        distinguishCancelAndClose: true,
        closeOnClickModal: false,
      },
    )
    // confirm = 作废
    try {
      await store.voidReimbursement(row.id, row.version)
      await store.fetchReimbursements()
      ElMessage.success('作废成功')
    } catch {
      ElMessage.error('作废失败')
    }
  } catch (action) {
    if (action === 'cancel') {
      // cancel = 删除
      try {
        await store.deleteReimbursement(row.id, row.version)
        await store.fetchReimbursements()
        ElMessage.success('删除成功')
      } catch {
        ElMessage.error('删除失败')
      }
    }
    // close = 什么都不做
  }
}

function handleSizeChange() {
  store.fetchReimbursements()
}

function handleCurrentChange() {
  store.fetchReimbursements()
}

function handleBusinessTypeNodeClick(_data: any, node: any) {
  if (!node.isLeaf) {
    node.expanded ? node.collapse() : node.expand()
  }
}

function handleBusinessTypeChange(values: string[]) {
  // 过滤掉父节点，只保留叶子节点
  queryForm.value.businessTypeIds = values.filter((id) =>
    isLeafBusinessType(id, businessTypes.value),
  )
}

onMounted(async () => {
  await loadMasterData()
  store.query = { ...queryForm.value }
  store.fetchReimbursements()
})
</script>

<style scoped>
.reimbursement-list {
  padding: 20px;
}

.page-header {
  margin-bottom: 16px;
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

.query-form {
  --query-field-width: 220px;
}

.query-grid {
  display: grid;
  grid-template-columns: repeat(4, calc(var(--query-field-width) + 96px));
  column-gap: 24px;
  row-gap: 16px;
  align-items: center;
}

.query-form :deep(.query-field) {
  margin-bottom: 0;
  margin-right: 0;
}

.query-form :deep(.query-field .el-form-item__content) {
  width: var(--query-field-width);
  flex: none;
}

.query-form :deep(.query-field .el-input),
.query-form :deep(.query-field .el-select),
.query-form :deep(.query-field .el-tree-select) {
  width: var(--query-field-width);
}

.query-form :deep(.query-field--actions .el-form-item__content) {
  width: auto;
  min-width: var(--query-field-width);
}

.query-form :deep(.query-field--actions .el-form-item__label) {
  visibility: hidden;
}

.query-actions {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 8px;
  min-width: var(--query-field-width);
  height: 32px;
  margin-left: -50px;
}

.table-section {
  background: white;
  border-radius: 4px;
  overflow: hidden;
}

.reimbursement-table {
  --el-table-border-color: #ebeef5;
}

.reimbursement-table :deep(.col-document-no .cell) {
  white-space: nowrap;
}

.document-no-link {
  white-space: nowrap;
}

.pagination-section {
  display: flex;
  justify-content: flex-end;
  padding: 20px;
}

.row-actions {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: 100%;
}

.action-icon {
  width: 24px;
  height: 24px;
  padding: 0;
  margin: 0;
  font-size: 16px;
  color: #409eff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.more-btn {
  width: 24px;
  height: 24px;
  border: 1px solid #c6e2ff;
  border-radius: 50%;
}

.more-btn:hover {
  border-color: #409eff;
  background: #ecf5ff;
}
</style>
