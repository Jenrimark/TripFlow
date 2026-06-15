-- ============================================================
-- TripFlow 差旅报销单 1000 条测试数据
-- 使用存储过程批量生成，可重复执行（先清空再插入）
-- 依据：docs/概要设计.md 5.6 页面数据 + 5.2 业务规则
-- ============================================================

USE tripflow;

DELIMITER $$

-- 清除旧测试数据（REIMTEST 开头的单据）
DROP PROCEDURE IF EXISTS cleanup_test_data$$
CREATE PROCEDURE cleanup_test_data()
BEGIN
    DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (
        SELECT id FROM reimbursement_allowance WHERE reimbursement_id IN (
            SELECT id FROM reimbursement WHERE document_no LIKE 'REIMTEST%'
        )
    );
    DELETE FROM reimbursement_allowance WHERE reimbursement_id IN (
        SELECT id FROM reimbursement WHERE document_no LIKE 'REIMTEST%'
    );
    DELETE FROM reimbursement_travel_record WHERE reimbursement_id IN (
        SELECT id FROM reimbursement WHERE document_no LIKE 'REIMTEST%'
    );
    DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id IN (
        SELECT id FROM reimbursement WHERE document_no LIKE 'REIMTEST%'
    );
    DELETE FROM reimbursement WHERE document_no LIKE 'REIMTEST%';
END$$

