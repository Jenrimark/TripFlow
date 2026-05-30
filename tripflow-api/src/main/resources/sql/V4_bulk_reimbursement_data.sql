-- TripFlow 差旅报销单批量种子数据（自动生成）
-- 依据：V2_reimbursement_schema.sql、概要设计.md、database-schema-mermaid.md
-- 共 55 条，可重复执行（按 document_no 幂等）

USE tripflow;

-- REIM202504190001 status=1 荆州客户项目现场支持
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504190001', 1,
    '荆州客户项目现场支持', '参加荆州举办的行业交流活动',
    '1C54557F1782E000', '13C7E2BAE0393001',
    '13AB7925EB808001', '1B5FEB7DD4396000',
    260.00, '单据已核对无误', '{"id": "1", "documentNo": "REIM202504190001", "status": 1, "createdAt": "2025-04-19", "basicInfo": {"title": "荆州客户项目现场支持", "reason": "参加荆州举办的行业交流活动", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "1B5FEB7DD4396000", "businessTypeName": "项目出差", "businessTypeNo": "10010010101"}, "travelRecords": [{"id": "travel_0001", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-04-19", "arrivalDate": "2025-04-20", "description": "上海至荆州，项目出差相关行程"}], "allowances": [{"id": "allowance_0001", "travelRecordId": "travel_0001", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-04-19", "arrivalDate": "2025-04-20", "allowanceDays": 2, "departureCity": "上海", "arrivalCity": "荆州", "calendar": [{"date": "2025-04-19", "weekday": "星期六", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-20", "weekday": "星期日", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 260, "totalAllowanceAmount": 260}], "costAllocations": [{"id": "alloc_0001", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "1762792DB4E9A002", "projectName": "华东客户定制化项目", "projectNo": "eastChina", "ratio": 1.0, "amount": 260}], "remark": "单据已核对无误", "totalAllowanceAmount": 260, "totalMealAmount": 100, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-04-19 08:01:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504190001');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0001', '13AB7925EB808001', '姜林', '10503',
    '10621', '上海', '10455', '荆州',
    '2025-04-19', '2025-04-20', '上海至荆州，项目出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0001', 'travel_0001',
    '13AB7925EB808001', '姜林', '2025-04-19', '2025-04-20',
    2, '上海', '荆州',
    260.00, 260.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-19', '星期六', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-04-20', '星期日', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0001', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '1762792DB4E9A002', '华东客户定制化项目', 'eastChina', 1.0000, 260.00, 0
);

-- REIM202503090002 status=1 上海驻场技术支持
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503090002', 1,
    '上海驻场技术支持', '配合非项目类费用归集项目进度，赴上海现场办公',
    '19218A262C976000', '13AB8D7B52A9B002',
    '13AB3A3F72409002', '13AB3A4154008001',
    900.00, '行程紧凑，备注备查', '{"id": "2", "documentNo": "REIM202503090002", "status": 1, "createdAt": "2025-03-09", "basicInfo": {"title": "上海驻场技术支持", "reason": "配合非项目类费用归集项目进度，赴上海现场办公", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departmentId": "13AB8D7B52A9B002", "departmentName": "客户成功事业部", "departmentNo": "072001", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "13AB3A4154008001", "businessTypeName": "售后维护出差", "businessTypeNo": "10010010202"}, "travelRecords": [{"id": "travel_0002", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-03-09", "arrivalDate": "2025-03-13", "description": "荆州至上海，售后维护出差相关行程"}], "allowances": [{"id": "allowance_0002", "travelRecordId": "travel_0002", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "departureDate": "2025-03-09", "arrivalDate": "2025-03-13", "allowanceDays": 5, "departureCity": "荆州", "arrivalCity": "上海", "calendar": [{"date": "2025-03-09", "weekday": "星期日", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-10", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-11", "weekday": "星期二", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-12", "weekday": "星期三", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-13", "weekday": "星期四", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 900, "totalAllowanceAmount": 900}], "costAllocations": [{"id": "alloc_0002", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "12BC248B25083001", "projectName": "非项目类费用归集", "projectNo": "nonProjectRelated", "ratio": 1.0, "amount": 900}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 900, "totalMealAmount": 500, "totalTransportAmount": 200, "totalCommunicationAmount": 200}', '2025-03-09 08:48:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503090002');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0002', '13AB3A3F72409002', '徐年年', '74541',
    '10455', '荆州', '10621', '上海',
    '2025-03-09', '2025-03-13', '荆州至上海，售后维护出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0002', 'travel_0002',
    '13AB3A3F72409002', '徐年年', '2025-03-09', '2025-03-13',
    5, '荆州', '上海',
    900.00, 900.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-09', '星期日', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-03-10', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-03-11', '星期二', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-03-12', '星期三', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-03-13', '星期四', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0002', '19218A262C976000', '胜意科技上海分公司', '0408',
    '12BC248B25083001', '非项目类费用归集', 'nonProjectRelated', 1.0000, 900.00, 0
);

-- REIM202501280003 status=1 荆州春季校园招聘
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501280003', 1,
    '荆州春季校园招聘', '配合华东客户定制化项目项目进度，赴荆州现场办公',
    '1717271D1DA15000', '13BFD31C6029A002',
    '13AB498CC6409002', '13AB3A41AC408001',
    390.00, '行程紧凑，备注备查', '{"id": "3", "documentNo": "REIM202501280003", "status": 1, "createdAt": "2025-01-28", "basicInfo": {"title": "荆州春季校园招聘", "reason": "配合华东客户定制化项目项目进度，赴荆州现场办公", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departmentId": "13BFD31C6029A002", "departmentName": "企业消费事业部", "departmentNo": "072002", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A41AC408001", "businessTypeName": "招聘会", "businessTypeNo": "100100202"}, "travelRecords": [{"id": "travel_0003", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-01-28", "arrivalDate": "2025-01-30", "description": "上海至荆州，招聘会相关行程"}], "allowances": [{"id": "allowance_0003", "travelRecordId": "travel_0003", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "departureDate": "2025-01-28", "arrivalDate": "2025-01-30", "allowanceDays": 3, "departureCity": "上海", "arrivalCity": "荆州", "calendar": [{"date": "2025-01-28", "weekday": "星期二", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-29", "weekday": "星期三", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-30", "weekday": "星期四", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 390, "totalAllowanceAmount": 390}], "costAllocations": [{"id": "alloc_0003", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1762792DB4E9A002", "projectName": "华东客户定制化项目", "projectNo": "eastChina", "ratio": 1.0, "amount": 390}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 390, "totalMealAmount": 150, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-01-28 13:38:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501280003');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0003', '13AB498CC6409002', '郑雨雪', '74008',
    '10621', '上海', '10455', '荆州',
    '2025-01-28', '2025-01-30', '上海至荆州，招聘会相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0003', 'travel_0003',
    '13AB498CC6409002', '郑雨雪', '2025-01-28', '2025-01-30',
    3, '上海', '荆州',
    390.00, 390.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-28', '星期二', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-01-29', '星期三', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-01-30', '星期四', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0003', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1762792DB4E9A002', '华东客户定制化项目', 'eastChina', 1.0000, 390.00, 0
);

-- REIM202502210004 status=2 季度团建拓展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502210004', 2,
    '季度团建拓展', '应北京分公司邀请，执行员工团建任务',
    '1C54557F1782E000', '14515BB4BFB92003',
    '13AB4A56BB009002', '13AB3A420CC08002',
    900.00, '行程取消，单据作废', '{"id": "4", "documentNo": "REIM202502210004", "status": 2, "createdAt": "2025-02-21", "basicInfo": {"title": "季度团建拓展", "reason": "应北京分公司邀请，执行员工团建任务", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "13AB3A420CC08002", "businessTypeName": "员工团建", "businessTypeNo": "100100302"}, "travelRecords": [{"id": "travel_0004", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10216", "departureCityName": "杭州", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-02-21", "arrivalDate": "2025-02-25", "description": "杭州至北京，员工团建相关行程"}], "allowances": [{"id": "allowance_0004", "travelRecordId": "travel_0004", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-02-21", "arrivalDate": "2025-02-25", "allowanceDays": 5, "departureCity": "杭州", "arrivalCity": "北京", "calendar": [{"date": "2025-02-21", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-22", "weekday": "星期六", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-23", "weekday": "星期日", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-24", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-25", "weekday": "星期二", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 900, "totalAllowanceAmount": 900}], "costAllocations": [{"id": "alloc_0004", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 900}], "remark": "行程取消，单据作废", "totalAllowanceAmount": 900, "totalMealAmount": 500, "totalTransportAmount": 200, "totalCommunicationAmount": 200}', '2025-02-21 09:02:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502210004');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0004', '13AB4A56BB009002', '邹薇', '21552',
    '10216', '杭州', '10119', '北京',
    '2025-02-21', '2025-02-25', '杭州至北京，员工团建相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0004', 'travel_0004',
    '13AB4A56BB009002', '邹薇', '2025-02-21', '2025-02-25',
    5, '杭州', '北京',
    900.00, 900.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-21', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-22', '星期六', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-23', '星期日', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-24', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-25', '星期二', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0004', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 900.00, 0
);

-- REIM202502190005 status=1 北京专业技能培训
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502190005', 1,
    '北京专业技能培训', '配合华中客户定制化项目项目进度，赴北京现场办公',
    '19218A262C976000', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A418F808001',
    720.00, '展会期间公司提供用车，已核减交通补助', '{"id": "5", "documentNo": "REIM202502190005", "status": 1, "createdAt": "2025-02-19", "basicInfo": {"title": "北京专业技能培训", "reason": "配合华中客户定制化项目项目进度，赴北京现场办公", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "13AB3A418F808001", "businessTypeName": "个人团队培训", "businessTypeNo": "100100201"}, "travelRecords": [{"id": "travel_0005", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-02-19", "arrivalDate": "2025-02-22", "description": "上海至北京，个人团队培训相关行程"}], "allowances": [{"id": "allowance_0005", "travelRecordId": "travel_0005", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-02-19", "arrivalDate": "2025-02-22", "allowanceDays": 4, "departureCity": "上海", "arrivalCity": "北京", "calendar": [{"date": "2025-02-19", "weekday": "星期三", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-20", "weekday": "星期四", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-21", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-22", "weekday": "星期六", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 720, "totalAllowanceAmount": 720}], "costAllocations": [{"id": "alloc_0005", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 720}], "remark": "展会期间公司提供用车，已核减交通补助", "totalAllowanceAmount": 720, "totalMealAmount": 400, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-02-19 13:13:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502190005');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0005', '13AB7925EB808001', '姜林', '10503',
    '10621', '上海', '10119', '北京',
    '2025-02-19', '2025-02-22', '上海至北京，个人团队培训相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0005', 'travel_0005',
    '13AB7925EB808001', '姜林', '2025-02-19', '2025-02-22',
    4, '上海', '北京',
    720.00, 720.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-19', '星期三', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-20', '星期四', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-21', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-22', '星期六', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0005', '19218A262C976000', '胜意科技上海分公司', '0408',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 720.00, 0
);

-- REIM202503150006 status=1 上海渠道合作洽谈
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503150006', 1,
    '上海渠道合作洽谈', '应上海分公司邀请，执行市场拓展出差任务',
    '1C61686865DA8000', '13C7E2BAE0393001',
    '13AB7925EB808001', '1A92E43082EFC000',
    360.00, '展会期间公司提供用车，已核减交通补助', '{"id": "6", "documentNo": "REIM202503150006", "status": 1, "createdAt": "2025-03-15", "basicInfo": {"title": "上海渠道合作洽谈", "reason": "应上海分公司邀请，执行市场拓展出差任务", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "1A92E43082EFC000", "businessTypeName": "市场拓展出差", "businessTypeNo": "10010010102"}, "travelRecords": [{"id": "travel_0006", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-03-15", "arrivalDate": "2025-03-16", "description": "荆州至上海，市场拓展出差相关行程"}], "allowances": [{"id": "allowance_0006", "travelRecordId": "travel_0006", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-03-15", "arrivalDate": "2025-03-16", "allowanceDays": 2, "departureCity": "荆州", "arrivalCity": "上海", "calendar": [{"date": "2025-03-15", "weekday": "星期六", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-16", "weekday": "星期日", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 360, "totalAllowanceAmount": 360}], "costAllocations": [{"id": "alloc_0006", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "1C5931735AC4A000", "projectName": "华南客户定制化项目", "projectNo": "southChina", "ratio": 1.0, "amount": 360}], "remark": "展会期间公司提供用车，已核减交通补助", "totalAllowanceAmount": 360, "totalMealAmount": 200, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-03-15 18:20:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503150006');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0006', '13AB7925EB808001', '姜林', '10503',
    '10455', '荆州', '10621', '上海',
    '2025-03-15', '2025-03-16', '荆州至上海，市场拓展出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0006', 'travel_0006',
    '13AB7925EB808001', '姜林', '2025-03-15', '2025-03-16',
    2, '荆州', '上海',
    360.00, 360.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-15', '星期六', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-03-16', '星期日', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0006', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '1C5931735AC4A000', '华南客户定制化项目', 'southChina', 1.0000, 360.00, 0
);

-- REIM202502110007 status=0 武汉客户项目现场支持
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502110007', 0,
    '武汉客户项目现场支持', '参加武汉举办的行业交流活动',
    '19218A262C976000', '13AB8D7B52A9B002',
    '13AB3A3F72409002', '1B5FEB7DD4396000',
    80.00, '展会期间公司提供用车，已核减交通补助', '{"id": "7", "documentNo": "REIM202502110007", "status": 0, "createdAt": "2025-02-11", "basicInfo": {"title": "武汉客户项目现场支持", "reason": "参加武汉举办的行业交流活动", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departmentId": "13AB8D7B52A9B002", "departmentName": "客户成功事业部", "departmentNo": "072001", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "1B5FEB7DD4396000", "businessTypeName": "项目出差", "businessTypeNo": "10010010101"}, "travelRecords": [{"id": "travel_0007", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departureCityId": "10216", "departureCityName": "杭州", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-02-11", "arrivalDate": "2025-02-11", "description": "杭州至武汉，项目出差相关行程"}], "allowances": [{"id": "allowance_0007", "travelRecordId": "travel_0007", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "departureDate": "2025-02-11", "arrivalDate": "2025-02-11", "allowanceDays": 1, "departureCity": "杭州", "arrivalCity": "武汉", "calendar": [{"date": "2025-02-11", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 160, "totalAllowanceAmount": 80}], "costAllocations": [{"id": "alloc_0007", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "17071065FC29A002", "projectName": "西南客户定制化项目", "projectNo": "southWest", "ratio": 1.0, "amount": 80}], "remark": "展会期间公司提供用车，已核减交通补助", "totalAllowanceAmount": 80, "totalMealAmount": 0, "totalTransportAmount": 40, "totalCommunicationAmount": 40}', '2025-02-11 14:56:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502110007');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0007', '13AB3A3F72409002', '徐年年', '74541',
    '10216', '杭州', '10458', '武汉',
    '2025-02-11', '2025-02-11', '杭州至武汉，项目出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0007', 'travel_0007',
    '13AB3A3F72409002', '徐年年', '2025-02-11', '2025-02-11',
    1, '杭州', '武汉',
    160.00, 80.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-11', '星期二', 80, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0007', '19218A262C976000', '胜意科技上海分公司', '0408',
    '17071065FC29A002', '西南客户定制化项目', 'southWest', 1.0000, 80.00, 0
);

