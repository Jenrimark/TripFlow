package com.jenrimark.tripflow.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@TableName("reimbursement_allowance")
public class ReimbursementAllowance {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long reimbursementId;
    private String allowanceKey;
    private String travelRecordKey;
    private String reimburserId;
    private String reimburserName;
    private LocalDate departureDate;
    private LocalDate arrivalDate;
    private Integer allowanceDays;
    private String departureCity;
    private String arrivalCity;
    private BigDecimal totalApplyAmount;
    private BigDecimal totalAllowanceAmount;
}
