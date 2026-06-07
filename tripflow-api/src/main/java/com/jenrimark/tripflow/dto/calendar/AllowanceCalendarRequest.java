package com.jenrimark.tripflow.dto.calendar;

import lombok.Data;

/**
 * 补助日历项请求 DTO（增/改/批量共用）。
 * id 字段：新增时不填，批量时必填。
 */
@Data
public class AllowanceCalendarRequest {
    /** 日历项ID，批量更新时必填，新增时可不填 */
    private Long id;
    /** 日期 (yyyy-MM-dd)，新增时必填 */
    private String date;
    /** 星期几，如"星期一"，新增时必填 */
    private String weekday;
    /** 餐费标准 */
    private Double mealAllowance;
    /** 交通标准 */
    private Double transportAllowance;
    /** 通讯标准 */
    private Double communicationAllowance;
    /** 餐费勾选状态 */
    private Boolean mealSelected;
    /** 交通勾选状态 */
    private Boolean transportSelected;
    /** 通讯勾选状态 */
    private Boolean communicationSelected;
    /** 餐费实际金额 */
    private Double mealAmount;
    /** 交通实际金额 */
    private Double transportAmount;
    /** 通讯实际金额 */
    private Double communicationAmount;
}