-- 主生成过程
DROP PROCEDURE IF EXISTS generate_test_data$$
CREATE PROCEDURE generate_test_data()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_doc_no VARCHAR(64);
    DECLARE v_status INT;
    DECLARE v_title VARCHAR(500);
    DECLARE v_reason VARCHAR(500);
    DECLARE v_company_id VARCHAR(32);
    DECLARE v_company_no VARCHAR(16);
    DECLARE v_company_name VARCHAR(128);
    DECLARE v_dept_id VARCHAR(32);
    DECLARE v_dept_no VARCHAR(16);
    DECLARE v_dept_name VARCHAR(128);
    DECLARE v_reimburser_id VARCHAR(32);
    DECLARE v_reimburser_no VARCHAR(16);
    DECLARE v_reimburser_name VARCHAR(64);
    DECLARE v_biz_type_id VARCHAR(32);
    DECLARE v_biz_type_no VARCHAR(32);
    DECLARE v_biz_type_name VARCHAR(128);
    DECLARE v_project_id VARCHAR(32);
    DECLARE v_project_no VARCHAR(64);
    DECLARE v_project_name VARCHAR(128);
    DECLARE v_departure_city_no VARCHAR(16);
    DECLARE v_departure_city_name VARCHAR(64);
    DECLARE v_arrival_city_no VARCHAR(16);
    DECLARE v_arrival_city_name VARCHAR(64);
    DECLARE v_departure_date DATE;
    DECLARE v_arrival_date DATE;
    DECLARE v_days INT;
    DECLARE v_meal_std DECIMAL(10,2);
    DECLARE v_transport_std DECIMAL(10,2);
    DECLARE v_comm_std DECIMAL(10,2);
    DECLARE v_city_type CHAR(1);
    DECLARE v_total_apply DECIMAL(12,2);
    DECLARE v_total_allowance DECIMAL(12,2);
    DECLARE v_rid BIGINT;  -- reimbursement id
    DECLARE v_aid BIGINT;  -- allowance id
    DECLARE v_alloc_ratio DECIMAL(8,4);
    DECLARE v_alloc_amount DECIMAL(12,2);
    DECLARE v_remark VARCHAR(1000);
    DECLARE v_created_at DATETIME;
    DECLARE v_content JSON;
    DECLARE v_weekday VARCHAR(8);
    DECLARE v_cal_date DATE;
    DECLARE v_day_idx INT;
    DECLARE v_travel_count INT;
    DECLARE v_travel_idx INT;
    DECLARE v_alloc_count INT;
    DECLARE v_alloc_idx INT;
    DECLARE v_d1 INT;  -- date offset 1
    DECLARE v_d2 INT;  -- date offset 2
    DECLARE v_base_ratio DECIMAL(8,4);
    DECLARE v_remainder DECIMAL(12,2);
    DECLARE v_sum_alloc DECIMAL(12,2);

    -- ==================== 固定数据定义 ====================

    -- 员工数组 (6人)
    -- idx 0: 徐年年 74541 客户成功事业部
    -- idx 1: 郑雨雪 74008 企业消费事业部
    -- idx 2: 邹薇   21552 企业费控事业部
    -- idx 3: 王成军 80681 集采事业部
    -- idx 4: 潘展飞 89899 航旅事业部
    -- idx 5: 姜林   10503 运营事业部

    -- 公司数组 (5家)
    -- idx 0: 1C54557F1782E000 0407 北京分公司
    -- idx 1: 19218A262C976000 0408 上海分公司
    -- idx 2: 1C61686865DA8000 0409 武汉分公司
    -- idx 3: 1717271D1DA15000 0410 杭州分公司
    -- idx 4: 16AE93CC7EF92002 0411 荆州分公司

    -- 业务类型叶子节点 (7个)
    -- idx 0: 1B5FEB7DD4396000 10010010101 项目出差
    -- idx 1: 1A92E43082EFC000 10010010102 市场拓展出差
    -- idx 2: 13AB3A4248008002 10010010201 国外考察
    -- idx 3: 13AB3A4154008001 10010010202 售后维护出差
    -- idx 4: 13AB3A418F808001 100100201   个人团队培训
    -- idx 5: 13AB3A41AC408001 100100202   招聘会
    -- idx 6: 13AB3A41ED408002 100100301   员工旅游
    -- idx 7: 13AB3A420CC08002 100100302   员工团建
    -- idx 8: 13AB3A422A808001 100100303   员工体检

    -- 城市数组 (5个)
    -- idx 0: 10119 北京 一线
    -- idx 1: 10621 上海 一线
    -- idx 2: 10458 武汉 二线
    -- idx 3: 10216 杭州 二线
    -- idx 4: 10455 荆州 三线

    -- 项目数组 (8个)
    -- idx 0: 12BC248B25083001 非项目类费用归集
    -- idx 1: 1C811ABF96195000 华中客户定制化项目
    -- idx 2: 1C5931735AC4A000 华南客户定制化项目
    -- idx 3: 1771EC45F2443000 华北客户定制化项目
    -- idx 4: 1762792DB4E9A002 华东客户定制化项目
    -- idx 5: 17071065FC29A002 西南客户定制化项目
    -- idx 6: 162664EBE9ABE001 西北客户定制化项目
    -- idx 7: 162664B8526BE002 东北客户定制化项目

    -- 备注池 (20条)
    -- idx 0: ''
    -- idx 1: '单据已核对无误'
    -- idx 2: '请尽快审批'
    -- idx 3: '出差行程已确认'
    -- idx 4: '附发票已扫描上传'
    -- idx 5: '本月出差汇总'
    -- idx 6: '客户现场需求紧急'
    -- idx 7: '项目交付前出差'
    -- idx 8: '季度例行出差'
    -- idx 9: '部门团建活动'
    -- idx 10: '出差期间有用车，请核减交补'
    -- idx 11: '出差期间有公司用餐安排'
    -- idx 12: '已与财务确认金额'
    -- idx 13: '高铁往返已报销'
    -- idx 14: '住宿费用另行报销'
    -- idx 15: '紧急项目出差'
    -- idx 16: '跨部门协作出差'
    -- idx 17: '年度例行巡检'
    -- idx 18: '新产品发布支持'
    -- idx 19: '区域市场调研'

    -- 标题池 (30条)
    -- idx 0-29 对应不同出差场景

    -- 事由池 (20条)

    -- 行程说明池 (15条)

    -- ==================== 先清理 ====================
    CALL cleanup_test_data();

    -- ==================== 循环生成 ====================
    WHILE i < 1000 DO

        -- 1) 生成单号 REIMTEST + 序号
        SET v_doc_no = CONCAT('REIMTEST', LPAD(i + 1, 6, '0'));

        -- 2) 状态分布：0草稿30% 1完成60% 2作废10%
        SET v_status = CASE
            WHEN (i % 10) < 3 THEN 0
            WHEN (i % 10) < 9 THEN 1
            ELSE 2
        END;

        -- 3) 创建时间：2024-01-01 ~ 2026-06-15 之间随机
        SET v_created_at = DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND(i * 1000 + 1) * 897) DAY);
        SET v_created_at = DATE_ADD(v_created_at, INTERVAL FLOOR(RAND(i * 2000 + 2) * 86400) SECOND);

        -- 4) 报销人（6人轮转）
        CASE (i % 6)
            WHEN 0 THEN
                SET v_reimburser_id = '13AB3A3F72409002'; SET v_reimburser_no = '74541'; SET v_reimburser_name = '徐年年';
                SET v_dept_id = '13AB8D7B52A9B002'; SET v_dept_no = '072001'; SET v_dept_name = '客户成功事业部';
            WHEN 1 THEN
                SET v_reimburser_id = '13AB498CC6409002'; SET v_reimburser_no = '74008'; SET v_reimburser_name = '郑雨雪';
                SET v_dept_id = '13BFD31C6029A002'; SET v_dept_no = '072002'; SET v_dept_name = '企业消费事业部';
            WHEN 2 THEN
                SET v_reimburser_id = '13AB4A56BB009002'; SET v_reimburser_no = '21552'; SET v_reimburser_name = '邹薇';
                SET v_dept_id = '14515BB4BFB92003'; SET v_dept_no = '072003'; SET v_dept_name = '企业费控事业部';
            WHEN 3 THEN
                SET v_reimburser_id = '13AB591FE8009002'; SET v_reimburser_no = '80681'; SET v_reimburser_name = '王成军';
                SET v_dept_id = '19206611C47A6000'; SET v_dept_no = '072004'; SET v_dept_name = '集采事业部';
            WHEN 4 THEN
                SET v_reimburser_id = '13AB77281A408001'; SET v_reimburser_no = '89899'; SET v_reimburser_name = '潘展飞';
                SET v_dept_id = '19D32F9FE9647000'; SET v_dept_no = '072005'; SET v_dept_name = '航旅事业部';
            WHEN 5 THEN
                SET v_reimburser_id = '13AB7925EB808001'; SET v_reimburser_no = '10503'; SET v_reimburser_name = '姜林';
                SET v_dept_id = '13C7E2BAE0393001'; SET v_dept_no = '072006'; SET v_dept_name = '运营事业部';
        END CASE;

        -- 5) 费用归属公司（5家随机）
        CASE (FLOOR(RAND(i * 3000 + 3) * 5))
            WHEN 0 THEN SET v_company_id = '1C54557F1782E000'; SET v_company_no = '0407'; SET v_company_name = '胜意科技北京分公司';
            WHEN 1 THEN SET v_company_id = '19218A262C976000'; SET v_company_no = '0408'; SET v_company_name = '胜意科技上海分公司';
            WHEN 2 THEN SET v_company_id = '1C61686865DA8000'; SET v_company_no = '0409'; SET v_company_name = '胜意科技武汉分公司';
            WHEN 3 THEN SET v_company_id = '1717271D1DA15000'; SET v_company_no = '0410'; SET v_company_name = '胜意科技杭州分公司';
            WHEN 4 THEN SET v_company_id = '16AE93CC7EF92002'; SET v_company_no = '0411'; SET v_company_name = '胜意科技荆州分公司';
        END CASE;

        -- 6) 业务类型（叶子节点，9个随机）
        CASE (FLOOR(RAND(i * 4000 + 4) * 9))
            WHEN 0 THEN SET v_biz_type_id = '1B5FEB7DD4396000'; SET v_biz_type_no = '10010010101'; SET v_biz_type_name = '项目出差';
            WHEN 1 THEN SET v_biz_type_id = '1A92E43082EFC000'; SET v_biz_type_no = '10010010102'; SET v_biz_type_name = '市场拓展出差';
            WHEN 2 THEN SET v_biz_type_id = '13AB3A4248008002'; SET v_biz_type_no = '10010010201'; SET v_biz_type_name = '国外考察';
            WHEN 3 THEN SET v_biz_type_id = '13AB3A4154008001'; SET v_biz_type_no = '10010010202'; SET v_biz_type_name = '售后维护出差';
            WHEN 4 THEN SET v_biz_type_id = '13AB3A418F808001'; SET v_biz_type_no = '100100201'; SET v_biz_type_name = '个人团队培训';
            WHEN 5 THEN SET v_biz_type_id = '13AB3A41AC408001'; SET v_biz_type_no = '100100202'; SET v_biz_type_name = '招聘会';
            WHEN 6 THEN SET v_biz_type_id = '13AB3A41ED408002'; SET v_biz_type_no = '100100301'; SET v_biz_type_name = '员工旅游';
            WHEN 7 THEN SET v_biz_type_id = '13AB3A420CC08002'; SET v_biz_type_no = '100100302'; SET v_biz_type_name = '员工团建';
            WHEN 8 THEN SET v_biz_type_id = '13AB3A422A808001'; SET v_biz_type_no = '100100303'; SET v_biz_type_name = '员工体检';
        END CASE;

        -- 7) 出发城市（确保出发!=到达）
        SET v_departure_city_no = ELT(FLOOR(RAND(i * 5000 + 5) * 5) + 1, '10119', '10621', '10458', '10216', '10455');
        SET v_arrival_city_no = ELT(FLOOR(RAND(i * 5000 + 6) * 5) + 1, '10119', '10621', '10458', '10216', '10455');
        -- 如果相同则偏移
        IF v_arrival_city_no = v_departure_city_no THEN
            SET v_arrival_city_no = CASE
                WHEN v_departure_city_no = '10119' THEN '10621'
                ELSE '10119'
            END;
        END IF;

        -- 城市名称
        SET v_departure_city_name = CASE v_departure_city_no
            WHEN '10119' THEN '北京' WHEN '10621' THEN '上海'
            WHEN '10458' THEN '武汉' WHEN '10216' THEN '杭州'
            WHEN '10455' THEN '荆州' END;
        SET v_arrival_city_name = CASE v_arrival_city_no
            WHEN '10119' THEN '北京' WHEN '10621' THEN '上海'
            WHEN '10458' THEN '武汉' WHEN '10216' THEN '杭州'
            WHEN '10455' THEN '荆州' END;

        -- 8) 行程日期：随机1-5天，不超过创建时间
        SET v_d1 = FLOOR(RAND(i * 6000 + 7) * 30) + 1;
        SET v_d2 = FLOOR(RAND(i * 6000 + 8) * 5) + 1;
        SET v_departure_date = DATE_SUB(DATE(v_created_at), INTERVAL v_d1 DAY);
        SET v_arrival_date = DATE_ADD(v_departure_date, INTERVAL v_d2 DAY);
        SET v_days = DATEDIFF(v_arrival_date, v_departure_date) + 1;

        -- 9) 补助标准（按到达城市类型）
        SET v_city_type = CASE v_arrival_city_no
            WHEN '10119' THEN '1' WHEN '10621' THEN '1'
            WHEN '10458' THEN '2' WHEN '10216' THEN '2'
            WHEN '10455' THEN '3' END;
        SET v_meal_std = CASE v_city_type
            WHEN '1' THEN 100 WHEN '2' THEN 80 ELSE 50 END;
        SET v_transport_std = 40;
        SET v_comm_std = 40;

        -- 10) 标题和事由
        SET v_title = ELT(FLOOR(RAND(i * 7000 + 9) * 30) + 1,
            CONCAT(v_arrival_city_name, '项目现场出差'),
            CONCAT(v_arrival_city_name, '客户拜访'),
            CONCAT(v_arrival_city_name, '季度项目验收'),
            CONCAT(v_arrival_city_name, '新产品现场部署'),
            CONCAT(v_arrival_city_name, '行业展会参会'),
            CONCAT(v_arrival_city_name, '区域市场调研'),
            CONCAT(v_arrival_city_name, '跨部门协作出差'),
            CONCAT(v_arrival_city_name, '客户培训现场支持'),
            CONCAT(v_arrival_city_name, '年度例行巡检'),
            CONCAT(v_arrival_city_name, '售后问题现场处理'),
            CONCAT(v_arrival_city_name, '供应链供应商考察'),
            CONCAT(v_arrival_city_name, '招标现场答疑'),
            CONCAT(v_arrival_city_name, '合作伙伴洽谈'),
            CONCAT(v_arrival_city_name, '渠道代理商拜访'),
            CONCAT(v_arrival_city_name, '区域销售启动会'),
            CONCAT(v_arrival_city_name, '客户现场需求调研'),
            CONCAT(v_arrival_city_name, '系统上线现场支持'),
            CONCAT(v_arrival_city_name, '技术方案现场交流'),
            CONCAT(v_arrival_city_name, '安全合规现场检查'),
            CONCAT(v_arrival_city_name, '新产品演示推广'),
            CONCAT(v_arrival_city_name, '内部培训出差'),
            CONCAT(v_arrival_city_name, '人才招聘会出差'),
            CONCAT(v_arrival_city_name, '团队建设活动'),
            CONCAT(v_arrival_city_name, '员工年度体检'),
            CONCAT(v_arrival_city_name, '客户回访'),
            CONCAT(v_arrival_city_name, '产品验收评审'),
            CONCAT(v_arrival_city_name, '数据迁移现场支持'),
            CONCAT(v_arrival_city_name, '数据中心巡检'),
            CONCAT(v_arrival_city_name, '项目交付前期沟通'),
            CONCAT(v_arrival_city_name, '紧急故障现场排查')
        );

        SET v_reason = ELT(FLOOR(RAND(i * 8000 + 10) * 20) + 1,
            CONCAT('参加', v_arrival_city_name, '举办的行业交流活动'),
            CONCAT(v_arrival_city_name, '客户需求紧急，现场对接'),
            CONCAT(v_arrival_city_name, '项目进入关键阶段，需现场支持'),
            CONCAT('赴', v_arrival_city_name, '进行季度项目验收'),
            CONCAT(v_arrival_city_name, '新产品功能现场部署上线'),
            CONCAT('受邀参加', v_arrival_city_name, '行业年度展会'),
            CONCAT(v_arrival_city_name, '区域市场情况摸底调研'),
            CONCAT('与', v_arrival_city_name, '分部进行跨部门协作'),
            CONCAT('赴', v_arrival_city_name, '对客户进行产品培训'),
            CONCAT('例行巡检', v_arrival_city_name, '区域客户使用情况'),
            CONCAT(v_arrival_city_name, '客户反馈系统问题需现场排查'),
            CONCAT('赴', v_arrival_city_name, '供应商现场审核'),
            CONCAT(v_arrival_city_name, '招标项目需现场技术答疑'),
            CONCAT('与', v_arrival_city_name, '合作伙伴进行业务洽谈'),
            CONCAT('拜访', v_arrival_city_name, '区域代理商，商讨合作方案'),
            CONCAT(v_arrival_city_name, '区域销售启动会参会'),
            CONCAT('赴', v_arrival_city_name, '进行客户需求深度调研'),
            CONCAT(v_arrival_city_name, '客户系统切换上线支持'),
            CONCAT('与', v_arrival_city_name, '客户进行技术方案交流'),
            CONCAT('赴', v_arrival_city_name, '进行年度信息安全检查')
        );

        -- 11) 补助金额计算（全选所有补助项）
        SET v_total_apply = v_days * (v_meal_std + v_transport_std + v_comm_std);
        SET v_total_allowance = v_total_apply;

        -- 12) 备注
        SET v_remark = CASE FLOOR(RAND(i * 9000 + 11) * 20)
            WHEN 0 THEN NULL
            WHEN 1 THEN '单据已核对无误'
            WHEN 2 THEN '请尽快审批'
            WHEN 3 THEN '出差行程已确认'
            WHEN 4 THEN '附发票已扫描上传'
            WHEN 5 THEN '本月出差汇总'
            WHEN 6 THEN '客户现场需求紧急'
            WHEN 7 THEN '项目交付前出差'
            WHEN 8 THEN '季度例行出差'
            WHEN 9 THEN '部门团建活动'
            WHEN 10 THEN '出差期间有用车，请核减交补'
            WHEN 11 THEN '出差期间有公司用餐安排'
            WHEN 12 THEN '已与财务确认金额'
            WHEN 13 THEN '高铁往返已报销'
            WHEN 14 THEN '住宿费用另行报销'
            WHEN 15 THEN '紧急项目出差'
            WHEN 16 THEN '跨部门协作出差'
            WHEN 17 THEN '年度例行巡检'
            WHEN 18 THEN '新产品发布支持'
            WHEN 19 THEN '区域市场调研'
        END;

        -- 13) 项目（8个随机）
        CASE (FLOOR(RAND(i * 10000 + 12) * 8))
            WHEN 0 THEN SET v_project_id = '12BC248B25083001'; SET v_project_no = 'nonProjectRelated'; SET v_project_name = '非项目类费用归集';
            WHEN 1 THEN SET v_project_id = '1C811ABF96195000'; SET v_project_no = 'centralChina'; SET v_project_name = '华中客户定制化项目';
            WHEN 2 THEN SET v_project_id = '1C5931735AC4A000'; SET v_project_no = 'southChina'; SET v_project_name = '华南客户定制化项目';
            WHEN 3 THEN SET v_project_id = '1771EC45F2443000'; SET v_project_no = 'northChina'; SET v_project_name = '华北客户定制化项目';
            WHEN 4 THEN SET v_project_id = '1762792DB4E9A002'; SET v_project_no = 'eastChina'; SET v_project_name = '华东客户定制化项目';
            WHEN 5 THEN SET v_project_id = '17071065FC29A002'; SET v_project_no = 'southWest'; SET v_project_name = '西南客户定制化项目';
            WHEN 6 THEN SET v_project_id = '162664EBE9ABE001'; SET v_project_no = 'northWest'; SET v_project_name = '西北客户定制化项目';
            WHEN 7 THEN SET v_project_id = '162664B8526BE002'; SET v_project_no = 'northEast'; SET v_project_name = '东北客户定制化项目';
        END CASE;

        -- ==================== 插入 reimbursement 主表 ====================
        INSERT INTO reimbursement (
            document_no, status, title, reason,
            company_id, department_id, reimburser_id, business_type_id,
            total_allowance_amount, remark, content, created_at
        ) VALUES (
            v_doc_no, v_status, v_title, v_reason,
            v_company_id, v_dept_id, v_reimburser_id, v_biz_type_id,
            v_total_allowance, v_remark, '{}', v_created_at
        );
        SET v_rid = LAST_INSERT_ID();

        -- ==================== 插入补录行程 ====================
        INSERT INTO reimbursement_travel_record (
            reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,
            departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,
            departure_date, arrival_date, description
        ) VALUES (
            v_rid, CONCAT('travel_', LPAD(i + 1, 6, '0'), '_001'),
            v_reimburser_id, v_reimburser_name, v_reimburser_no,
            v_departure_city_no, v_departure_city_name, v_arrival_city_no, v_arrival_city_name,
            v_departure_date, v_arrival_date,
            CONCAT(v_departure_city_name, '至', v_arrival_city_name, '，', v_biz_type_name, '相关行程')
        );

        -- ==================== 插入补助信息 ====================
        INSERT INTO reimbursement_allowance (
            reimbursement_id, allowance_key, travel_record_key,
            reimburser_id, reimburser_name, departure_date, arrival_date,
            allowance_days, departure_city, arrival_city,
            total_apply_amount, total_allowance_amount
        ) VALUES (
            v_rid, CONCAT('allowance_', LPAD(i + 1, 6, '0'), '_001'),
            CONCAT('travel_', LPAD(i + 1, 6, '0'), '_001'),
            v_reimburser_id, v_reimburser_name, v_departure_date, v_arrival_date,
            v_days, v_departure_city_name, v_arrival_city_name,
            v_total_apply, v_total_allowance
        );
        SET v_aid = LAST_INSERT_ID();

        -- ==================== 插入补助日历（按天生成） ====================
        SET v_day_idx = 0;
        SET v_cal_date = v_departure_date;

        WHILE v_day_idx < v_days DO
            -- 星期几（1=周日, 2=周一, ..., 7=周六 -> 转中文）
            SET v_weekday = CASE DAYOFWEEK(v_cal_date)
                WHEN 1 THEN '星期日' WHEN 2 THEN '星期一' WHEN 3 THEN '星期二'
                WHEN 4 THEN '星期三' WHEN 5 THEN '星期四' WHEN 6 THEN '星期五'
                WHEN 7 THEN '星期六' END;

            INSERT INTO reimbursement_allowance_calendar (
                allowance_id, calendar_date, weekday,
                meal_allowance, transport_allowance, communication_allowance,
                meal_selected, transport_selected, communication_selected,
                meal_amount, transport_amount, communication_amount
            ) VALUES (
                v_aid, v_cal_date, v_weekday,
                v_meal_std, v_transport_std, v_comm_std,
                1, 1, 1,
                v_meal_std, v_transport_std, v_comm_std
            );

            SET v_day_idx = v_day_idx + 1;
            SET v_cal_date = DATE_ADD(v_cal_date, INTERVAL 1 DAY);
        END WHILE;

        -- ==================== 插入费用分摊（1-3行） ====================
        SET v_alloc_count = FLOOR(RAND(i * 11000 + 13) * 3) + 1;
        SET v_alloc_idx = 0;
        SET v_sum_alloc = 0;

        WHILE v_alloc_idx < v_alloc_count DO
            IF v_alloc_count = 1 THEN
                -- 仅一行：100%
                SET v_alloc_ratio = 1.0000;
                SET v_alloc_amount = v_total_allowance;
            ELSEIF v_alloc_idx = 0 THEN
                -- 第一行：等均摊后再减
                SET v_alloc_ratio = 0;
                SET v_alloc_amount = 0;
            ELSE
                -- 第2+行：均分比例
                SET v_base_ratio = ROUND(1.0 / v_alloc_count, 4);
                SET v_alloc_ratio = v_base_ratio;
                SET v_alloc_amount = ROUND(v_total_allowance * v_base_ratio, 2);
                SET v_sum_alloc = v_sum_alloc + v_alloc_amount;
            END IF;

            INSERT INTO reimbursement_cost_allocation (
                reimbursement_id, allocation_key,
                company_id, company_name, company_no,
                project_id, project_name, project_no,
                ratio, amount, sort_order
            ) VALUES (
                v_rid, CONCAT('alloc_', LPAD(i + 1, 6, '0'), '_', LPAD(v_alloc_idx + 1, 2, '0')),
                v_company_id, v_company_name, v_company_no,
                v_project_id, v_project_name, v_project_no,
                v_alloc_ratio, v_alloc_amount, v_alloc_idx
            );

            SET v_alloc_idx = v_alloc_idx + 1;
        END WHILE;

        -- 修正第一行分摊（兜底余额）
        IF v_alloc_count > 1 THEN
            SET v_alloc_ratio = ROUND(1.0 - (v_alloc_count - 1) * ROUND(1.0 / v_alloc_count, 4), 4);
            SET v_alloc_amount = v_total_allowance - v_sum_alloc;

            UPDATE reimbursement_cost_allocation
            SET ratio = v_alloc_ratio, amount = v_alloc_amount
            WHERE reimbursement_id = v_rid AND sort_order = 0;
        END IF;

        -- ==================== 更新 content JSON ====================
        SET v_content = JSON_OBJECT(
            'id', CAST(v_rid AS CHAR),
            'documentNo', v_doc_no,
            'status', v_status,
            'createdAt', DATE_FORMAT(v_created_at, '%Y-%m-%d'),
            'basicInfo', JSON_OBJECT(
                'title', v_title,
                'reason', v_reason,
                'reimburserId', v_reimburser_id,
                'reimburserName', v_reimburser_name,
                'reimburserNo', v_reimburser_no,
                'departmentId', v_dept_id,
                'departmentName', v_dept_name,
                'departmentNo', v_dept_no,
                'companyId', v_company_id,
                'companyName', v_company_name,
                'companyNo', v_company_no,
                'businessTypeId', v_biz_type_id,
                'businessTypeName', v_biz_type_name,
                'businessTypeNo', v_biz_type_no
            ),
            'totalAllowanceAmount', v_total_allowance,
            'remark', IFNULL(v_remark, '')
        );

        UPDATE reimbursement SET content = v_content WHERE id = v_rid;

        SET i = i + 1;
    END WHILE;

    SELECT CONCAT('成功生成 ', i, ' 条测试报销单数据') AS result;
END$$

DELIMITER ;

-- 执行生成
CALL generate_test_data();

-- 清理存储过程
DROP PROCEDURE IF EXISTS cleanup_test_data;
DROP PROCEDURE IF EXISTS generate_test_data;

-- 验证数据
SELECT COUNT(*) AS total_reimbursement FROM reimbursement WHERE document_no LIKE 'REIMTEST%';
SELECT COUNT(*) AS total_travel_record FROM reimbursement_travel_record WHERE reimbursement_id IN (SELECT id FROM reimbursement WHERE document_no LIKE 'REIMTEST%');
SELECT COUNT(*) AS total_allowance FROM reimbursement_allowance WHERE reimbursement_id IN (SELECT id FROM reimbursement WHERE document_no LIKE 'REIMTEST%');
SELECT COUNT(*) AS total_calendar FROM reimbursement_allowance_calendar WHERE allowance_id IN (SELECT id FROM reimbursement_allowance WHERE reimbursement_id IN (SELECT id FROM reimbursement WHERE document_no LIKE 'REIMTEST%'));
SELECT COUNT(*) AS total_cost_allocation FROM reimbursement_cost_allocation WHERE reimbursement_id IN (SELECT id FROM reimbursement WHERE document_no LIKE 'REIMTEST%');
