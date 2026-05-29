import { ref, shallowRef } from 'vue'
import {
  masterApi,
  buildBusinessTypeTree,
  type ReimCompany,
  type ReimDepartment,
  type Reimburser,
  type BusinessType,
  type City,
  type Project,
} from '@/api/master'

const companies = shallowRef<ReimCompany[]>([])
const departments = shallowRef<ReimDepartment[]>([])
const reimbursers = shallowRef<Reimburser[]>([])
const businessTypes = shallowRef<BusinessType[]>([])
const cities = shallowRef<City[]>([])
const projects = shallowRef<Project[]>([])
const loaded = ref(false)
const loading = ref(false)

export function useReimbursementMasterData() {
  async function loadMasterData() {
    if (loaded.value || loading.value) return
    loading.value = true
    try {
      const [companyRes, deptRes, reimburserRes, typeRes, cityRes, projectRes] = await Promise.all([
        masterApi.getCompanies(),
        masterApi.getDepartments(),
        masterApi.getReimbursers(),
        masterApi.getBusinessTypes(),
        masterApi.getCities(),
        masterApi.getProjects(),
      ])
      companies.value = companyRes.data
      departments.value = deptRes.data
      reimbursers.value = reimburserRes.data
      businessTypes.value = buildBusinessTypeTree(typeRes.data)
      cities.value = cityRes.data
      projects.value = projectRes.data
      loaded.value = true
    } finally {
      loading.value = false
    }
  }

  return {
    companies,
    departments,
    reimbursers,
    businessTypes,
    cities,
    projects,
    loading,
    loadMasterData,
  }
}
