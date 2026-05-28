import request from './request'
import type { WorkflowTask } from '@/types/workflow'

export function getWorkflowTasks() {
  return request.get<WorkflowTask[]>('/workflow/tasks')
}