-- REIM202503240008 status=1 国际合作伙伴拜访
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503240008', 1,
    '国际合作伙伴拜访', '参加荆州举办的行业交流活动',
    '1717271D1DA15000', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A4248008002',
    600.00, '单据已核对无误', '{"id": "8", "documentNo": "REIM202503240008", "status": 1, "createdAt": "2025-03-24", "basicInfo": {"title": "国际合作伙伴拜访", "reason": "参加荆州举办的行业交流活动", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A4248008002", "businessTypeName": "国外考察", "businessTypeNo": "10010010201"}, "travelRecords": [{"id": "travel_0008", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-03-24", "arrivalDate": "2025-03-28", "description": "上海至荆州，国外考察相关行程"}], "allowances": [{"id": "allowance_0008", "travelRecordId": "travel_0008", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-03-24", "arrivalDate": "2025-03-28", "allowanceDays": 5, "departureCity": "上海", "arrivalCity": "荆州", "calendar": [{"date": "2025-03-24", "weekday": "星期一", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-25", "weekday": "星期二", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-26", "weekday": "星期三", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-27", "weekday": "星期四", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-28", "weekday": "星期五", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 650, "totalAllowanceAmount": 600}], "costAllocations": [{"id": "alloc_0008", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1762792DB4E9A002", "projectName": "华东客户定制化项目", "projectNo": "eastChina", "ratio": 1.0, "amount": 600}], "remark": "单据已核对无误", "totalAllowanceAmount": 600, "totalMealAmount": 200, "totalTransportAmount": 200, "totalCommunicationAmount": 200}', '2025-03-24 13:14:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503240008');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0008', '13AB7925EB808001', '姜林', '10503',
    '10621', '上海', '10455', '荆州',
    '2025-03-24', '2025-03-28', '上海至荆州，国外考察相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0008', 'travel_0008',
    '13AB7925EB808001', '姜林', '2025-03-24', '2025-03-28',
    5, '上海', '荆州',
    650.00, 600.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-24', '星期一', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-03-25', '星期二', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-03-26', '星期三', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-03-27', '星期四', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-03-28', '星期五', 50, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0008', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1762792DB4E9A002', '华东客户定制化项目', 'eastChina', 1.0000, 600.00, 0
);

-- REIM202504050009 status=1 荆州团队建设活动
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504050009', 1,
    '荆州团队建设活动', '参加荆州举办的行业交流活动',
    '16AE93CC7EF92002', '13BFD31C6029A002',
    '13AB498CC6409002', '13AB3A420CC08002',
    260.00, '行程紧凑，备注备查', '{"id": "9", "documentNo": "REIM202504050009", "status": 1, "createdAt": "2025-04-05", "basicInfo": {"title": "荆州团队建设活动", "reason": "参加荆州举办的行业交流活动", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departmentId": "13BFD31C6029A002", "departmentName": "企业消费事业部", "departmentNo": "072002", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "businessTypeId": "13AB3A420CC08002", "businessTypeName": "员工团建", "businessTypeNo": "100100302"}, "travelRecords": [{"id": "travel_0009", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departureCityId": "10119", "departureCityName": "北京", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-04-05", "arrivalDate": "2025-04-06", "description": "北京至荆州，员工团建相关行程"}], "allowances": [{"id": "allowance_0009", "travelRecordId": "travel_0009", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "departureDate": "2025-04-05", "arrivalDate": "2025-04-06", "allowanceDays": 2, "departureCity": "北京", "arrivalCity": "荆州", "calendar": [{"date": "2025-04-05", "weekday": "星期六", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-06", "weekday": "星期日", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 260, "totalAllowanceAmount": 260}], "costAllocations": [{"id": "alloc_0009", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 260}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 260, "totalMealAmount": 100, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-04-05 14:38:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504050009');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0009', '13AB498CC6409002', '郑雨雪', '74008',
    '10119', '北京', '10455', '荆州',
    '2025-04-05', '2025-04-06', '北京至荆州，员工团建相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0009', 'travel_0009',
    '13AB498CC6409002', '郑雨雪', '2025-04-05', '2025-04-06',
    2, '北京', '荆州',
    260.00, 260.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-05', '星期六', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-04-06', '星期日', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0009', '16AE93CC7EF92002', '胜意科技荆州分公司', '0411',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 260.00, 0
);

-- REIM202501290010 status=1 武汉专业技能培训
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501290010', 1,
    '武汉专业技能培训', '参加武汉举办的行业交流活动',
    '16AE93CC7EF92002', '19206611C47A6000',
    '13AB591FE8009002', '13AB3A418F808001',
    320.00, '行程紧凑，备注备查', '{"id": "10", "documentNo": "REIM202501290010", "status": 1, "createdAt": "2025-01-29", "basicInfo": {"title": "武汉专业技能培训", "reason": "参加武汉举办的行业交流活动", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departmentId": "19206611C47A6000", "departmentName": "集采事业部", "departmentNo": "072004", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "businessTypeId": "13AB3A418F808001", "businessTypeName": "个人团队培训", "businessTypeNo": "100100201"}, "travelRecords": [{"id": "travel_0010", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departureCityId": "10119", "departureCityName": "北京", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-01-29", "arrivalDate": "2025-01-31", "description": "北京至武汉，个人团队培训相关行程"}], "allowances": [{"id": "allowance_0010", "travelRecordId": "travel_0010", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "departureDate": "2025-01-29", "arrivalDate": "2025-01-31", "allowanceDays": 3, "departureCity": "北京", "arrivalCity": "武汉", "calendar": [{"date": "2025-01-29", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-30", "weekday": "星期四", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-31", "weekday": "星期五", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 480, "totalAllowanceAmount": 320}], "costAllocations": [{"id": "alloc_0010", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "projectId": "12BC248B25083001", "projectName": "非项目类费用归集", "projectNo": "nonProjectRelated", "ratio": 1.0, "amount": 320}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 320, "totalMealAmount": 80, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-01-29 08:46:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501290010');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0010', '13AB591FE8009002', '王成军', '80681',
    '10119', '北京', '10458', '武汉',
    '2025-01-29', '2025-01-31', '北京至武汉，个人团队培训相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0010', 'travel_0010',
    '13AB591FE8009002', '王成军', '2025-01-29', '2025-01-31',
    3, '北京', '武汉',
    480.00, 320.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-29', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-01-30', '星期四', 80, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-01-31', '星期五', 80, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0010', '16AE93CC7EF92002', '胜意科技荆州分公司', '0411',
    '12BC248B25083001', '非项目类费用归集', 'nonProjectRelated', 1.0000, 320.00, 0
);

-- REIM202505020011 status=0 北京年度健康体检
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202505020011', 0,
    '北京年度健康体检', '应北京分公司邀请，执行员工体检任务',
    '1C61686865DA8000', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A422A808001',
    240.00, '单据已核对无误', '{"id": "11", "documentNo": "REIM202505020011", "status": 0, "createdAt": "2025-05-02", "basicInfo": {"title": "北京年度健康体检", "reason": "应北京分公司邀请，执行员工体检任务", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "13AB3A422A808001", "businessTypeName": "员工体检", "businessTypeNo": "100100303"}, "travelRecords": [{"id": "travel_0011", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-05-02", "arrivalDate": "2025-05-04", "description": "荆州至北京，员工体检相关行程"}], "allowances": [{"id": "allowance_0011", "travelRecordId": "travel_0011", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-05-02", "arrivalDate": "2025-05-04", "allowanceDays": 3, "departureCity": "荆州", "arrivalCity": "北京", "calendar": [{"date": "2025-05-02", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-05-03", "weekday": "星期六", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-05-04", "weekday": "星期日", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 540, "totalAllowanceAmount": 240}], "costAllocations": [{"id": "alloc_0011", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "1C5931735AC4A000", "projectName": "华南客户定制化项目", "projectNo": "southChina", "ratio": 1.0, "amount": 240}], "remark": "单据已核对无误", "totalAllowanceAmount": 240, "totalMealAmount": 0, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-05-02 13:48:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202505020011');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0011', '13AB7925EB808001', '姜林', '10503',
    '10455', '荆州', '10119', '北京',
    '2025-05-02', '2025-05-04', '荆州至北京，员工体检相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0011', 'travel_0011',
    '13AB7925EB808001', '姜林', '2025-05-02', '2025-05-04',
    3, '荆州', '北京',
    540.00, 240.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-05-02', '星期五', 100, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-05-03', '星期六', 100, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-05-04', '星期日', 100, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0011', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '1C5931735AC4A000', '华南客户定制化项目', 'southChina', 1.0000, 240.00, 0
);

-- REIM202501170012 status=1 入职专项体检
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501170012', 1,
    '入职专项体检', '应武汉分公司邀请，执行员工体检任务',
    '16AE93CC7EF92002', '13BFD31C6029A002',
    '13AB498CC6409002', '13AB3A422A808001',
    640.00, '展会期间公司提供用车，已核减交通补助', '{"id": "12", "documentNo": "REIM202501170012", "status": 1, "createdAt": "2025-01-17", "basicInfo": {"title": "入职专项体检", "reason": "应武汉分公司邀请，执行员工体检任务", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departmentId": "13BFD31C6029A002", "departmentName": "企业消费事业部", "departmentNo": "072002", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "businessTypeId": "13AB3A422A808001", "businessTypeName": "员工体检", "businessTypeNo": "100100303"}, "travelRecords": [{"id": "travel_0012", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-01-17", "arrivalDate": "2025-01-20", "description": "荆州至武汉，员工体检相关行程"}], "allowances": [{"id": "allowance_0012", "travelRecordId": "travel_0012", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "departureDate": "2025-01-17", "arrivalDate": "2025-01-20", "allowanceDays": 4, "departureCity": "荆州", "arrivalCity": "武汉", "calendar": [{"date": "2025-01-17", "weekday": "星期五", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-18", "weekday": "星期六", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-19", "weekday": "星期日", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-20", "weekday": "星期一", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 640, "totalAllowanceAmount": 640}], "costAllocations": [{"id": "alloc_0012", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "projectId": "12BC248B25083001", "projectName": "非项目类费用归集", "projectNo": "nonProjectRelated", "ratio": 1.0, "amount": 640}], "remark": "展会期间公司提供用车，已核减交通补助", "totalAllowanceAmount": 640, "totalMealAmount": 320, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-01-17 08:15:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501170012');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0012', '13AB498CC6409002', '郑雨雪', '74008',
    '10455', '荆州', '10458', '武汉',
    '2025-01-17', '2025-01-20', '荆州至武汉，员工体检相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0012', 'travel_0012',
    '13AB498CC6409002', '郑雨雪', '2025-01-17', '2025-01-20',
    4, '荆州', '武汉',
    640.00, 640.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-17', '星期五', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-01-18', '星期六', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-01-19', '星期日', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-01-20', '星期一', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0012', '16AE93CC7EF92002', '胜意科技荆州分公司', '0411',
    '12BC248B25083001', '非项目类费用归集', 'nonProjectRelated', 1.0000, 640.00, 0
);

-- REIM202504090013 status=1 上海行业展会参展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504090013', 1,
    '上海行业展会参展', '配合东北客户定制化项目项目进度，赴上海现场办公',
    '1C54557F1782E000', '19D32F9FE9647000',
    '13AB77281A408001', '1A92E43082EFC000',
    360.00, '单据已核对无误', '{"id": "13", "documentNo": "REIM202504090013", "status": 1, "createdAt": "2025-04-09", "basicInfo": {"title": "上海行业展会参展", "reason": "配合东北客户定制化项目项目进度，赴上海现场办公", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departmentId": "19D32F9FE9647000", "departmentName": "航旅事业部", "departmentNo": "072005", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "1A92E43082EFC000", "businessTypeName": "市场拓展出差", "businessTypeNo": "10010010102"}, "travelRecords": [{"id": "travel_0013", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departureCityId": "10119", "departureCityName": "北京", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-04-09", "arrivalDate": "2025-04-10", "description": "北京至上海，市场拓展出差相关行程"}], "allowances": [{"id": "allowance_0013", "travelRecordId": "travel_0013", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "departureDate": "2025-04-09", "arrivalDate": "2025-04-10", "allowanceDays": 2, "departureCity": "北京", "arrivalCity": "上海", "calendar": [{"date": "2025-04-09", "weekday": "星期三", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-10", "weekday": "星期四", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 360, "totalAllowanceAmount": 360}], "costAllocations": [{"id": "alloc_0013", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "162664B8526BE002", "projectName": "东北客户定制化项目", "projectNo": "northEast", "ratio": 1.0, "amount": 360}], "remark": "单据已核对无误", "totalAllowanceAmount": 360, "totalMealAmount": 200, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-04-09 16:55:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504090013');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0013', '13AB77281A408001', '潘展飞', '89899',
    '10119', '北京', '10621', '上海',
    '2025-04-09', '2025-04-10', '北京至上海，市场拓展出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0013', 'travel_0013',
    '13AB77281A408001', '潘展飞', '2025-04-09', '2025-04-10',
    2, '北京', '上海',
    360.00, 360.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-09', '星期三', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-04-10', '星期四', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0013', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '162664B8526BE002', '东北客户定制化项目', 'northEast', 1.0000, 360.00, 0
);

-- REIM202503120014 status=1 杭州客户售后维护
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503120014', 1,
    '杭州客户售后维护', '应杭州分公司邀请，执行售后维护出差任务',
    '1717271D1DA15000', '19D32F9FE9647000',
    '13AB77281A408001', '13AB3A4154008001',
    400.00, '行程紧凑，备注备查', '{"id": "14", "documentNo": "REIM202503120014", "status": 1, "createdAt": "2025-03-12", "basicInfo": {"title": "杭州客户售后维护", "reason": "应杭州分公司邀请，执行售后维护出差任务", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departmentId": "19D32F9FE9647000", "departmentName": "航旅事业部", "departmentNo": "072005", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A4154008001", "businessTypeName": "售后维护出差", "businessTypeNo": "10010010202"}, "travelRecords": [{"id": "travel_0014", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10216", "arrivalCityName": "杭州", "departureDate": "2025-03-12", "arrivalDate": "2025-03-14", "description": "武汉至杭州，售后维护出差相关行程"}], "allowances": [{"id": "allowance_0014", "travelRecordId": "travel_0014", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "departureDate": "2025-03-12", "arrivalDate": "2025-03-14", "allowanceDays": 3, "departureCity": "武汉", "arrivalCity": "杭州", "calendar": [{"date": "2025-03-12", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-13", "weekday": "星期四", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-14", "weekday": "星期五", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 480, "totalAllowanceAmount": 400}], "costAllocations": [{"id": "alloc_0014", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1771EC45F2443000", "projectName": "华北客户定制化项目", "projectNo": "northChina", "ratio": 1.0, "amount": 400}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 400, "totalMealAmount": 160, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-03-12 11:04:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503120014');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0014', '13AB77281A408001', '潘展飞', '89899',
    '10458', '武汉', '10216', '杭州',
    '2025-03-12', '2025-03-14', '武汉至杭州，售后维护出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0014', 'travel_0014',
    '13AB77281A408001', '潘展飞', '2025-03-12', '2025-03-14',
    3, '武汉', '杭州',
    480.00, 400.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-12', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-03-13', '星期四', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-03-14', '星期五', 80, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0014', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1771EC45F2443000', '华北客户定制化项目', 'northChina', 1.0000, 400.00, 0
);

