package com.jenrimark.tripflow.dto.reimbursement;

import lombok.Data;

@Data
public class ReimbursementExpenseSummaryResult {

    private String documentNo;
    private Double totalAllowanceAmount;
    private Double totalMealAmount;
    private Double totalTransportAmount;
    private Double totalCommunicationAmount;
}
