package com.jenrimark.tripflow.controller;

import com.jenrimark.tripflow.dto.calendar.AllowanceCalendarAddResult;
import com.jenrimark.tripflow.dto.calendar.AllowanceCalendarDto;
import com.jenrimark.tripflow.dto.calendar.AllowanceCalendarRequest;
import com.jenrimark.tripflow.dto.calendar.ApiResponse;
import com.jenrimark.tripflow.exception.ReimbursementVersionConflictException;
import com.jenrimark.tripflow.service.ReimbursementService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/reimbursement/{reimbursementId}/allowances/{allowanceId}/calendar")
public class ReimbursementAllowanceCalendarController {

    private final ReimbursementService reimbursementService;

    public ReimbursementAllowanceCalendarController(ReimbursementService reimbursementService) {
        this.reimbursementService = reimbursementService;
    }

    /**
     * 查询指定补助下的全部日历项。
     */
    @GetMapping
    public ApiResponse<List<AllowanceCalendarDto>> list(@PathVariable Long reimbursementId, @PathVariable Long allowanceId) {
        try {
            return ApiResponse.success(reimbursementService.listAllowanceCalendars(reimbursementId, allowanceId));
        } catch (IllegalArgumentException e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PostMapping
    public ApiResponse<AllowanceCalendarDto> create(
            @PathVariable Long reimbursementId,
            @PathVariable Long allowanceId,
            @RequestBody AllowanceCalendarRequest request) {
        try {
            AllowanceCalendarAddResult result = reimbursementService.addAllowanceCalendar(
                    reimbursementId, allowanceId, request != null ? request.getVersion() : null, request);
            if (result.isNewlyCreated()) {
                return ApiResponse.success(result.getCalendar(), "新增成功");
            } else {
                return ApiResponse.success(result.getCalendar(), "记录已存在");
            }
        } catch (ReimbursementVersionConflictException e) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
        } catch (IllegalArgumentException e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PutMapping("/{calendarId}")
    public ApiResponse<AllowanceCalendarDto> update(
            @PathVariable Long reimbursementId,
            @PathVariable Long allowanceId,
            @PathVariable Long calendarId,
            @RequestBody AllowanceCalendarRequest request) {
        try {
            return ApiResponse.success(reimbursementService.updateAllowanceCalendar(
                    reimbursementId, allowanceId, calendarId, request != null ? request.getVersion() : null, request));
        } catch (ReimbursementVersionConflictException e) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
        } catch (IllegalArgumentException e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PutMapping
    public ApiResponse<List<AllowanceCalendarDto>> batchUpdate(
            @PathVariable Long reimbursementId,
            @PathVariable Long allowanceId,
            @RequestBody List<AllowanceCalendarRequest> items) {
        try {
            Long version = (items != null && !items.isEmpty() && items.get(0) != null) ? items.get(0).getVersion() : null;
            return ApiResponse.success(reimbursementService.batchUpdateAllowanceCalendars(
                    reimbursementId, allowanceId, version, items));
        } catch (ReimbursementVersionConflictException e) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
        } catch (IllegalArgumentException e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @DeleteMapping("/{calendarId}")
    public ApiResponse<Void> delete(
            @PathVariable Long reimbursementId,
            @PathVariable Long allowanceId,
            @PathVariable Long calendarId,
            @RequestParam Long version) {
        try {
            reimbursementService.deleteAllowanceCalendar(reimbursementId, allowanceId, calendarId, version);
            return ApiResponse.success("删除成功");
        } catch (ReimbursementVersionConflictException e) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
        } catch (IllegalArgumentException e) {
            return ApiResponse.error(e.getMessage());
        }
    }
}