-- REIM202501240015 status=0 上海年度健康体检
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501240015', 0,
    '上海年度健康体检', '根据业务安排前往上海开展员工体检相关工作',
    '1C54557F1782E000', '14515BB4BFB92003',
    '13AB4A56BB009002', '13AB3A422A808001',
    180.00, '', '{"id": "15", "documentNo": "REIM202501240015", "status": 0, "createdAt": "2025-01-24", "basicInfo": {"title": "上海年度健康体检", "reason": "根据业务安排前往上海开展员工体检相关工作", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "13AB3A422A808001", "businessTypeName": "员工体检", "businessTypeNo": "100100303"}, "travelRecords": [{"id": "travel_0015", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-01-24", "arrivalDate": "2025-01-24", "description": "荆州至上海，员工体检相关行程"}], "allowances": [{"id": "allowance_0015", "travelRecordId": "travel_0015", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-01-24", "arrivalDate": "2025-01-24", "allowanceDays": 1, "departureCity": "荆州", "arrivalCity": "上海", "calendar": [{"date": "2025-01-24", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 180, "totalAllowanceAmount": 180}], "costAllocations": [{"id": "alloc_0015", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "1771EC45F2443000", "projectName": "华北客户定制化项目", "projectNo": "northChina", "ratio": 1.0, "amount": 180}], "remark": "", "totalAllowanceAmount": 180, "totalMealAmount": 100, "totalTransportAmount": 40, "totalCommunicationAmount": 40}', '2025-01-24 08:55:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501240015');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0015', '13AB4A56BB009002', '邹薇', '21552',
    '10455', '荆州', '10621', '上海',
    '2025-01-24', '2025-01-24', '荆州至上海，员工体检相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0015', 'travel_0015',
    '13AB4A56BB009002', '邹薇', '2025-01-24', '2025-01-24',
    1, '荆州', '上海',
    180.00, 180.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-24', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0015', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '1771EC45F2443000', '华北客户定制化项目', 'northChina', 1.0000, 180.00, 0
);

-- REIM202503250016 status=1 入职专项体检
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503250016', 1,
    '入职专项体检', '应杭州分公司邀请，执行员工体检任务',
    '1C54557F1782E000', '14515BB4BFB92003',
    '13AB4A56BB009002', '13AB3A422A808001',
    320.00, '单据已核对无误', '{"id": "16", "documentNo": "REIM202503250016", "status": 1, "createdAt": "2025-03-25", "basicInfo": {"title": "入职专项体检", "reason": "应杭州分公司邀请，执行员工体检任务", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "13AB3A422A808001", "businessTypeName": "员工体检", "businessTypeNo": "100100303"}, "travelRecords": [{"id": "travel_0016", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10216", "arrivalCityName": "杭州", "departureDate": "2025-03-25", "arrivalDate": "2025-03-26", "description": "武汉至杭州，员工体检相关行程"}], "allowances": [{"id": "allowance_0016", "travelRecordId": "travel_0016", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-03-25", "arrivalDate": "2025-03-26", "allowanceDays": 2, "departureCity": "武汉", "arrivalCity": "杭州", "calendar": [{"date": "2025-03-25", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-26", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 320, "totalAllowanceAmount": 320}], "costAllocations": [{"id": "alloc_0016", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "1771EC45F2443000", "projectName": "华北客户定制化项目", "projectNo": "northChina", "ratio": 1.0, "amount": 320}], "remark": "单据已核对无误", "totalAllowanceAmount": 320, "totalMealAmount": 160, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-03-25 15:51:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503250016');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0016', '13AB4A56BB009002', '邹薇', '21552',
    '10458', '武汉', '10216', '杭州',
    '2025-03-25', '2025-03-26', '武汉至杭州，员工体检相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0016', 'travel_0016',
    '13AB4A56BB009002', '邹薇', '2025-03-25', '2025-03-26',
    2, '武汉', '杭州',
    320.00, 320.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-25', '星期二', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-03-26', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0016', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '1771EC45F2443000', '华北客户定制化项目', 'northChina', 1.0000, 320.00, 0
);

-- REIM202503080017 status=1 武汉渠道合作洽谈
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503080017', 1,
    '武汉渠道合作洽谈', '根据业务安排前往武汉开展市场拓展出差相关工作',
    '19218A262C976000', '19206611C47A6000',
    '13AB591FE8009002', '1A92E43082EFC000',
    560.00, '', '{"id": "17", "documentNo": "REIM202503080017", "status": 1, "createdAt": "2025-03-08", "basicInfo": {"title": "武汉渠道合作洽谈", "reason": "根据业务安排前往武汉开展市场拓展出差相关工作", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departmentId": "19206611C47A6000", "departmentName": "集采事业部", "departmentNo": "072004", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "1A92E43082EFC000", "businessTypeName": "市场拓展出差", "businessTypeNo": "10010010102"}, "travelRecords": [{"id": "travel_0017", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departureCityId": "10216", "departureCityName": "杭州", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-03-08", "arrivalDate": "2025-03-11", "description": "杭州至武汉，市场拓展出差相关行程"}], "allowances": [{"id": "allowance_0017", "travelRecordId": "travel_0017", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "departureDate": "2025-03-08", "arrivalDate": "2025-03-11", "allowanceDays": 4, "departureCity": "杭州", "arrivalCity": "武汉", "calendar": [{"date": "2025-03-08", "weekday": "星期六", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-09", "weekday": "星期日", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-10", "weekday": "星期一", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-11", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 640, "totalAllowanceAmount": 560}], "costAllocations": [{"id": "alloc_0017", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 560}], "remark": "", "totalAllowanceAmount": 560, "totalMealAmount": 240, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-03-08 08:25:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503080017');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0017', '13AB591FE8009002', '王成军', '80681',
    '10216', '杭州', '10458', '武汉',
    '2025-03-08', '2025-03-11', '杭州至武汉，市场拓展出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0017', 'travel_0017',
    '13AB591FE8009002', '王成军', '2025-03-08', '2025-03-11',
    4, '杭州', '武汉',
    640.00, 560.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-08', '星期六', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-03-09', '星期日', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-03-10', '星期一', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-03-11', '星期二', 80, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0017', '19218A262C976000', '胜意科技上海分公司', '0408',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 560.00, 0
);

-- REIM202503130018 status=1 荆州行业展会参展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503130018', 1,
    '荆州行业展会参展', '配合华北客户定制化项目项目进度，赴荆州现场办公',
    '1C61686865DA8000', '13C7E2BAE0393001',
    '13AB7925EB808001', '1A92E43082EFC000',
    600.00, '行程紧凑，备注备查', '{"id": "18", "documentNo": "REIM202503130018", "status": 1, "createdAt": "2025-03-13", "basicInfo": {"title": "荆州行业展会参展", "reason": "配合华北客户定制化项目项目进度，赴荆州现场办公", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "1A92E43082EFC000", "businessTypeName": "市场拓展出差", "businessTypeNo": "10010010102"}, "travelRecords": [{"id": "travel_0018", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-03-13", "arrivalDate": "2025-03-17", "description": "上海至荆州，市场拓展出差相关行程"}], "allowances": [{"id": "allowance_0018", "travelRecordId": "travel_0018", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-03-13", "arrivalDate": "2025-03-17", "allowanceDays": 5, "departureCity": "上海", "arrivalCity": "荆州", "calendar": [{"date": "2025-03-13", "weekday": "星期四", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-14", "weekday": "星期五", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-15", "weekday": "星期六", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-16", "weekday": "星期日", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-17", "weekday": "星期一", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 650, "totalAllowanceAmount": 600}], "costAllocations": [{"id": "alloc_0018", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "1771EC45F2443000", "projectName": "华北客户定制化项目", "projectNo": "northChina", "ratio": 1.0, "amount": 600}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 600, "totalMealAmount": 200, "totalTransportAmount": 200, "totalCommunicationAmount": 200}', '2025-03-13 15:15:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503130018');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0018', '13AB7925EB808001', '姜林', '10503',
    '10621', '上海', '10455', '荆州',
    '2025-03-13', '2025-03-17', '上海至荆州，市场拓展出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0018', 'travel_0018',
    '13AB7925EB808001', '姜林', '2025-03-13', '2025-03-17',
    5, '上海', '荆州',
    650.00, 600.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-13', '星期四', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-03-14', '星期五', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-03-15', '星期六', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-03-16', '星期日', 50, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-03-17', '星期一', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0018', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '1771EC45F2443000', '华北客户定制化项目', 'northChina', 1.0000, 600.00, 0
);

-- REIM202505130019 status=0 荆州年度健康体检
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202505130019', 0,
    '荆州年度健康体检', '参加荆州举办的行业交流活动',
    '1717271D1DA15000', '13AB8D7B52A9B002',
    '13AB3A3F72409002', '13AB3A422A808001',
    130.00, '出差期间部分餐费由客户承担，已核减', '{"id": "19", "documentNo": "REIM202505130019", "status": 0, "createdAt": "2025-05-13", "basicInfo": {"title": "荆州年度健康体检", "reason": "参加荆州举办的行业交流活动", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departmentId": "13AB8D7B52A9B002", "departmentName": "客户成功事业部", "departmentNo": "072001", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A422A808001", "businessTypeName": "员工体检", "businessTypeNo": "100100303"}, "travelRecords": [{"id": "travel_0019", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departureCityId": "10119", "departureCityName": "北京", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-05-13", "arrivalDate": "2025-05-13", "description": "北京至荆州，员工体检相关行程"}], "allowances": [{"id": "allowance_0019", "travelRecordId": "travel_0019", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "departureDate": "2025-05-13", "arrivalDate": "2025-05-13", "allowanceDays": 1, "departureCity": "北京", "arrivalCity": "荆州", "calendar": [{"date": "2025-05-13", "weekday": "星期二", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 130, "totalAllowanceAmount": 130}], "costAllocations": [{"id": "alloc_0019", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 130}], "remark": "出差期间部分餐费由客户承担，已核减", "totalAllowanceAmount": 130, "totalMealAmount": 50, "totalTransportAmount": 40, "totalCommunicationAmount": 40}', '2025-05-13 15:30:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202505130019');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0019', '13AB3A3F72409002', '徐年年', '74541',
    '10119', '北京', '10455', '荆州',
    '2025-05-13', '2025-05-13', '北京至荆州，员工体检相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0019', 'travel_0019',
    '13AB3A3F72409002', '徐年年', '2025-05-13', '2025-05-13',
    1, '北京', '荆州',
    130.00, 130.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-05-13', '星期二', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0019', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 130.00, 0
);

-- REIM202502170020 status=2 北京定制化项目实施
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502170020', 2,
    '北京定制化项目实施', '配合华南客户定制化项目项目进度，赴北京现场办公',
    '1717271D1DA15000', '13BFD31C6029A002',
    '13AB498CC6409002', '1B5FEB7DD4396000',
    720.00, '行程取消，单据作废', '{"id": "20", "documentNo": "REIM202502170020", "status": 2, "createdAt": "2025-02-17", "basicInfo": {"title": "北京定制化项目实施", "reason": "配合华南客户定制化项目项目进度，赴北京现场办公", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departmentId": "13BFD31C6029A002", "departmentName": "企业消费事业部", "departmentNo": "072002", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "1B5FEB7DD4396000", "businessTypeName": "项目出差", "businessTypeNo": "10010010101"}, "travelRecords": [{"id": "travel_0020", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departureCityId": "10216", "departureCityName": "杭州", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-02-17", "arrivalDate": "2025-02-20", "description": "杭州至北京，项目出差相关行程"}], "allowances": [{"id": "allowance_0020", "travelRecordId": "travel_0020", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "departureDate": "2025-02-17", "arrivalDate": "2025-02-20", "allowanceDays": 4, "departureCity": "杭州", "arrivalCity": "北京", "calendar": [{"date": "2025-02-17", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-18", "weekday": "星期二", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-19", "weekday": "星期三", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-20", "weekday": "星期四", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 720, "totalAllowanceAmount": 720}], "costAllocations": [{"id": "alloc_0020", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1C5931735AC4A000", "projectName": "华南客户定制化项目", "projectNo": "southChina", "ratio": 1.0, "amount": 720}], "remark": "行程取消，单据作废", "totalAllowanceAmount": 720, "totalMealAmount": 400, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-02-17 14:44:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502170020');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0020', '13AB498CC6409002', '郑雨雪', '74008',
    '10216', '杭州', '10119', '北京',
    '2025-02-17', '2025-02-20', '杭州至北京，项目出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0020', 'travel_0020',
    '13AB498CC6409002', '郑雨雪', '2025-02-17', '2025-02-20',
    4, '杭州', '北京',
    720.00, 720.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-17', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-18', '星期二', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-19', '星期三', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-20', '星期四', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0020', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1C5931735AC4A000', '华南客户定制化项目', 'southChina', 1.0000, 720.00, 0
);

-- REIM202501220021 status=0 武汉团队建设活动
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501220021', 0,
    '武汉团队建设活动', '配合华南客户定制化项目项目进度，赴武汉现场办公',
    '16AE93CC7EF92002', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A420CC08002',
    320.00, '单据已核对无误', '{"id": "21", "documentNo": "REIM202501220021", "status": 0, "createdAt": "2025-01-22", "basicInfo": {"title": "武汉团队建设活动", "reason": "配合华南客户定制化项目项目进度，赴武汉现场办公", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "businessTypeId": "13AB3A420CC08002", "businessTypeName": "员工团建", "businessTypeNo": "100100302"}, "travelRecords": [{"id": "travel_0021", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-01-22", "arrivalDate": "2025-01-23", "description": "上海至武汉，员工团建相关行程"}], "allowances": [{"id": "allowance_0021", "travelRecordId": "travel_0021", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-01-22", "arrivalDate": "2025-01-23", "allowanceDays": 2, "departureCity": "上海", "arrivalCity": "武汉", "calendar": [{"date": "2025-01-22", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-23", "weekday": "星期四", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 320, "totalAllowanceAmount": 320}], "costAllocations": [{"id": "alloc_0021", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "projectId": "1C5931735AC4A000", "projectName": "华南客户定制化项目", "projectNo": "southChina", "ratio": 1.0, "amount": 320}], "remark": "单据已核对无误", "totalAllowanceAmount": 320, "totalMealAmount": 160, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-01-22 08:03:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501220021');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0021', '13AB7925EB808001', '姜林', '10503',
    '10621', '上海', '10458', '武汉',
    '2025-01-22', '2025-01-23', '上海至武汉，员工团建相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0021', 'travel_0021',
    '13AB7925EB808001', '姜林', '2025-01-22', '2025-01-23',
    2, '上海', '武汉',
    320.00, 320.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-22', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-01-23', '星期四', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0021', '16AE93CC7EF92002', '胜意科技荆州分公司', '0411',
    '1C5931735AC4A000', '华南客户定制化项目', 'southChina', 1.0000, 320.00, 0
);

