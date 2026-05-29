package com.jenrimark.tripflow.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("reimbursement")
public class ReimbursementRecord {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String documentNo;

    private Integer status;

    private String title;

    private String reason;

    private String companyId;

    private String departmentId;

    private String reimburserId;

    private String businessTypeId;

    private BigDecimal totalAllowanceAmount;

    private String remark;

    /** 完整报销单 JSON */
    private String content;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
