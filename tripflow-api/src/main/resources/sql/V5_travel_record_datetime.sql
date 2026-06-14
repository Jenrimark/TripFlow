-- V5: 补录行程增加出发/到达精确时间
-- 对应前端 datetimerange 选择器，精确到秒

ALTER TABLE reimbursement_travel_record
  ADD COLUMN departure_datetime DATETIME DEFAULT NULL COMMENT '出发时间' AFTER arrival_date,
  ADD COLUMN arrival_datetime   DATETIME DEFAULT NULL COMMENT '到达时间' AFTER departure_datetime;
