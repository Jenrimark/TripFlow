<template>
  <el-dialog
    :model-value="visible"
    @update:model-value="$emit('update:visible', $event)"
    :title="dialogTitle"
    width="720px"
    :close-on-click-modal="false"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-alert
        title="仅可补录未从申请单带入或未产生费用的行程信息。跨天跨城行程填写说明：出发城市-到达城市：武汉-北京; 出发日期-到达日期：1号-5号; 1号~5号补助按北京匹配;"
        type="warning"
        show-icon
        :closable="false"
        class="modal-alert"
      />

      <el-form-item label="出行人" prop="reimburserId">
        <el-select
          v-model="formData.reimburserId"
          filterable
          placeholder="请选择出行人"
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

      <el-form-item label="出发城市" prop="departureCityId">
        <el-select
          v-model="formData.departureCityId"
          filterable
          placeholder="请选择出发城市"
          @change="handleDepartureCityChange"
        >
          <el-option
            v-for="city in cities"
            :key="city.cityNo"
            :label="city.cityName"
            :value="city.cityNo"
          />
        </el-select>
      </el-form-item>

      <el-form-item label="到达城市" prop="arrivalCityId">
        <el-select
          v-model="formData.arrivalCityId"
          filterable
          placeholder="请选择到达城市"
          @change="handleArrivalCityChange"
        >
          <el-option
            v-for="city in cities"
            :key="city.cityNo"
            :label="city.cityName"
            :value="city.cityNo"
          />
        </el-select>
      </el-form-item>

      <el-form-item label="出发到达日期" prop="dateRange">
        <el-date-picker
          v-model="formData.dateRange"
          type="datetimerange"
          range-separator="-"
          start-placeholder="请选择出发日期"
          end-placeholder="请选择到达日期"
          value-format="YYYY-MM-DD HH:mm:ss"
          :default-time="[new Date(0, 0, 0, 0, 0, 0), new Date(0, 0, 0, 23, 59, 59)]"
          :disabled-date="disableFutureDate"
        />
      </el-form-item>

      <el-form-item label="行程说明" prop="description">
        <el-input
          v-model="formData.description"
          type="textarea"
          placeholder="请输入行程说明"
          maxlength="500"
          show-word-limit
          :rows="3"
        />
      </el-form-item>
    </el-form>

    <template #footer>
      <el-button @click="$emit('update:visible', false)">取消</el-button>
      <el-button type="primary" @click="handleSave">确定</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted, onUnmounted, nextTick } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import type { TravelRecord } from '@/types/reimbursement'
import { useReimbursementMasterData } from '@/composables/useReimbursementMasterData'

const { reimbursers, cities, loadMasterData } = useReimbursementMasterData()

const props = defineProps<{
  visible: boolean
  record: TravelRecord | null
  mode: 'add' | 'edit' | 'copy'
}>()

const emit = defineEmits<{
  'update:visible': [value: boolean]
  save: [record: Omit<TravelRecord, 'id'>]
  autoSave: [record: Omit<TravelRecord, 'id'>]
  revert: []
}>()

const formRef = ref<FormInstance>()

const formData = reactive<Omit<TravelRecord, 'id'>>({
  reimburserId: '',
  reimburserName: '',
  reimburserNo: '',
  departureCityId: '',
  departureCityName: '',
  arrivalCityId: '',
  arrivalCityName: '',
  departureDate: '',
  arrivalDate: '',
  departureDatetime: '',
  arrivalDatetime: '',
  description: '',
  dateRange: [] as string[],
})

const isEditMode = computed(() => props.mode === 'edit')

function buildSavePayload(): Omit<TravelRecord, 'id'> | null {
  if (formData.dateRange.length !== 2) return null
  const [start, end] = formData.dateRange
  formData.departureDatetime = start
  formData.arrivalDatetime = end
  formData.departureDate = start.slice(0, 10)
  formData.arrivalDate = end.slice(0, 10)
  return { ...formData }
}

function emitAutoSave() {
  if (!isEditMode.value) return
  const payload = buildSavePayload()
  if (payload) emit('autoSave', payload)
}

function handleKeydown(e: KeyboardEvent) {
  if ((e.metaKey || e.ctrlKey) && e.key === 'z' && !e.shiftKey) {
    if (isEditMode.value) {
      e.preventDefault()
      emit('revert')
    }
  }
}

onMounted(() => {
  document.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  document.removeEventListener('keydown', handleKeydown)
})

