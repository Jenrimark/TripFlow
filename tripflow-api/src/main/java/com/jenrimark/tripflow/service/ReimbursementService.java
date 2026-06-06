package com.jenrimark.tripflow.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementAllowanceGenerateResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementExpenseSummaryResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementListResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementRemarkRequest;
import com.jenrimark.tripflow.entity.ReimbursementRecord;

import java.util.List;

public interface ReimbursementService extends IService<ReimbursementRecord> {

    ReimbursementListResult list(
            String documentNo,
            String title,
            String reason,
            List<String> companyIds,
            List<String> departmentIds,
            List<String> reimburserIds,
            List<String> businessTypeIds,
            int page,
            int pageSize);

    ReimbursementDto getDetail(Long id);

    ReimbursementDto create(ReimbursementDto dto);

    ReimbursementDto update(Long id, ReimbursementDto dto);

    ReimbursementDto updateRemark(Long id, ReimbursementRemarkRequest request);

    ReimbursementDto clearRemark(Long id);

    ReimbursementAllowanceGenerateResult generateAllowances(Long id);

    ReimbursementExpenseSummaryResult calculateExpenseSummary(Long id);

    List<ReimbursementDto.CostAllocation> listCostAllocations(Long id);

    List<ReimbursementDto.CostAllocation> evenlyDistributeCostAllocations(Long id);

    ReimbursementDto.CostAllocation addCostAllocation(Long id, ReimbursementDto.CostAllocation costAllocation);

    ReimbursementDto.CostAllocation updateCostAllocation(
            Long id,
            String allocationKey,
            ReimbursementDto.CostAllocation costAllocation);

    void deleteCostAllocation(Long id, String allocationKey);

    List<ReimbursementDto.TravelRecord> listTravelRecords(Long id);

    ReimbursementDto.TravelRecord getTravelRecord(Long id, String recordKey);

    ReimbursementDto.TravelRecord addTravelRecord(Long id, ReimbursementDto.TravelRecord travelRecord);

    ReimbursementDto.TravelRecord updateTravelRecord(Long id, String recordKey, ReimbursementDto.TravelRecord travelRecord);

    void deleteTravelRecord(Long id, String recordKey);

    void delete(Long id);

    void submit(Long id);

    void voidDocument(Long id);
}
