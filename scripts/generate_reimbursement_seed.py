#!/usr/bin/env python3
"""生成差旅报销单批量种子 SQL（依据 V2 主数据 + 概要设计补助标准）"""

import json
import random
from datetime import date, timedelta
from pathlib import Path

COUNT = 55  # 含 V3 已有 3 条风格的样本，总计至少 50

COMPANIES = [
    ("1C54557F1782E000", "0407", "胜意科技北京分公司"),
    ("19218A262C976000", "0408", "胜意科技上海分公司"),
    ("1C61686865DA8000", "0409", "胜意科技武汉分公司"),
    ("1717271D1DA15000", "0410", "胜意科技杭州分公司"),
    ("16AE93CC7EF92002", "0411", "胜意科技荆州分公司"),
]

DEPARTMENTS = [
    ("13AB8D7B52A9B002", "072001", "客户成功事业部"),
    ("13BFD31C6029A002", "072002", "企业消费事业部"),
    ("14515BB4BFB92003", "072003", "企业费控事业部"),
    ("19206611C47A6000", "072004", "集采事业部"),
    ("19D32F9FE9647000", "072005", "航旅事业部"),
    ("13C7E2BAE0393001", "072006", "运营事业部"),
    ("14055D22BB808001", "072007", "营销事业部"),
]

REIMBURSERS = [
    ("13AB3A3F72409002", "74541", "徐年年", "13AB8D7B52A9B002"),
    ("13AB498CC6409002", "74008", "郑雨雪", "13BFD31C6029A002"),
    ("13AB4A56BB009002", "21552", "邹薇", "14515BB4BFB92003"),
    ("13AB591FE8009002", "80681", "王成军", "19206611C47A6000"),
    ("13AB77281A408001", "89899", "潘展飞", "19D32F9FE9647000"),
    ("13AB7925EB808001", "10503", "姜林", "13C7E2BAE0393001"),
]

# 叶子业务类型
BUSINESS_TYPES = [
    ("1B5FEB7DD4396000", "10010010101", "项目出差"),
    ("1A92E43082EFC000", "10010010102", "市场拓展出差"),
    ("13AB3A4248008002", "10010010201", "国外考察"),
    ("13AB3A4154008001", "10010010202", "售后维护出差"),
    ("13AB3A418F808001", "100100201", "个人团队培训"),
    ("13AB3A41AC408001", "100100202", "招聘会"),
    ("13AB3A41ED408002", "100100301", "员工旅游"),
    ("13AB3A420CC08002", "100100302", "员工团建"),
    ("13AB3A422A808001", "100100303", "员工体检"),
]

CITIES = [
    ("10119", "北京", "1"),
    ("10621", "上海", "1"),
    ("10458", "武汉", "2"),
    ("10216", "杭州", "2"),
    ("10455", "荆州", "3"),
]

PROJECTS = [
    ("12BC248B25083001", "nonProjectRelated", "非项目类费用归集"),
    ("1C811ABF96195000", "centralChina", "华中客户定制化项目"),
    ("1C5931735AC4A000", "southChina", "华南客户定制化项目"),
    ("1771EC45F2443000", "northChina", "华北客户定制化项目"),
    ("1762792DB4E9A002", "eastChina", "华东客户定制化项目"),
    ("17071065FC29A002", "southWest", "西南客户定制化项目"),
    ("162664EBE9ABE001", "northWest", "西北客户定制化项目"),
    ("162664B8526BE002", "northEast", "东北客户定制化项目"),
]

DEPT_MAP = {d[0]: d for d in DEPARTMENTS}
COMPANY_MAP = {c[0]: c for c in COMPANIES}

WEEKDAYS = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"]

TITLE_TEMPLATES = {
    "项目出差": ["{city}客户项目现场支持", "{city}定制化项目实施", "{city}客户需求调研"],
    "市场拓展出差": ["{city}行业展会参展", "{city}区域市场拓展", "{city}渠道合作洽谈"],
    "国外考察": ["海外市场考察行程", "国际合作伙伴拜访"],
    "售后维护出差": ["{city}客户售后维护", "{city}系统故障排查", "{city}驻场技术支持"],
    "个人团队培训": ["{city}专业技能培训", "团队管理能力提升培训"],
    "招聘会": ["{city}春季校园招聘", "{city}社会招聘专场"],
    "员工旅游": ["{city}年度员工旅游", "部门团建旅游"],
    "员工团建": ["{city}团队建设活动", "季度团建拓展"],
    "员工体检": ["{city}年度健康体检", "入职专项体检"],
}

