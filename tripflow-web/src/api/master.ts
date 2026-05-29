import request from './request'

export interface ReimCompany {
  reimCompanyId: string
  reimCompanyNo: string
  reimCompanyName: string
}

export interface ReimDepartment {
  reimDepartmentId: string
  reimDepartmentNo: string
  reimDepartmentName: string
}

export interface Reimburser {
  reimburserId: string
  reimburserNo: string
  reimburserName: string
  departmentId?: string
  departmentName?: string
  departmentNo?: string
}

export interface BusinessType {
  businessTypeId: string
  businessTypeNo: string
  businessTypeName: string
  thereSubordinateNode: string
  superiorId: string
  children?: BusinessType[]
}

export interface City {
  cityNo: string
  cityName: string
  cityType: string
}

export interface Project {
  projectId: string
  projectNo: string
  projectName: string
}

export const masterApi = {
  getCompanies() {
    return request.get<ReimCompany[]>('/master/companies')
  },
  getDepartments() {
    return request.get<ReimDepartment[]>('/master/departments')
  },
  getReimbursers() {
    return request.get<Reimburser[]>('/master/reimbursers')
  },
  getBusinessTypes() {
    return request.get<BusinessType[]>('/master/business-types')
  },
  getCities() {
    return request.get<City[]>('/master/cities')
  },
  getProjects() {
    return request.get<Project[]>('/master/projects')
  },
}

export function buildBusinessTypeTree(types: BusinessType[]): BusinessType[] {
  const map = new Map<string, BusinessType>()
  types.forEach((type) => {
    map.set(type.businessTypeId, { ...type, children: [] })
  })
  const roots: BusinessType[] = []
  types.forEach((type) => {
    const node = map.get(type.businessTypeId)!
    if (type.superiorId === 'none') {
      roots.push(node)
    } else {
      const parent = map.get(type.superiorId)
      if (parent) {
        parent.children!.push(node)
      } else {
        roots.push(node)
      }
    }
  })
  return roots
}
