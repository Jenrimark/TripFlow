-- TripFlow 差旅报销单示例数据
-- 依据：docs/概要设计.md 补助标准与页面数据
-- 可重复执行（按 document_no 幂等）

USE tripflow;

-- ============================================================
-- 示例 1：已完成 — 武汉→北京 项目出差，3 天补助 540 元
-- ============================================================

INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM20250510001', 1,
    '华北客户拜访差旅报销', '拜访北京重点客户，推进华中定制化项目签约',
    '1C54557F1782E000', '13AB8D7B52A9B002', '13AB3A3F72409002', '1B5FEB7DD4396000',
    540.00, '客户接待期间公司安排用餐，已自行核减',
    JSON_OBJECT(
        'id', '1',
        'documentNo', 'REIM20250510001',
        'status', 1,
        'createdAt', '2025-05-10',
        'basicInfo', JSON_OBJECT(
            'title', '华北客户拜访差旅报销',
            'reason', '拜访北京重点客户，推进华中定制化项目签约',
            'reimburserId', '13AB3A3F72409002',
            'reimburserName', '徐年年',
            'reimburserNo', '74541',
            'departmentId', '13AB8D7B52A9B002',
            'departmentName', '客户成功事业部',
            'departmentNo', '072001',
            'companyId', '1C54557F1782E000',
            'companyName', '胜意科技北京分公司',
            'companyNo', '0407',
            'businessTypeId', '1B5FEB7DD4396000',
            'businessTypeName', '项目出差',
            'businessTypeNo', '10010010101'
        ),
        'travelRecords', JSON_ARRAY(
            JSON_OBJECT(
                'id', 'travel_001',
                'reimburserId', '13AB3A3F72409002',
                'reimburserName', '徐年年',
                'reimburserNo', '74541',
                'departureCityId', '10458',
                'departureCityName', '武汉',
                'arrivalCityId', '10119',
                'arrivalCityName', '北京',
                'departureDate', '2025-05-10',
                'arrivalDate', '2025-05-12',
                'description', '拜访北京重点客户，洽谈项目合作事宜'
            )
        ),
        'allowances', JSON_ARRAY(
            JSON_OBJECT(
                'id', 'allowance_001',
                'travelRecordId', 'travel_001',
                'reimburserId', '13AB3A3F72409002',
                'reimburserName', '徐年年',
                'departureDate', '2025-05-10',
                'arrivalDate', '2025-05-12',
                'allowanceDays', 3,
                'departureCity', '武汉',
                'arrivalCity', '北京',
                'calendar', JSON_ARRAY(
                    JSON_OBJECT('date', '2025-05-10', 'weekday', '星期六', 'mealAllowance', 100, 'transportAllowance', 40, 'communicationAllowance', 40, 'mealSelected', true, 'transportSelected', true, 'communicationSelected', true, 'mealAmount', 100, 'transportAmount', 40, 'communicationAmount', 40),
                    JSON_OBJECT('date', '2025-05-11', 'weekday', '星期日', 'mealAllowance', 100, 'transportAllowance', 40, 'communicationAllowance', 40, 'mealSelected', true, 'transportSelected', true, 'communicationSelected', true, 'mealAmount', 100, 'transportAmount', 40, 'communicationAmount', 40),
                    JSON_OBJECT('date', '2025-05-12', 'weekday', '星期一', 'mealAllowance', 100, 'transportAllowance', 40, 'communicationAllowance', 40, 'mealSelected', true, 'transportSelected', true, 'communicationSelected', true, 'mealAmount', 100, 'transportAmount', 40, 'communicationAmount', 40)
                ),
                'totalApplyAmount', 540,
                'totalAllowanceAmount', 540
            )
        ),
        'costAllocations', JSON_ARRAY(
            JSON_OBJECT(
                'id', 'alloc_001',
                'companyId', '1C54557F1782E000',
                'companyName', '胜意科技北京分公司',
                'companyNo', '0407',
                'projectId', '1C811ABF96195000',
                'projectName', '华中客户定制化项目',
                'projectNo', 'centralChina',
                'ratio', 1,
                'amount', 540
            )
        ),
        'remark', '客户接待期间公司安排用餐，已自行核减',
        'totalAllowanceAmount', 540,
        'totalMealAmount', 300,
        'totalTransportAmount', 120,
        'totalCommunicationAmount', 120
    ),
    '2025-05-10 09:30:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @reim_id_1 = (SELECT id FROM reimbursement WHERE document_no = 'REIM20250510001');

DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @reim_id_1
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @reim_id_1;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @reim_id_1;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @reim_id_1;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @reim_id_1, 'travel_001', '13AB3A3F72409002', '徐年年', '74541',
    '10458', '武汉', '10119', '北京',
    '2025-05-10', '2025-05-12', '拜访北京重点客户，洽谈项目合作事宜'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @reim_id_1, 'allowance_001', 'travel_001',
    '13AB3A3F72409002', '徐年年', '2025-05-10', '2025-05-12',
    3, '武汉', '北京', 540.00, 540.00
);

