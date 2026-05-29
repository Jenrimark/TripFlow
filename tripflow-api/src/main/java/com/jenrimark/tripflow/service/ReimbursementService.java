package com.jenrimark.tripflow.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementListResult;
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

    void delete(Long id);

    void submit(Long id);

    void voidDocument(Long id);
}
