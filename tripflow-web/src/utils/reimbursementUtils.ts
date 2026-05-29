import type {
  AllowanceCalendarItem,
  TravelRecord,
  CostAllocation,
} from '@/types/reimbursement'

// 城市类型定义
export enum CityType {
  FIRST_TIER = '1', // 一线城市
  SECOND_TIER = '2', // 二线城市
  THIRD_TIER = '3', // 三线城市
}

// 补助标准
export const ALLOWANCE_STANDARDS = {
  [CityType.FIRST_TIER]: {
    meal: 100,
    transport: 40,
    communication: 40,
  },
  [CityType.SECOND_TIER]: {
    meal: 80,
    transport: 40,
    communication: 40,
  },
  [CityType.THIRD_TIER]: {
    meal: 50,
    transport: 40,
    communication: 40,
  },
}

// 城市数据（示例）
export const CITIES = [
  { cityNo: '10119', cityName: '北京', cityType: CityType.FIRST_TIER },
  { cityNo: '10621', cityName: '上海', cityType: CityType.FIRST_TIER },
  { cityNo: '10458', cityName: '武汉', cityType: CityType.SECOND_TIER },
  { cityNo: '10216', cityName: '杭州', cityType: CityType.SECOND_TIER },
  { cityNo: '10455', cityName: '荆州', cityType: CityType.THIRD_TIER },
]

/**
 * 获取城市类型
 */
export function getCityType(cityId: string): CityType {
  const city = CITIES.find((c) => c.cityNo === cityId)
  return city?.cityType || CityType.THIRD_TIER
}

/**
 * 获取补助标准
 */
export function getAllowanceStandard(cityId: string) {
  const cityType = getCityType(cityId)
  return ALLOWANCE_STANDARDS[cityType]
}

/**
 * 计算两个日期之间的天数（包含首尾）
 */
export function calculateDaysBetween(startDate: string, endDate: string): number {
  const start = new Date(startDate)
  const end = new Date(endDate)
  const diffTime = end.getTime() - start.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1
  return diffDays
}

/**
 * 获取星期几
 */
export function getWeekday(date: string): string {
  const d = new Date(date)
  const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
  return weekdays[d.getDay()]!
}

/**
 * 生成补助日历
 */
export function generateAllowanceCalendar(
  startDate: string,
  endDate: string,
  cityId: string,
): AllowanceCalendarItem[] {
  const days = calculateDaysBetween(startDate, endDate)
  const standard = getAllowanceStandard(cityId)
  const calendar: AllowanceCalendarItem[] = []

  const start = new Date(startDate)
  for (let i = 0; i < days; i++) {
    const currentDate = new Date(start)
    currentDate.setDate(start.getDate() + i)
    const dateStr = currentDate.toISOString().split('T')[0]!

    calendar.push({
      date: dateStr,
      weekday: getWeekday(dateStr),
      mealAllowance: standard.meal,
      transportAllowance: standard.transport,
      communicationAllowance: standard.communication,
      mealSelected: false,
      transportSelected: false,
      communicationSelected: false,
      mealAmount: 0,
      transportAmount: 0,
      communicationAmount: 0,
    })
  }

  return calendar
}

/**
 * 检查时间范围是否完全重叠
 */
export function isDateRangeFullyOverlapping(
  range1: { start: string; end: string },
  range2: { start: string; end: string },
): boolean {
  return range1.start === range2.start && range1.end === range2.end
}

/**
 * 检查同一人员的时间范围是否完全重叠
 */
export function checkTravelRecordOverlap(
  records: TravelRecord[],
  newRecord: TravelRecord,
): boolean {
  return records.some(
    (record) =>
      record.reimburserId === newRecord.reimburserId &&
      isDateRangeFullyOverlapping(
        { start: record.departureDate, end: record.arrivalDate },
        { start: newRecord.departureDate, end: newRecord.arrivalDate },
      ),
  )
}

/**
 * 银行家舍入法
 */
export function bankerRound(num: number, decimals: number): number {
  const factor = Math.pow(10, decimals)
  const n = num * factor
  const isPositive = n >= 0

  const absN = Math.abs(n)
  const floorN = Math.floor(absN)
  const decimalPart = absN - floorN

  let result: number
  if (decimalPart === 0.5) {
    result = floorN % 2 === 0 ? floorN : floorN + 1
  } else {
    result = Math.round(absN)
  }

  return (isPositive ? result : -result) / factor
}

/**
 * 计算均摊金额
 */
export function calculateEvenAllocation(
  totalAmount: number,
  count: number,
): { ratio: number; amount: number }[] {
  const results: { ratio: number; amount: number }[] = []
  let remainingAmount = totalAmount
  let remainingRatio = 1

  for (let i = 0; i < count; i++) {
    if (i === count - 1) {
      results.push({
        ratio: bankerRound(remainingRatio, 4),
        amount: bankerRound(remainingAmount, 2),
      })
    } else {
      const ratio = bankerRound(1 / count, 4)
      const amount = bankerRound(totalAmount * ratio, 2)
      results.push({ ratio, amount })
      remainingAmount -= amount
      remainingRatio -= ratio
    }
  }

  return results
}

/**
 * 格式化金额显示
 */
export function formatAmount(amount: number): string {
  return `¥${amount.toLocaleString('zh-CN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`
}

/**
 * 验证分摊比例是否超限
 */
export function isAllocationRatioExceeded(
  allocations: CostAllocation[],
  index: number,
  newRatio: number,
): boolean {
  let sum = newRatio
  for (let i = 0; i < allocations.length; i++) {
    if (i !== index) {
      sum += allocations[i]!.ratio
    }
  }
  return sum > 1
}
