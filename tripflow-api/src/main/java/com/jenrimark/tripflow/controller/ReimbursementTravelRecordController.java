package com.jenrimark.tripflow.controller;

import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.exception.ReimbursementVersionConflictException;
import com.jenrimark.tripflow.service.ReimbursementService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/reimbursement/{id}/travel-records")
public class ReimbursementTravelRecordController {

    private final ReimbursementService reimbursementService;

    public ReimbursementTravelRecordController(ReimbursementService reimbursementService) {
        this.reimbursementService = reimbursementService;
    }

    /**
     * 查询指定报销单下的全部补录行程。
     */
    @GetMapping
    public List<ReimbursementDto.TravelRecord> list(@PathVariable Long id) {
        return wrap(() -> reimbursementService.listTravelRecords(id));
    }

    /**
     * 查询指定报销单下的单条补录行程详情。
     */
    @GetMapping("/{recordKey}")
    public ReimbursementDto.TravelRecord detail(
            @PathVariable Long id,
            @PathVariable String recordKey) {
        return wrap(() -> reimbursementService.getTravelRecord(id, recordKey));
    }

    /**
     * 为指定报销单新增一条补录行程。
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ReimbursementDto.TravelRecord create(
            @PathVariable Long id,
            @RequestParam Long version,
            @RequestBody ReimbursementDto.TravelRecord travelRecord) {
        return wrap(() -> reimbursementService.addTravelRecord(id, version, travelRecord));
    }

    /**
     * 修改指定报销单中的某条补录行程。
     */
    @PutMapping("/{recordKey}")
    public ReimbursementDto.TravelRecord update(
            @PathVariable Long id,
            @PathVariable String recordKey,
            @RequestParam Long version,
            @RequestBody ReimbursementDto.TravelRecord travelRecord) {
        return wrap(() -> reimbursementService.updateTravelRecord(id, recordKey, version, travelRecord));
    }

    /**
     * 删除指定报销单中的某条补录行程。
     */
    @DeleteMapping("/{recordKey}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
            @PathVariable Long id,
            @PathVariable String recordKey,
            @RequestParam Long version) {
        wrap(() -> {
            reimbursementService.deleteTravelRecord(id, recordKey, version);
            return null;
        });
    }

    private <T> T wrap(ServiceCall<T> call) {
        try {
            return call.run();
        } catch (ReimbursementVersionConflictException e) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
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
