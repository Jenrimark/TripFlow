export interface WorkflowTask {
  id: number
  title: string
  taskType: 'expense_approval' | 'general'
  kanbanStatus: 'todo' | 'in_progress' | 'done'
  approvalStatus: 'pending' | 'approved' | 'rejected'
  assigneeId: number
  bizId: number | null
  createdAt: string
}
