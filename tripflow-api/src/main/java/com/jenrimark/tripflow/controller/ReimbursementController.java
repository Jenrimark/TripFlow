package com.jenrimark.tripflow.controller;

import com.jenrimark.tripflow.dto.reimbursement.ReimbursementAllowanceGenerateResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementExpenseSummaryResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementListResult;
import com.jenrimark.tripflow.service.ReimbursementService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/reimbursement")
public class ReimbursementController {

    private final ReimbursementService reimbursementService;

    public ReimbursementController(ReimbursementService reimbursementService) {
        this.reimbursementService = reimbursementService;
    }

    @GetMapping
    public ReimbursementListResult list(
            @RequestParam(required = false) String documentNo,
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String reason,
            @RequestParam(required = false) List<String> companyIds,
            @RequestParam(required = false) List<String> departmentIds,
            @RequestParam(required = false) List<String> reimburserIds,
            @RequestParam(required = false) List<String> businessTypeIds,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        return reimbursementService.list(
                documentNo, title, reason, companyIds, departmentIds, reimburserIds, businessTypeIds, page, pageSize);
    }

    @GetMapping("/{id}")
    public ReimbursementDto detail(@PathVariable Long id) {
        return wrap(() -> reimbursementService.getDetail(id));
    }

    @GetMapping("/{id}/expense-summary")
    public ReimbursementExpenseSummaryResult expenseSummary(@PathVariable Long id) {
        return wrap(() -> reimbursementService.calculateExpenseSummary(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ReimbursementDto create(@RequestBody ReimbursementDto dto) {
        return wrap(() -> reimbursementService.create(dto));
    }

    @PutMapping("/{id}")
    public ReimbursementDto update(@PathVariable Long id, @RequestBody ReimbursementDto dto) {
        return wrap(() -> reimbursementService.update(id, dto));
    }

    /**
     * 查询现有的补助行程，自动生成补助信息并落盘
     * */
    @PostMapping("/{id}/allowances/generate")
    public ReimbursementAllowanceGenerateResult generateAllowances(@PathVariable Long id) {
        return wrap(() -> reimbursementService.generateAllowances(id));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        wrap(() -> {
            reimbursementService.delete(id);
            return null;
        });
    }

    @PostMapping("/{id}/submit")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void submit(@PathVariable Long id) {
        wrap(() -> {
            reimbursementService.submit(id);
            return null;
        });
    }

    @PostMapping("/{id}/void")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void voidDocument(@PathVariable Long id) {
        wrap(() -> {
            reimbursementService.voidDocument(id);
            return null;
        });
    }

    private <T> T wrap(ServiceCall<T> call) {
        try {
            return call.run();
        } catch (IllegalArgumentException e) {
            if (e.getMessage() != null && e.getMessage().contains("不存在")) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
            }
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }

    @FunctionalInterface
    private interface ServiceCall<T> {
        T run();
    }
}
