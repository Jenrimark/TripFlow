import request from './request'
import type { ExpenseReport } from '@/types/expense'

export function getExpenseList() {
  return request.get<ExpenseReport[]>('/expense/list')
}