-- REIM202501230022 status=0 荆州年度健康体检
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501230022', 0,
    '荆州年度健康体检', '参加荆州举办的行业交流活动',
    '1717271D1DA15000', '19D32F9FE9647000',
    '13AB77281A408001', '13AB3A422A808001',
    210.00, '', '{"id": "22", "documentNo": "REIM202501230022", "status": 0, "createdAt": "2025-01-23", "basicInfo": {"title": "荆州年度健康体检", "reason": "参加荆州举办的行业交流活动", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departmentId": "19D32F9FE9647000", "departmentName": "航旅事业部", "departmentNo": "072005", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A422A808001", "businessTypeName": "员工体检", "businessTypeNo": "100100303"}, "travelRecords": [{"id": "travel_0022", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departureCityId": "10119", "departureCityName": "北京", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-01-23", "arrivalDate": "2025-01-24", "description": "北京至荆州，员工体检相关行程"}], "allowances": [{"id": "allowance_0022", "travelRecordId": "travel_0022", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "departureDate": "2025-01-23", "arrivalDate": "2025-01-24", "allowanceDays": 2, "departureCity": "北京", "arrivalCity": "荆州", "calendar": [{"date": "2025-01-23", "weekday": "星期四", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-24", "weekday": "星期五", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 260, "totalAllowanceAmount": 210}], "costAllocations": [{"id": "alloc_0022", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1C5931735AC4A000", "projectName": "华南客户定制化项目", "projectNo": "southChina", "ratio": 1.0, "amount": 210}], "remark": "", "totalAllowanceAmount": 210, "totalMealAmount": 50, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-01-23 09:56:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501230022');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0022', '13AB77281A408001', '潘展飞', '89899',
    '10119', '北京', '10455', '荆州',
    '2025-01-23', '2025-01-24', '北京至荆州，员工体检相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0022', 'travel_0022',
    '13AB77281A408001', '潘展飞', '2025-01-23', '2025-01-24',
    2, '北京', '荆州',
    260.00, 210.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-23', '星期四', 50, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-01-24', '星期五', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0022', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1C5931735AC4A000', '华南客户定制化项目', 'southChina', 1.0000, 210.00, 0
);

-- REIM202502100023 status=0 武汉客户项目现场支持
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502100023', 0,
    '武汉客户项目现场支持', '配合华中客户定制化项目项目进度，赴武汉现场办公',
    '19218A262C976000', '19D32F9FE9647000',
    '13AB77281A408001', '1B5FEB7DD4396000',
    480.00, '展会期间公司提供用车，已核减交通补助', '{"id": "23", "documentNo": "REIM202502100023", "status": 0, "createdAt": "2025-02-10", "basicInfo": {"title": "武汉客户项目现场支持", "reason": "配合华中客户定制化项目项目进度，赴武汉现场办公", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departmentId": "19D32F9FE9647000", "departmentName": "航旅事业部", "departmentNo": "072005", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "1B5FEB7DD4396000", "businessTypeName": "项目出差", "businessTypeNo": "10010010101"}, "travelRecords": [{"id": "travel_0023", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departureCityId": "10216", "departureCityName": "杭州", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-02-10", "arrivalDate": "2025-02-12", "description": "杭州至武汉，项目出差相关行程"}], "allowances": [{"id": "allowance_0023", "travelRecordId": "travel_0023", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "departureDate": "2025-02-10", "arrivalDate": "2025-02-12", "allowanceDays": 3, "departureCity": "杭州", "arrivalCity": "武汉", "calendar": [{"date": "2025-02-10", "weekday": "星期一", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-11", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-12", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 480, "totalAllowanceAmount": 480}], "costAllocations": [{"id": "alloc_0023", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 480}], "remark": "展会期间公司提供用车，已核减交通补助", "totalAllowanceAmount": 480, "totalMealAmount": 240, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-02-10 14:08:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502100023');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0023', '13AB77281A408001', '潘展飞', '89899',
    '10216', '杭州', '10458', '武汉',
    '2025-02-10', '2025-02-12', '杭州至武汉，项目出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0023', 'travel_0023',
    '13AB77281A408001', '潘展飞', '2025-02-10', '2025-02-12',
    3, '杭州', '武汉',
    480.00, 480.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-10', '星期一', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-02-11', '星期二', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-02-12', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0023', '19218A262C976000', '胜意科技上海分公司', '0408',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 480.00, 0
);

-- REIM202504040024 status=0 荆州团队建设活动
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504040024', 0,
    '荆州团队建设活动', '应荆州分公司邀请，执行员工团建任务',
    '1C61686865DA8000', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A420CC08002',
    420.00, '', '{"id": "24", "documentNo": "REIM202504040024", "status": 0, "createdAt": "2025-04-04", "basicInfo": {"title": "荆州团队建设活动", "reason": "应荆州分公司邀请，执行员工团建任务", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "13AB3A420CC08002", "businessTypeName": "员工团建", "businessTypeNo": "100100302"}, "travelRecords": [{"id": "travel_0024", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10119", "departureCityName": "北京", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-04-04", "arrivalDate": "2025-04-07", "description": "北京至荆州，员工团建相关行程"}], "allowances": [{"id": "allowance_0024", "travelRecordId": "travel_0024", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-04-04", "arrivalDate": "2025-04-07", "allowanceDays": 4, "departureCity": "北京", "arrivalCity": "荆州", "calendar": [{"date": "2025-04-04", "weekday": "星期五", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-05", "weekday": "星期六", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-06", "weekday": "星期日", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-07", "weekday": "星期一", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 520, "totalAllowanceAmount": 420}], "costAllocations": [{"id": "alloc_0024", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "17071065FC29A002", "projectName": "西南客户定制化项目", "projectNo": "southWest", "ratio": 1.0, "amount": 420}], "remark": "", "totalAllowanceAmount": 420, "totalMealAmount": 100, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-04-04 16:16:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504040024');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0024', '13AB7925EB808001', '姜林', '10503',
    '10119', '北京', '10455', '荆州',
    '2025-04-04', '2025-04-07', '北京至荆州，员工团建相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0024', 'travel_0024',
    '13AB7925EB808001', '姜林', '2025-04-04', '2025-04-07',
    4, '北京', '荆州',
    520.00, 420.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-04', '星期五', 50, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-04-05', '星期六', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-04-06', '星期日', 50, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-04-07', '星期一', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0024', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '17071065FC29A002', '西南客户定制化项目', 'southWest', 1.0000, 420.00, 0
);

-- REIM202503120025 status=2 荆州渠道合作洽谈
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503120025', 2,
    '荆州渠道合作洽谈', '配合华北客户定制化项目项目进度，赴荆州现场办公',
    '1C61686865DA8000', '13BFD31C6029A002',
    '13AB498CC6409002', '1A92E43082EFC000',
    210.00, '行程取消，单据作废', '{"id": "25", "documentNo": "REIM202503120025", "status": 2, "createdAt": "2025-03-12", "basicInfo": {"title": "荆州渠道合作洽谈", "reason": "配合华北客户定制化项目项目进度，赴荆州现场办公", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departmentId": "13BFD31C6029A002", "departmentName": "企业消费事业部", "departmentNo": "072002", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "1A92E43082EFC000", "businessTypeName": "市场拓展出差", "businessTypeNo": "10010010102"}, "travelRecords": [{"id": "travel_0025", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-03-12", "arrivalDate": "2025-03-13", "description": "武汉至荆州，市场拓展出差相关行程"}], "allowances": [{"id": "allowance_0025", "travelRecordId": "travel_0025", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "departureDate": "2025-03-12", "arrivalDate": "2025-03-13", "allowanceDays": 2, "departureCity": "武汉", "arrivalCity": "荆州", "calendar": [{"date": "2025-03-12", "weekday": "星期三", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-13", "weekday": "星期四", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 260, "totalAllowanceAmount": 210}], "costAllocations": [{"id": "alloc_0025", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "1771EC45F2443000", "projectName": "华北客户定制化项目", "projectNo": "northChina", "ratio": 1.0, "amount": 210}], "remark": "行程取消，单据作废", "totalAllowanceAmount": 210, "totalMealAmount": 50, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-03-12 17:51:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503120025');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0025', '13AB498CC6409002', '郑雨雪', '74008',
    '10458', '武汉', '10455', '荆州',
    '2025-03-12', '2025-03-13', '武汉至荆州，市场拓展出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0025', 'travel_0025',
    '13AB498CC6409002', '郑雨雪', '2025-03-12', '2025-03-13',
    2, '武汉', '荆州',
    260.00, 210.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-12', '星期三', 50, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-03-13', '星期四', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0025', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '1771EC45F2443000', '华北客户定制化项目', 'northChina', 1.0000, 210.00, 0
);

-- REIM202501290026 status=1 上海客户项目现场支持
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501290026', 1,
    '上海客户项目现场支持', '配合华东客户定制化项目项目进度，赴上海现场办公',
    '16AE93CC7EF92002', '13C7E2BAE0393001',
    '13AB7925EB808001', '1B5FEB7DD4396000',
    440.00, '单据已核对无误', '{"id": "26", "documentNo": "REIM202501290026", "status": 1, "createdAt": "2025-01-29", "basicInfo": {"title": "上海客户项目现场支持", "reason": "配合华东客户定制化项目项目进度，赴上海现场办公", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "businessTypeId": "1B5FEB7DD4396000", "businessTypeName": "项目出差", "businessTypeNo": "10010010101"}, "travelRecords": [{"id": "travel_0026", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10119", "departureCityName": "北京", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-01-29", "arrivalDate": "2025-01-31", "description": "北京至上海，项目出差相关行程"}], "allowances": [{"id": "allowance_0026", "travelRecordId": "travel_0026", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-01-29", "arrivalDate": "2025-01-31", "allowanceDays": 3, "departureCity": "北京", "arrivalCity": "上海", "calendar": [{"date": "2025-01-29", "weekday": "星期三", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-30", "weekday": "星期四", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-31", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 540, "totalAllowanceAmount": 440}], "costAllocations": [{"id": "alloc_0026", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "projectId": "1762792DB4E9A002", "projectName": "华东客户定制化项目", "projectNo": "eastChina", "ratio": 1.0, "amount": 440}], "remark": "单据已核对无误", "totalAllowanceAmount": 440, "totalMealAmount": 200, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-01-29 12:38:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501290026');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0026', '13AB7925EB808001', '姜林', '10503',
    '10119', '北京', '10621', '上海',
    '2025-01-29', '2025-01-31', '北京至上海，项目出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0026', 'travel_0026',
    '13AB7925EB808001', '姜林', '2025-01-29', '2025-01-31',
    3, '北京', '上海',
    540.00, 440.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-29', '星期三', 100, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-01-30', '星期四', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-01-31', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0026', '16AE93CC7EF92002', '胜意科技荆州分公司', '0411',
    '1762792DB4E9A002', '华东客户定制化项目', 'eastChina', 1.0000, 440.00, 0
);

-- REIM202505100027 status=2 杭州客户售后维护
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202505100027', 2,
    '杭州客户售后维护', '根据业务安排前往杭州开展售后维护出差相关工作',
    '1C61686865DA8000', '13BFD31C6029A002',
    '13AB498CC6409002', '13AB3A4154008001',
    480.00, '行程取消，单据作废', '{"id": "27", "documentNo": "REIM202505100027", "status": 2, "createdAt": "2025-05-10", "basicInfo": {"title": "杭州客户售后维护", "reason": "根据业务安排前往杭州开展售后维护出差相关工作", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departmentId": "13BFD31C6029A002", "departmentName": "企业消费事业部", "departmentNo": "072002", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "13AB3A4154008001", "businessTypeName": "售后维护出差", "businessTypeNo": "10010010202"}, "travelRecords": [{"id": "travel_0027", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10216", "arrivalCityName": "杭州", "departureDate": "2025-05-10", "arrivalDate": "2025-05-12", "description": "荆州至杭州，售后维护出差相关行程"}], "allowances": [{"id": "allowance_0027", "travelRecordId": "travel_0027", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "departureDate": "2025-05-10", "arrivalDate": "2025-05-12", "allowanceDays": 3, "departureCity": "荆州", "arrivalCity": "杭州", "calendar": [{"date": "2025-05-10", "weekday": "星期六", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-05-11", "weekday": "星期日", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-05-12", "weekday": "星期一", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 480, "totalAllowanceAmount": 480}], "costAllocations": [{"id": "alloc_0027", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "1762792DB4E9A002", "projectName": "华东客户定制化项目", "projectNo": "eastChina", "ratio": 1.0, "amount": 480}], "remark": "行程取消，单据作废", "totalAllowanceAmount": 480, "totalMealAmount": 240, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-05-10 18:27:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202505100027');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0027', '13AB498CC6409002', '郑雨雪', '74008',
    '10455', '荆州', '10216', '杭州',
    '2025-05-10', '2025-05-12', '荆州至杭州，售后维护出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0027', 'travel_0027',
    '13AB498CC6409002', '郑雨雪', '2025-05-10', '2025-05-12',
    3, '荆州', '杭州',
    480.00, 480.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-05-10', '星期六', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-05-11', '星期日', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-05-12', '星期一', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0027', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '1762792DB4E9A002', '华东客户定制化项目', 'eastChina', 1.0000, 480.00, 0
);

-- REIM202504190028 status=1 武汉客户需求调研
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504190028', 1,
    '武汉客户需求调研', '参加武汉举办的行业交流活动',
    '1C54557F1782E000', '14515BB4BFB92003',
    '13AB4A56BB009002', '1B5FEB7DD4396000',
    320.00, '单据已核对无误', '{"id": "28", "documentNo": "REIM202504190028", "status": 1, "createdAt": "2025-04-19", "basicInfo": {"title": "武汉客户需求调研", "reason": "参加武汉举办的行业交流活动", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "1B5FEB7DD4396000", "businessTypeName": "项目出差", "businessTypeNo": "10010010101"}, "travelRecords": [{"id": "travel_0028", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-04-19", "arrivalDate": "2025-04-20", "description": "上海至武汉，项目出差相关行程"}], "allowances": [{"id": "allowance_0028", "travelRecordId": "travel_0028", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-04-19", "arrivalDate": "2025-04-20", "allowanceDays": 2, "departureCity": "上海", "arrivalCity": "武汉", "calendar": [{"date": "2025-04-19", "weekday": "星期六", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-20", "weekday": "星期日", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 320, "totalAllowanceAmount": 320}], "costAllocations": [{"id": "alloc_0028", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "17071065FC29A002", "projectName": "西南客户定制化项目", "projectNo": "southWest", "ratio": 1.0, "amount": 320}], "remark": "单据已核对无误", "totalAllowanceAmount": 320, "totalMealAmount": 160, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-04-19 16:00:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504190028');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0028', '13AB4A56BB009002', '邹薇', '21552',
    '10621', '上海', '10458', '武汉',
    '2025-04-19', '2025-04-20', '上海至武汉，项目出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0028', 'travel_0028',
    '13AB4A56BB009002', '邹薇', '2025-04-19', '2025-04-20',
    2, '上海', '武汉',
    320.00, 320.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-19', '星期六', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-04-20', '星期日', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0028', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '17071065FC29A002', '西南客户定制化项目', 'southWest', 1.0000, 320.00, 0
);

