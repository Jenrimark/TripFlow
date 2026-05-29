package com.jenrimark.tripflow.service.reimbursement;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.entity.ReimbursementAllowance;
import com.jenrimark.tripflow.entity.ReimbursementAllowanceCalendar;
import com.jenrimark.tripflow.entity.ReimbursementCostAllocation;
import com.jenrimark.tripflow.entity.ReimbursementTravelRecord;
import com.jenrimark.tripflow.mapper.ReimbursementAllowanceCalendarMapper;
import com.jenrimark.tripflow.mapper.ReimbursementAllowanceMapper;
import com.jenrimark.tripflow.mapper.ReimbursementCostAllocationMapper;
import com.jenrimark.tripflow.mapper.ReimbursementTravelRecordMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Service
public class ReimbursementChildRecordService {

    private final ReimbursementTravelRecordMapper travelRecordMapper;
    private final ReimbursementAllowanceMapper allowanceMapper;
    private final ReimbursementAllowanceCalendarMapper calendarMapper;
    private final ReimbursementCostAllocationMapper costAllocationMapper;

    public ReimbursementChildRecordService(
            ReimbursementTravelRecordMapper travelRecordMapper,
            ReimbursementAllowanceMapper allowanceMapper,
            ReimbursementAllowanceCalendarMapper calendarMapper,
            ReimbursementCostAllocationMapper costAllocationMapper) {
        this.travelRecordMapper = travelRecordMapper;
        this.allowanceMapper = allowanceMapper;
        this.calendarMapper = calendarMapper;
        this.costAllocationMapper = costAllocationMapper;
    }

    @Transactional
    public void replaceChildRecords(Long reimbursementId, ReimbursementDto dto) {
        deleteChildRecords(reimbursementId);
        if (dto.getTravelRecords() != null) {
            for (ReimbursementDto.TravelRecord record : dto.getTravelRecords()) {
                ReimbursementTravelRecord entity = new ReimbursementTravelRecord();
                entity.setReimbursementId(reimbursementId);
                entity.setRecordKey(record.getId());
                entity.setReimburserId(record.getReimburserId());
                entity.setReimburserName(record.getReimburserName());
                entity.setReimburserNo(record.getReimburserNo());
                entity.setDepartureCityId(record.getDepartureCityId());
                entity.setDepartureCityName(record.getDepartureCityName());
                entity.setArrivalCityId(record.getArrivalCityId());
                entity.setArrivalCityName(record.getArrivalCityName());
                entity.setDepartureDate(LocalDate.parse(record.getDepartureDate()));
                entity.setArrivalDate(LocalDate.parse(record.getArrivalDate()));
                entity.setDescription(record.getDescription());
                travelRecordMapper.insert(entity);
            }
        }
        if (dto.getAllowances() != null) {
            for (ReimbursementDto.AllowanceInfo allowance : dto.getAllowances()) {
                ReimbursementAllowance entity = new ReimbursementAllowance();
                entity.setReimbursementId(reimbursementId);
                entity.setAllowanceKey(allowance.getId());
                entity.setTravelRecordKey(allowance.getTravelRecordId());
                entity.setReimburserId(allowance.getReimburserId());
                entity.setReimburserName(allowance.getReimburserName());
                entity.setDepartureDate(LocalDate.parse(allowance.getDepartureDate()));
                entity.setArrivalDate(LocalDate.parse(allowance.getArrivalDate()));
                entity.setAllowanceDays(allowance.getAllowanceDays());
                entity.setDepartureCity(allowance.getDepartureCity());
                entity.setArrivalCity(allowance.getArrivalCity());
                entity.setTotalApplyAmount(toDecimal(allowance.getTotalApplyAmount()));
                entity.setTotalAllowanceAmount(toDecimal(allowance.getTotalAllowanceAmount()));
                allowanceMapper.insert(entity);

                if (allowance.getCalendar() != null) {
                    for (ReimbursementDto.AllowanceCalendarItem item : allowance.getCalendar()) {
                        ReimbursementAllowanceCalendar calendar = new ReimbursementAllowanceCalendar();
                        calendar.setAllowanceId(entity.getId());
                        calendar.setCalendarDate(LocalDate.parse(item.getDate()));
                        calendar.setWeekday(item.getWeekday());
                        calendar.setMealAllowance(toDecimal(item.getMealAllowance()));
                        calendar.setTransportAllowance(toDecimal(item.getTransportAllowance()));
                        calendar.setCommunicationAllowance(toDecimal(item.getCommunicationAllowance()));
                        calendar.setMealSelected(item.getMealSelected());
                        calendar.setTransportSelected(item.getTransportSelected());
                        calendar.setCommunicationSelected(item.getCommunicationSelected());
                        calendar.setMealAmount(toDecimal(item.getMealAmount()));
                        calendar.setTransportAmount(toDecimal(item.getTransportAmount()));
                        calendar.setCommunicationAmount(toDecimal(item.getCommunicationAmount()));
                        calendarMapper.insert(calendar);
                    }
                }
            }
        }
        if (dto.getCostAllocations() != null) {
            int order = 0;
            for (ReimbursementDto.CostAllocation allocation : dto.getCostAllocations()) {
                ReimbursementCostAllocation entity = new ReimbursementCostAllocation();
                entity.setReimbursementId(reimbursementId);
                entity.setAllocationKey(allocation.getId());
                entity.setCompanyId(allocation.getCompanyId());
                entity.setCompanyName(allocation.getCompanyName());
                entity.setCompanyNo(allocation.getCompanyNo());
                entity.setProjectId(allocation.getProjectId());
                entity.setProjectName(allocation.getProjectName());
                entity.setProjectNo(allocation.getProjectNo());
                entity.setRatio(toDecimal(allocation.getRatio()));
                entity.setAmount(toDecimal(allocation.getAmount()));
                entity.setSortOrder(order++);
                costAllocationMapper.insert(entity);
            }
        }
    }

    @Transactional
    public void deleteChildRecords(Long reimbursementId) {
        List<ReimbursementAllowance> allowances = allowanceMapper.selectList(
                new LambdaQueryWrapper<ReimbursementAllowance>()
                        .eq(ReimbursementAllowance::getReimbursementId, reimbursementId));
        for (ReimbursementAllowance allowance : allowances) {
            calendarMapper.delete(new LambdaQueryWrapper<ReimbursementAllowanceCalendar>()
                    .eq(ReimbursementAllowanceCalendar::getAllowanceId, allowance.getId()));
        }
        allowanceMapper.delete(new LambdaQueryWrapper<ReimbursementAllowance>()
                .eq(ReimbursementAllowance::getReimbursementId, reimbursementId));
        travelRecordMapper.delete(new LambdaQueryWrapper<ReimbursementTravelRecord>()
                .eq(ReimbursementTravelRecord::getReimbursementId, reimbursementId));
        costAllocationMapper.delete(new LambdaQueryWrapper<ReimbursementCostAllocation>()
                .eq(ReimbursementCostAllocation::getReimbursementId, reimbursementId));
    }

    private BigDecimal toDecimal(Double value) {
        return value != null ? BigDecimal.valueOf(value) : BigDecimal.ZERO;
    }
}
