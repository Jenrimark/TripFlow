<template>
  <el-dialog
    :model-value="visible"
    @update:model-value="$emit('update:visible', $event)"
    :title="dialogTitle"
    width="600px"
    :close-on-click-modal="false"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="100px">
      <el-alert
        title="仅可补录未从申请单带入或未产生费用的行程信息。跨天跨城行程填写说明：出发城市-到达城市：武汉-北京; 出发日期-到达日期：1号-5号; 1号~5号补助按北京匹配;"
        type="info"
        show-icon
        :closable="false"
        style="margin-bottom: 20px"
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

      <el-form-item label="出发日期" prop="departureDate">
        <el-date-picker
          v-model="formData.departureDate"
          type="date"
          placeholder="请选择出发日期"
          value-format="YYYY-MM-DD"
          :disabled-date="disableFutureDate"
        />
      </el-form-item>

      <el-form-item label="到达日期" prop="arrivalDate">
        <el-date-picker
          v-model="formData.arrivalDate"
          type="date"
          placeholder="请选择到达日期"
          value-format="YYYY-MM-DD"
          :disabled-date="disableDateBeforeDeparture"
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
      <el-button type="primary" @click="handleSave">保存</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue'
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
  description: '',
})

const rules: FormRules = {
  reimburserId: [{ required: true, message: '请选择出行人', trigger: 'change' }],
  departureCityId: [{ required: true, message: '请选择出发城市', trigger: 'change' }],
  arrivalCityId: [{ required: true, message: '请选择到达城市', trigger: 'change' }],
  departureDate: [{ required: true, message: '请选择出发日期', trigger: 'change' }],
  arrivalDate: [{ required: true, message: '请选择到达日期', trigger: 'change' }],
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

function disableDateBeforeDeparture(date: Date) {
  if (!formData.departureDate) return false
  return date < new Date(formData.departureDate)
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
    if (valid) {
      emit('save', { ...formData })
    }
  })
}

watch(
  () => props.record,
  (newRecord) => {
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
        description: newRecord.description,
      })
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
        description: '',
      })
    }
  },
  { immediate: true },
)

onMounted(() => {
  loadMasterData()
})
</script>
