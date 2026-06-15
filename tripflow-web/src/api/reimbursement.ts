import request from './request'
import type {
  Reimbursement,
  ReimbursementQuery,
  ReimbursementListResult,
} from '@/types/reimbursement'

export const reimbursementApi = {
  getList(query: ReimbursementQuery, page: number, pageSize: number) {
    return request.get<ReimbursementListResult>('/reimbursement', {
      params: { ...query, page, pageSize },
    })
  },

  getDetail(id: string) {
    return request.get<Reimbursement>(`/reimbursement/${id}`)
  },

  create(data: Partial<Reimbursement>) {
    return request.post<Reimbursement>('/reimbursement', data)
  },

  update(id: string, data: Partial<Reimbursement>) {
    return request.put<Reimbursement>(`/reimbursement/${id}`, data)
  },

  delete(id: string, version?: number) {
    return request.delete(`/reimbursement/${id}`, { params: { version } })
  },

  submit(id: string, version: number) {
    return request.post(`/reimbursement/${id}/submit`, null, { params: { version } })
  },

  void(id: string, version: number) {
    return request.post(`/reimbursement/${id}/void`, null, { params: { version } })
  },
}
