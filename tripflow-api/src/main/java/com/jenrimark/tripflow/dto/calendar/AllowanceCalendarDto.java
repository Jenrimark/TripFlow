package com.jenrimark.tripflow.dto.calendar;

import lombok.Data;

/**
 * 补助日历项查询返回 DTO。
 */
@Data
public class AllowanceCalendarDto {
    private Long id;
    private String date;
    private String weekday;
    private Double mealAllowance;
    private Double transportAllowance;
    private Double communicationAllowance;
    private Boolean mealSelected;
    private Boolean transportSelected;
    private Boolean communicationSelected;
    private Double mealAmount;
    private Double transportAmount;
    private Double communicationAmount;
}