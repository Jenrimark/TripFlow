-- V6: 回填 departure_datetime / arrival_datetime 及 content JSON 中的 datetime 字段
-- 对 departure_datetime / arrival_datetime 为 NULL 的记录，使用：
--   departure_datetime = departure_date 08:00:00
--   arrival_datetime   = arrival_date   18:00:00

USE tripflow;

-- 1. 回填 reimbursement_travel_record 表的 datetime 列
UPDATE reimbursement_travel_record
SET departure_datetime = CONCAT(departure_date, ' 08:00:00'),
    arrival_datetime   = CONCAT(arrival_date,   ' 18:00:00')
WHERE departure_datetime IS NULL;

-- 2. 回填 reimbursement.content JSON 中 travelRecords 的 departureDatetime / arrivalDatetime
--    使用 JSON_MERGE_PATCH 覆盖已有值，确保所有记录都有 datetime
UPDATE reimbursement r
SET content = JSON_SET(
    content,
    '$.travelRecords',
    (
        SELECT JSON_ARRAYAGG(
            JSON_MERGE_PATCH(
                tr.value,
                JSON_OBJECT(
                    'departureDatetime', CONCAT(JSON_UNQUOTE(JSON_EXTRACT(tr.value, '$.departureDate')), ' 08:00:00'),
                    'arrivalDatetime',   CONCAT(JSON_UNQUOTE(JSON_EXTRACT(tr.value, '$.arrivalDate')),   ' 18:00:00')
                )
            )
        )
        FROM JSON_TABLE(r.content, '$.travelRecords[*]' COLUMNS (value JSON PATH '$')) tr
    )
)
WHERE JSON_CONTAINS_PATH(content, 'one', '$.travelRecords')
  AND JSON_LENGTH(JSON_EXTRACT(content, '$.travelRecords')) > 0;
