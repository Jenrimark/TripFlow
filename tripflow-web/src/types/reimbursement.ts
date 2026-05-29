// 单据状态
export enum DocumentStatus {
  DRAFT = 0, // 草稿
  COMPLETED = 1, // 已完成
  VOIDED = 2, // 已作废
}

// 报销单基础信息
export interface ReimbursementBasicInfo {
  title: string // 报销标题，最多500字
  reason: string // 出差事由，最多500字
  reimburserId: string // 报销人ID
  reimburserName: string // 报销人姓名
  reimburserNo: string // 报销人工号
  departmentId: string // 报销部门ID
  departmentName: string // 报销部门名称
  departmentNo: string // 报销部门编号
  companyId: string // 费用归属公司ID
  companyName: string // 费用归属公司名称
  companyNo: string // 费用归属公司编号
  businessTypeId: string // 业务类型ID
  businessTypeName: string // 业务类型名称
  businessTypeNo: string // 业务类型编号
}

// 补录行程
export interface TravelRecord {
  id: string // 行程ID
  reimburserId: string // 出行人ID
  reimburserName: string // 出行人姓名
  reimburserNo: string // 出行人工号
  departureCityId: string // 出发城市ID
  departureCityName: string // 出发城市名称
  arrivalCityId: string // 到达城市ID
  arrivalCityName: string // 到达城市名称
  departureDate: string // 出发日期 YYYY-MM-DD
  arrivalDate: string // 到达日期 YYYY-MM-DD
  description: string // 行程说明，最多500字
}

// 补助日历项
export interface AllowanceCalendarItem {
  date: string // 日期 YYYY-MM-DD
  weekday: string // 星期几
  mealAllowance: number // 餐费补助标准
  transportAllowance: number // 交通补助标准
  communicationAllowance: number // 通讯补助标准
  mealSelected: boolean // 餐费补助是否选中
  transportSelected: boolean // 交通补助是否选中
  communicationSelected: boolean // 通讯补助是否选中
  mealAmount: number // 餐费补助金额（可修改）
  transportAmount: number // 交通补助金额（可修改）
  communicationAmount: number // 通讯补助金额（可修改）
}

// 补助信息
export interface AllowanceInfo {
  id: string // 补助信息ID
  travelRecordId: string // 关联的行程ID
  reimburserId: string // 出行人ID
  reimburserName: string // 出行人姓名
  departureDate: string // 开始日期
  arrivalDate: string // 结束日期
  allowanceDays: number // 补助天数
  departureCity: string // 出发城市
  arrivalCity: string // 到达城市（补助城市）
  calendar: AllowanceCalendarItem[] // 补助日历
  totalApplyAmount: number // 申请金额（标准总额）
  totalAllowanceAmount: number // 补助金额
}

// 分摊信息
export interface CostAllocation {
  id: string // 分摊ID
  companyId: string // 费用归属公司ID
  companyName: string // 费用归属公司名称
  companyNo: string // 费用归属公司编号
  projectId: string // 项目ID
  projectName: string // 项目名称
  projectNo: string // 项目编号
  ratio: number // 分摊比例 0-1
  amount: number // 分摊金额
}

// 报销单完整信息
export interface Reimbursement {
  id: string // 报销单ID
  documentNo: string // 报销单号
  status: DocumentStatus // 单据状态
  createdAt: string // 创建时间
  basicInfo: ReimbursementBasicInfo // 基本信息
  travelRecords: TravelRecord[] // 补录行程列表
  allowances: AllowanceInfo[] // 补助信息列表
  costAllocations: CostAllocation[] // 分摊信息列表
  remark: string // 备注信息，最多1000字
  totalAllowanceAmount: number // 补助总金额
  totalMealAmount: number // 餐费补助总额
  totalTransportAmount: number // 交通补助总额
  totalCommunicationAmount: number // 通讯补助总额
}

// 查询条件
export interface ReimbursementQuery {
  documentNo?: string // 报销单号
  title?: string // 标题
  reason?: string // 事由
  companyIds?: string[] // 费用归属公司IDs
  departmentIds?: string[] // 报销部门IDs
  reimburserIds?: string[] // 报销人IDs
  businessTypeIds?: string[] // 业务类型IDs
}

// 分页查询结果
export interface ReimbursementListResult {
  list: Reimbursement[]
  total: number
  page: number
  pageSize: number
}
