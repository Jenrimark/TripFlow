package com.jenrimark.tripflow.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;

@Data
@TableName("reimbursement_cost_allocation")
public class ReimbursementCostAllocation {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long reimbursementId;
    private String allocationKey;
    private String companyId;
    private String companyName;
    private String companyNo;
    private String projectId;
    private String projectName;
    private String projectNo;
    private BigDecimal ratio;
    private BigDecimal amount;
    private Integer sortOrder;
}
