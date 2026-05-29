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
import { masterDataFallback } from '@/data/masterDataFallback'

const companies = shallowRef<ReimCompany[]>([])
const departments = shallowRef<ReimDepartment[]>([])
const reimbursers = shallowRef<Reimburser[]>([])
const businessTypes = shallowRef<BusinessType[]>([])
const cities = shallowRef<City[]>([])
const projects = shallowRef<Project[]>([])
const loaded = ref(false)
const loading = ref(false)
const usingFallback = ref(false)

function applyFallback() {
  companies.value = masterDataFallback.companies
  departments.value = masterDataFallback.departments
  reimbursers.value = masterDataFallback.reimbursers
  businessTypes.value = buildBusinessTypeTree(masterDataFallback.businessTypesFlat)
  cities.value = masterDataFallback.cities
  projects.value = masterDataFallback.projects
  usingFallback.value = true
  loaded.value = true
}

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
      usingFallback.value = false
      loaded.value = true
    } catch {
      applyFallback()
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
    usingFallback,
    loadMasterData,
  }
}
