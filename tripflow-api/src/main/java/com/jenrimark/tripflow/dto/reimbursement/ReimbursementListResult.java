package com.jenrimark.tripflow.dto.reimbursement;

import lombok.Data;

import java.util.List;

@Data
public class ReimbursementListResult {

    private List<ReimbursementDto> list;
    private long total;
    private int page;
    private int pageSize;
}
