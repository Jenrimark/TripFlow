import axios from 'axios'

const request = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

// 响应拦截器：提取后端错误消息，注入到 error.displayMessage
request.interceptors.response.use(
  (response) => response,
  (error) => {
    const serverMessage =
      error.response?.data?.message ||
      error.response?.data?.error ||
      error.response?.data?.detail
    if (serverMessage) {
      error.displayMessage = serverMessage
    }
    return Promise.reject(error)
  },
)

export default request
