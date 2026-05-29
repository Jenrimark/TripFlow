import type {
  Reimbursement,
  ReimbursementQuery,
  ReimbursementListResult,
} from '@/types/reimbursement'
import axios from 'axios'

const API_BASE = '/api/reimbursement'

export const reimbursementApi = {
  async getList(
    query: ReimbursementQuery,
    page: number,
    pageSize: number,
  ): Promise<ReimbursementListResult> {
    const response = await axios.get<ReimbursementListResult>(API_BASE, {
      params: { ...query, page, pageSize },
    })
    return response.data
  },

  async getDetail(id: string): Promise<Reimbursement> {
    const response = await axios.get<Reimbursement>(`${API_BASE}/${id}`)
    return response.data
  },

  async create(data: Partial<Reimbursement>): Promise<Reimbursement> {
    const response = await axios.post<Reimbursement>(API_BASE, data)
    return response.data
  },

  async update(id: string, data: Partial<Reimbursement>): Promise<Reimbursement> {
    const response = await axios.put<Reimbursement>(`${API_BASE}/${id}`, data)
    return response.data
  },

  async delete(id: string): Promise<void> {
    await axios.delete(`${API_BASE}/${id}`)
  },

  async submit(id: string): Promise<void> {
    await axios.post(`${API_BASE}/${id}/submit`)
  },

  async void(id: string): Promise<void> {
    await axios.post(`${API_BASE}/${id}/void`)
  },
}
