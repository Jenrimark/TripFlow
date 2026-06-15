package com.jenrimark.tripflow.service.reimbursement;

import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

/**
 * 报销单校验规则。
 */
@Component
public class ReimbursementValidator {

    public void validateForSave(ReimbursementDto dto) {
        List<String> errors = collectErrors(dto, false);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException(errors.get(0));
        }
    }

    public void validateForSubmit(ReimbursementDto dto) {
        List<String> errors = collectErrors(dto, true);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException(errors.get(0));
        }
    }

    public void validateRemark(String remark) {
        if (remark != null && remark.length() > 1000) {
            throw new IllegalArgumentException("备注信息不能超过1000个字符");
        }
    }

    public void validateCostAllocations(
            List<ReimbursementDto.CostAllocation> costAllocations,
            Double totalAllowanceAmount) {
        List<String> errors = new ArrayList<>();
        validateCostAllocations(costAllocations, totalAllowanceAmount, errors);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException(errors.get(0));
        }
    }

    private List<String> collectErrors(ReimbursementDto dto, boolean submit) {
        List<String> errors = new ArrayList<>();
        if (dto == null) {
            errors.add("报销单不存在");
            return errors;
        }

        ReimbursementDto.BasicInfo basic = dto.getBasicInfo();
        if (basic != null) {
            if (StringUtils.hasText(basic.getTitle()) && basic.getTitle().length() > 500) {
                errors.add("报销标题不能超过500个字符");
            }
            if (StringUtils.hasText(basic.getReason()) && basic.getReason().length() > 500) {
                errors.add("出差事由不能超过500个字符");
            }
        }

        if (submit) {
            if (basic == null
                    || !StringUtils.hasText(basic.getTitle())
                    || !StringUtils.hasText(basic.getReason())
                    || !StringUtils.hasText(basic.getReimburserId())
                    || !StringUtils.hasText(basic.getDepartmentId())
                    || !StringUtils.hasText(basic.getCompanyId())
                    || !StringUtils.hasText(basic.getBusinessTypeId())) {
                errors.add("请填写完整的单据信息");
            }
            if (dto.getTravelRecords() == null || dto.getTravelRecords().isEmpty()) {
                errors.add("请至少添加一条补录行程");
            }
            if (dto.getAllowances() == null || dto.getAllowances().isEmpty()) {
                errors.add("请至少添加一条补助信息");
            }
            if (dto.getCostAllocations() == null || dto.getCostAllocations().isEmpty()) {
                errors.add("请至少添加一条分摊信息");
            }
        }

        if (dto.getRemark() != null && dto.getRemark().length() > 1000) {
            errors.add("备注信息不能超过1000个字符");
        }

        validateTravelRecords(dto, errors);
        if (submit) {
            validateAllowances(dto, errors);
            validateCostAllocations(dto, errors);
        }

        return errors;
    }

    private void validateTravelRecords(ReimbursementDto dto, List<String> errors) {
        if (dto.getTravelRecords() == null) {
            return;
        }

        LocalDate today = LocalDate.now();
        List<TravelDateRange> ranges = new ArrayList<>();

        for (ReimbursementDto.TravelRecord record : dto.getTravelRecords()) {
            if (record == null) {
                errors.add("补录行程不能为空");
                return;
            }
            if (!StringUtils.hasText(record.getReimburserId())
                    || !StringUtils.hasText(record.getReimburserName())
                    || !StringUtils.hasText(record.getReimburserNo())) {
                errors.add("请选择完整的出行人信息");
                return;
            }
            if (!StringUtils.hasText(record.getDepartureCityId())
                    || !StringUtils.hasText(record.getDepartureCityName())
                    || !StringUtils.hasText(record.getArrivalCityId())
                    || !StringUtils.hasText(record.getArrivalCityName())) {
                errors.add("请选择完整的出发城市和到达城市");
                return;
            }
            if (record.getDepartureCityId().equals(record.getArrivalCityId())) {
                errors.add("出发城市不能与到达城市相同");
                return;
            }
            if (!StringUtils.hasText(record.getDepartureDate()) || !StringUtils.hasText(record.getArrivalDate())) {
                errors.add("请选择出发日期和到达日期");
                return;
            }
            if (!StringUtils.hasText(record.getDescription())) {
                errors.add("请输入行程说明");
                return;
            }

            LocalDate departure;
            LocalDate arrival;
            try {
                departure = LocalDate.parse(record.getDepartureDate());
                arrival = LocalDate.parse(record.getArrivalDate());
            } catch (DateTimeParseException e) {
                errors.add("行程日期格式不正确");
                return;
            }

            if (arrival.isBefore(departure)) {
                errors.add("到达日期不能早于出发日期");
                return;
            }
            if (departure.isAfter(today) || arrival.isAfter(today)) {
                errors.add("行程日期不能晚于当前日期");
                return;
            }
            if (record.getDescription().length() > 500) {
                errors.add("行程说明不能超过500个字符");
                return;
            }

            for (TravelDateRange existing : ranges) {
                if (!existing.reimburserId().equals(record.getReimburserId())) {
                    continue;
                }
                if (isDateRangeOverlapping(existing.departureDate(), existing.arrivalDate(), departure, arrival)) {
                    errors.add("同一出行人在所选日期范围内已存在补录行程，不可重复");
                    return;
                }
            }

            ranges.add(new TravelDateRange(record.getReimburserId(), departure, arrival));
        }
    }

    private boolean isDateRangeOverlapping(
            LocalDate existingDeparture,
            LocalDate existingArrival,
            LocalDate currentDeparture,
            LocalDate currentArrival) {
        return !currentDeparture.isAfter(existingArrival) && !currentArrival.isBefore(existingDeparture);
    }

    private void validateAllowances(ReimbursementDto dto, List<String> errors) {
        if (dto.getAllowances() == null) {
            return;
        }
        for (ReimbursementDto.AllowanceInfo allowance : dto.getAllowances()) {
            if (allowance.getCalendar() == null) {
                continue;
            }
            for (ReimbursementDto.AllowanceCalendarItem item : allowance.getCalendar()) {
                if (Boolean.TRUE.equals(item.getMealSelected())
                        && item.getMealAmount() != null
                        && item.getMealAllowance() != null
                        && item.getMealAmount() > item.getMealAllowance()) {
                    errors.add("餐费补助超出有效范围");
                    return;
                }
                if (Boolean.TRUE.equals(item.getTransportSelected())
                        && item.getTransportAmount() != null
                        && item.getTransportAllowance() != null
                        && item.getTransportAmount() > item.getTransportAllowance()) {
                    errors.add("交通补助超出有效范围");
                    return;
                }
                if (Boolean.TRUE.equals(item.getCommunicationSelected())
                        && item.getCommunicationAmount() != null
                        && item.getCommunicationAllowance() != null
                        && item.getCommunicationAmount() > item.getCommunicationAllowance()) {
                    errors.add("通讯补助超出有效范围");
                    return;
                }
            }
        }
    }

    private void validateCostAllocations(ReimbursementDto dto, List<String> errors) {
        validateCostAllocations(dto.getCostAllocations(), dto.getTotalAllowanceAmount(), errors);
    }

    private void validateCostAllocations(
            List<ReimbursementDto.CostAllocation> costAllocations,
            Double totalAllowanceAmount,
            List<String> errors) {
        if (costAllocations == null || costAllocations.isEmpty()) {
            return;
        }

        for (ReimbursementDto.CostAllocation allocation : costAllocations) {
            if (allocation == null) {
                errors.add("分摊信息不能为空");
                return;
            }
            if (!StringUtils.hasText(allocation.getCompanyId())
                    || !StringUtils.hasText(allocation.getCompanyName())
                    || !StringUtils.hasText(allocation.getCompanyNo())) {
                errors.add("请选择完整的归属公司信息");
                return;
            }
            if (!StringUtils.hasText(allocation.getProjectId())
                    || !StringUtils.hasText(allocation.getProjectName())
                    || !StringUtils.hasText(allocation.getProjectNo())) {
                errors.add("请选择完整的归属项目信息");
                return;
            }
            if (allocation.getRatio() == null) {
                errors.add("请填写分摊比例");
                return;
            }
            if (allocation.getAmount() == null) {
                errors.add("请填写分摊金额");
                return;
            }
            if (allocation.getRatio() < 0 || allocation.getRatio() > 1) {
                errors.add("分摊比例必须在0到1之间");
                return;
            }
            if (allocation.getAmount() < 0) {
                errors.add("分摊金额不能小于0");
                return;
            }
        }

        double ratioSum = costAllocations.stream()
                .mapToDouble(a -> a.getRatio() != null ? a.getRatio() : 0D)
                .sum();
        if (Math.abs(ratioSum - 1.0) > 0.0001) {
            errors.add("分摊比例合计必须为100%");
            return;
        }

        double totalAllowance = totalAllowanceAmount != null ? totalAllowanceAmount : 0D;
        double allocationSum = costAllocations.stream()
                .mapToDouble(a -> a.getAmount() != null ? a.getAmount() : 0D)
                .sum();
        if (Math.abs(allocationSum - totalAllowance) > 0.01) {
            errors.add("分摊金额合计必须等于补助总金额");
        }
    }

    private record TravelDateRange(String reimburserId, LocalDate departureDate, LocalDate arrivalDate) {
    }
}
