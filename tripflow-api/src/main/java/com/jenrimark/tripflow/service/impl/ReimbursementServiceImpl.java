package com.jenrimark.tripflow.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementAllowanceGenerateResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementExpenseSummaryResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementListResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementRemarkRequest;
import com.jenrimark.tripflow.entity.ReimbursementAllowance;
import com.jenrimark.tripflow.entity.ReimbursementAllowanceCalendar;
import com.jenrimark.tripflow.entity.ReimbursementCostAllocation;
import com.jenrimark.tripflow.entity.ReimbursementRecord;
import com.jenrimark.tripflow.mapper.ReimbursementAllowanceCalendarMapper;
import com.jenrimark.tripflow.mapper.ReimbursementAllowanceMapper;
import com.jenrimark.tripflow.mapper.ReimbursementCostAllocationMapper;
import com.jenrimark.tripflow.mapper.ReimbursementMapper;
import com.jenrimark.tripflow.service.ReimbursementService;
import com.jenrimark.tripflow.service.reimbursement.ReimbursementAllowanceGenerationService;
import com.jenrimark.tripflow.service.reimbursement.ReimbursementChildRecordService;
import com.jenrimark.tripflow.service.reimbursement.ReimbursementValidator;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Stream;

@Service
public class ReimbursementServiceImpl extends ServiceImpl<ReimbursementMapper, ReimbursementRecord>
        implements ReimbursementService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;

    private final ObjectMapper objectMapper;
    private final ReimbursementValidator validator;
    private final ReimbursementAllowanceGenerationService allowanceGenerationService;
    private final ReimbursementChildRecordService childRecordService;
    private final ReimbursementAllowanceMapper allowanceMapper;
    private final ReimbursementAllowanceCalendarMapper calendarMapper;
    private final ReimbursementCostAllocationMapper costAllocationMapper;

    public ReimbursementServiceImpl(
            ObjectMapper objectMapper,
            ReimbursementValidator validator,
            ReimbursementAllowanceGenerationService allowanceGenerationService,
            ReimbursementChildRecordService childRecordService,
            ReimbursementAllowanceMapper allowanceMapper,
            ReimbursementAllowanceCalendarMapper calendarMapper,
            ReimbursementCostAllocationMapper costAllocationMapper) {
        this.objectMapper = objectMapper;
        this.validator = validator;
        this.allowanceGenerationService = allowanceGenerationService;
        this.childRecordService = childRecordService;
        this.allowanceMapper = allowanceMapper;
        this.calendarMapper = calendarMapper;
        this.costAllocationMapper = costAllocationMapper;
    }

    @Override
    public ReimbursementListResult list(
            String documentNo,
            String title,
            String reason,
            List<String> companyIds,
            List<String> departmentIds,
            List<String> reimburserIds,
            List<String> businessTypeIds,
            int page,
            int pageSize) {
        LambdaQueryWrapper<ReimbursementRecord> wrapper = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(documentNo) && documentNo.length() >= 3) {
            wrapper.like(ReimbursementRecord::getDocumentNo, documentNo);
        }
        if (StringUtils.hasText(title)) {
            wrapper.like(ReimbursementRecord::getTitle, title);
        }
        if (StringUtils.hasText(reason)) {
            wrapper.like(ReimbursementRecord::getReason, reason);
        }
        if (companyIds != null && !companyIds.isEmpty()) {
            wrapper.in(ReimbursementRecord::getCompanyId, companyIds);
        }
        if (departmentIds != null && !departmentIds.isEmpty()) {
            wrapper.in(ReimbursementRecord::getDepartmentId, departmentIds);
        }
        if (reimburserIds != null && !reimburserIds.isEmpty()) {
            wrapper.in(ReimbursementRecord::getReimburserId, reimburserIds);
        }
        if (businessTypeIds != null && !businessTypeIds.isEmpty()) {
            wrapper.in(ReimbursementRecord::getBusinessTypeId, businessTypeIds);
        }
        wrapper.orderByDesc(ReimbursementRecord::getCreatedAt);

        Page<ReimbursementRecord> pageResult = page(new Page<>(page, pageSize), wrapper);

        ReimbursementListResult result = new ReimbursementListResult();
        result.setList(pageResult.getRecords().stream().map(this::toDto).toList());
        result.setTotal(pageResult.getTotal());
        result.setPage(page);
        result.setPageSize(pageSize);
        return result;
    }

    @Override
    public ReimbursementDto getDetail(Long id) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        return toDto(record);
    }

    @Override
    @Transactional
    public ReimbursementDto create(ReimbursementDto dto) {
        validator.validateForSave(dto);

        ReimbursementRecord record = new ReimbursementRecord();
        record.setDocumentNo(generateDocumentNo());
        record.setStatus(dto.getStatus() != null ? dto.getStatus() : 0);
        record.setCreatedAt(LocalDateTime.now());
        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        save(record);
        childRecordService.replaceChildRecords(record.getId(), dto);
        return toDto(record);
    }

    @Override
    @Transactional
    public ReimbursementDto update(Long id, ReimbursementDto dto) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }

        validator.validateForSave(dto);
        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        childRecordService.replaceChildRecords(id, dto);
        return toDto(record);
    }

    @Override
    @Transactional
    public ReimbursementDto updateRemark(Long id, ReimbursementRemarkRequest request) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        ReimbursementDto dto = toDto(record);

        dto.setRemark(request != null ? request.getRemark() : null);
        validator.validateRemark(dto.getRemark());

        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        return toDto(record);
    }

    @Override
    @Transactional
    public ReimbursementDto clearRemark(Long id) {
        return updateRemark(id, null);
    }

    @Override
    @Transactional
    public ReimbursementAllowanceGenerateResult generateAllowances(Long id) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        ReimbursementDto dto = toDto(record);

        if (dto.getTravelRecords() == null || dto.getTravelRecords().isEmpty()) {
            throw new IllegalArgumentException("请先填写补录行程");
        }

        dto.setAllowances(allowanceGenerationService.generate(dto.getTravelRecords()));
        dto.setTotalAllowanceAmount(sumAllowanceAmount(dto.getAllowances()));
        dto.setTotalMealAmount(sumMealAmount(dto.getAllowances()));
        dto.setTotalTransportAmount(sumTransportAmount(dto.getAllowances()));
        dto.setTotalCommunicationAmount(sumCommunicationAmount(dto.getAllowances()));

        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        childRecordService.replaceChildRecords(id, dto);
        return buildAllowanceGenerateResult(dto);
    }

    @Override
    @Transactional(readOnly = true)
    public ReimbursementExpenseSummaryResult calculateExpenseSummary(Long id) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);

        List<ReimbursementAllowance> allowances = allowanceMapper.selectList(
                new LambdaQueryWrapper<ReimbursementAllowance>()
                        .eq(ReimbursementAllowance::getReimbursementId, record.getId()));

        ReimbursementExpenseSummaryResult result = new ReimbursementExpenseSummaryResult();
        result.setDocumentNo(record.getDocumentNo());
        result.setTotalAllowanceAmount(sumPersistedAllowanceAmount(allowances));

        if (allowances.isEmpty()) {
            result.setTotalMealAmount(0D);
            result.setTotalTransportAmount(0D);
            result.setTotalCommunicationAmount(0D);
            return result;
        }

        Set<Long> allowanceIds = allowances.stream()
                .map(ReimbursementAllowance::getId)
                .collect(java.util.stream.Collectors.toSet());
        List<ReimbursementAllowanceCalendar> calendars = calendarMapper.selectList(
                new LambdaQueryWrapper<ReimbursementAllowanceCalendar>()
                        .in(ReimbursementAllowanceCalendar::getAllowanceId, allowanceIds));

        result.setTotalMealAmount(sumSelectedMealAmount(calendars));
        result.setTotalTransportAmount(sumSelectedTransportAmount(calendars));
        result.setTotalCommunicationAmount(sumSelectedCommunicationAmount(calendars));
        return result;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReimbursementDto.CostAllocation> listCostAllocations(Long id) {
        getExistingReimbursementRecord(id);

        return costAllocationMapper.selectList(
                        new LambdaQueryWrapper<ReimbursementCostAllocation>()
                                .eq(ReimbursementCostAllocation::getReimbursementId, id)
                                .orderByAsc(ReimbursementCostAllocation::getSortOrder, ReimbursementCostAllocation::getId))
                .stream()
                .map(this::toCostAllocationDto)
                .toList();
    }

    @Override
    @Transactional
    public List<ReimbursementDto.CostAllocation> evenlyDistributeCostAllocations(Long id) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        ReimbursementDto dto = toDto(record);

        if (dto.getCostAllocations() == null || dto.getCostAllocations().isEmpty()) {
            throw new IllegalArgumentException("请至少添加一条分摊信息");
        }

        int count = dto.getCostAllocations().size();
        double totalAmount = dto.getTotalAllowanceAmount() != null ? dto.getTotalAllowanceAmount() : 0D;
        List<EvenAllocationItem> evenResults = calculateEvenAllocations(totalAmount, count);

        for (int i = 0; i < count; i++) {
            ReimbursementDto.CostAllocation allocation = dto.getCostAllocations().get(i);
            EvenAllocationItem evenItem = evenResults.get(i);
            allocation.setRatio(evenItem.getRatio());
            allocation.setAmount(evenItem.getAmount());
        }

        validator.validateForSave(dto);
        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        childRecordService.replaceChildRecords(id, dto);
        return dto.getCostAllocations();
    }

    @Override
    @Transactional
    public ReimbursementDto.CostAllocation addCostAllocation(Long id, ReimbursementDto.CostAllocation costAllocation) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        ReimbursementDto dto = toDto(record);
        List<ReimbursementDto.CostAllocation> costAllocations =
                dto.getCostAllocations() != null ? new ArrayList<>(dto.getCostAllocations()) : new ArrayList<>();

        ReimbursementDto.CostAllocation newAllocation = createInitialCostAllocation(costAllocation);

        costAllocations.add(newAllocation);
        dto.setCostAllocations(costAllocations);

        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        childRecordService.replaceChildRecords(id, dto);
        return newAllocation;
    }

    @Override
    @Transactional
    public ReimbursementDto.CostAllocation updateCostAllocation(
            Long id,
            String allocationKey,
            ReimbursementDto.CostAllocation costAllocation) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        if (costAllocation == null) {
            throw new IllegalArgumentException("分摊信息不能为空");
        }

        ReimbursementDto dto = toDto(record);
        ReimbursementDto.CostAllocation existing = findCostAllocation(dto, allocationKey);

        costAllocation.setId(allocationKey);
        existing.setCompanyId(costAllocation.getCompanyId());
        existing.setCompanyName(costAllocation.getCompanyName());
        existing.setCompanyNo(costAllocation.getCompanyNo());
        existing.setProjectId(costAllocation.getProjectId());
        existing.setProjectName(costAllocation.getProjectName());
        existing.setProjectNo(costAllocation.getProjectNo());
        existing.setRatio(costAllocation.getRatio());
        existing.setAmount(costAllocation.getAmount());

        validator.validateForSave(dto);
        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        childRecordService.replaceChildRecords(id, dto);
        return existing;
    }

    @Override
    @Transactional
    public void deleteCostAllocation(Long id, String allocationKey) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        ReimbursementDto dto = toDto(record);
        findCostAllocation(dto, allocationKey);

        if (dto.getCostAllocations() == null || dto.getCostAllocations().size() <= 1) {
            throw new IllegalArgumentException("至少保留一条分摊信息");
        }

        List<ReimbursementDto.CostAllocation> costAllocations =
                dto.getCostAllocations() != null ? new ArrayList<>(dto.getCostAllocations()) : new ArrayList<>();
        costAllocations.removeIf(item -> allocationKey.equals(item.getId()));
        dto.setCostAllocations(costAllocations);

        validator.validateForSave(dto);
        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        childRecordService.replaceChildRecords(id, dto);
    }

    @Override
    @Transactional
    public List<ReimbursementDto.TravelRecord> listTravelRecords(Long id) {
        ReimbursementDto dto = getExistingReimbursementDto(id);
        return dto.getTravelRecords() != null ? dto.getTravelRecords() : List.of();
    }

    @Override
    @Transactional
    public ReimbursementDto.TravelRecord getTravelRecord(Long id, String recordKey) {
        ReimbursementDto dto = getExistingReimbursementDto(id);
        return findTravelRecord(dto, recordKey);
    }

    @Override
    @Transactional
    public ReimbursementDto.TravelRecord addTravelRecord(Long id, ReimbursementDto.TravelRecord travelRecord) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        if (travelRecord == null) {
            throw new IllegalArgumentException("补录行程不能为空");
        }

        ReimbursementDto dto = toDto(record);
        List<ReimbursementDto.TravelRecord> travelRecords =
                dto.getTravelRecords() != null ? new ArrayList<>(dto.getTravelRecords()) : new ArrayList<>();

        if (!StringUtils.hasText(travelRecord.getId())) {
            travelRecord.setId("travel_" + System.currentTimeMillis());
        }

        travelRecords.add(travelRecord);
        dto.setTravelRecords(travelRecords);

        validator.validateForSave(dto);

        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        childRecordService.replaceChildRecords(id, dto);
        return travelRecord;
    }

    @Override
    @Transactional
    public ReimbursementDto.TravelRecord updateTravelRecord(
            Long id,
            String recordKey,
            ReimbursementDto.TravelRecord travelRecord) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        if (travelRecord == null) {
            throw new IllegalArgumentException("补录行程不能为空");
        }

        ReimbursementDto dto = toDto(record);
        ReimbursementDto.TravelRecord existing = findTravelRecord(dto, recordKey);

        travelRecord.setId(recordKey);
        existing.setReimburserId(travelRecord.getReimburserId());
        existing.setReimburserName(travelRecord.getReimburserName());
        existing.setReimburserNo(travelRecord.getReimburserNo());
        existing.setDepartureCityId(travelRecord.getDepartureCityId());
        existing.setDepartureCityName(travelRecord.getDepartureCityName());
        existing.setArrivalCityId(travelRecord.getArrivalCityId());
        existing.setArrivalCityName(travelRecord.getArrivalCityName());
        existing.setDepartureDate(travelRecord.getDepartureDate());
        existing.setArrivalDate(travelRecord.getArrivalDate());
        existing.setDescription(travelRecord.getDescription());

        validator.validateForSave(dto);

        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        childRecordService.replaceChildRecords(id, dto);
        return existing;
    }

    @Override
    @Transactional
    public void deleteTravelRecord(Long id, String recordKey) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        ReimbursementDto dto = toDto(record);
        findTravelRecord(dto, recordKey);

        List<ReimbursementDto.TravelRecord> travelRecords =
                dto.getTravelRecords() != null ? new ArrayList<>(dto.getTravelRecords()) : new ArrayList<>();
        travelRecords.removeIf(item -> recordKey.equals(item.getId()));
        dto.setTravelRecords(travelRecords);

        if (dto.getAllowances() != null) {
            dto.setAllowances(dto.getAllowances().stream()
                    .filter(item -> !recordKey.equals(item.getTravelRecordId()))
                    .toList());
        }

        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        updateById(record);
        childRecordService.replaceChildRecords(id, dto);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        if (getById(id) == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        childRecordService.deleteChildRecords(id);
        removeById(id);
    }

    @Override
    @Transactional
    public void submit(Long id) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        ReimbursementDto dto = toDto(record);
        validator.validateForSubmit(dto);
        record.setStatus(1);
        record.setUpdatedAt(LocalDateTime.now());
        updateById(record);
        syncStatusToContent(record);
    }

    @Override
    @Transactional
    public void voidDocument(Long id) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        record.setStatus(2);
        record.setUpdatedAt(LocalDateTime.now());
        updateById(record);
        syncStatusToContent(record);
    }

    private void syncStatusToContent(ReimbursementRecord record) {
        try {
            ReimbursementDto dto = objectMapper.readValue(record.getContent(), ReimbursementDto.class);
            dto.setStatus(record.getStatus());
            record.setContent(objectMapper.writeValueAsString(dto));
            updateById(record);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("报销单数据解析失败", e);
        }
    }

    private String generateDocumentNo() {
        return "REIM" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
                + String.format("%04d", System.currentTimeMillis() % 10000);
    }

    private void applyDtoToRecord(ReimbursementDto dto, ReimbursementRecord record) {
        if (dto.getBasicInfo() != null) {
            record.setTitle(dto.getBasicInfo().getTitle());
            record.setReason(dto.getBasicInfo().getReason());
            record.setCompanyId(dto.getBasicInfo().getCompanyId());
            record.setDepartmentId(dto.getBasicInfo().getDepartmentId());
            record.setReimburserId(dto.getBasicInfo().getReimburserId());
            record.setBusinessTypeId(dto.getBasicInfo().getBusinessTypeId());
        }
        record.setRemark(dto.getRemark());
        if (dto.getTotalAllowanceAmount() != null) {
            record.setTotalAllowanceAmount(BigDecimal.valueOf(dto.getTotalAllowanceAmount()));
        } else {
            record.setTotalAllowanceAmount(BigDecimal.ZERO);
        }
        if (dto.getStatus() != null) {
            record.setStatus(dto.getStatus());
        }
        try {
            if (record.getId() != null) {
                dto.setId(String.valueOf(record.getId()));
            }
            if (StringUtils.hasText(record.getDocumentNo())) {
                dto.setDocumentNo(record.getDocumentNo());
            }
            if (record.getCreatedAt() != null) {
                dto.setCreatedAt(record.getCreatedAt().toLocalDate().format(DATE_FMT));
            }
            record.setContent(objectMapper.writeValueAsString(dto));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("报销单数据序列化失败", e);
        }
    }

    private ReimbursementDto toDto(ReimbursementRecord record) {
        try {
            ReimbursementDto dto = objectMapper.readValue(record.getContent(), ReimbursementDto.class);
            dto.setId(String.valueOf(record.getId()));
            dto.setDocumentNo(record.getDocumentNo());
            dto.setStatus(record.getStatus());
            dto.setRemark(record.getRemark());
            if (record.getCreatedAt() != null) {
                dto.setCreatedAt(record.getCreatedAt().toLocalDate().format(DATE_FMT));
            }
            if (record.getTotalAllowanceAmount() != null) {
                dto.setTotalAllowanceAmount(record.getTotalAllowanceAmount().doubleValue());
            }
            if (!StringUtils.hasText(dto.getDocumentType())) {
                dto.setDocumentType("日常报销单");
            }
            return dto;
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("报销单数据解析失败", e);
        }
    }

    private ReimbursementRecord getExistingReimbursementRecord(Long id) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        return record;
    }

    private ReimbursementDto getExistingReimbursementDto(Long id) {
        return toDto(getExistingReimbursementRecord(id));
    }

    private ReimbursementDto.TravelRecord findTravelRecord(ReimbursementDto dto, String recordKey) {
        if (!StringUtils.hasText(recordKey)) {
            throw new IllegalArgumentException("补录行程标识不能为空");
        }
        if (dto.getTravelRecords() == null) {
            throw new IllegalArgumentException("补录行程不存在");
        }
        return dto.getTravelRecords().stream()
                .filter(item -> recordKey.equals(item.getId()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("补录行程不存在"));
    }

    private ReimbursementDto.CostAllocation findCostAllocation(ReimbursementDto dto, String allocationKey) {
        if (!StringUtils.hasText(allocationKey)) {
            throw new IllegalArgumentException("分摊信息标识不能为空");
        }
        if (dto.getCostAllocations() == null) {
            throw new IllegalArgumentException("分摊信息不存在");
        }
        return dto.getCostAllocations().stream()
                .filter(item -> allocationKey.equals(item.getId()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("分摊信息不存在"));
    }

    private double sumAllowanceAmount(List<ReimbursementDto.AllowanceInfo> allowances) {
        if (allowances == null) {
            return 0D;
        }
        return allowances.stream()
                .mapToDouble(item -> item.getTotalAllowanceAmount() != null ? item.getTotalAllowanceAmount() : 0D)
                .sum();
    }

    private double sumPersistedAllowanceAmount(List<ReimbursementAllowance> allowances) {
        if (allowances == null) {
            return 0D;
        }
        return allowances.stream()
                .map(ReimbursementAllowance::getTotalAllowanceAmount)
                .filter(java.util.Objects::nonNull)
                .mapToDouble(BigDecimal::doubleValue)
                .sum();
    }

    private double sumMealAmount(List<ReimbursementDto.AllowanceInfo> allowances) {
        return allowanceCalendarStream(allowances)
                .mapToDouble(item -> Boolean.TRUE.equals(item.getMealSelected()) && item.getMealAmount() != null
                        ? item.getMealAmount() : 0D)
                .sum();
    }

    private double sumTransportAmount(List<ReimbursementDto.AllowanceInfo> allowances) {
        return allowanceCalendarStream(allowances)
                .mapToDouble(item -> Boolean.TRUE.equals(item.getTransportSelected()) && item.getTransportAmount() != null
                        ? item.getTransportAmount() : 0D)
                .sum();
    }

    private double sumCommunicationAmount(List<ReimbursementDto.AllowanceInfo> allowances) {
        return allowanceCalendarStream(allowances)
                .mapToDouble(item -> Boolean.TRUE.equals(item.getCommunicationSelected()) && item.getCommunicationAmount() != null
                        ? item.getCommunicationAmount() : 0D)
                .sum();
    }

    private Stream<ReimbursementDto.AllowanceCalendarItem> allowanceCalendarStream(
            List<ReimbursementDto.AllowanceInfo> allowances) {
        if (allowances == null) {
            return Stream.empty();
        }
        return allowances.stream()
                .flatMap(item -> item.getCalendar() != null ? item.getCalendar().stream() : Stream.empty());
    }

    private double sumSelectedMealAmount(List<ReimbursementAllowanceCalendar> calendars) {
        if (calendars == null) {
            return 0D;
        }
        return calendars.stream()
                .mapToDouble(item -> Boolean.TRUE.equals(item.getMealSelected()) && item.getMealAmount() != null
                        ? item.getMealAmount().doubleValue() : 0D)
                .sum();
    }

    private double sumSelectedTransportAmount(List<ReimbursementAllowanceCalendar> calendars) {
        if (calendars == null) {
            return 0D;
        }
        return calendars.stream()
                .mapToDouble(item -> Boolean.TRUE.equals(item.getTransportSelected()) && item.getTransportAmount() != null
                        ? item.getTransportAmount().doubleValue() : 0D)
                .sum();
    }

    private double sumSelectedCommunicationAmount(List<ReimbursementAllowanceCalendar> calendars) {
        if (calendars == null) {
            return 0D;
        }
        return calendars.stream()
                .mapToDouble(item -> Boolean.TRUE.equals(item.getCommunicationSelected()) && item.getCommunicationAmount() != null
                        ? item.getCommunicationAmount().doubleValue() : 0D)
                .sum();
    }

    private ReimbursementAllowanceGenerateResult buildAllowanceGenerateResult(ReimbursementDto dto) {
        ReimbursementAllowanceGenerateResult result = new ReimbursementAllowanceGenerateResult();
        result.setAllowances(dto.getAllowances() != null ? dto.getAllowances() : List.of());
        result.setTotalAllowanceAmount(dto.getTotalAllowanceAmount() != null ? dto.getTotalAllowanceAmount() : 0D);
        result.setTotalMealAmount(dto.getTotalMealAmount() != null ? dto.getTotalMealAmount() : 0D);
        result.setTotalTransportAmount(dto.getTotalTransportAmount() != null ? dto.getTotalTransportAmount() : 0D);
        result.setTotalCommunicationAmount(
                dto.getTotalCommunicationAmount() != null ? dto.getTotalCommunicationAmount() : 0D);
        return result;
    }

    private ReimbursementDto.CostAllocation toCostAllocationDto(ReimbursementCostAllocation entity) {
        ReimbursementDto.CostAllocation dto = new ReimbursementDto.CostAllocation();
        dto.setId(entity.getAllocationKey());
        dto.setCompanyId(entity.getCompanyId());
        dto.setCompanyName(entity.getCompanyName());
        dto.setCompanyNo(entity.getCompanyNo());
        dto.setProjectId(entity.getProjectId());
        dto.setProjectName(entity.getProjectName());
        dto.setProjectNo(entity.getProjectNo());
        dto.setRatio(entity.getRatio() != null ? entity.getRatio().doubleValue() : 0D);
        dto.setAmount(entity.getAmount() != null ? entity.getAmount().doubleValue() : 0D);
        return dto;
    }

    private List<EvenAllocationItem> calculateEvenAllocations(double totalAmount, int count) {
        List<EvenAllocationItem> results = new ArrayList<>();
        if (count <= 0) {
            return results;
        }
        if (count == 1) {
            results.add(new EvenAllocationItem(1D, roundHalfEven(totalAmount, 2)));
            return results;
        }

        double baseRatio = roundHalfEven(1D / count, 4);
        double baseAmount = roundHalfEven(totalAmount * baseRatio, 2);
        double otherRatioSum = 0D;
        double otherAmountSum = 0D;

        results.add(new EvenAllocationItem(0D, 0D));
        for (int i = 1; i < count; i++) {
            results.add(new EvenAllocationItem(baseRatio, baseAmount));
            otherRatioSum += baseRatio;
            otherAmountSum += baseAmount;
        }

        results.set(0, new EvenAllocationItem(
                roundHalfEven(1D - otherRatioSum, 4),
                roundHalfEven(totalAmount - otherAmountSum, 2)));
        return results;
    }

    private double roundHalfEven(double value, int scale) {
        return BigDecimal.valueOf(value)
                .setScale(scale, RoundingMode.HALF_EVEN)
                .doubleValue();
    }

    private ReimbursementDto.CostAllocation createInitialCostAllocation(ReimbursementDto.CostAllocation source) {
        ReimbursementDto.CostAllocation dto = new ReimbursementDto.CostAllocation();
        if (source != null && StringUtils.hasText(source.getId())) {
            dto.setId(source.getId());
        } else {
            dto.setId("allocation_" + System.currentTimeMillis());
        }
        dto.setCompanyId("");
        dto.setCompanyName("");
        dto.setCompanyNo("");
        dto.setProjectId("");
        dto.setProjectName("");
        dto.setProjectNo("");
        dto.setRatio(0D);
        dto.setAmount(0D);
        return dto;
    }

    private static class EvenAllocationItem {
        private final double ratio;
        private final double amount;

        private EvenAllocationItem(double ratio, double amount) {
            this.ratio = ratio;
            this.amount = amount;
        }

        public double getRatio() {
            return ratio;
        }

        public double getAmount() {
            return amount;
        }
    }
}
