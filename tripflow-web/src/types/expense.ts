export interface ExpenseReport {
  id: number
  title: string
  tripDestination: string
  tripStartDate: string
  tripEndDate: string
  amount: number
  status: 'draft' | 'pending' | 'approved' | 'rejected'
  applicantId: number
  createdAt: string
}
