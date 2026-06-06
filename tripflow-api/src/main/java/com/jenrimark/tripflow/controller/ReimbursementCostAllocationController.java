package com.jenrimark.tripflow.controller;

import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.service.ReimbursementService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/reimbursement/{id}/cost-allocations")
public class ReimbursementCostAllocationController {

    private final ReimbursementService reimbursementService;

    public ReimbursementCostAllocationController(ReimbursementService reimbursementService) {
        this.reimbursementService = reimbursementService;
    }

    /**
     * 查询指定报销单下的全部分摊信息。
     */
    @GetMapping
    public List<ReimbursementDto.CostAllocation> list(@PathVariable Long id) {
        return wrap(() -> reimbursementService.listCostAllocations(id));
    }

    /**
     * 按当前分摊行数自动均摊比例和金额，并回写报销单。
     */
    @PostMapping("/evenly-distribute")
    public List<ReimbursementDto.CostAllocation> evenlyDistribute(@PathVariable Long id) {
        return wrap(() -> reimbursementService.evenlyDistributeCostAllocations(id));
    }

    /**
     * 为指定报销单新增一条分摊信息。
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ReimbursementDto.CostAllocation create(
            @PathVariable Long id,
            @RequestBody(required = false) ReimbursementDto.CostAllocation costAllocation) {
        return wrap(() -> reimbursementService.addCostAllocation(id, costAllocation));
    }

    /**
     * 修改指定报销单中的某条分摊信息。
     */
    @PutMapping("/{allocationKey}")
    public ReimbursementDto.CostAllocation update(
            @PathVariable Long id,
            @PathVariable String allocationKey,
            @RequestBody ReimbursementDto.CostAllocation costAllocation) {
        return wrap(() -> reimbursementService.updateCostAllocation(id, allocationKey, costAllocation));
    }

    /**
     * 删除指定报销单中的某条分摊信息。
     */
    @DeleteMapping("/{allocationKey}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
            @PathVariable Long id,
            @PathVariable String allocationKey) {
        wrap(() -> {
            reimbursementService.deleteCostAllocation(id, allocationKey);
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
