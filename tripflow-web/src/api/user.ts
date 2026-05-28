import request from './request'
import type { User } from '@/types/user'

export function getUserList() {
  return request.get<User[]>('/user/list')
}
