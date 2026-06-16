-- TripFlow 初始化脚本（MySQL）
-- ----------------------------------------
-- 说明：expense_report 表已移除，业务迁移到 reimbursement 表
-- ----------------------------------------
CREATE DATABASE IF NOT EXISTS tripflow DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tripflow;

DROP TABLE IF EXISTS workflow_task;
DROP TABLE IF EXISTS user;

CREATE TABLE user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    role VARCHAR(32) NOT NULL DEFAULT 'employee',
    department VARCHAR(64) DEFAULT NULL
);

CREATE TABLE workflow_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    task_type VARCHAR(32) NOT NULL DEFAULT 'general',
    kanban_status VARCHAR(32) NOT NULL DEFAULT 'todo',
    approval_status VARCHAR(32) NOT NULL DEFAULT 'pending',
    assignee_id BIGINT DEFAULT NULL,
    biz_id BIGINT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO user (username, role, department) VALUES
('张三', 'employee', '销售部'),
('李经理', 'manager', '销售部'),
('王财务', 'finance', '财务部');

INSERT INTO workflow_task (title, task_type, kanban_status, approval_status, assignee_id, biz_id) VALUES
('审批：上海客户拜访差旅', 'expense_approval', 'in_progress', 'pending', 2, 1),
('补充发票附件', 'general', 'todo', 'pending', 1, NULL);

CREATE TABLE IF NOT EXISTS reimbursement (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_no VARCHAR(64) NOT NULL,
    status INT NOT NULL DEFAULT 0,
    title VARCHAR(500) DEFAULT NULL,
    reason VARCHAR(500) DEFAULT NULL,
    company_id VARCHAR(64) DEFAULT NULL,
    department_id VARCHAR(64) DEFAULT NULL,
    reimburser_id VARCHAR(64) DEFAULT NULL,
    business_type_id VARCHAR(64) DEFAULT NULL,
    total_allowance_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    version BIGINT NOT NULL DEFAULT 0,
    content JSON NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
