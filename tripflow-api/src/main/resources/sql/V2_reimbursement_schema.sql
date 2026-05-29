-- TripFlow 差旅报销模块 - 主数据与报销单表结构
-- 依据：docs/概要设计.md 第五章 页面数据（5.3.1 ~ 5.3.6）
-- 适用：云端 MySQL tripflow 库，可重复执行（幂等）

USE tripflow;

-- ============================================================
-- 一、主数据表
-- ============================================================

CREATE TABLE IF NOT EXISTS reim_company (
    reim_company_id   VARCHAR(32)  NOT NULL PRIMARY KEY COMMENT '费用归属公司ID',
    reim_company_no   VARCHAR(16)  NOT NULL COMMENT '公司编号',
    reim_company_name VARCHAR(128) NOT NULL COMMENT '公司名称',
    created_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='费用归属公司';

CREATE TABLE IF NOT EXISTS reim_department (
    reim_department_id   VARCHAR(32)  NOT NULL PRIMARY KEY COMMENT '报销部门ID',
    reim_department_no   VARCHAR(16)  NOT NULL COMMENT '部门编号',
    reim_department_name VARCHAR(128) NOT NULL COMMENT '部门名称',
    created_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报销部门';

CREATE TABLE IF NOT EXISTS reimburser (
    reimburser_id     VARCHAR(32)  NOT NULL PRIMARY KEY COMMENT '员工ID',
    reimburser_no     VARCHAR(16)  NOT NULL COMMENT '工号',
    reimburser_name   VARCHAR(64)  NOT NULL COMMENT '姓名',
    department_id     VARCHAR(32)  DEFAULT NULL COMMENT '所属部门ID',
    created_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_reimburser_department (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报销人/员工';

CREATE TABLE IF NOT EXISTS business_type (
    business_type_id        VARCHAR(32)  NOT NULL PRIMARY KEY COMMENT '业务类型ID',
    business_type_no        VARCHAR(32)  NOT NULL COMMENT '类型编号',
    business_type_name      VARCHAR(128) NOT NULL COMMENT '类型名称',
    there_subordinate_node  CHAR(1)      NOT NULL DEFAULT '0' COMMENT '是否有下级 1是0否',
    superior_id             VARCHAR(32)  NOT NULL DEFAULT 'none' COMMENT '上级ID，none为根',
    created_at              DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_business_type_parent (superior_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='业务类型';

CREATE TABLE IF NOT EXISTS city (
    city_no    VARCHAR(16)  NOT NULL PRIMARY KEY COMMENT '城市编号',
    city_name  VARCHAR(64)  NOT NULL COMMENT '城市名称',
    city_type  CHAR(1)      NOT NULL COMMENT '城市类型 1一线2二线3三线',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='城市';

CREATE TABLE IF NOT EXISTS project (
    project_id   VARCHAR(32)  NOT NULL PRIMARY KEY COMMENT '项目ID',
    project_no   VARCHAR(64)  NOT NULL COMMENT '项目编号',
    project_name VARCHAR(128) NOT NULL COMMENT '项目名称',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='费用分摊项目';

-- ============================================================
-- 二、报销单主表（保留 JSON 存完整单据，列表字段冗余便于查询）
-- ============================================================

CREATE TABLE IF NOT EXISTS reimbursement (
    id                     BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_no            VARCHAR(64)    NOT NULL COMMENT '报销单号',
    status                 INT            NOT NULL DEFAULT 0 COMMENT '0草稿1已完成2已作废',
    title                  VARCHAR(500)   DEFAULT NULL COMMENT '报销标题',
    reason                 VARCHAR(500)   DEFAULT NULL COMMENT '出差事由',
    company_id             VARCHAR(64)    DEFAULT NULL COMMENT '费用归属公司ID',
    department_id          VARCHAR(64)    DEFAULT NULL COMMENT '报销部门ID',
    reimburser_id          VARCHAR(64)    DEFAULT NULL COMMENT '报销人ID',
    business_type_id       VARCHAR(64)    DEFAULT NULL COMMENT '业务类型ID',
    total_allowance_amount DECIMAL(12, 2) NOT NULL DEFAULT 0 COMMENT '补助总金额',
    remark                 VARCHAR(1000)  DEFAULT NULL COMMENT '备注',
    content                JSON           NOT NULL COMMENT '完整报销单JSON',
    created_at             DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_document_no (document_no),
    KEY idx_reimbursement_status (status),
    KEY idx_reimbursement_company (company_id),
    KEY idx_reimbursement_department (department_id),
    KEY idx_reimbursement_reimburser (reimburser_id),
    KEY idx_reimbursement_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='差旅报销单';

-- 兼容已存在的 reimbursement 表（若列已存在可忽略报错）
-- ALTER TABLE reimbursement ADD COLUMN remark VARCHAR(1000) DEFAULT NULL COMMENT '备注' AFTER total_allowance_amount;

-- ============================================================
-- 三、报销单子表（规范化存储，便于统计与扩展）
-- ============================================================

CREATE TABLE IF NOT EXISTS reimbursement_travel_record (
    id                  BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    reimbursement_id    BIGINT       NOT NULL COMMENT '报销单ID',
    record_key          VARCHAR(64)  NOT NULL COMMENT '前端行程ID',
    reimburser_id       VARCHAR(32)  NOT NULL,
    reimburser_name     VARCHAR(64)  NOT NULL,
    reimburser_no       VARCHAR(16)  NOT NULL,
    departure_city_id   VARCHAR(16)  NOT NULL,
    departure_city_name VARCHAR(64)  NOT NULL,
    arrival_city_id     VARCHAR(16)  NOT NULL,
    arrival_city_name   VARCHAR(64)  NOT NULL,
    departure_date      DATE         NOT NULL,
    arrival_date        DATE         NOT NULL,
    description         VARCHAR(500) DEFAULT NULL,
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_travel_reimbursement (reimbursement_id),
    KEY idx_travel_reimburser_date (reimburser_id, departure_date, arrival_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='补录行程';

CREATE TABLE IF NOT EXISTS reimbursement_allowance (
    id                  BIGINT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    reimbursement_id    BIGINT        NOT NULL,
    allowance_key       VARCHAR(64)   NOT NULL COMMENT '前端补助ID',
    travel_record_key   VARCHAR(64)   NOT NULL,
    reimburser_id       VARCHAR(32)   NOT NULL,
    reimburser_name     VARCHAR(64)   NOT NULL,
    departure_date      DATE          NOT NULL,
    arrival_date        DATE          NOT NULL,
    allowance_days      INT           NOT NULL DEFAULT 0,
    departure_city      VARCHAR(64)   DEFAULT NULL,
    arrival_city        VARCHAR(64)   DEFAULT NULL,
    total_apply_amount  DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_allowance_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_allowance_reimbursement (reimbursement_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='补助信息';

CREATE TABLE IF NOT EXISTS reimbursement_allowance_calendar (
    id                       BIGINT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    allowance_id             BIGINT        NOT NULL,
    calendar_date            DATE          NOT NULL,
    weekday                  VARCHAR(8)    NOT NULL,
    meal_allowance           DECIMAL(10,2) NOT NULL DEFAULT 0,
    transport_allowance      DECIMAL(10,2) NOT NULL DEFAULT 0,
    communication_allowance  DECIMAL(10,2) NOT NULL DEFAULT 0,
    meal_selected            TINYINT(1)    NOT NULL DEFAULT 0,
    transport_selected       TINYINT(1)    NOT NULL DEFAULT 0,
    communication_selected   TINYINT(1)    NOT NULL DEFAULT 0,
    meal_amount              DECIMAL(10,2) NOT NULL DEFAULT 0,
    transport_amount         DECIMAL(10,2) NOT NULL DEFAULT 0,
    communication_amount     DECIMAL(10,2) NOT NULL DEFAULT 0,
    KEY idx_calendar_allowance (allowance_id),
    KEY idx_calendar_date (calendar_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='补助日历';

CREATE TABLE IF NOT EXISTS reimbursement_cost_allocation (
    id               BIGINT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    reimbursement_id BIGINT        NOT NULL,
    allocation_key   VARCHAR(64)   NOT NULL COMMENT '前端分摊ID',
    company_id       VARCHAR(32)   DEFAULT NULL,
    company_name     VARCHAR(128)  DEFAULT NULL,
    company_no       VARCHAR(16)   DEFAULT NULL,
    project_id       VARCHAR(32)   DEFAULT NULL,
    project_name     VARCHAR(128)  DEFAULT NULL,
    project_no       VARCHAR(64)   DEFAULT NULL,
    ratio            DECIMAL(8,4)  NOT NULL DEFAULT 0 COMMENT '分摊比例0-1',
    amount           DECIMAL(12,2) NOT NULL DEFAULT 0,
    sort_order       INT           NOT NULL DEFAULT 0,
    KEY idx_allocation_reimbursement (reimbursement_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='费用分摊';

-- ============================================================
-- 四、主数据种子（概要设计 5.3.1 ~ 5.3.6）
-- ============================================================

INSERT INTO reim_company (reim_company_id, reim_company_no, reim_company_name) VALUES
('1C54557F1782E000', '0407', '胜意科技北京分公司'),
('19218A262C976000', '0408', '胜意科技上海分公司'),
('1C61686865DA8000', '0409', '胜意科技武汉分公司'),
('1717271D1DA15000', '0410', '胜意科技杭州分公司'),
('16AE93CC7EF92002', '0411', '胜意科技荆州分公司')
ON DUPLICATE KEY UPDATE
    reim_company_no = VALUES(reim_company_no),
    reim_company_name = VALUES(reim_company_name);

INSERT INTO reim_department (reim_department_id, reim_department_no, reim_department_name) VALUES
('13AB8D7B52A9B002', '072001', '客户成功事业部'),
('13BFD31C6029A002', '072002', '企业消费事业部'),
('14515BB4BFB92003', '072003', '企业费控事业部'),
('19206611C47A6000', '072004', '集采事业部'),
('19D32F9FE9647000', '072005', '航旅事业部'),
('13C7E2BAE0393001', '072006', '运营事业部'),
('14055D22BB808001', '072007', '营销事业部')
ON DUPLICATE KEY UPDATE
    reim_department_no = VALUES(reim_department_no),
    reim_department_name = VALUES(reim_department_name);

INSERT INTO reimburser (reimburser_id, reimburser_no, reimburser_name, department_id) VALUES
('13AB3A3F72409002', '74541', '徐年年', '13AB8D7B52A9B002'),
('13AB498CC6409002', '74008', '郑雨雪', '13BFD31C6029A002'),
('13AB4A56BB009002', '21552', '邹薇',   '14515BB4BFB92003'),
('13AB591FE8009002', '80681', '王成军', '19206611C47A6000'),
('13AB77281A408001', '89899', '潘展飞', '19D32F9FE9647000'),
('13AB7925EB808001', '10503', '姜林',   '13C7E2BAE0393001')
ON DUPLICATE KEY UPDATE
    reimburser_no = VALUES(reimburser_no),
    reimburser_name = VALUES(reimburser_name),
    department_id = VALUES(department_id);

INSERT INTO business_type (business_type_id, business_type_no, business_type_name, there_subordinate_node, superior_id) VALUES
('18F0916A8C2C4000', '1001001', '员工差旅活动', '1', 'none'),
('18F091913EEC4000', '100100101', '境内出差', '1', '18F0916A8C2C4000'),
('1B5FEB7DD4396000', '10010010101', '项目出差', '0', '18F091913EEC4000'),
('1A92E43082EFC000', '10010010102', '市场拓展出差', '0', '18F091913EEC4000'),
('13AB3A4138008001', '100100102', '境外出差', '1', '18F0916A8C2C4000'),
('13AB3A4248008002', '10010010201', '国外考察', '0', '13AB3A4138008001'),
('13AB3A4154008001', '10010010202', '售后维护出差', '0', '13AB3A4138008001'),
('13AB3A4172008001', '1001002', '人力资源', '1', 'none'),
('13AB3A418F808001', '100100201', '个人团队培训', '0', '13AB3A4172008001'),
('13AB3A41AC408001', '100100202', '招聘会', '0', '13AB3A4172008001'),
('13AB3A41CD808002', '1001003', '员工福利', '1', 'none'),
('13AB3A41ED408002', '100100301', '员工旅游', '0', '13AB3A41CD808002'),
('13AB3A420CC08002', '100100302', '员工团建', '0', '13AB3A41CD808002'),
('13AB3A422A808001', '100100303', '员工体检', '0', '13AB3A41CD808002')
ON DUPLICATE KEY UPDATE
    business_type_no = VALUES(business_type_no),
    business_type_name = VALUES(business_type_name),
    there_subordinate_node = VALUES(there_subordinate_node),
    superior_id = VALUES(superior_id);

INSERT INTO city (city_no, city_name, city_type) VALUES
('10119', '北京', '1'),
('10621', '上海', '1'),
('10458', '武汉', '2'),
('10216', '杭州', '2'),
('10455', '荆州', '3')
ON DUPLICATE KEY UPDATE
    city_name = VALUES(city_name),
    city_type = VALUES(city_type);

INSERT INTO project (project_id, project_no, project_name) VALUES
('12BC248B25083001', 'nonProjectRelated', '非项目类费用归集'),
('1C811ABF96195000', 'centralChina', '华中客户定制化项目'),
('1C5931735AC4A000', 'southChina', '华南客户定制化项目'),
('1771EC45F2443000', 'northChina', '华北客户定制化项目'),
('1762792DB4E9A002', 'eastChina', '华东客户定制化项目'),
('17071065FC29A002', 'southWest', '西南客户定制化项目'),
('162664EBE9ABE001', 'northWest', '西北客户定制化项目'),
('162664B8526BE002', 'northEast', '东北客户定制化项目')
ON DUPLICATE KEY UPDATE
    project_no = VALUES(project_no),
    project_name = VALUES(project_name);