const rules: FormRules = {
  reimburserId: [{ required: true, message: '请选择出行人', trigger: 'change' }],
  departureCityId: [{ required: true, message: '请选择出发城市', trigger: 'change' }],
  arrivalCityId: [
    { required: true, message: '请选择到达城市', trigger: 'change' },
    {
      validator: (_rule: any, value: string, callback: any) => {
        if (value && formData.departureCityId && value === formData.departureCityId) {
          callback(new Error('出发城市不能与到达城市相同'))
        } else {
          callback()
        }
      },
      trigger: 'change',
    },
  ],
  dateRange: [{ required: true, message: '请选择出发到达日期', trigger: 'change' }],
  description: [{ required: true, message: '请输入行程说明', trigger: 'blur' }],
}

const dialogTitle = computed(() => {
  if (props.mode === 'edit') return '编辑行程'
  if (props.mode === 'copy') return '复制行程'
  return '新增行程'
})

function disableFutureDate(date: Date) {
  return date > new Date()
}

function handleReimburserChange(value: string) {
  const person = reimbursers.value.find((p) => p.reimburserId === value)
  if (person) {
    formData.reimburserName = person.reimburserName
    formData.reimburserNo = person.reimburserNo
  }
}

function handleDepartureCityChange(value: string) {
  const city = cities.value.find((c) => c.cityNo === value)
  if (city) {
    formData.departureCityName = city.cityName
  }
  // 出发城市变更后重新校验到达城市（同城校验）
  if (formRef.value) {
    formRef.value.validateField('arrivalCityId')
  }
}

function handleArrivalCityChange(value: string) {
  const city = cities.value.find((c) => c.cityNo === value)
  if (city) {
    formData.arrivalCityName = city.cityName
  }
}

async function handleSave() {
  if (!formRef.value) return

  await formRef.value.validate((valid) => {
    if (valid && formData.dateRange.length === 2) {
      const [start, end] = formData.dateRange
      formData.departureDatetime = start
      formData.arrivalDatetime = end
      formData.departureDate = start.slice(0, 10)
      formData.arrivalDate = end.slice(0, 10)
      emit('save', { ...formData })
    }
  })
}

let initializing = false

watch(
  () => props.record,
  (newRecord) => {
    initializing = true
    if (newRecord) {
      Object.assign(formData, {
        reimburserId: newRecord.reimburserId,
        reimburserName: newRecord.reimburserName,
        reimburserNo: newRecord.reimburserNo,
        departureCityId: newRecord.departureCityId,
        departureCityName: newRecord.departureCityName,
        arrivalCityId: newRecord.arrivalCityId,
        arrivalCityName: newRecord.arrivalCityName,
        departureDate: newRecord.departureDate,
        arrivalDate: newRecord.arrivalDate,
        departureDatetime: newRecord.departureDatetime ?? '',
        arrivalDatetime: newRecord.arrivalDatetime ?? '',
        description: newRecord.description,
      })
      formData.dateRange = newRecord.departureDatetime && newRecord.arrivalDatetime
        ? [newRecord.departureDatetime, newRecord.arrivalDatetime]
        : []
    } else {
      Object.assign(formData, {
        reimburserId: '',
        reimburserName: '',
        reimburserNo: '',
        departureCityId: '',
        departureCityName: '',
        arrivalCityId: '',
        arrivalCityName: '',
        departureDate: '',
        arrivalDate: '',
        departureDatetime: '',
        arrivalDatetime: '',
        dateRange: [],
        description: '',
      })
    }
    nextTick(() => { initializing = false })
  },
  { immediate: true },
)

watch(() => formData.dateRange, () => {
  if (!initializing) emitAutoSave()
})

watch(
  () => [formData.reimburserId, formData.departureCityId, formData.arrivalCityId, formData.description],
  () => {
    if (!initializing) emitAutoSave()
  },
)

onMounted(() => {
  loadMasterData()
})
</script>

<style scoped>
.modal-alert {
  margin-bottom: 20px;
  --el-alert-bg-color: rgb(255, 247, 233);
  --el-alert-icon-color: rgb(255, 153, 1);
}

.modal-alert :deep(.el-alert__icon) {
  background-color: transparent;
}

.modal-alert :deep(.el-alert__icon svg) {
  color: rgb(255, 153, 1);
}

.modal-alert :deep(.el-alert__title) {
  color: #000 !important;
}

:deep(.el-dialog__body) {
  padding: 20px 30px;
}

:deep(.el-form-item) {
  margin-bottom: 22px;
}

</style>
