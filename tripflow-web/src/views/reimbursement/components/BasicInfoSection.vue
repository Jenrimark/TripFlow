<template>
  <div class="basic-info-section">
    <div class="section-header" @click="toggleExpanded">
      <span class="section-title">基本信息</span>
      <el-icon class="expand-icon" :class="{ expanded }">
        <ArrowDown />
      </el-icon>
    </div>

    <div v-show="expanded" class="section-content">
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
        <el-form-item label="报销标题" prop="title">
          <el-input
            v-model="formData.title"
            placeholder="请输入报销标题"
            maxlength="500"
            show-word-limit
            :disabled="isViewMode"
          />
        </el-form-item>

        <el-form-item label="出差事由" prop="reason">
          <el-input
            v-model="formData.reason"
            type="textarea"
            placeholder="请输入出差事由"
            maxlength="500"
            show-word-limit
            :rows="3"
            :disabled="isViewMode"
          />
        </el-form-item>

        <el-form-item label="报销人" prop="reimburserId">
          <el-select
            v-model="formData.reimburserId"
            filterable
            placeholder="请选择报销人"
            :disabled="isViewMode"
            @change="handleReimburserChange"
          >
            <el-option
              v-for="person in reimbursers"
              :key="person.reimburserId"
              :label="`${person.reimburserName}(${person.reimburserNo})`"
              :value="person.reimburserId"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="报销部门" prop="departmentId">
          <el-input v-model="formData.departmentName" disabled placeholder="选择报销人后自动带出" />
        </el-form-item>

        <el-form-item label="费用归属公司" prop="companyId">
          <el-select
            v-model="formData.companyId"
            filterable
            placeholder="请选择费用归属公司"
            :disabled="isViewMode"
            @change="handleCompanyChange"
          >
            <el-option
              v-for="company in companies"
              :key="company.reimCompanyId"
              :label="company.reimCompanyName"
              :value="company.reimCompanyId"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="业务类型" prop="businessTypeId">
          <el-tree-select
            v-model="formData.businessTypeId"
            :data="businessTypes"
            :props="{ label: 'businessTypeName', value: 'businessTypeId' }"
            check-strictly
            placeholder="请选择业务类型"
            :disabled="isViewMode"
            @change="handleBusinessTypeChange"
          />
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, watch, onMounted } from 'vue'
import { ArrowDown } from '@element-plus/icons-vue'
import type { FormInstance, FormRules } from 'element-plus'
import { useReimbursementStore } from '@/stores/reimbursementStore'
import { useReimbursementPageMode } from '@/composables/useReimbursementPageMode'
import type { ReimbursementBasicInfo } from '@/types/reimbursement'
import type { BusinessType } from '@/api/master'
import { useReimbursementMasterData } from '@/composables/useReimbursementMasterData'

const store = useReimbursementStore()
const { isViewMode } = useReimbursementPageMode()
const { companies, reimbursers, businessTypes, loadMasterData } = useReimbursementMasterData()
const formRef = ref<FormInstance>()
const expanded = ref(true)

const formData = reactive<ReimbursementBasicInfo>({
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
})

const rules: FormRules = {
  title: [{ required: true, message: '请输入报销标题', trigger: 'blur' }],
  reason: [{ required: true, message: '请输入出差事由', trigger: 'blur' }],
  reimburserId: [{ required: true, message: '请选择报销人', trigger: 'change' }],
  companyId: [{ required: true, message: '请选择费用归属公司', trigger: 'change' }],
  businessTypeId: [{ required: true, message: '请选择业务类型', trigger: 'change' }],
}

function toggleExpanded() {
  expanded.value = !expanded.value
}

function handleReimburserChange(value: string) {
  const person = reimbursers.value.find((p) => p.reimburserId === value)
  if (person) {
    formData.reimburserName = person.reimburserName
    formData.reimburserNo = person.reimburserNo
    formData.departmentId = person.departmentId ?? ''
    formData.departmentName = person.departmentName ?? ''
    formData.departmentNo = person.departmentNo ?? ''
  }
}

function handleCompanyChange(value: string) {
  const company = companies.value.find((c) => c.reimCompanyId === value)
  if (company) {
    formData.companyName = company.reimCompanyName
    formData.companyNo = company.reimCompanyNo
  }
}

function handleBusinessTypeChange(value: string) {
  const findType = (types: BusinessType[]): BusinessType | null => {
    for (const type of types) {
      if (type.businessTypeId === value) return type
      if (type.children) {
        const found = findType(type.children)
        if (found) return found
      }
    }
    return null
  }
  const type = findType(businessTypes.value)
  if (type) {
    formData.businessTypeName = type.businessTypeName
    formData.businessTypeNo = type.businessTypeNo
  }
}

watch(
  () => store.currentReimbursement?.basicInfo,
  (newInfo) => {
    if (newInfo) {
      Object.assign(formData, newInfo)
    }
  },
  { immediate: true },
)

watch(
  formData,
  (newData) => {
    if (store.currentReimbursement) {
      store.currentReimbursement.basicInfo = { ...newData }
    }
  },
  { deep: true },
)

onMounted(() => {
  loadMasterData()
})

defineExpose({
  validate: () => formRef.value?.validate(),
})
</script>

<style scoped>
.basic-info-section {
  background: white;
  border-radius: 4px;
  margin-bottom: 16px;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
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
</style>
