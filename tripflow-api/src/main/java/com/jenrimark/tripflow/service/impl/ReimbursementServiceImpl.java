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

    /**
     * 注入报销单服务实现依赖的序列化、校验和数据访问组件。
     */
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

    /**
     * 按条件分页查询报销单列表。
     */
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

    /**
     * 查询指定报销单详情，并将存储内容转换为前端使用的 DTO。
     */
    @Override
    public ReimbursementDto getDetail(Long id) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        return toDto(record);
    }

    /**
     * 新增报销单主表和全部子表数据。（初始化报销单）
     */
    @Override
    @Transactional
    public ReimbursementDto create(ReimbursementDto dto) {
        // 校验报销单数据（保存级别）
        validator.validateForSave(dto);
        // 创建主表对象
        ReimbursementRecord record = new ReimbursementRecord();
        // 生成报销单号
        record.setDocumentNo(generateDocumentNo());
        // 设置状态码（前端没传就默认为0（草稿））
        record.setStatus(dto.getStatus() != null ? dto.getStatus() : 0);
        // 设置创建时间和更新时间
        record.setCreatedAt(LocalDateTime.now());
        record.setUpdatedAt(LocalDateTime.now());
        // 把前端传来的dto数据映射到主表对象record
        applyDtoToRecord(dto, record);
        // 保存到主表reimbursement
        save(record);
        // 保存子表数据（补录行程，补助信息，补助日历，费用分摊）
        childRecordService.replaceChildRecords(record.getId(), dto);
        return toDto(record);
    }

    /**
     * 更新报销单主表并整体重建关联子表数据。
     */
    @Override
    @Transactional
    public ReimbursementDto update(Long id, ReimbursementDto dto) {
        // 根据报销单id查询报销单
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }

        // 校验报销单数据
        validator.validateForSave(dto);
        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        // 更新主表数据
        updateById(record);
        // 更新子表数据
        childRecordService.replaceChildRecords(id, dto);
        return toDto(record);
    }

    /**
     * 只更新报销单备注信息，并同步更新 content JSON 中的备注字段。
     */
    @Override
    public ReimbursementDto updateRemark(Long id, ReimbursementRemarkRequest request) {
        // 根据报销单id查询主表数据
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        ReimbursementDto dto = toDto(record);

        // 修改dto中的备注信息
        dto.setRemark(request != null ? request.getRemark() : null);
        // 校验备注
        validator.validateRemark(dto.getRemark());

        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        // 更新主表数据
        updateById(record);
        return toDto(record);
    }

    /**
     * 清空指定报销单的备注信息。
     */
    @Override
    public ReimbursementDto clearRemark(Long id) {
        return updateRemark(id, null);
    }

    /**
     * 根据已有补录行程自动生成补助信息并落盘。
     */
    @Override
    @Transactional
    public ReimbursementAllowanceGenerateResult generateAllowances(Long id) {
        // 根据报销单id查询主表数据
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        ReimbursementDto dto = toDto(record);

        // 判断补录行程是否为空
        if (dto.getTravelRecords() == null || dto.getTravelRecords().isEmpty()) {
            throw new IllegalArgumentException("请先填写补录行程");
        }

        // 计算补助信息
        dto.setAllowances(allowanceGenerationService.generate(dto.getTravelRecords()));
        // 计算四个汇总字段
        dto.setTotalAllowanceAmount(sumAllowanceAmount(dto.getAllowances()));
        dto.setTotalMealAmount(sumMealAmount(dto.getAllowances()));
        dto.setTotalTransportAmount(sumTransportAmount(dto.getAllowances()));
        dto.setTotalCommunicationAmount(sumCommunicationAmount(dto.getAllowances()));

        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        // 更新主表数据
        updateById(record);
        // 重建子表数据
        childRecordService.replaceChildRecords(id, dto);
        return buildAllowanceGenerateResult(dto);
    }

    /**
     * 汇总指定报销单的补助总金额、餐补、交通补助和通讯补助。
     */
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

    /**
     * 查询指定报销单下的全部费用归属及分摊记录。
     */
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

    /**
     * 按当前分摊行数对比例和金额做均摊，并将结果回写数据库。
     */
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

    /**
     * 为指定报销单新增一条初始化的分摊记录。
     */
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

    /**
     * 修改指定报销单中的某条分摊记录。
     */
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

    /**
     * 删除指定报销单中的某条分摊记录，并校验至少保留一条数据。
     */
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

    /**
     * 查询指定报销单下的全部补录行程。
     */
    @Override
    @Transactional
    public List<ReimbursementDto.TravelRecord> listTravelRecords(Long id) {
        ReimbursementDto dto = getExistingReimbursementDto(id);
        return dto.getTravelRecords() != null ? dto.getTravelRecords() : List.of();
    }

    /**
     * 查询指定报销单中的单条补录行程。
     */
    @Override
    @Transactional
    public ReimbursementDto.TravelRecord getTravelRecord(Long id, String recordKey) {
        ReimbursementDto dto = getExistingReimbursementDto(id);
        return findTravelRecord(dto, recordKey);
    }

    /**
     * 为指定报销单新增一条补录行程。
     */
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

    /**
     * 修改指定报销单中的某条补录行程。
     */
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

    /**
     * 删除指定补录行程，并同步清理关联补助信息。
     */
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

    /**
     * 删除报销单主表及其所有关联子表数据。
     */
    @Override
    @Transactional
    public void delete(Long id) {
        if (getById(id) == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        childRecordService.deleteChildRecords(id);
        removeById(id);
    }

    /**
     * 提交报销单，并同步更新 content JSON 中的状态值。
     */
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

    /**
     * 作废报销单，并同步更新 content JSON 中的状态值。
     */
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

    /**
     * 将主表中的状态值同步回 content JSON，保持两份数据一致。
     */
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

    /**
     * 生成新的报销单号。
     */
    private String generateDocumentNo() {
        return "REIM" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
                + String.format("%04d", System.currentTimeMillis() % 10000);
    }

    /**
     * 将报销单 DTO 中的字段映射回主表实体，并刷新 content JSON。
     */
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

    /**
     * 将主表记录和 content JSON 反序列化为统一的报销单 DTO。
     */
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

    /**
     * 获取指定报销单主表记录，不存在时直接抛出异常。
     */
    private ReimbursementRecord getExistingReimbursementRecord(Long id) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        return record;
    }

    /**
     * 获取指定报销单的 DTO 形式数据。
     */
    private ReimbursementDto getExistingReimbursementDto(Long id) {
        return toDto(getExistingReimbursementRecord(id));
    }

    /**
     * 从当前报销单中按标识查找指定补录行程。
     */
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

    /**
     * 从当前报销单中按标识查找指定分摊记录。
     */
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

    /**
     * 汇总补助列表中的补助总金额。
     */
    private double sumAllowanceAmount(List<ReimbursementDto.AllowanceInfo> allowances) {
        if (allowances == null) {
            return 0D;
        }
        return allowances.stream()
                .mapToDouble(item -> item.getTotalAllowanceAmount() != null ? item.getTotalAllowanceAmount() : 0D)
                .sum();
    }

    /**
     * 汇总已落库补助主表中的补助总金额。
     */
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

    /**
     * 汇总 DTO 中已勾选的餐费补助金额。
     */
    private double sumMealAmount(List<ReimbursementDto.AllowanceInfo> allowances) {
        return allowanceCalendarStream(allowances)
                .mapToDouble(item -> Boolean.TRUE.equals(item.getMealSelected()) && item.getMealAmount() != null
                        ? item.getMealAmount() : 0D)
                .sum();
    }

    /**
     * 汇总 DTO 中已勾选的交通补助金额。
     */
    private double sumTransportAmount(List<ReimbursementDto.AllowanceInfo> allowances) {
        return allowanceCalendarStream(allowances)
                .mapToDouble(item -> Boolean.TRUE.equals(item.getTransportSelected()) && item.getTransportAmount() != null
                        ? item.getTransportAmount() : 0D)
                .sum();
    }

    /**
     * 汇总 DTO 中已勾选的通讯补助金额。
     */
    private double sumCommunicationAmount(List<ReimbursementDto.AllowanceInfo> allowances) {
        return allowanceCalendarStream(allowances)
                .mapToDouble(item -> Boolean.TRUE.equals(item.getCommunicationSelected()) && item.getCommunicationAmount() != null
                        ? item.getCommunicationAmount() : 0D)
                .sum();
    }

    /**
     * 将补助列表中的日历明细打平成统一流，方便做金额汇总。
     */
    private Stream<ReimbursementDto.AllowanceCalendarItem> allowanceCalendarStream(
            List<ReimbursementDto.AllowanceInfo> allowances) {
        if (allowances == null) {
            return Stream.empty();
        }
        return allowances.stream()
                .flatMap(item -> item.getCalendar() != null ? item.getCalendar().stream() : Stream.empty());
    }

    /**
     * 汇总已落库补助日历中已勾选的餐费金额。
     */
    private double sumSelectedMealAmount(List<ReimbursementAllowanceCalendar> calendars) {
        if (calendars == null) {
            return 0D;
        }
        return calendars.stream()
                .mapToDouble(item -> Boolean.TRUE.equals(item.getMealSelected()) && item.getMealAmount() != null
                        ? item.getMealAmount().doubleValue() : 0D)
                .sum();
    }

    /**
     * 汇总已落库补助日历中已勾选的交通补助金额。
     */
    private double sumSelectedTransportAmount(List<ReimbursementAllowanceCalendar> calendars) {
        if (calendars == null) {
            return 0D;
        }
        return calendars.stream()
                .mapToDouble(item -> Boolean.TRUE.equals(item.getTransportSelected()) && item.getTransportAmount() != null
                        ? item.getTransportAmount().doubleValue() : 0D)
                .sum();
    }

    /**
     * 汇总已落库补助日历中已勾选的通讯补助金额。
     */
    private double sumSelectedCommunicationAmount(List<ReimbursementAllowanceCalendar> calendars) {
        if (calendars == null) {
            return 0D;
        }
        return calendars.stream()
                .mapToDouble(item -> Boolean.TRUE.equals(item.getCommunicationSelected()) && item.getCommunicationAmount() != null
                        ? item.getCommunicationAmount().doubleValue() : 0D)
                .sum();
    }

    /**
     * 将生成后的补助列表和费用汇总字段组装成接口返回结果。
     */
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

    /**
     * 将费用分摊实体转换为前端使用的 DTO。
     */
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

    /**
     * 按分摊行数计算均摊后的比例和金额，差值放在首行。
     */
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

    /**
     * 使用银行家舍入规则对数值按指定精度进行四舍六入五成双处理。
     */
    private double roundHalfEven(double value, int scale) {
        return BigDecimal.valueOf(value)
                .setScale(scale, RoundingMode.HALF_EVEN)
                .doubleValue();
    }

    /**
     * 创建一条用于初始化展示的空白分摊记录。
     */
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

    /**
     * 均摊结果项，保存单行分摊比例和金额。
     */
    private static class EvenAllocationItem {
        private final double ratio;
        private final double amount;

        /**
         * 构造单条均摊结果。
         */
        private EvenAllocationItem(double ratio, double amount) {
            this.ratio = ratio;
            this.amount = amount;
        }

        /**
         * 返回当前结果项的分摊比例。
         */
        public double getRatio() {
            return ratio;
        }

        /**
         * 返回当前结果项的分摊金额。
         */
        public double getAmount() {
            return amount;
        }
    }
}
