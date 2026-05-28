package com.jenrimark.tripflow.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("expense_report")
public class ExpenseReport {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String title;

    private String tripDestination;

    private LocalDate tripStartDate;

    private LocalDate tripEndDate;

    private BigDecimal amount;

    /** draft | pending | approved | rejected */
    private String status;

    private Long applicantId;

    private LocalDateTime createdAt;
}