SET @allowance_id_1 = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@allowance_id_1, '2025-05-10', '星期六', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@allowance_id_1, '2025-05-11', '星期日', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@allowance_id_1, '2025-05-12', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @reim_id_1, 'alloc_001', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 540.00, 0
);

-- ============================================================
-- 示例 2：草稿 — 上海→杭州 市场拓展出差，3 天补助 480 元
-- ============================================================

INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM20250515001', 0,
    '华东市场拓展出差', '参加杭州行业展会，拓展华东区域客户',
    '19218A262C976000', '13BFD31C6029A002', '13AB498CC6409002', '1A92E43082EFC000',
    480.00, '',
    JSON_OBJECT(
        'id', '2',
        'documentNo', 'REIM20250515001',
        'status', 0,
        'createdAt', '2025-05-15',
        'basicInfo', JSON_OBJECT(
            'title', '华东市场拓展出差',
            'reason', '参加杭州行业展会，拓展华东区域客户',
            'reimburserId', '13AB498CC6409002',
            'reimburserName', '郑雨雪',
            'reimburserNo', '74008',
            'departmentId', '13BFD31C6029A002',
            'departmentName', '企业消费事业部',
            'departmentNo', '072002',
            'companyId', '19218A262C976000',
            'companyName', '胜意科技上海分公司',
            'companyNo', '0408',
            'businessTypeId', '1A92E43082EFC000',
            'businessTypeName', '市场拓展出差',
            'businessTypeNo', '10010010102'
        ),
        'travelRecords', JSON_ARRAY(
            JSON_OBJECT(
                'id', 'travel_002',
                'reimburserId', '13AB498CC6409002',
                'reimburserName', '郑雨雪',
                'reimburserNo', '74008',
                'departureCityId', '10621',
                'departureCityName', '上海',
                'arrivalCityId', '10216',
                'arrivalCityName', '杭州',
                'departureDate', '2025-05-15',
                'arrivalDate', '2025-05-17',
                'description', '参加杭州行业展会及客户拜访'
            )
        ),
        'allowances', JSON_ARRAY(
            JSON_OBJECT(
                'id', 'allowance_002',
                'travelRecordId', 'travel_002',
                'reimburserId', '13AB498CC6409002',
                'reimburserName', '郑雨雪',
                'departureDate', '2025-05-15',
                'arrivalDate', '2025-05-17',
                'allowanceDays', 3,
                'departureCity', '上海',
                'arrivalCity', '杭州',
                'calendar', JSON_ARRAY(
                    JSON_OBJECT('date', '2025-05-15', 'weekday', '星期四', 'mealAllowance', 80, 'transportAllowance', 40, 'communicationAllowance', 40, 'mealSelected', true, 'transportSelected', true, 'communicationSelected', true, 'mealAmount', 80, 'transportAmount', 40, 'communicationAmount', 40),
                    JSON_OBJECT('date', '2025-05-16', 'weekday', '星期五', 'mealAllowance', 80, 'transportAllowance', 40, 'communicationAllowance', 40, 'mealSelected', true, 'transportSelected', true, 'communicationSelected', true, 'mealAmount', 80, 'transportAmount', 40, 'communicationAmount', 40),
                    JSON_OBJECT('date', '2025-05-17', 'weekday', '星期六', 'mealAllowance', 80, 'transportAllowance', 40, 'communicationAllowance', 40, 'mealSelected', true, 'transportSelected', true, 'communicationSelected', true, 'mealAmount', 80, 'transportAmount', 40, 'communicationAmount', 40)
                ),
                'totalApplyAmount', 480,
                'totalAllowanceAmount', 480
            )
        ),
        'costAllocations', JSON_ARRAY(
            JSON_OBJECT(
                'id', 'alloc_002',
                'companyId', '19218A262C976000',
                'companyName', '胜意科技上海分公司',
                'companyNo', '0408',
                'projectId', '1762792DB4E9A002',
                'projectName', '华东客户定制化项目',
                'projectNo', 'eastChina',
                'ratio', 1,
                'amount', 480
            )
        ),
        'remark', '',
        'totalAllowanceAmount', 480,
        'totalMealAmount', 240,
        'totalTransportAmount', 120,
        'totalCommunicationAmount', 120
    ),
    '2025-05-15 14:00:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @reim_id_2 = (SELECT id FROM reimbursement WHERE document_no = 'REIM20250515001');

DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @reim_id_2
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @reim_id_2;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @reim_id_2;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @reim_id_2;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @reim_id_2, 'travel_002', '13AB498CC6409002', '郑雨雪', '74008',
    '10621', '上海', '10216', '杭州',
    '2025-05-15', '2025-05-17', '参加杭州行业展会及客户拜访'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @reim_id_2, 'allowance_002', 'travel_002',
    '13AB498CC6409002', '郑雨雪', '2025-05-15', '2025-05-17',
    3, '上海', '杭州', 480.00, 480.00
);