-- REIM202501310029 status=1 国际合作伙伴拜访
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501310029', 1,
    '国际合作伙伴拜访', '根据业务安排前往上海开展国外考察相关工作',
    '1C54557F1782E000', '13AB8D7B52A9B002',
    '13AB3A3F72409002', '13AB3A4248008002',
    720.00, '展会期间公司提供用车，已核减交通补助', '{"id": "29", "documentNo": "REIM202501310029", "status": 1, "createdAt": "2025-01-31", "basicInfo": {"title": "国际合作伙伴拜访", "reason": "根据业务安排前往上海开展国外考察相关工作", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departmentId": "13AB8D7B52A9B002", "departmentName": "客户成功事业部", "departmentNo": "072001", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "13AB3A4248008002", "businessTypeName": "国外考察", "businessTypeNo": "10010010201"}, "travelRecords": [{"id": "travel_0029", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-01-31", "arrivalDate": "2025-02-03", "description": "武汉至上海，国外考察相关行程"}], "allowances": [{"id": "allowance_0029", "travelRecordId": "travel_0029", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "departureDate": "2025-01-31", "arrivalDate": "2025-02-03", "allowanceDays": 4, "departureCity": "武汉", "arrivalCity": "上海", "calendar": [{"date": "2025-01-31", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-01", "weekday": "星期六", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-02", "weekday": "星期日", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-03", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 720, "totalAllowanceAmount": 720}], "costAllocations": [{"id": "alloc_0029", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "12BC248B25083001", "projectName": "非项目类费用归集", "projectNo": "nonProjectRelated", "ratio": 1.0, "amount": 720}], "remark": "展会期间公司提供用车，已核减交通补助", "totalAllowanceAmount": 720, "totalMealAmount": 400, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-01-31 13:13:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501310029');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0029', '13AB3A3F72409002', '徐年年', '74541',
    '10458', '武汉', '10621', '上海',
    '2025-01-31', '2025-02-03', '武汉至上海，国外考察相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0029', 'travel_0029',
    '13AB3A3F72409002', '徐年年', '2025-01-31', '2025-02-03',
    4, '武汉', '上海',
    720.00, 720.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-31', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-01', '星期六', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-02', '星期日', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-03', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0029', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '12BC248B25083001', '非项目类费用归集', 'nonProjectRelated', 1.0000, 720.00, 0
);

-- REIM202504200030 status=1 杭州行业展会参展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504200030', 1,
    '杭州行业展会参展', '应杭州分公司邀请，执行市场拓展出差任务',
    '19218A262C976000', '13C7E2BAE0393001',
    '13AB7925EB808001', '1A92E43082EFC000',
    480.00, '出差期间部分餐费由客户承担，已核减', '{"id": "30", "documentNo": "REIM202504200030", "status": 1, "createdAt": "2025-04-20", "basicInfo": {"title": "杭州行业展会参展", "reason": "应杭州分公司邀请，执行市场拓展出差任务", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "1A92E43082EFC000", "businessTypeName": "市场拓展出差", "businessTypeNo": "10010010102"}, "travelRecords": [{"id": "travel_0030", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10216", "arrivalCityName": "杭州", "departureDate": "2025-04-20", "arrivalDate": "2025-04-24", "description": "荆州至杭州，市场拓展出差相关行程"}], "allowances": [{"id": "allowance_0030", "travelRecordId": "travel_0030", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-04-20", "arrivalDate": "2025-04-24", "allowanceDays": 5, "departureCity": "荆州", "arrivalCity": "杭州", "calendar": [{"date": "2025-04-20", "weekday": "星期日", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-21", "weekday": "星期一", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-22", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-23", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-24", "weekday": "星期四", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 800, "totalAllowanceAmount": 480}], "costAllocations": [{"id": "alloc_0030", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "17071065FC29A002", "projectName": "西南客户定制化项目", "projectNo": "southWest", "ratio": 1.0, "amount": 480}], "remark": "出差期间部分餐费由客户承担，已核减", "totalAllowanceAmount": 480, "totalMealAmount": 80, "totalTransportAmount": 200, "totalCommunicationAmount": 200}', '2025-04-20 14:01:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504200030');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0030', '13AB7925EB808001', '姜林', '10503',
    '10455', '荆州', '10216', '杭州',
    '2025-04-20', '2025-04-24', '荆州至杭州，市场拓展出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0030', 'travel_0030',
    '13AB7925EB808001', '姜林', '2025-04-20', '2025-04-24',
    5, '荆州', '杭州',
    800.00, 480.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-20', '星期日', 80, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-04-21', '星期一', 80, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-04-22', '星期二', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-04-23', '星期三', 80, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-04-24', '星期四', 80, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0030', '19218A262C976000', '胜意科技上海分公司', '0408',
    '17071065FC29A002', '西南客户定制化项目', 'southWest', 1.0000, 480.00, 0
);

-- REIM202503040031 status=1 上海年度员工旅游
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503040031', 1,
    '上海年度员工旅游', '应上海分公司邀请，执行员工旅游任务',
    '1C61686865DA8000', '13BFD31C6029A002',
    '13AB498CC6409002', '13AB3A41ED408002',
    180.00, '行程紧凑，备注备查', '{"id": "31", "documentNo": "REIM202503040031", "status": 1, "createdAt": "2025-03-04", "basicInfo": {"title": "上海年度员工旅游", "reason": "应上海分公司邀请，执行员工旅游任务", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departmentId": "13BFD31C6029A002", "departmentName": "企业消费事业部", "departmentNo": "072002", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "13AB3A41ED408002", "businessTypeName": "员工旅游", "businessTypeNo": "100100301"}, "travelRecords": [{"id": "travel_0031", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-03-04", "arrivalDate": "2025-03-04", "description": "武汉至上海，员工旅游相关行程"}], "allowances": [{"id": "allowance_0031", "travelRecordId": "travel_0031", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "departureDate": "2025-03-04", "arrivalDate": "2025-03-04", "allowanceDays": 1, "departureCity": "武汉", "arrivalCity": "上海", "calendar": [{"date": "2025-03-04", "weekday": "星期二", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 180, "totalAllowanceAmount": 180}], "costAllocations": [{"id": "alloc_0031", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "1771EC45F2443000", "projectName": "华北客户定制化项目", "projectNo": "northChina", "ratio": 1.0, "amount": 180}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 180, "totalMealAmount": 100, "totalTransportAmount": 40, "totalCommunicationAmount": 40}', '2025-03-04 15:22:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503040031');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0031', '13AB498CC6409002', '郑雨雪', '74008',
    '10458', '武汉', '10621', '上海',
    '2025-03-04', '2025-03-04', '武汉至上海，员工旅游相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0031', 'travel_0031',
    '13AB498CC6409002', '郑雨雪', '2025-03-04', '2025-03-04',
    1, '武汉', '上海',
    180.00, 180.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-04', '星期二', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0031', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '1771EC45F2443000', '华北客户定制化项目', 'northChina', 1.0000, 180.00, 0
);

-- REIM202502190032 status=1 杭州系统故障排查
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502190032', 1,
    '杭州系统故障排查', '参加杭州举办的行业交流活动',
    '19218A262C976000', '14515BB4BFB92003',
    '13AB4A56BB009002', '13AB3A4154008001',
    400.00, '展会期间公司提供用车，已核减交通补助', '{"id": "32", "documentNo": "REIM202502190032", "status": 1, "createdAt": "2025-02-19", "basicInfo": {"title": "杭州系统故障排查", "reason": "参加杭州举办的行业交流活动", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "13AB3A4154008001", "businessTypeName": "售后维护出差", "businessTypeNo": "10010010202"}, "travelRecords": [{"id": "travel_0032", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10216", "arrivalCityName": "杭州", "departureDate": "2025-02-19", "arrivalDate": "2025-02-21", "description": "上海至杭州，售后维护出差相关行程"}], "allowances": [{"id": "allowance_0032", "travelRecordId": "travel_0032", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-02-19", "arrivalDate": "2025-02-21", "allowanceDays": 3, "departureCity": "上海", "arrivalCity": "杭州", "calendar": [{"date": "2025-02-19", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-20", "weekday": "星期四", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-21", "weekday": "星期五", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 480, "totalAllowanceAmount": 400}], "costAllocations": [{"id": "alloc_0032", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "12BC248B25083001", "projectName": "非项目类费用归集", "projectNo": "nonProjectRelated", "ratio": 1.0, "amount": 400}], "remark": "展会期间公司提供用车，已核减交通补助", "totalAllowanceAmount": 400, "totalMealAmount": 160, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-02-19 18:53:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502190032');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0032', '13AB4A56BB009002', '邹薇', '21552',
    '10621', '上海', '10216', '杭州',
    '2025-02-19', '2025-02-21', '上海至杭州，售后维护出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0032', 'travel_0032',
    '13AB4A56BB009002', '邹薇', '2025-02-19', '2025-02-21',
    3, '上海', '杭州',
    480.00, 400.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-19', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-02-20', '星期四', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-02-21', '星期五', 80, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0032', '19218A262C976000', '胜意科技上海分公司', '0408',
    '12BC248B25083001', '非项目类费用归集', 'nonProjectRelated', 1.0000, 400.00, 0
);

-- REIM202502170033 status=1 上海客户需求调研
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502170033', 1,
    '上海客户需求调研', '参加上海举办的行业交流活动',
    '1C61686865DA8000', '19D32F9FE9647000',
    '13AB77281A408001', '1B5FEB7DD4396000',
    600.00, '', '{"id": "33", "documentNo": "REIM202502170033", "status": 1, "createdAt": "2025-02-17", "basicInfo": {"title": "上海客户需求调研", "reason": "参加上海举办的行业交流活动", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departmentId": "19D32F9FE9647000", "departmentName": "航旅事业部", "departmentNo": "072005", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "1B5FEB7DD4396000", "businessTypeName": "项目出差", "businessTypeNo": "10010010101"}, "travelRecords": [{"id": "travel_0033", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-02-17", "arrivalDate": "2025-02-21", "description": "武汉至上海，项目出差相关行程"}], "allowances": [{"id": "allowance_0033", "travelRecordId": "travel_0033", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "departureDate": "2025-02-17", "arrivalDate": "2025-02-21", "allowanceDays": 5, "departureCity": "武汉", "arrivalCity": "上海", "calendar": [{"date": "2025-02-17", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-18", "weekday": "星期二", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-19", "weekday": "星期三", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-20", "weekday": "星期四", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-21", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 900, "totalAllowanceAmount": 600}], "costAllocations": [{"id": "alloc_0033", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 600}], "remark": "", "totalAllowanceAmount": 600, "totalMealAmount": 200, "totalTransportAmount": 200, "totalCommunicationAmount": 200}', '2025-02-17 13:46:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502170033');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0033', '13AB77281A408001', '潘展飞', '89899',
    '10458', '武汉', '10621', '上海',
    '2025-02-17', '2025-02-21', '武汉至上海，项目出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0033', 'travel_0033',
    '13AB77281A408001', '潘展飞', '2025-02-17', '2025-02-21',
    5, '武汉', '上海',
    900.00, 600.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-17', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-18', '星期二', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-19', '星期三', 100, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-02-20', '星期四', 100, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-02-21', '星期五', 100, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0033', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 600.00, 0
);

-- REIM202501200034 status=0 上海年度健康体检
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501200034', 0,
    '上海年度健康体检', '应上海分公司邀请，执行员工体检任务',
    '1717271D1DA15000', '14515BB4BFB92003',
    '13AB4A56BB009002', '13AB3A422A808001',
    540.00, '行程紧凑，备注备查', '{"id": "34", "documentNo": "REIM202501200034", "status": 0, "createdAt": "2025-01-20", "basicInfo": {"title": "上海年度健康体检", "reason": "应上海分公司邀请，执行员工体检任务", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A422A808001", "businessTypeName": "员工体检", "businessTypeNo": "100100303"}, "travelRecords": [{"id": "travel_0034", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10216", "departureCityName": "杭州", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-01-20", "arrivalDate": "2025-01-22", "description": "杭州至上海，员工体检相关行程"}], "allowances": [{"id": "allowance_0034", "travelRecordId": "travel_0034", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-01-20", "arrivalDate": "2025-01-22", "allowanceDays": 3, "departureCity": "杭州", "arrivalCity": "上海", "calendar": [{"date": "2025-01-20", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-21", "weekday": "星期二", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-22", "weekday": "星期三", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 540, "totalAllowanceAmount": 540}], "costAllocations": [{"id": "alloc_0034", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 540}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 540, "totalMealAmount": 300, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-01-20 13:27:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501200034');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0034', '13AB4A56BB009002', '邹薇', '21552',
    '10216', '杭州', '10621', '上海',
    '2025-01-20', '2025-01-22', '杭州至上海，员工体检相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0034', 'travel_0034',
    '13AB4A56BB009002', '邹薇', '2025-01-20', '2025-01-22',
    3, '杭州', '上海',
    540.00, 540.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-20', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-01-21', '星期二', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-01-22', '星期三', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0034', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 540.00, 0
);

-- REIM202502250035 status=1 荆州春季校园招聘
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502250035', 1,
    '荆州春季校园招聘', '应荆州分公司邀请，执行招聘会任务',
    '1C61686865DA8000', '13AB8D7B52A9B002',
    '13AB3A3F72409002', '13AB3A41AC408001',
    520.00, '展会期间公司提供用车，已核减交通补助', '{"id": "35", "documentNo": "REIM202502250035", "status": 1, "createdAt": "2025-02-25", "basicInfo": {"title": "荆州春季校园招聘", "reason": "应荆州分公司邀请，执行招聘会任务", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departmentId": "13AB8D7B52A9B002", "departmentName": "客户成功事业部", "departmentNo": "072001", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "13AB3A41AC408001", "businessTypeName": "招聘会", "businessTypeNo": "100100202"}, "travelRecords": [{"id": "travel_0035", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-02-25", "arrivalDate": "2025-02-28", "description": "武汉至荆州，招聘会相关行程"}], "allowances": [{"id": "allowance_0035", "travelRecordId": "travel_0035", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "departureDate": "2025-02-25", "arrivalDate": "2025-02-28", "allowanceDays": 4, "departureCity": "武汉", "arrivalCity": "荆州", "calendar": [{"date": "2025-02-25", "weekday": "星期二", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-26", "weekday": "星期三", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-27", "weekday": "星期四", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-28", "weekday": "星期五", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 520, "totalAllowanceAmount": 520}], "costAllocations": [{"id": "alloc_0035", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 520}], "remark": "展会期间公司提供用车，已核减交通补助", "totalAllowanceAmount": 520, "totalMealAmount": 200, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-02-25 14:42:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502250035');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0035', '13AB3A3F72409002', '徐年年', '74541',
    '10458', '武汉', '10455', '荆州',
    '2025-02-25', '2025-02-28', '武汉至荆州，招聘会相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0035', 'travel_0035',
    '13AB3A3F72409002', '徐年年', '2025-02-25', '2025-02-28',
    4, '武汉', '荆州',
    520.00, 520.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-25', '星期二', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-02-26', '星期三', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-02-27', '星期四', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-02-28', '星期五', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0035', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 520.00, 0
);

-- REIM202502200036 status=1 团队管理能力提升培训
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502200036', 1,
    '团队管理能力提升培训', '参加北京举办的行业交流活动',
    '19218A262C976000', '19206611C47A6000',
    '13AB591FE8009002', '13AB3A418F808001',
    540.00, '行程紧凑，备注备查', '{"id": "36", "documentNo": "REIM202502200036", "status": 1, "createdAt": "2025-02-20", "basicInfo": {"title": "团队管理能力提升培训", "reason": "参加北京举办的行业交流活动", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departmentId": "19206611C47A6000", "departmentName": "集采事业部", "departmentNo": "072004", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "13AB3A418F808001", "businessTypeName": "个人团队培训", "businessTypeNo": "100100201"}, "travelRecords": [{"id": "travel_0036", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-02-20", "arrivalDate": "2025-02-22", "description": "荆州至北京，个人团队培训相关行程"}], "allowances": [{"id": "allowance_0036", "travelRecordId": "travel_0036", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "departureDate": "2025-02-20", "arrivalDate": "2025-02-22", "allowanceDays": 3, "departureCity": "荆州", "arrivalCity": "北京", "calendar": [{"date": "2025-02-20", "weekday": "星期四", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-21", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-22", "weekday": "星期六", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 540, "totalAllowanceAmount": 540}], "costAllocations": [{"id": "alloc_0036", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "162664EBE9ABE001", "projectName": "西北客户定制化项目", "projectNo": "northWest", "ratio": 1.0, "amount": 540}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 540, "totalMealAmount": 300, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-02-20 15:28:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502200036');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0036', '13AB591FE8009002', '王成军', '80681',
    '10455', '荆州', '10119', '北京',
    '2025-02-20', '2025-02-22', '荆州至北京，个人团队培训相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0036', 'travel_0036',
    '13AB591FE8009002', '王成军', '2025-02-20', '2025-02-22',
    3, '荆州', '北京',
    540.00, 540.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-20', '星期四', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-21', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-22', '星期六', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0036', '19218A262C976000', '胜意科技上海分公司', '0408',
    '162664EBE9ABE001', '西北客户定制化项目', 'northWest', 1.0000, 540.00, 0
);

