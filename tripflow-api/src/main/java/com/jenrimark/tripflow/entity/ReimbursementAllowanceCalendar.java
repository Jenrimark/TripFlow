package com.jenrimark.tripflow.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@TableName("reimbursement_allowance_calendar")
public class ReimbursementAllowanceCalendar {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long allowanceId;
    private LocalDate calendarDate;
    private String weekday;
    private BigDecimal mealAllowance;
    private BigDecimal transportAllowance;
    private BigDecimal communicationAllowance;
    private Boolean mealSelected;
    private Boolean transportSelected;
    private Boolean communicationSelected;
    private BigDecimal mealAmount;
    private BigDecimal transportAmount;
    private BigDecimal communicationAmount;
}