REASON_TEMPLATES = [
    "根据业务安排前往{arr}开展{type}相关工作",
    "应{city}分公司邀请，执行{type}任务",
    "配合{project}项目进度，赴{arr}现场办公",
    "参加{arr}举办的行业交流活动",
]

REMARKS = [
    "",
    "出差期间部分餐费由客户承担，已核减",
    "展会期间公司提供用车，已核减交通补助",
    "行程紧凑，备注备查",
    "单据已核对无误",
    "行程取消，单据作废",
]

STATUS_WEIGHTS = [(1, 35), (0, 14), (2, 6)]  # 已完成 / 草稿 / 已作废


def pick_status(rng: random.Random) -> int:
    total = sum(w for _, w in STATUS_WEIGHTS)
    n = rng.randint(1, total)
    acc = 0
    for status, w in STATUS_WEIGHTS:
        acc += w
        if n <= acc:
            return status
    return 1


def daily_rates(city_type: str) -> tuple[int, int, int]:
    if city_type == "1":
        return 100, 40, 40
    if city_type == "2":
        return 80, 40, 40
    return 50, 40, 40


def build_calendar(start: date, days: int, arrival: tuple) -> list[dict]:
    _, _, city_type = arrival
    meal_std, trans_std, comm_std = daily_rates(city_type)
    items = []
    for i in range(days):
        d = start + timedelta(days=i)
        weekday = WEEKDAYS[d.weekday()]
        # 约 15% 天核减餐补
        meal_sel = random.random() > 0.15
        trans_sel = True
        comm_sel = True
        items.append({
            "date": d.isoformat(),
            "weekday": weekday,
            "mealAllowance": meal_std,
            "transportAllowance": trans_std,
            "communicationAllowance": comm_std,
            "mealSelected": meal_sel,
            "transportSelected": trans_sel,
            "communicationSelected": comm_sel,
            "mealAmount": meal_std if meal_sel else 0,
            "transportAmount": trans_std if trans_sel else 0,
            "communicationAmount": comm_std if comm_sel else 0,
        })
    return items


def sum_allowance(calendar: list[dict]) -> tuple[float, float, float, float]:
    meal = sum(c["mealAmount"] for c in calendar)
    trans = sum(c["transportAmount"] for c in calendar)
    comm = sum(c["communicationAmount"] for c in calendar)
    return meal + trans + comm, meal, trans, comm


def sql_str(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "''") + "'"