-- REIM202503210037 status=0 入职专项体检
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503210037', 0,
    '入职专项体检', '根据业务安排前往北京开展员工体检相关工作',
    '19218A262C976000', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A422A808001',
    540.00, '单据已核对无误', '{"id": "37", "documentNo": "REIM202503210037", "status": 0, "createdAt": "2025-03-21", "basicInfo": {"title": "入职专项体检", "reason": "根据业务安排前往北京开展员工体检相关工作", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "13AB3A422A808001", "businessTypeName": "员工体检", "businessTypeNo": "100100303"}, "travelRecords": [{"id": "travel_0037", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-03-21", "arrivalDate": "2025-03-23", "description": "上海至北京，员工体检相关行程"}], "allowances": [{"id": "allowance_0037", "travelRecordId": "travel_0037", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-03-21", "arrivalDate": "2025-03-23", "allowanceDays": 3, "departureCity": "上海", "arrivalCity": "北京", "calendar": [{"date": "2025-03-21", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-22", "weekday": "星期六", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-23", "weekday": "星期日", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 540, "totalAllowanceAmount": 540}], "costAllocations": [{"id": "alloc_0037", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "162664B8526BE002", "projectName": "东北客户定制化项目", "projectNo": "northEast", "ratio": 1.0, "amount": 540}], "remark": "单据已核对无误", "totalAllowanceAmount": 540, "totalMealAmount": 300, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-03-21 11:43:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503210037');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0037', '13AB7925EB808001', '姜林', '10503',
    '10621', '上海', '10119', '北京',
    '2025-03-21', '2025-03-23', '上海至北京，员工体检相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0037', 'travel_0037',
    '13AB7925EB808001', '姜林', '2025-03-21', '2025-03-23',
    3, '上海', '北京',
    540.00, 540.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-21', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-03-22', '星期六', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-03-23', '星期日', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0037', '19218A262C976000', '胜意科技上海分公司', '0408',
    '162664B8526BE002', '东北客户定制化项目', 'northEast', 1.0000, 540.00, 0
);

-- REIM202503160038 status=0 荆州系统故障排查
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503160038', 0,
    '荆州系统故障排查', '参加荆州举办的行业交流活动',
    '19218A262C976000', '14515BB4BFB92003',
    '13AB4A56BB009002', '13AB3A4154008001',
    160.00, '', '{"id": "38", "documentNo": "REIM202503160038", "status": 0, "createdAt": "2025-03-16", "basicInfo": {"title": "荆州系统故障排查", "reason": "参加荆州举办的行业交流活动", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "13AB3A4154008001", "businessTypeName": "售后维护出差", "businessTypeNo": "10010010202"}, "travelRecords": [{"id": "travel_0038", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10119", "departureCityName": "北京", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-03-16", "arrivalDate": "2025-03-17", "description": "北京至荆州，售后维护出差相关行程"}], "allowances": [{"id": "allowance_0038", "travelRecordId": "travel_0038", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-03-16", "arrivalDate": "2025-03-17", "allowanceDays": 2, "departureCity": "北京", "arrivalCity": "荆州", "calendar": [{"date": "2025-03-16", "weekday": "星期日", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-17", "weekday": "星期一", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 260, "totalAllowanceAmount": 160}], "costAllocations": [{"id": "alloc_0038", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "1C5931735AC4A000", "projectName": "华南客户定制化项目", "projectNo": "southChina", "ratio": 1.0, "amount": 160}], "remark": "", "totalAllowanceAmount": 160, "totalMealAmount": 0, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-03-16 18:36:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503160038');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0038', '13AB4A56BB009002', '邹薇', '21552',
    '10119', '北京', '10455', '荆州',
    '2025-03-16', '2025-03-17', '北京至荆州，售后维护出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0038', 'travel_0038',
    '13AB4A56BB009002', '邹薇', '2025-03-16', '2025-03-17',
    2, '北京', '荆州',
    260.00, 160.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-16', '星期日', 50, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-03-17', '星期一', 50, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0038', '19218A262C976000', '胜意科技上海分公司', '0408',
    '1C5931735AC4A000', '华南客户定制化项目', 'southChina', 1.0000, 160.00, 0
);

-- REIM202505090039 status=0 季度团建拓展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202505090039', 0,
    '季度团建拓展', '应荆州分公司邀请，执行员工团建任务',
    '1717271D1DA15000', '13BFD31C6029A002',
    '13AB498CC6409002', '13AB3A420CC08002',
    130.00, '', '{"id": "39", "documentNo": "REIM202505090039", "status": 0, "createdAt": "2025-05-09", "basicInfo": {"title": "季度团建拓展", "reason": "应荆州分公司邀请，执行员工团建任务", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departmentId": "13BFD31C6029A002", "departmentName": "企业消费事业部", "departmentNo": "072002", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A420CC08002", "businessTypeName": "员工团建", "businessTypeNo": "100100302"}, "travelRecords": [{"id": "travel_0039", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "reimburserNo": "74008", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-05-09", "arrivalDate": "2025-05-09", "description": "上海至荆州，员工团建相关行程"}], "allowances": [{"id": "allowance_0039", "travelRecordId": "travel_0039", "reimburserId": "13AB498CC6409002", "reimburserName": "郑雨雪", "departureDate": "2025-05-09", "arrivalDate": "2025-05-09", "allowanceDays": 1, "departureCity": "上海", "arrivalCity": "荆州", "calendar": [{"date": "2025-05-09", "weekday": "星期五", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 130, "totalAllowanceAmount": 130}], "costAllocations": [{"id": "alloc_0039", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "162664EBE9ABE001", "projectName": "西北客户定制化项目", "projectNo": "northWest", "ratio": 1.0, "amount": 130}], "remark": "", "totalAllowanceAmount": 130, "totalMealAmount": 50, "totalTransportAmount": 40, "totalCommunicationAmount": 40}', '2025-05-09 10:51:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202505090039');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0039', '13AB498CC6409002', '郑雨雪', '74008',
    '10621', '上海', '10455', '荆州',
    '2025-05-09', '2025-05-09', '上海至荆州，员工团建相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0039', 'travel_0039',
    '13AB498CC6409002', '郑雨雪', '2025-05-09', '2025-05-09',
    1, '上海', '荆州',
    130.00, 130.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-05-09', '星期五', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0039', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '162664EBE9ABE001', '西北客户定制化项目', 'northWest', 1.0000, 130.00, 0
);

-- REIM202503140040 status=1 季度团建拓展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503140040', 1,
    '季度团建拓展', '参加上海举办的行业交流活动',
    '16AE93CC7EF92002', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A420CC08002',
    180.00, '行程紧凑，备注备查', '{"id": "40", "documentNo": "REIM202503140040", "status": 1, "createdAt": "2025-03-14", "basicInfo": {"title": "季度团建拓展", "reason": "参加上海举办的行业交流活动", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "businessTypeId": "13AB3A420CC08002", "businessTypeName": "员工团建", "businessTypeNo": "100100302"}, "travelRecords": [{"id": "travel_0040", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-03-14", "arrivalDate": "2025-03-14", "description": "荆州至上海，员工团建相关行程"}], "allowances": [{"id": "allowance_0040", "travelRecordId": "travel_0040", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-03-14", "arrivalDate": "2025-03-14", "allowanceDays": 1, "departureCity": "荆州", "arrivalCity": "上海", "calendar": [{"date": "2025-03-14", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 180, "totalAllowanceAmount": 180}], "costAllocations": [{"id": "alloc_0040", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "projectId": "12BC248B25083001", "projectName": "非项目类费用归集", "projectNo": "nonProjectRelated", "ratio": 1.0, "amount": 180}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 180, "totalMealAmount": 100, "totalTransportAmount": 40, "totalCommunicationAmount": 40}', '2025-03-14 17:52:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503140040');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0040', '13AB7925EB808001', '姜林', '10503',
    '10455', '荆州', '10621', '上海',
    '2025-03-14', '2025-03-14', '荆州至上海，员工团建相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0040', 'travel_0040',
    '13AB7925EB808001', '姜林', '2025-03-14', '2025-03-14',
    1, '荆州', '上海',
    180.00, 180.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-14', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0040', '16AE93CC7EF92002', '胜意科技荆州分公司', '0411',
    '12BC248B25083001', '非项目类费用归集', 'nonProjectRelated', 1.0000, 180.00, 0
);

-- REIM202502170041 status=0 部门团建旅游
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502170041', 0,
    '部门团建旅游', '参加杭州举办的行业交流活动',
    '16AE93CC7EF92002', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A41ED408002',
    640.00, '出差期间部分餐费由客户承担，已核减', '{"id": "41", "documentNo": "REIM202502170041", "status": 0, "createdAt": "2025-02-17", "basicInfo": {"title": "部门团建旅游", "reason": "参加杭州举办的行业交流活动", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "businessTypeId": "13AB3A41ED408002", "businessTypeName": "员工旅游", "businessTypeNo": "100100301"}, "travelRecords": [{"id": "travel_0041", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10216", "arrivalCityName": "杭州", "departureDate": "2025-02-17", "arrivalDate": "2025-02-20", "description": "上海至杭州，员工旅游相关行程"}], "allowances": [{"id": "allowance_0041", "travelRecordId": "travel_0041", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-02-17", "arrivalDate": "2025-02-20", "allowanceDays": 4, "departureCity": "上海", "arrivalCity": "杭州", "calendar": [{"date": "2025-02-17", "weekday": "星期一", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-18", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-19", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-20", "weekday": "星期四", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 640, "totalAllowanceAmount": 640}], "costAllocations": [{"id": "alloc_0041", "companyId": "16AE93CC7EF92002", "companyName": "胜意科技荆州分公司", "companyNo": "0411", "projectId": "162664B8526BE002", "projectName": "东北客户定制化项目", "projectNo": "northEast", "ratio": 1.0, "amount": 640}], "remark": "出差期间部分餐费由客户承担，已核减", "totalAllowanceAmount": 640, "totalMealAmount": 320, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-02-17 18:15:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502170041');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0041', '13AB7925EB808001', '姜林', '10503',
    '10621', '上海', '10216', '杭州',
    '2025-02-17', '2025-02-20', '上海至杭州，员工旅游相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0041', 'travel_0041',
    '13AB7925EB808001', '姜林', '2025-02-17', '2025-02-20',
    4, '上海', '杭州',
    640.00, 640.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-17', '星期一', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-02-18', '星期二', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-02-19', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-02-20', '星期四', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0041', '16AE93CC7EF92002', '胜意科技荆州分公司', '0411',
    '162664B8526BE002', '东北客户定制化项目', 'northEast', 1.0000, 640.00, 0
);

-- REIM202502240042 status=1 武汉行业展会参展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502240042', 1,
    '武汉行业展会参展', '应武汉分公司邀请，执行市场拓展出差任务',
    '1717271D1DA15000', '14515BB4BFB92003',
    '13AB4A56BB009002', '1A92E43082EFC000',
    400.00, '', '{"id": "42", "documentNo": "REIM202502240042", "status": 1, "createdAt": "2025-02-24", "basicInfo": {"title": "武汉行业展会参展", "reason": "应武汉分公司邀请，执行市场拓展出差任务", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "1A92E43082EFC000", "businessTypeName": "市场拓展出差", "businessTypeNo": "10010010102"}, "travelRecords": [{"id": "travel_0042", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-02-24", "arrivalDate": "2025-02-26", "description": "上海至武汉，市场拓展出差相关行程"}], "allowances": [{"id": "allowance_0042", "travelRecordId": "travel_0042", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-02-24", "arrivalDate": "2025-02-26", "allowanceDays": 3, "departureCity": "上海", "arrivalCity": "武汉", "calendar": [{"date": "2025-02-24", "weekday": "星期一", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-25", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-26", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 480, "totalAllowanceAmount": 400}], "costAllocations": [{"id": "alloc_0042", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1762792DB4E9A002", "projectName": "华东客户定制化项目", "projectNo": "eastChina", "ratio": 1.0, "amount": 400}], "remark": "", "totalAllowanceAmount": 400, "totalMealAmount": 160, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-02-24 11:24:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502240042');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0042', '13AB4A56BB009002', '邹薇', '21552',
    '10621', '上海', '10458', '武汉',
    '2025-02-24', '2025-02-26', '上海至武汉，市场拓展出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0042', 'travel_0042',
    '13AB4A56BB009002', '邹薇', '2025-02-24', '2025-02-26',
    3, '上海', '武汉',
    480.00, 400.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-24', '星期一', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-02-25', '星期二', 80, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-02-26', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0042', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1762792DB4E9A002', '华东客户定制化项目', 'eastChina', 1.0000, 400.00, 0
);

-- REIM202503250043 status=1 荆州客户售后维护
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503250043', 1,
    '荆州客户售后维护', '应荆州分公司邀请，执行售后维护出差任务',
    '19218A262C976000', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A4154008001',
    390.00, '行程紧凑，备注备查', '{"id": "43", "documentNo": "REIM202503250043", "status": 1, "createdAt": "2025-03-25", "basicInfo": {"title": "荆州客户售后维护", "reason": "应荆州分公司邀请，执行售后维护出差任务", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "13AB3A4154008001", "businessTypeName": "售后维护出差", "businessTypeNo": "10010010202"}, "travelRecords": [{"id": "travel_0043", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10216", "departureCityName": "杭州", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-03-25", "arrivalDate": "2025-03-27", "description": "杭州至荆州，售后维护出差相关行程"}], "allowances": [{"id": "allowance_0043", "travelRecordId": "travel_0043", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-03-25", "arrivalDate": "2025-03-27", "allowanceDays": 3, "departureCity": "杭州", "arrivalCity": "荆州", "calendar": [{"date": "2025-03-25", "weekday": "星期二", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-26", "weekday": "星期三", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-27", "weekday": "星期四", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 390, "totalAllowanceAmount": 390}], "costAllocations": [{"id": "alloc_0043", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 390}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 390, "totalMealAmount": 150, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-03-25 14:24:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503250043');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0043', '13AB7925EB808001', '姜林', '10503',
    '10216', '杭州', '10455', '荆州',
    '2025-03-25', '2025-03-27', '杭州至荆州，售后维护出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0043', 'travel_0043',
    '13AB7925EB808001', '姜林', '2025-03-25', '2025-03-27',
    3, '杭州', '荆州',
    390.00, 390.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-25', '星期二', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-03-26', '星期三', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-03-27', '星期四', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0043', '19218A262C976000', '胜意科技上海分公司', '0408',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 390.00, 0
);

