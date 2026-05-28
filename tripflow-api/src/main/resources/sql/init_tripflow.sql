-- TripFlow 初始化脚本（MySQL）
CREATE DATABASE IF NOT EXISTS tripflow DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tripflow;

DROP TABLE IF EXISTS workflow_task;
DROP TABLE IF EXISTS expense_report;
DROP TABLE IF EXISTS user;

CREATE TABLE user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    role VARCHAR(32) NOT NULL DEFAULT 'employee',
    department VARCHAR(64) DEFAULT NULL
);

CREATE TABLE expense_report (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    trip_destination VARCHAR(128) DEFAULT NULL,
    trip_start_date DATE DEFAULT NULL,
    trip_end_date DATE DEFAULT NULL,
    amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    status VARCHAR(32) NOT NULL DEFAULT 'draft',
    applicant_id BIGINT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
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

INSERT INTO expense_report (title, trip_destination, trip_start_date, trip_end_date, amount, status, applicant_id) VALUES
('上海客户拜访差旅', '上海', '2026-05-10', '2026-05-12', 3280.50, 'pending', 1),
('深圳展会出差', '深圳', '2026-05-20', '2026-05-22', 5120.00, 'draft', 1);

INSERT INTO workflow_task (title, task_type, kanban_status, approval_status, assignee_id, biz_id) VALUES
('审批：上海客户拜访差旅', 'expense_approval', 'in_progress', 'pending', 2, 1),
('补充发票附件', 'general', 'todo', 'pending', 1, NULL);