SET @allowance_id_2 = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@allowance_id_2, '2025-05-15', '星期四', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@allowance_id_2, '2025-05-16', '星期五', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@allowance_id_2, '2025-05-17', '星期六', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @reim_id_2, 'alloc_002', '19218A262C976000', '胜意科技上海分公司', '0408',
    '1762792DB4E9A002', '华东客户定制化项目', 'eastChina', 1.0000, 480.00, 0
);

-- ============================================================
-- 示例 3：已作废 — 荆州售后维护，2 天补助 260 元
-- ============================================================

INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM20250508001', 2,
    '荆州客户售后维护', '荆州分公司客户系统故障现场排查',
    '16AE93CC7EF92002', '14515BB4BFB92003', '13AB4A56BB009002', '13AB3A4154008001',
    260.00, '行程取消，单据作废',
    JSON_OBJECT(
        'id', '3',
        'documentNo', 'REIM20250508001',
        'status', 2,
        'createdAt', '2025-05-08',
        'basicInfo', JSON_OBJECT(
            'title', '荆州客户售后维护',
            'reason', '荆州分公司客户系统故障现场排查',
            'reimburserId', '13AB4A56BB009002',
            'reimburserName', '邹薇',
            'reimburserNo', '21552',
            'departmentId', '14515BB4BFB92003',
            'departmentName', '企业费控事业部',
            'departmentNo', '072003',
            'companyId', '16AE93CC7EF92002',
            'companyName', '胜意科技荆州分公司',
            'companyNo', '0411',
            'businessTypeId', '13AB3A4154008001',
            'businessTypeName', '售后维护出差',
            'businessTypeNo', '10010010202'
        ),
        'travelRecords', JSON_ARRAY(
            JSON_OBJECT(
                'id', 'travel_003',
                'reimburserId', '13AB4A56BB009002',
                'reimburserName', '邹薇',
                'reimburserNo', '21552',
                'departureCityId', '10458',
                'departureCityName', '武汉',
                'arrivalCityId', '10455',
                'arrivalCityName', '荆州',
                'departureDate', '2025-05-08',
                'arrivalDate', '2025-05-09',
                'description', '客户系统故障现场排查与修复'
            )
        ),
        'allowances', JSON_ARRAY(
            JSON_OBJECT(
                'id', 'allowance_003',
                'travelRecordId', 'travel_003',
                'reimburserId', '13AB4A56BB009002',
                'reimburserName', '邹薇',
                'departureDate', '2025-05-08',
                'arrivalDate', '2025-05-09',
                'allowanceDays', 2,
                'departureCity', '武汉',
                'arrivalCity', '荆州',
                'calendar', JSON_ARRAY(
                    JSON_OBJECT('date', '2025-05-08', 'weekday', '星期四', 'mealAllowance', 50, 'transportAllowance', 40, 'communicationAllowance', 40, 'mealSelected', true, 'transportSelected', true, 'communicationSelected', true, 'mealAmount', 50, 'transportAmount', 40, 'communicationAmount', 40),
                    JSON_OBJECT('date', '2025-05-09', 'weekday', '星期五', 'mealAllowance', 50, 'transportAllowance', 40, 'communicationAllowance', 40, 'mealSelected', true, 'transportSelected', true, 'communicationSelected', true, 'mealAmount', 50, 'transportAmount', 40, 'communicationAmount', 40)
                ),
                'totalApplyAmount', 260,
                'totalAllowanceAmount', 260
            )
        ),
        'costAllocations', JSON_ARRAY(
            JSON_OBJECT(
                'id', 'alloc_003',
                'companyId', '16AE93CC7EF92002',
                'companyName', '胜意科技荆州分公司',
                'companyNo', '0411',
                'projectId', '12BC248B25083001',
                'projectName', '非项目类费用归集',
                'projectNo', 'nonProjectRelated',
                'ratio', 1,
                'amount', 260
            )
        ),
        'remark', '行程取消，单据作废',
        'totalAllowanceAmount', 260,
        'totalMealAmount', 100,
        'totalTransportAmount', 80,
        'totalCommunicationAmount', 80
    ),
    '2025-05-08 10:00:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @reim_id_3 = (SELECT id FROM reimbursement WHERE document_no = 'REIM20250508001');

DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @reim_id_3
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @reim_id_3;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @reim_id_3;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @reim_id_3;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @reim_id_3, 'travel_003', '13AB4A56BB009002', '邹薇', '21552',
    '10458', '武汉', '10455', '荆州',
    '2025-05-08', '2025-05-09', '客户系统故障现场排查与修复'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @reim_id_3, 'allowance_003', 'travel_003',
    '13AB4A56BB009002', '邹薇', '2025-05-08', '2025-05-09',
    2, '武汉', '荆州', 260.00, 260.00
);

SET @allowance_id_3 = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@allowance_id_3, '2025-05-08', '星期四', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@allowance_id_3, '2025-05-09', '星期五', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @reim_id_3, 'alloc_003', '16AE93CC7EF92002', '胜意科技荆州分公司', '0411',
    '12BC248B25083001', '非项目类费用归集', 'nonProjectRelated', 1.0000, 260.00, 0
);