-- REIM202504210044 status=1 武汉年度员工旅游
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504210044', 1,
    '武汉年度员工旅游', '参加武汉举办的行业交流活动',
    '1C54557F1782E000', '19D32F9FE9647000',
    '13AB77281A408001', '13AB3A41ED408002',
    480.00, '行程紧凑，备注备查', '{"id": "44", "documentNo": "REIM202504210044", "status": 1, "createdAt": "2025-04-21", "basicInfo": {"title": "武汉年度员工旅游", "reason": "参加武汉举办的行业交流活动", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departmentId": "19D32F9FE9647000", "departmentName": "航旅事业部", "departmentNo": "072005", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "13AB3A41ED408002", "businessTypeName": "员工旅游", "businessTypeNo": "100100301"}, "travelRecords": [{"id": "travel_0044", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departureCityId": "10119", "departureCityName": "北京", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-04-21", "arrivalDate": "2025-04-23", "description": "北京至武汉，员工旅游相关行程"}], "allowances": [{"id": "allowance_0044", "travelRecordId": "travel_0044", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "departureDate": "2025-04-21", "arrivalDate": "2025-04-23", "allowanceDays": 3, "departureCity": "北京", "arrivalCity": "武汉", "calendar": [{"date": "2025-04-21", "weekday": "星期一", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-22", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-23", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 480, "totalAllowanceAmount": 480}], "costAllocations": [{"id": "alloc_0044", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "162664B8526BE002", "projectName": "东北客户定制化项目", "projectNo": "northEast", "ratio": 1.0, "amount": 480}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 480, "totalMealAmount": 240, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-04-21 11:17:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504210044');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0044', '13AB77281A408001', '潘展飞', '89899',
    '10119', '北京', '10458', '武汉',
    '2025-04-21', '2025-04-23', '北京至武汉，员工旅游相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0044', 'travel_0044',
    '13AB77281A408001', '潘展飞', '2025-04-21', '2025-04-23',
    3, '北京', '武汉',
    480.00, 480.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-21', '星期一', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-04-22', '星期二', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-04-23', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0044', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '162664B8526BE002', '东北客户定制化项目', 'northEast', 1.0000, 480.00, 0
);

-- REIM202505020045 status=1 杭州客户需求调研
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202505020045', 1,
    '杭州客户需求调研', '根据业务安排前往杭州开展项目出差相关工作',
    '1717271D1DA15000', '19206611C47A6000',
    '13AB591FE8009002', '1B5FEB7DD4396000',
    240.00, '出差期间部分餐费由客户承担，已核减', '{"id": "45", "documentNo": "REIM202505020045", "status": 1, "createdAt": "2025-05-02", "basicInfo": {"title": "杭州客户需求调研", "reason": "根据业务安排前往杭州开展项目出差相关工作", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departmentId": "19206611C47A6000", "departmentName": "集采事业部", "departmentNo": "072004", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "1B5FEB7DD4396000", "businessTypeName": "项目出差", "businessTypeNo": "10010010101"}, "travelRecords": [{"id": "travel_0045", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10216", "arrivalCityName": "杭州", "departureDate": "2025-05-02", "arrivalDate": "2025-05-03", "description": "武汉至杭州，项目出差相关行程"}], "allowances": [{"id": "allowance_0045", "travelRecordId": "travel_0045", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "departureDate": "2025-05-02", "arrivalDate": "2025-05-03", "allowanceDays": 2, "departureCity": "武汉", "arrivalCity": "杭州", "calendar": [{"date": "2025-05-02", "weekday": "星期五", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-05-03", "weekday": "星期六", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 320, "totalAllowanceAmount": 240}], "costAllocations": [{"id": "alloc_0045", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "162664EBE9ABE001", "projectName": "西北客户定制化项目", "projectNo": "northWest", "ratio": 1.0, "amount": 240}], "remark": "出差期间部分餐费由客户承担，已核减", "totalAllowanceAmount": 240, "totalMealAmount": 80, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-05-02 14:37:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202505020045');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0045', '13AB591FE8009002', '王成军', '80681',
    '10458', '武汉', '10216', '杭州',
    '2025-05-02', '2025-05-03', '武汉至杭州，项目出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0045', 'travel_0045',
    '13AB591FE8009002', '王成军', '2025-05-02', '2025-05-03',
    2, '武汉', '杭州',
    320.00, 240.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-05-02', '星期五', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-05-03', '星期六', 80, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0045', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '162664EBE9ABE001', '西北客户定制化项目', 'northWest', 1.0000, 240.00, 0
);

-- REIM202501210046 status=1 杭州区域市场拓展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501210046', 1,
    '杭州区域市场拓展', '应杭州分公司邀请，执行市场拓展出差任务',
    '1C54557F1782E000', '19D32F9FE9647000',
    '13AB77281A408001', '1A92E43082EFC000',
    320.00, '行程紧凑，备注备查', '{"id": "46", "documentNo": "REIM202501210046", "status": 1, "createdAt": "2025-01-21", "basicInfo": {"title": "杭州区域市场拓展", "reason": "应杭州分公司邀请，执行市场拓展出差任务", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departmentId": "19D32F9FE9647000", "departmentName": "航旅事业部", "departmentNo": "072005", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "1A92E43082EFC000", "businessTypeName": "市场拓展出差", "businessTypeNo": "10010010102"}, "travelRecords": [{"id": "travel_0046", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "reimburserNo": "89899", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10216", "arrivalCityName": "杭州", "departureDate": "2025-01-21", "arrivalDate": "2025-01-22", "description": "上海至杭州，市场拓展出差相关行程"}], "allowances": [{"id": "allowance_0046", "travelRecordId": "travel_0046", "reimburserId": "13AB77281A408001", "reimburserName": "潘展飞", "departureDate": "2025-01-21", "arrivalDate": "2025-01-22", "allowanceDays": 2, "departureCity": "上海", "arrivalCity": "杭州", "calendar": [{"date": "2025-01-21", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-22", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 320, "totalAllowanceAmount": 320}], "costAllocations": [{"id": "alloc_0046", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "162664EBE9ABE001", "projectName": "西北客户定制化项目", "projectNo": "northWest", "ratio": 1.0, "amount": 320}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 320, "totalMealAmount": 160, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-01-21 15:20:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501210046');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0046', '13AB77281A408001', '潘展飞', '89899',
    '10621', '上海', '10216', '杭州',
    '2025-01-21', '2025-01-22', '上海至杭州，市场拓展出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0046', 'travel_0046',
    '13AB77281A408001', '潘展飞', '2025-01-21', '2025-01-22',
    2, '上海', '杭州',
    320.00, 320.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-21', '星期二', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-01-22', '星期三', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0046', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '162664EBE9ABE001', '西北客户定制化项目', 'northWest', 1.0000, 320.00, 0
);

-- REIM202501170047 status=0 北京专业技能培训
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202501170047', 0,
    '北京专业技能培训', '配合西北客户定制化项目项目进度，赴北京现场办公',
    '1717271D1DA15000', '14515BB4BFB92003',
    '13AB4A56BB009002', '13AB3A418F808001',
    520.00, '单据已核对无误', '{"id": "47", "documentNo": "REIM202501170047", "status": 0, "createdAt": "2025-01-17", "basicInfo": {"title": "北京专业技能培训", "reason": "配合西北客户定制化项目项目进度，赴北京现场办公", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A418F808001", "businessTypeName": "个人团队培训", "businessTypeNo": "100100201"}, "travelRecords": [{"id": "travel_0047", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-01-17", "arrivalDate": "2025-01-20", "description": "武汉至北京，个人团队培训相关行程"}], "allowances": [{"id": "allowance_0047", "travelRecordId": "travel_0047", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-01-17", "arrivalDate": "2025-01-20", "allowanceDays": 4, "departureCity": "武汉", "arrivalCity": "北京", "calendar": [{"date": "2025-01-17", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-18", "weekday": "星期六", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-19", "weekday": "星期日", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-01-20", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 720, "totalAllowanceAmount": 520}], "costAllocations": [{"id": "alloc_0047", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "162664EBE9ABE001", "projectName": "西北客户定制化项目", "projectNo": "northWest", "ratio": 1.0, "amount": 520}], "remark": "单据已核对无误", "totalAllowanceAmount": 520, "totalMealAmount": 200, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-01-17 11:41:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202501170047');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0047', '13AB4A56BB009002', '邹薇', '21552',
    '10458', '武汉', '10119', '北京',
    '2025-01-17', '2025-01-20', '武汉至北京，个人团队培训相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0047', 'travel_0047',
    '13AB4A56BB009002', '邹薇', '2025-01-17', '2025-01-20',
    4, '武汉', '北京',
    720.00, 520.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-01-17', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-01-18', '星期六', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-01-19', '星期日', 100, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-01-20', '星期一', 100, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0047', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '162664EBE9ABE001', '西北客户定制化项目', 'northWest', 1.0000, 520.00, 0
);

-- REIM202502030048 status=1 北京定制化项目实施
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502030048', 1,
    '北京定制化项目实施', '根据业务安排前往北京开展项目出差相关工作',
    '1C54557F1782E000', '13AB8D7B52A9B002',
    '13AB3A3F72409002', '1B5FEB7DD4396000',
    900.00, '出差期间部分餐费由客户承担，已核减', '{"id": "48", "documentNo": "REIM202502030048", "status": 1, "createdAt": "2025-02-03", "basicInfo": {"title": "北京定制化项目实施", "reason": "根据业务安排前往北京开展项目出差相关工作", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departmentId": "13AB8D7B52A9B002", "departmentName": "客户成功事业部", "departmentNo": "072001", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "businessTypeId": "1B5FEB7DD4396000", "businessTypeName": "项目出差", "businessTypeNo": "10010010101"}, "travelRecords": [{"id": "travel_0048", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-02-03", "arrivalDate": "2025-02-07", "description": "上海至北京，项目出差相关行程"}], "allowances": [{"id": "allowance_0048", "travelRecordId": "travel_0048", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "departureDate": "2025-02-03", "arrivalDate": "2025-02-07", "allowanceDays": 5, "departureCity": "上海", "arrivalCity": "北京", "calendar": [{"date": "2025-02-03", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-04", "weekday": "星期二", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-05", "weekday": "星期三", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-06", "weekday": "星期四", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-07", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 900, "totalAllowanceAmount": 900}], "costAllocations": [{"id": "alloc_0048", "companyId": "1C54557F1782E000", "companyName": "胜意科技北京分公司", "companyNo": "0407", "projectId": "1771EC45F2443000", "projectName": "华北客户定制化项目", "projectNo": "northChina", "ratio": 1.0, "amount": 900}], "remark": "出差期间部分餐费由客户承担，已核减", "totalAllowanceAmount": 900, "totalMealAmount": 500, "totalTransportAmount": 200, "totalCommunicationAmount": 200}', '2025-02-03 17:13:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502030048');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0048', '13AB3A3F72409002', '徐年年', '74541',
    '10621', '上海', '10119', '北京',
    '2025-02-03', '2025-02-07', '上海至北京，项目出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0048', 'travel_0048',
    '13AB3A3F72409002', '徐年年', '2025-02-03', '2025-02-07',
    5, '上海', '北京',
    900.00, 900.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-03', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-04', '星期二', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-05', '星期三', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-06', '星期四', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-07', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0048', '1C54557F1782E000', '胜意科技北京分公司', '0407',
    '1771EC45F2443000', '华北客户定制化项目', 'northChina', 1.0000, 900.00, 0
);

-- REIM202502230049 status=1 北京春季校园招聘
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502230049', 1,
    '北京春季校园招聘', '配合华南客户定制化项目项目进度，赴北京现场办公',
    '1C61686865DA8000', '19206611C47A6000',
    '13AB591FE8009002', '13AB3A41AC408001',
    360.00, '单据已核对无误', '{"id": "49", "documentNo": "REIM202502230049", "status": 1, "createdAt": "2025-02-23", "basicInfo": {"title": "北京春季校园招聘", "reason": "配合华南客户定制化项目项目进度，赴北京现场办公", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departmentId": "19206611C47A6000", "departmentName": "集采事业部", "departmentNo": "072004", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "13AB3A41AC408001", "businessTypeName": "招聘会", "businessTypeNo": "100100202"}, "travelRecords": [{"id": "travel_0049", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-02-23", "arrivalDate": "2025-02-24", "description": "荆州至北京，招聘会相关行程"}], "allowances": [{"id": "allowance_0049", "travelRecordId": "travel_0049", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "departureDate": "2025-02-23", "arrivalDate": "2025-02-24", "allowanceDays": 2, "departureCity": "荆州", "arrivalCity": "北京", "calendar": [{"date": "2025-02-23", "weekday": "星期日", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-24", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 360, "totalAllowanceAmount": 360}], "costAllocations": [{"id": "alloc_0049", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "1C5931735AC4A000", "projectName": "华南客户定制化项目", "projectNo": "southChina", "ratio": 1.0, "amount": 360}], "remark": "单据已核对无误", "totalAllowanceAmount": 360, "totalMealAmount": 200, "totalTransportAmount": 80, "totalCommunicationAmount": 80}', '2025-02-23 17:43:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502230049');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0049', '13AB591FE8009002', '王成军', '80681',
    '10455', '荆州', '10119', '北京',
    '2025-02-23', '2025-02-24', '荆州至北京，招聘会相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0049', 'travel_0049',
    '13AB591FE8009002', '王成军', '2025-02-23', '2025-02-24',
    2, '荆州', '北京',
    360.00, 360.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-23', '星期日', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-02-24', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0049', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '1C5931735AC4A000', '华南客户定制化项目', 'southChina', 1.0000, 360.00, 0
);

-- REIM202504140050 status=2 上海系统故障排查
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504140050', 2,
    '上海系统故障排查', '根据业务安排前往上海开展售后维护出差相关工作',
    '1717271D1DA15000', '19206611C47A6000',
    '13AB591FE8009002', '13AB3A4154008001',
    180.00, '行程取消，单据作废', '{"id": "50", "documentNo": "REIM202504140050", "status": 2, "createdAt": "2025-04-14", "basicInfo": {"title": "上海系统故障排查", "reason": "根据业务安排前往上海开展售后维护出差相关工作", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departmentId": "19206611C47A6000", "departmentName": "集采事业部", "departmentNo": "072004", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A4154008001", "businessTypeName": "售后维护出差", "businessTypeNo": "10010010202"}, "travelRecords": [{"id": "travel_0050", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "reimburserNo": "80681", "departureCityId": "10455", "departureCityName": "荆州", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-04-14", "arrivalDate": "2025-04-14", "description": "荆州至上海，售后维护出差相关行程"}], "allowances": [{"id": "allowance_0050", "travelRecordId": "travel_0050", "reimburserId": "13AB591FE8009002", "reimburserName": "王成军", "departureDate": "2025-04-14", "arrivalDate": "2025-04-14", "allowanceDays": 1, "departureCity": "荆州", "arrivalCity": "上海", "calendar": [{"date": "2025-04-14", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 180, "totalAllowanceAmount": 180}], "costAllocations": [{"id": "alloc_0050", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1C811ABF96195000", "projectName": "华中客户定制化项目", "projectNo": "centralChina", "ratio": 1.0, "amount": 180}], "remark": "行程取消，单据作废", "totalAllowanceAmount": 180, "totalMealAmount": 100, "totalTransportAmount": 40, "totalCommunicationAmount": 40}', '2025-04-14 17:50:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504140050');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0050', '13AB591FE8009002', '王成军', '80681',
    '10455', '荆州', '10621', '上海',
    '2025-04-14', '2025-04-14', '荆州至上海，售后维护出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0050', 'travel_0050',
    '13AB591FE8009002', '王成军', '2025-04-14', '2025-04-14',
    1, '荆州', '上海',
    180.00, 180.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-14', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0050', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1C811ABF96195000', '华中客户定制化项目', 'centralChina', 1.0000, 180.00, 0
);