def generate_record(seq: int, rng: random.Random) -> dict:
    reimb = rng.choice(REIMBURSERS)
    r_id, r_no, r_name, dept_id = reimb
    dept = DEPT_MAP[dept_id]
    company = rng.choice(COMPANIES)
    biz = rng.choice(BUSINESS_TYPES)
    biz_id, biz_no, biz_name = biz
    project = rng.choice(PROJECTS)

    dep_city, arr_city = rng.sample(CITIES, 2)
    trip_days = rng.randint(1, 5)
    start_offset = rng.randint(0, 120)
    start = date(2025, 1, 15) + timedelta(days=start_offset)
    end = start + timedelta(days=trip_days - 1)

    status = pick_status(rng)
    if status == 2:
        remark = "行程取消，单据作废"
    else:
        remark = rng.choice([r for r in REMARKS if r != "行程取消，单据作废"])

    arr_name = arr_city[1]
    templates = TITLE_TEMPLATES.get(biz_name, ["{city}出差"])
    title = rng.choice(templates).format(city=arr_name)
    reason = rng.choice(REASON_TEMPLATES).format(
        city=arr_name, arr=arr_name, type=biz_name, project=project[2]
    )

    doc_no = f"REIM{start.strftime('%Y%m%d')}{seq:04d}"
    travel_key = f"travel_{seq:04d}"
    allowance_key = f"allowance_{seq:04d}"
    alloc_key = f"alloc_{seq:04d}"

    calendar = build_calendar(start, trip_days, arr_city)
    total, meal_t, trans_t, comm_t = sum_allowance(calendar)
    apply_total = sum(
        daily_rates(arr_city[2])[0] + daily_rates(arr_city[2])[1] + daily_rates(arr_city[2])[2]
        for _ in range(trip_days)
    )

    dto = {
        "id": str(seq),
        "documentNo": doc_no,
        "status": status,
        "createdAt": start.isoformat(),
        "basicInfo": {
            "title": title,
            "reason": reason,
            "reimburserId": r_id,
            "reimburserName": r_name,
            "reimburserNo": r_no,
            "departmentId": dept_id,
            "departmentName": dept[2],
            "departmentNo": dept[1],
            "companyId": company[0],
            "companyName": company[2],
            "companyNo": company[1],
            "businessTypeId": biz_id,
            "businessTypeName": biz_name,
            "businessTypeNo": biz_no,
        },
        "travelRecords": [{
            "id": travel_key,
            "reimburserId": r_id,
            "reimburserName": r_name,
            "reimburserNo": r_no,
            "departureCityId": dep_city[0],
            "departureCityName": dep_city[1],
            "arrivalCityId": arr_city[0],
            "arrivalCityName": arr_city[1],
            "departureDate": start.isoformat(),
            "arrivalDate": end.isoformat(),
            "description": f"{dep_city[1]}至{arr_name}，{biz_name}相关行程",
        }],
        "allowances": [{
            "id": allowance_key,
            "travelRecordId": travel_key,
            "reimburserId": r_id,
            "reimburserName": r_name,
            "departureDate": start.isoformat(),
            "arrivalDate": end.isoformat(),
            "allowanceDays": trip_days,
            "departureCity": dep_city[1],
            "arrivalCity": arr_name,
            "calendar": calendar,
            "totalApplyAmount": apply_total,
            "totalAllowanceAmount": total,
        }],
        "costAllocations": [{
            "id": alloc_key,
            "companyId": company[0],
            "companyName": company[2],
            "companyNo": company[1],
            "projectId": project[0],
            "projectName": project[2],
            "projectNo": project[1],
            "ratio": 1.0,
            "amount": total,
        }],
        "remark": remark,
        "totalAllowanceAmount": total,
        "totalMealAmount": meal_t,
        "totalTransportAmount": trans_t,
        "totalCommunicationAmount": comm_t,
    }

    created_at = f"{start.isoformat()} {rng.randint(8, 18):02d}:{rng.randint(0, 59):02d}:00"

    return {
        "seq": seq,
        "doc_no": doc_no,
        "status": status,
        "title": title,
        "reason": reason,
        "company_id": company[0],
        "department_id": dept_id,
        "reimburser_id": r_id,
        "business_type_id": biz_id,
        "total": total,
        "remark": remark,
        "content": json.dumps(dto, ensure_ascii=False),
        "created_at": created_at,
        "travel_key": travel_key,
        "allowance_key": allowance_key,
        "alloc_key": alloc_key,
        "reimb": reimb,
        "dep_city": dep_city,
        "arr_city": arr_city,
        "start": start,
        "end": end,
        "trip_days": trip_days,
        "calendar": calendar,
        "company": company,
        "project": project,
        "description": dto["travelRecords"][0]["description"],
        "apply_total": apply_total,
    }


