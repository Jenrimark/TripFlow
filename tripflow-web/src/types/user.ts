export interface User {
  id: number
  username: string
  role: 'employee' | 'manager' | 'finance'
  department: string
}