-- REIM202504070051 status=1 入职专项体检
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504070051', 1,
    '入职专项体检', '参加北京举办的行业交流活动',
    '1C61686865DA8000', '13AB8D7B52A9B002',
    '13AB3A3F72409002', '13AB3A422A808001',
    900.00, '', '{"id": "51", "documentNo": "REIM202504070051", "status": 1, "createdAt": "2025-04-07", "basicInfo": {"title": "入职专项体检", "reason": "参加北京举办的行业交流活动", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departmentId": "13AB8D7B52A9B002", "departmentName": "客户成功事业部", "departmentNo": "072001", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "businessTypeId": "13AB3A422A808001", "businessTypeName": "员工体检", "businessTypeNo": "100100303"}, "travelRecords": [{"id": "travel_0051", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "reimburserNo": "74541", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10119", "arrivalCityName": "北京", "departureDate": "2025-04-07", "arrivalDate": "2025-04-11", "description": "武汉至北京，员工体检相关行程"}], "allowances": [{"id": "allowance_0051", "travelRecordId": "travel_0051", "reimburserId": "13AB3A3F72409002", "reimburserName": "徐年年", "departureDate": "2025-04-07", "arrivalDate": "2025-04-11", "allowanceDays": 5, "departureCity": "武汉", "arrivalCity": "北京", "calendar": [{"date": "2025-04-07", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-08", "weekday": "星期二", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-09", "weekday": "星期三", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-10", "weekday": "星期四", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-11", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 900, "totalAllowanceAmount": 900}], "costAllocations": [{"id": "alloc_0051", "companyId": "1C61686865DA8000", "companyName": "胜意科技武汉分公司", "companyNo": "0409", "projectId": "162664EBE9ABE001", "projectName": "西北客户定制化项目", "projectNo": "northWest", "ratio": 1.0, "amount": 900}], "remark": "", "totalAllowanceAmount": 900, "totalMealAmount": 500, "totalTransportAmount": 200, "totalCommunicationAmount": 200}', '2025-04-07 09:27:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504070051');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0051', '13AB3A3F72409002', '徐年年', '74541',
    '10458', '武汉', '10119', '北京',
    '2025-04-07', '2025-04-11', '武汉至北京，员工体检相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0051', 'travel_0051',
    '13AB3A3F72409002', '徐年年', '2025-04-07', '2025-04-11',
    5, '武汉', '北京',
    900.00, 900.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-07', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-04-08', '星期二', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-04-09', '星期三', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-04-10', '星期四', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-04-11', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0051', '1C61686865DA8000', '胜意科技武汉分公司', '0409',
    '162664EBE9ABE001', '西北客户定制化项目', 'northWest', 1.0000, 900.00, 0
);

-- REIM202504280052 status=1 国际合作伙伴拜访
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504280052', 1,
    '国际合作伙伴拜访', '参加武汉举办的行业交流活动',
    '1717271D1DA15000', '14515BB4BFB92003',
    '13AB4A56BB009002', '13AB3A4248008002',
    560.00, '行程紧凑，备注备查', '{"id": "52", "documentNo": "REIM202504280052", "status": 1, "createdAt": "2025-04-28", "basicInfo": {"title": "国际合作伙伴拜访", "reason": "参加武汉举办的行业交流活动", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A4248008002", "businessTypeName": "国外考察", "businessTypeNo": "10010010201"}, "travelRecords": [{"id": "travel_0052", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10621", "departureCityName": "上海", "arrivalCityId": "10458", "arrivalCityName": "武汉", "departureDate": "2025-04-28", "arrivalDate": "2025-05-02", "description": "上海至武汉，国外考察相关行程"}], "allowances": [{"id": "allowance_0052", "travelRecordId": "travel_0052", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-04-28", "arrivalDate": "2025-05-02", "allowanceDays": 5, "departureCity": "上海", "arrivalCity": "武汉", "calendar": [{"date": "2025-04-28", "weekday": "星期一", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-29", "weekday": "星期二", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-30", "weekday": "星期三", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-05-01", "weekday": "星期四", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-05-02", "weekday": "星期五", "mealAllowance": 80, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 80, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 800, "totalAllowanceAmount": 560}], "costAllocations": [{"id": "alloc_0052", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "162664EBE9ABE001", "projectName": "西北客户定制化项目", "projectNo": "northWest", "ratio": 1.0, "amount": 560}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 560, "totalMealAmount": 160, "totalTransportAmount": 200, "totalCommunicationAmount": 200}', '2025-04-28 17:17:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504280052');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0052', '13AB4A56BB009002', '邹薇', '21552',
    '10621', '上海', '10458', '武汉',
    '2025-04-28', '2025-05-02', '上海至武汉，国外考察相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0052', 'travel_0052',
    '13AB4A56BB009002', '邹薇', '2025-04-28', '2025-05-02',
    5, '上海', '武汉',
    800.00, 560.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-28', '星期一', 80, 40, 40, 1, 1, 1, 80, 40, 40),
(@aid, '2025-04-29', '星期二', 80, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-04-30', '星期三', 80, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-05-01', '星期四', 80, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-05-02', '星期五', 80, 40, 40, 1, 1, 1, 80, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0052', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '162664EBE9ABE001', '西北客户定制化项目', 'northWest', 1.0000, 560.00, 0
);

-- REIM202503280053 status=0 上海区域市场拓展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202503280053', 0,
    '上海区域市场拓展', '根据业务安排前往上海开展市场拓展出差相关工作',
    '19218A262C976000', '14515BB4BFB92003',
    '13AB4A56BB009002', '1A92E43082EFC000',
    620.00, '行程紧凑，备注备查', '{"id": "53", "documentNo": "REIM202503280053", "status": 0, "createdAt": "2025-03-28", "basicInfo": {"title": "上海区域市场拓展", "reason": "根据业务安排前往上海开展市场拓展出差相关工作", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "1A92E43082EFC000", "businessTypeName": "市场拓展出差", "businessTypeNo": "10010010102"}, "travelRecords": [{"id": "travel_0053", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10216", "departureCityName": "杭州", "arrivalCityId": "10621", "arrivalCityName": "上海", "departureDate": "2025-03-28", "arrivalDate": "2025-03-31", "description": "杭州至上海，市场拓展出差相关行程"}], "allowances": [{"id": "allowance_0053", "travelRecordId": "travel_0053", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-03-28", "arrivalDate": "2025-03-31", "allowanceDays": 4, "departureCity": "杭州", "arrivalCity": "上海", "calendar": [{"date": "2025-03-28", "weekday": "星期五", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-29", "weekday": "星期六", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-30", "weekday": "星期日", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-03-31", "weekday": "星期一", "mealAllowance": 100, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 100, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 720, "totalAllowanceAmount": 620}], "costAllocations": [{"id": "alloc_0053", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "1762792DB4E9A002", "projectName": "华东客户定制化项目", "projectNo": "eastChina", "ratio": 1.0, "amount": 620}], "remark": "行程紧凑，备注备查", "totalAllowanceAmount": 620, "totalMealAmount": 300, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-03-28 15:54:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202503280053');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0053', '13AB4A56BB009002', '邹薇', '21552',
    '10216', '杭州', '10621', '上海',
    '2025-03-28', '2025-03-31', '杭州至上海，市场拓展出差相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0053', 'travel_0053',
    '13AB4A56BB009002', '邹薇', '2025-03-28', '2025-03-31',
    4, '杭州', '上海',
    720.00, 620.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-03-28', '星期五', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-03-29', '星期六', 100, 40, 40, 1, 1, 1, 100, 40, 40),
(@aid, '2025-03-30', '星期日', 100, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-03-31', '星期一', 100, 40, 40, 1, 1, 1, 100, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0053', '19218A262C976000', '胜意科技上海分公司', '0408',
    '1762792DB4E9A002', '华东客户定制化项目', 'eastChina', 1.0000, 620.00, 0
);

-- REIM202502190054 status=0 荆州团队建设活动
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202502190054', 0,
    '荆州团队建设活动', '应荆州分公司邀请，执行员工团建任务',
    '19218A262C976000', '14515BB4BFB92003',
    '13AB4A56BB009002', '13AB3A420CC08002',
    390.00, '展会期间公司提供用车，已核减交通补助', '{"id": "54", "documentNo": "REIM202502190054", "status": 0, "createdAt": "2025-02-19", "basicInfo": {"title": "荆州团队建设活动", "reason": "应荆州分公司邀请，执行员工团建任务", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departmentId": "14515BB4BFB92003", "departmentName": "企业费控事业部", "departmentNo": "072003", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "businessTypeId": "13AB3A420CC08002", "businessTypeName": "员工团建", "businessTypeNo": "100100302"}, "travelRecords": [{"id": "travel_0054", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "reimburserNo": "21552", "departureCityId": "10458", "departureCityName": "武汉", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-02-19", "arrivalDate": "2025-02-21", "description": "武汉至荆州，员工团建相关行程"}], "allowances": [{"id": "allowance_0054", "travelRecordId": "travel_0054", "reimburserId": "13AB4A56BB009002", "reimburserName": "邹薇", "departureDate": "2025-02-19", "arrivalDate": "2025-02-21", "allowanceDays": 3, "departureCity": "武汉", "arrivalCity": "荆州", "calendar": [{"date": "2025-02-19", "weekday": "星期三", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-20", "weekday": "星期四", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-02-21", "weekday": "星期五", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 390, "totalAllowanceAmount": 390}], "costAllocations": [{"id": "alloc_0054", "companyId": "19218A262C976000", "companyName": "胜意科技上海分公司", "companyNo": "0408", "projectId": "1771EC45F2443000", "projectName": "华北客户定制化项目", "projectNo": "northChina", "ratio": 1.0, "amount": 390}], "remark": "展会期间公司提供用车，已核减交通补助", "totalAllowanceAmount": 390, "totalMealAmount": 150, "totalTransportAmount": 120, "totalCommunicationAmount": 120}', '2025-02-19 09:15:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202502190054');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0054', '13AB4A56BB009002', '邹薇', '21552',
    '10458', '武汉', '10455', '荆州',
    '2025-02-19', '2025-02-21', '武汉至荆州，员工团建相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0054', 'travel_0054',
    '13AB4A56BB009002', '邹薇', '2025-02-19', '2025-02-21',
    3, '武汉', '荆州',
    390.00, 390.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-02-19', '星期三', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-02-20', '星期四', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-02-21', '星期五', 50, 40, 40, 1, 1, 1, 50, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0054', '19218A262C976000', '胜意科技上海分公司', '0408',
    '1771EC45F2443000', '华北客户定制化项目', 'northChina', 1.0000, 390.00, 0
);

-- REIM202504260055 status=1 季度团建拓展
INSERT INTO reimbursement (
    document_no, status, title, reason,
    company_id, department_id, reimburser_id, business_type_id,
    total_allowance_amount, remark, content, created_at
) VALUES (
    'REIM202504260055', 1,
    '季度团建拓展', '应荆州分公司邀请，执行员工团建任务',
    '1717271D1DA15000', '13C7E2BAE0393001',
    '13AB7925EB808001', '13AB3A420CC08002',
    420.00, '', '{"id": "55", "documentNo": "REIM202504260055", "status": 1, "createdAt": "2025-04-26", "basicInfo": {"title": "季度团建拓展", "reason": "应荆州分公司邀请，执行员工团建任务", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departmentId": "13C7E2BAE0393001", "departmentName": "运营事业部", "departmentNo": "072006", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "businessTypeId": "13AB3A420CC08002", "businessTypeName": "员工团建", "businessTypeNo": "100100302"}, "travelRecords": [{"id": "travel_0055", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "reimburserNo": "10503", "departureCityId": "10216", "departureCityName": "杭州", "arrivalCityId": "10455", "arrivalCityName": "荆州", "departureDate": "2025-04-26", "arrivalDate": "2025-04-29", "description": "杭州至荆州，员工团建相关行程"}], "allowances": [{"id": "allowance_0055", "travelRecordId": "travel_0055", "reimburserId": "13AB7925EB808001", "reimburserName": "姜林", "departureDate": "2025-04-26", "arrivalDate": "2025-04-29", "allowanceDays": 4, "departureCity": "杭州", "arrivalCity": "荆州", "calendar": [{"date": "2025-04-26", "weekday": "星期六", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-27", "weekday": "星期日", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": true, "transportSelected": true, "communicationSelected": true, "mealAmount": 50, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-28", "weekday": "星期一", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}, {"date": "2025-04-29", "weekday": "星期二", "mealAllowance": 50, "transportAllowance": 40, "communicationAllowance": 40, "mealSelected": false, "transportSelected": true, "communicationSelected": true, "mealAmount": 0, "transportAmount": 40, "communicationAmount": 40}], "totalApplyAmount": 520, "totalAllowanceAmount": 420}], "costAllocations": [{"id": "alloc_0055", "companyId": "1717271D1DA15000", "companyName": "胜意科技杭州分公司", "companyNo": "0410", "projectId": "1771EC45F2443000", "projectName": "华北客户定制化项目", "projectNo": "northChina", "ratio": 1.0, "amount": 420}], "remark": "", "totalAllowanceAmount": 420, "totalMealAmount": 100, "totalTransportAmount": 160, "totalCommunicationAmount": 160}', '2025-04-26 14:44:00'
) ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    title = VALUES(title),
    reason = VALUES(reason),
    total_allowance_amount = VALUES(total_allowance_amount),
    remark = VALUES(remark),
    content = VALUES(content);

SET @rid = (SELECT id FROM reimbursement WHERE document_no = 'REIM202504260055');
DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid
);
DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;
DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;

INSERT INTO reimbursement_travel_record (
    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
    departure_date, arrival_date, description
) VALUES (
    @rid, 'travel_0055', '13AB7925EB808001', '姜林', '10503',
    '10216', '杭州', '10455', '荆州',
    '2025-04-26', '2025-04-29', '杭州至荆州，员工团建相关行程'
);

INSERT INTO reimbursement_allowance (
    reimbursement_id, allowance_key, travel_record_key,
    reimburser_id, reimburser_name, departure_date, arrival_date,
    allowance_days, departure_city, arrival_city,
    total_apply_amount, total_allowance_amount
) VALUES (
    @rid, 'allowance_0055', 'travel_0055',
    '13AB7925EB808001', '姜林', '2025-04-26', '2025-04-29',
    4, '杭州', '荆州',
    520.00, 420.00
);
SET @aid = LAST_INSERT_ID();

INSERT INTO reimbursement_allowance_calendar (
    allowance_id, calendar_date, weekday,
    meal_allowance, transport_allowance, communication_allowance,
    meal_selected, transport_selected, communication_selected,
    meal_amount, transport_amount, communication_amount
) VALUES
(@aid, '2025-04-26', '星期六', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-04-27', '星期日', 50, 40, 40, 1, 1, 1, 50, 40, 40),
(@aid, '2025-04-28', '星期一', 50, 40, 40, 0, 1, 1, 0, 40, 40),
(@aid, '2025-04-29', '星期二', 50, 40, 40, 0, 1, 1, 0, 40, 40);

INSERT INTO reimbursement_cost_allocation (
    reimbursement_id, allocation_key, company_id, company_name, company_no,
    project_id, project_name, project_no, ratio, amount, sort_order
) VALUES (
    @rid, 'alloc_0055', '1717271D1DA15000', '胜意科技杭州分公司', '0410',
    '1771EC45F2443000', '华北客户定制化项目', 'northChina', 1.0000, 420.00, 0
);