def emit_sql(records: list[dict]) -> str:
    lines = [
        "-- TripFlow 差旅报销单批量种子数据（自动生成）",
        "-- 依据：V2_reimbursement_schema.sql、概要设计.md、database-schema-mermaid.md",
        f"-- 共 {len(records)} 条，可重复执行（按 document_no 幂等）",
        "",
        "USE tripflow;",
        "",
    ]

    for rec in records:
        lines.append(f"-- {rec['doc_no']} status={rec['status']} {rec['title']}")
        lines.append("INSERT INTO reimbursement (")
        lines.append("    document_no, status, title, reason,")
        lines.append("    company_id, department_id, reimburser_id, business_type_id,")
        lines.append("    total_allowance_amount, remark, content, created_at")
        lines.append(") VALUES (")
        lines.append(f"    {sql_str(rec['doc_no'])}, {rec['status']},")
        lines.append(f"    {sql_str(rec['title'])}, {sql_str(rec['reason'])},")
        lines.append(f"    {sql_str(rec['company_id'])}, {sql_str(rec['department_id'])},")
        lines.append(f"    {sql_str(rec['reimburser_id'])}, {sql_str(rec['business_type_id'])},")
        lines.append(f"    {rec['total']:.2f}, {sql_str(rec['remark'])}, {sql_str(rec['content'])}, {sql_str(rec['created_at'])}")
        lines.append(") ON DUPLICATE KEY UPDATE")
        lines.append("    status = VALUES(status),")
        lines.append("    title = VALUES(title),")
        lines.append("    reason = VALUES(reason),")
        lines.append("    total_allowance_amount = VALUES(total_allowance_amount),")
        lines.append("    remark = VALUES(remark),")
        lines.append("    content = VALUES(content);")
        lines.append("")
        lines.append(f"SET @rid = (SELECT id FROM reimbursement WHERE document_no = {sql_str(rec['doc_no'])});")
        lines.append("DELETE FROM reimbursement_allowance_calendar WHERE allowance_id IN (")
        lines.append("    SELECT id FROM reimbursement_allowance WHERE reimbursement_id = @rid")
        lines.append(");")
        lines.append("DELETE FROM reimbursement_allowance WHERE reimbursement_id = @rid;")
        lines.append("DELETE FROM reimbursement_travel_record WHERE reimbursement_id = @rid;")
        lines.append("DELETE FROM reimbursement_cost_allocation WHERE reimbursement_id = @rid;")
        lines.append("")

        r_id, r_no, r_name, _ = rec["reimb"]
        dep, arr = rec["dep_city"], rec["arr_city"]
        lines.append("INSERT INTO reimbursement_travel_record (")
        lines.append("    reimbursement_id, record_key, reimburser_id, reimburser_name, reimburser_no,")
        lines.append("    departure_city_id, departure_city_name, arrival_city_id, arrival_city_name,")
        lines.append("    departure_date, arrival_date, description")
        lines.append(") VALUES (")
        lines.append(f"    @rid, {sql_str(rec['travel_key'])}, {sql_str(r_id)}, {sql_str(r_name)}, {sql_str(r_no)},")
        lines.append(f"    {sql_str(dep[0])}, {sql_str(dep[1])}, {sql_str(arr[0])}, {sql_str(arr[1])},")
        lines.append(f"    {sql_str(rec['start'].isoformat())}, {sql_str(rec['end'].isoformat())}, {sql_str(rec['description'])}")
        lines.append(");")
        lines.append("")
        lines.append("INSERT INTO reimbursement_allowance (")
        lines.append("    reimbursement_id, allowance_key, travel_record_key,")
        lines.append("    reimburser_id, reimburser_name, departure_date, arrival_date,")
        lines.append("    allowance_days, departure_city, arrival_city,")
        lines.append("    total_apply_amount, total_allowance_amount")
        lines.append(") VALUES (")
        lines.append(f"    @rid, {sql_str(rec['allowance_key'])}, {sql_str(rec['travel_key'])},")
        lines.append(f"    {sql_str(r_id)}, {sql_str(r_name)}, {sql_str(rec['start'].isoformat())}, {sql_str(rec['end'].isoformat())},")
        lines.append(f"    {rec['trip_days']}, {sql_str(dep[1])}, {sql_str(arr[1])},")
        lines.append(f"    {rec['apply_total']:.2f}, {rec['total']:.2f}")
        lines.append(");")
        lines.append("SET @aid = LAST_INSERT_ID();")
        lines.append("")

        cal_rows = []
        for c in rec["calendar"]:
            cal_rows.append(
                f"(@aid, {sql_str(c['date'])}, {sql_str(c['weekday'])}, "
                f"{c['mealAllowance']}, {c['transportAllowance']}, {c['communicationAllowance']}, "
                f"{1 if c['mealSelected'] else 0}, {1 if c['transportSelected'] else 0}, {1 if c['communicationSelected'] else 0}, "
                f"{c['mealAmount']}, {c['transportAmount']}, {c['communicationAmount']})"
            )
        lines.append("INSERT INTO reimbursement_allowance_calendar (")
        lines.append("    allowance_id, calendar_date, weekday,")
        lines.append("    meal_allowance, transport_allowance, communication_allowance,")
        lines.append("    meal_selected, transport_selected, communication_selected,")
        lines.append("    meal_amount, transport_amount, communication_amount")
        lines.append(") VALUES")
        lines.append(",\n".join(cal_rows) + ";")
        lines.append("")

        comp = rec["company"]
        proj = rec["project"]
        lines.append("INSERT INTO reimbursement_cost_allocation (")
        lines.append("    reimbursement_id, allocation_key, company_id, company_name, company_no,")
        lines.append("    project_id, project_name, project_no, ratio, amount, sort_order")
        lines.append(") VALUES (")
        lines.append(f"    @rid, {sql_str(rec['alloc_key'])}, {sql_str(comp[0])}, {sql_str(comp[2])}, {sql_str(comp[1])},")
        lines.append(f"    {sql_str(proj[0])}, {sql_str(proj[2])}, {sql_str(proj[1])}, 1.0000, {rec['total']:.2f}, 0")
        lines.append(");")
        lines.append("")

    return "\n".join(lines)


def main():
    rng = random.Random(42)
    records = [generate_record(i, rng) for i in range(1, COUNT + 1)]

    sql = emit_sql(records)
    out_paths = [
        Path(__file__).resolve().parent.parent / "tripflow-api/src/main/resources/sql/V4_bulk_reimbursement_data.sql",
        Path(__file__).resolve().parent.parent / "docs/sql/V4_bulk_reimbursement_data.sql",
    ]
    for p in out_paths:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(sql, encoding="utf-8")
        print(f"Wrote {p} ({len(records)} records)")


if __name__ == "__main__":
    main()
