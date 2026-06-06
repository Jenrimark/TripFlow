package com.jenrimark.tripflow.dto.reimbursement;

import lombok.Data;

import java.util.List;

@Data
public class ReimbursementAllowanceGenerateResult {

    private List<ReimbursementDto.AllowanceInfo> allowances;
    private Double totalAllowanceAmount;
    private Double totalMealAmount;
    private Double totalTransportAmount;
    private Double totalCommunicationAmount;
}
