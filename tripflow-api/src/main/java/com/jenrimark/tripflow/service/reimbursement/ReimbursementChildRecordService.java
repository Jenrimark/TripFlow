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
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
public class ReimbursementChildRecordService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;
    private static final DateTimeFormatter DATETIME_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

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

    public List<ReimbursementDto.TravelRecord> loadTravelRecords(Long reimbursementId) {
        List<ReimbursementTravelRecord> records = travelRecordMapper.selectList(
                new LambdaQueryWrapper<ReimbursementTravelRecord>()
                        .eq(ReimbursementTravelRecord::getReimbursementId, reimbursementId)
                        .orderByAsc(ReimbursementTravelRecord::getDepartureDate)
                        .orderByAsc(ReimbursementTravelRecord::getId));

        List<ReimbursementDto.TravelRecord> result = new ArrayList<>();
        for (ReimbursementTravelRecord record : records) {
            result.add(toTravelRecordDto(record));
        }
        return result;
    }

    public ReimbursementDto.TravelRecord loadTravelRecord(Long reimbursementId, String recordKey) {
        ReimbursementTravelRecord record = travelRecordMapper.selectOne(
                new LambdaQueryWrapper<ReimbursementTravelRecord>()
                        .eq(ReimbursementTravelRecord::getReimbursementId, reimbursementId)
                        .eq(ReimbursementTravelRecord::getRecordKey, recordKey));
        if (record == null) {
            throw new IllegalArgumentException("补录行程不存在");
        }
        return toTravelRecordDto(record);
    }

    public List<ReimbursementDto.AllowanceInfo> loadAllowances(Long reimbursementId) {
        List<ReimbursementAllowance> allowances = allowanceMapper.selectList(
                new LambdaQueryWrapper<ReimbursementAllowance>()
                        .eq(ReimbursementAllowance::getReimbursementId, reimbursementId)
                        .orderByAsc(ReimbursementAllowance::getDepartureDate)
                        .orderByAsc(ReimbursementAllowance::getId));

        List<ReimbursementDto.AllowanceInfo> result = new ArrayList<>();
        for (ReimbursementAllowance allowance : allowances) {
            ReimbursementDto.AllowanceInfo item = new ReimbursementDto.AllowanceInfo();
            item.setId(allowance.getAllowanceKey());
            item.setTravelRecordId(allowance.getTravelRecordKey());
            item.setReimburserId(allowance.getReimburserId());
            item.setReimburserName(allowance.getReimburserName());
            if (allowance.getDepartureDate() != null) {
                item.setDepartureDate(allowance.getDepartureDate().format(DATE_FMT));
            }
            if (allowance.getArrivalDate() != null) {
                item.setArrivalDate(allowance.getArrivalDate().format(DATE_FMT));
            }
            item.setAllowanceDays(allowance.getAllowanceDays());
            item.setDepartureCity(allowance.getDepartureCity());
            item.setArrivalCity(allowance.getArrivalCity());
            item.setTotalApplyAmount(toDouble(allowance.getTotalApplyAmount()));
            item.setTotalAllowanceAmount(toDouble(allowance.getTotalAllowanceAmount()));
            item.setCalendar(loadAllowanceCalendar(allowance.getId()));
            result.add(item);
        }
        return result;
    }

    public List<ReimbursementDto.CostAllocation> loadCostAllocations(Long reimbursementId) {
        List<ReimbursementCostAllocation> allocations = costAllocationMapper.selectList(
                new LambdaQueryWrapper<ReimbursementCostAllocation>()
                        .eq(ReimbursementCostAllocation::getReimbursementId, reimbursementId)
                        .orderByAsc(ReimbursementCostAllocation::getSortOrder)
                        .orderByAsc(ReimbursementCostAllocation::getId));

        List<ReimbursementDto.CostAllocation> result = new ArrayList<>();
        for (ReimbursementCostAllocation allocation : allocations) {
            ReimbursementDto.CostAllocation item = new ReimbursementDto.CostAllocation();
            item.setId(allocation.getAllocationKey());
            item.setCompanyId(allocation.getCompanyId());
            item.setCompanyName(allocation.getCompanyName());
            item.setCompanyNo(allocation.getCompanyNo());
            item.setProjectId(allocation.getProjectId());
            item.setProjectName(allocation.getProjectName());
            item.setProjectNo(allocation.getProjectNo());
            item.setRatio(toDouble(allocation.getRatio()));
            item.setAmount(toDouble(allocation.getAmount()));
            result.add(item);
        }
        return result;
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
                if (record.getDepartureDatetime() != null) {
                    entity.setDepartureDatetime(LocalDateTime.parse(record.getDepartureDatetime(), DATETIME_FMT));
                }
                if (record.getArrivalDatetime() != null) {
                    entity.setArrivalDatetime(LocalDateTime.parse(record.getArrivalDatetime(), DATETIME_FMT));
                }
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

    private List<ReimbursementDto.AllowanceCalendarItem> loadAllowanceCalendar(Long allowanceId) {
        List<ReimbursementAllowanceCalendar> calendars = calendarMapper.selectList(
                new LambdaQueryWrapper<ReimbursementAllowanceCalendar>()
                        .eq(ReimbursementAllowanceCalendar::getAllowanceId, allowanceId));
        calendars.sort(Comparator.comparing(ReimbursementAllowanceCalendar::getCalendarDate)
                .thenComparing(ReimbursementAllowanceCalendar::getId));

        List<ReimbursementDto.AllowanceCalendarItem> result = new ArrayList<>();
        for (ReimbursementAllowanceCalendar calendar : calendars) {
            ReimbursementDto.AllowanceCalendarItem item = new ReimbursementDto.AllowanceCalendarItem();
            if (calendar.getCalendarDate() != null) {
                item.setDate(calendar.getCalendarDate().format(DATE_FMT));
            }
            item.setWeekday(calendar.getWeekday());
            item.setMealAllowance(toDouble(calendar.getMealAllowance()));
            item.setTransportAllowance(toDouble(calendar.getTransportAllowance()));
            item.setCommunicationAllowance(toDouble(calendar.getCommunicationAllowance()));
            item.setMealSelected(calendar.getMealSelected());
            item.setTransportSelected(calendar.getTransportSelected());
            item.setCommunicationSelected(calendar.getCommunicationSelected());
            item.setMealAmount(toDouble(calendar.getMealAmount()));
            item.setTransportAmount(toDouble(calendar.getTransportAmount()));
            item.setCommunicationAmount(toDouble(calendar.getCommunicationAmount()));
            result.add(item);
        }
        return result;
    }

    private Double toDouble(BigDecimal value) {
        return value != null ? value.doubleValue() : 0D;
    }

    private ReimbursementDto.TravelRecord toTravelRecordDto(ReimbursementTravelRecord record) {
        ReimbursementDto.TravelRecord item = new ReimbursementDto.TravelRecord();
        item.setId(record.getRecordKey());
        item.setReimburserId(record.getReimburserId());
        item.setReimburserName(record.getReimburserName());
        item.setReimburserNo(record.getReimburserNo());
        item.setDepartureCityId(record.getDepartureCityId());
        item.setDepartureCityName(record.getDepartureCityName());
        item.setArrivalCityId(record.getArrivalCityId());
        item.setArrivalCityName(record.getArrivalCityName());
        if (record.getDepartureDate() != null) {
            item.setDepartureDate(record.getDepartureDate().format(DATE_FMT));
        }
        if (record.getArrivalDate() != null) {
            item.setArrivalDate(record.getArrivalDate().format(DATE_FMT));
        }
        if (record.getDepartureDatetime() != null) {
            item.setDepartureDatetime(record.getDepartureDatetime().format(DATETIME_FMT));
        }
        if (record.getArrivalDatetime() != null) {
            item.setArrivalDatetime(record.getArrivalDatetime().format(DATETIME_FMT));
        }
        item.setDescription(record.getDescription());
        return item;
    }
}
