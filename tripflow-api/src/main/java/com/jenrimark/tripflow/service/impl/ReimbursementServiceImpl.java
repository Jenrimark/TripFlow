package com.jenrimark.tripflow.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jenrimark.tripflow.config.TripflowCacheKeys;
import com.jenrimark.tripflow.config.TripflowCacheNames;
import com.jenrimark.tripflow.dto.calendar.AllowanceCalendarAddResult;
import com.jenrimark.tripflow.dto.calendar.AllowanceCalendarDto;
import com.jenrimark.tripflow.dto.calendar.AllowanceCalendarRequest;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementAllowanceGenerateResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementExpenseSummaryResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementListResult;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementRemarkRequest;
import com.jenrimark.tripflow.exception.ReimbursementVersionConflictException;
import com.jenrimark.tripflow.entity.ReimbursementAllowance;
import com.jenrimark.tripflow.entity.ReimbursementAllowanceCalendar;
import com.jenrimark.tripflow.entity.ReimbursementCostAllocation;
import com.jenrimark.tripflow.entity.ReimbursementRecord;
import com.jenrimark.tripflow.entity.ReimbursementTravelRecord;
import com.jenrimark.tripflow.mapper.ReimbursementAllowanceCalendarMapper;
import com.jenrimark.tripflow.mapper.ReimbursementAllowanceMapper;
import com.jenrimark.tripflow.mapper.ReimbursementCostAllocationMapper;
import com.jenrimark.tripflow.mapper.ReimbursementMapper;
import com.jenrimark.tripflow.mapper.ReimbursementTravelRecordMapper;
import com.jenrimark.tripflow.service.ReimbursementService;
import com.jenrimark.tripflow.service.reimbursement.ReimbursementAllowanceGenerationService;
import com.jenrimark.tripflow.service.reimbursement.ReimbursementCacheService;
import com.jenrimark.tripflow.service.reimbursement.ReimbursementChildRecordService;
import com.jenrimark.tripflow.service.reimbursement.ReimbursementValidator;
import org.springframework.cache.annotation.Cacheable;
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
    private static final DateTimeFormatter DATETIME_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final ObjectMapper objectMapper;
    private final ReimbursementValidator validator;
    private final ReimbursementAllowanceGenerationService allowanceGenerationService;
    private final ReimbursementCacheService reimbursementCacheService;
    private final ReimbursementChildRecordService childRecordService;
    private final ReimbursementAllowanceMapper allowanceMapper;
    private final ReimbursementAllowanceCalendarMapper calendarMapper;
    private final ReimbursementCostAllocationMapper costAllocationMapper;
    private final ReimbursementTravelRecordMapper travelRecordMapper;

    /**
     * 注入报销单服务实现依赖的序列化、校验和数据访问组件。
     */
    public ReimbursementServiceImpl(
            ObjectMapper objectMapper,
            ReimbursementValidator validator,
            ReimbursementAllowanceGenerationService allowanceGenerationService,
            ReimbursementCacheService reimbursementCacheService,
            ReimbursementChildRecordService childRecordService,
            ReimbursementAllowanceMapper allowanceMapper,
            ReimbursementAllowanceCalendarMapper calendarMapper,
            ReimbursementCostAllocationMapper costAllocationMapper,
            ReimbursementTravelRecordMapper travelRecordMapper) {
        this.objectMapper = objectMapper;
        this.validator = validator;
        this.allowanceGenerationService = allowanceGenerationService;
        this.reimbursementCacheService = reimbursementCacheService;
        this.childRecordService = childRecordService;
        this.allowanceMapper = allowanceMapper;
        this.calendarMapper = calendarMapper;
        this.costAllocationMapper = costAllocationMapper;
        this.travelRecordMapper = travelRecordMapper;
    }

    private ReimbursementDto toDto(ReimbursementRecord record) {
        return toDetailDto(record);
    }

    /**
     * 把主表record对象 映射到 报销单对象（ReimbursementDto）,并补齐子表信息
     * */
    private ReimbursementDto toDetailDto(ReimbursementRecord record) {
        ReimbursementDto dto = toListDto(record);
        // 查询补录行程子表
        dto.setTravelRecords(childRecordService.loadTravelRecords(record.getId()));
        // 查询补助信息子表
        dto.setAllowances(childRecordService.loadAllowances(record.getId()));
        // 查询费用归属及分摊子表
        dto.setCostAllocations(childRecordService.loadCostAllocations(record.getId()));
        // 重新计算汇总金额
        dto.setTotalAllowanceAmount(sumAllowanceAmount(dto.getAllowances()));
        dto.setTotalMealAmount(sumMealAmount(dto.getAllowances()));
        dto.setTotalTransportAmount(sumTransportAmount(dto.getAllowances()));
        dto.setTotalCommunicationAmount(sumCommunicationAmount(dto.getAllowances()));
        return dto;
    }

    /**
     * 按条件分页查询报销单列表。
     */
    @Override
    @Cacheable(
            cacheNames = TripflowCacheNames.REIMBURSEMENT_LIST,
            key = "T(com.jenrimark.tripflow.config.TripflowCacheKeys).reimbursementListKey("
                    + "#documentNo, #title, #reason, #companyIds, #departmentIds, "
                    + "#reimburserIds, #businessTypeIds, #page, #pageSize)")
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
        result.setList(pageResult.getRecords().stream().map(this::toListDto).toList());
        result.setTotal(pageResult.getTotal());
        result.setPage(page);
        result.setPageSize(pageSize);
        return result;
    }

    /**
     * 查询指定报销单详情，并将存储内容转换为前端使用的 DTO。
     */
    @Override
    @Cacheable(cacheNames = TripflowCacheNames.REIMBURSEMENT_DETAIL, key = "#id")
    public ReimbursementDto getDetail(Long id) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        return rebuildSnapshotAndLoadDetail(record.getId());
    }

    /**
     * 新增报销单主表和全部子表数据。（初始化报销单）
     */
    @Override
    @Transactional
    public ReimbursementDto create(ReimbursementDto dto) {
        // 校验报销单数据（保存级别）
        validator.validateForSave(dto);
        beginReimbursementListCacheDoubleDelete();  // 删除缓存
        // 创建主表对象
        ReimbursementRecord record = new ReimbursementRecord();
        // 生成报销单号
        record.setDocumentNo(generateDocumentNo());
        // 设置状态码（前端没传就默认为0（草稿））
        record.setStatus(dto.getStatus() != null ? dto.getStatus() : 0);
        record.setVersion(0L);
        // 设置创建时间和更新时间
        record.setCreatedAt(LocalDateTime.now());
        record.setUpdatedAt(LocalDateTime.now());
        // 把前端传来的dto数据映射到主表对象record
        applyDtoToRecord(dto, record);
        // 保存到主表reimbursement
        save(record);
        beginReimbursementDetailCacheDoubleDelete(record.getId());
        // 保存子表数据（补录行程，补助信息，补助日历，费用分摊）
        childRecordService.replaceChildRecords(record.getId(), dto);
        return rebuildSnapshotAndLoadDetail(record.getId());
    }

    /**
     * 更新报销单主表 并 更新子表数据。
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
        assertVersionMatches(record, dto.getVersion());
        beginReimbursementCacheDoubleDelete(id);
        record.setUpdatedAt(LocalDateTime.now());
        applyDtoToRecord(dto, record);
        // 更新主表数据
        updateRecordWithVersionCheck(record, dto.getVersion());
        // 更新子表数据
        childRecordService.replaceChildRecords(id, dto);
        return rebuildSnapshotAndLoadDetail(id);
    }

    /**
     * 只更新报销单备注信息，并同步更新 content JSON 中的备注字段。
     */
    @Override
    @Transactional
    public ReimbursementDto updateRemark(Long id, ReimbursementRemarkRequest request) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        String remark = request != null ? request.getRemark() : null;
        // 校验备注数据
        validator.validateRemark(remark);
        Long version = request != null ? request.getVersion() : null;
        assertVersionMatches(record, version);
        beginReimbursementCacheDoubleDelete(id);

        // 更新备注
        record.setRemark(remark);
        record.setUpdatedAt(LocalDateTime.now());
        // 更新主表快照
        ReimbursementDto snapshot = toListDto(record);
        record.setContent(writeSnapshot(snapshot, record));
        // 更新数据库
        updateRecordWithVersionCheck(record, version);
        return rebuildSnapshotAndLoadDetail(id);
    }

    /**
     * 清空指定报销单的备注信息。
     */
    @Override
    @Transactional
    public ReimbursementDto clearRemark(Long id, Long version) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        beginReimbursementCacheDoubleDelete(id);
        record.setRemark(null);
        record.setUpdatedAt(LocalDateTime.now());
        ReimbursementDto snapshot = toListDto(record);
        record.setContent(writeSnapshot(snapshot, record));
        updateRecordWithVersionCheck(record, version);
        return rebuildSnapshotAndLoadDetail(id);
    }

    /**
     * 根据已有补录行程自动生成补助信息并落盘。
     */
    @Override
    @Transactional
    public ReimbursementAllowanceGenerateResult generateAllowances(Long id, Long version) {
        // 根据报销单id查询主表数据
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        ReimbursementDto dto = toDto(record);

        // 判断补录行程是否为空
        if (dto.getTravelRecords() == null || dto.getTravelRecords().isEmpty()) {
            throw new IllegalArgumentException("请先填写补录行程");
        }
        beginReimbursementCacheDoubleDelete(id);

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
        updateRecordWithVersionCheck(record, version);
        // 重建子表数据
        childRecordService.replaceChildRecords(id, dto);
        return buildAllowanceGenerateResult(rebuildSnapshotAndLoadDetail(id));
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
    public List<ReimbursementDto.CostAllocation> evenlyDistributeCostAllocations(Long id, Long version) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        List<ReimbursementCostAllocation> allocations = loadCostAllocationEntities(id);
        if (allocations.isEmpty()) {
            throw new IllegalArgumentException("请至少添加一条分摊信息");
        }
        beginReimbursementCacheDoubleDelete(id);

        int count = allocations.size();
        double totalAmount = getTotalAllowanceAmount(record);
        List<EvenAllocationItem> evenResults = calculateEvenAllocations(totalAmount, count);

        for (int i = 0; i < count; i++) {
            ReimbursementCostAllocation allocation = allocations.get(i);
            EvenAllocationItem evenItem = evenResults.get(i);
            allocation.setRatio(toRatioDecimal(evenItem.getRatio()));
            allocation.setAmount(toAmountDecimal(evenItem.getAmount()));
        }

        validateCostAllocationListIfComplete(allocations, totalAmount);
        updateCostAllocationEntities(allocations);
        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
        return rebuildSnapshotAndLoadDetail(id).getCostAllocations();
    }

    /**
     * 为指定报销单新增一条初始化的分摊记录。
     */
    @Override
    @Transactional
    public ReimbursementDto.CostAllocation addCostAllocation(
            Long id,
            Long version,
            ReimbursementDto.CostAllocation costAllocation) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        beginReimbursementCacheDoubleDelete(id);
        ReimbursementDto.CostAllocation newAllocation = createInitialCostAllocation(costAllocation);
        long existingCount = costAllocationMapper.selectCount(
                new LambdaQueryWrapper<ReimbursementCostAllocation>()
                        .eq(ReimbursementCostAllocation::getReimbursementId, id));

        ReimbursementCostAllocation entity = new ReimbursementCostAllocation();
        entity.setReimbursementId(id);
        entity.setAllocationKey(newAllocation.getId());
        entity.setCompanyId(newAllocation.getCompanyId());
        entity.setCompanyName(newAllocation.getCompanyName());
        entity.setCompanyNo(newAllocation.getCompanyNo());
        entity.setProjectId(newAllocation.getProjectId());
        entity.setProjectName(newAllocation.getProjectName());
        entity.setProjectNo(newAllocation.getProjectNo());
        entity.setRatio(BigDecimal.ZERO);
        entity.setAmount(BigDecimal.ZERO);
        entity.setSortOrder((int) existingCount);
        costAllocationMapper.insert(entity);

        List<ReimbursementCostAllocation> allocations = loadCostAllocationEntities(id);
        recalculateCostAllocationRows(allocations, getTotalAllowanceAmount(record));
        updateCostAllocationEntities(allocations);

        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
        return findCostAllocation(rebuildSnapshotAndLoadDetail(id), newAllocation.getId());
    }

    /**
     * 修改指定报销单中的某条分摊记录。
     */
    @Override
    @Transactional
    public ReimbursementDto.CostAllocation updateCostAllocation(Long id, String allocationKey, Long version,
            ReimbursementDto.CostAllocation costAllocation) {
        // 先确认报销单存在，再读取当前分摊修改请求
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        if (costAllocation == null) {
            throw new IllegalArgumentException("分摊信息不能为空");
        }
        beginReimbursementCacheDoubleDelete(id);

        // 查询当前报销单下的全部分摊行，并定位要修改的目标记录
        List<ReimbursementCostAllocation> allocations = loadCostAllocationEntities(id);
        ReimbursementCostAllocation target = findCostAllocationEntity(allocations, allocationKey);
        ReimbursementDto.CostAllocation mergedAllocation =
                mergeCostAllocationDraft(toCostAllocationDto(target), costAllocation);
        validateCostAllocationDraft(mergedAllocation);

        // 先更新当前行，再统一重算整张分摊表，自动回写首行比例和金额
        applyCostAllocationChange(target, mergedAllocation);
        // 重新计算分摊金额
        recalculateCostAllocationRows(allocations, getTotalAllowanceAmount(record));
        validateCostAllocationListIfComplete(allocations, getTotalAllowanceAmount(record));
        updateCostAllocationEntities(allocations);

        // 同步主表更新时间，并重建快照后返回最新结果
        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
        return findCostAllocation(rebuildSnapshotAndLoadDetail(id), allocationKey);
    }

    /**
     * 删除指定报销单中的某条分摊记录，并校验至少保留一条数据。
     */
    @Override
    @Transactional
    public void deleteCostAllocation(Long id, String allocationKey, Long version) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        // 先查询当前报销单下的全部分摊行，并确认待删除记录存在
        List<ReimbursementCostAllocation> allocations = loadCostAllocationEntities(id);
        if (allocations.size() <= 1) {
            throw new IllegalArgumentException("至少保留一条分摊信息");
        }
        beginReimbursementCacheDoubleDelete(id);

        ReimbursementCostAllocation target = findCostAllocationEntity(allocations, allocationKey);

        // 删除分摊行本身，不再因为其余分摊行暂未填写完整而拦截删除操作
        costAllocationMapper.deleteById(target.getId());

        List<ReimbursementCostAllocation> remainingAllocations = loadCostAllocationEntities(id);
        recalculateCostAllocationRows(remainingAllocations, getTotalAllowanceAmount(record));
        updateCostAllocationEntities(remainingAllocations);

        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
        rebuildSnapshot(id);
    }

    /**
     * 查询指定报销单下的全部补录行程。
     */
    @Override
    @Transactional
    public List<ReimbursementDto.TravelRecord> listTravelRecords(Long id) {
        getExistingReimbursementRecord(id);
        return childRecordService.loadTravelRecords(id);
    }

    /**
     * 查询指定报销单中的单条补录行程。
     */
    @Override
    @Transactional
    public ReimbursementDto.TravelRecord getTravelRecord(Long id, String recordKey) {
        getExistingReimbursementRecord(id);
        return childRecordService.loadTravelRecord(id, recordKey);
    }

    /**
     * 为指定报销单新增一条补录行程。
     */
    @Override
    @Transactional
    public ReimbursementDto.TravelRecord addTravelRecord(Long id, Long version, ReimbursementDto.TravelRecord travelRecord) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        if (travelRecord == null) {
            throw new IllegalArgumentException("补录行程不能为空");
        }

        if (!StringUtils.hasText(travelRecord.getId())) {
            travelRecord.setId("travel_" + System.currentTimeMillis());
        }
        beginReimbursementCacheDoubleDelete(id);

        List<ReimbursementDto.TravelRecord> travelRecords = childRecordService.loadTravelRecords(id);
        travelRecords.add(travelRecord);
        validateTravelRecordList(travelRecords);

        travelRecordMapper.insert(toTravelRecordEntity(id, travelRecord));
        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
        rebuildSnapshot(id);
        return childRecordService.loadTravelRecord(id, travelRecord.getId());
    }

    /**
     * 修改指定报销单中的某条补录行程。
     */
    @Override
    @Transactional
    public ReimbursementDto.TravelRecord updateTravelRecord(
            Long id,
            String recordKey,
            Long version,
            ReimbursementDto.TravelRecord travelRecord) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        if (travelRecord == null) {
            throw new IllegalArgumentException("补录行程不能为空");
        }
        beginReimbursementCacheDoubleDelete(id);

        ReimbursementTravelRecord existing = getTravelRecordEntity(id, recordKey);
        ReimbursementDto.TravelRecord mergedTravelRecord = mergeTravelRecordDraft(toTravelRecordDto(existing), travelRecord);
        mergedTravelRecord.setId(recordKey);

        List<ReimbursementDto.TravelRecord> travelRecords = childRecordService.loadTravelRecords(id).stream()
                .map(item -> recordKey.equals(item.getId()) ? mergedTravelRecord : item)
                .toList();
        validateTravelRecordList(travelRecords);

        applyTravelRecordChange(existing, mergedTravelRecord);
        travelRecordMapper.updateById(existing);
        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
        rebuildSnapshot(id);
        return childRecordService.loadTravelRecord(id, recordKey);
    }

    /**
     * 删除指定补录行程，并同步清理关联补助信息。
     */
    @Override
    @Transactional
    public void deleteTravelRecord(Long id, String recordKey, Long version) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        getTravelRecordEntity(id, recordKey);
        beginReimbursementCacheDoubleDelete(id);

        List<ReimbursementAllowance> allowances = allowanceMapper.selectList(
                new LambdaQueryWrapper<ReimbursementAllowance>()
                        .eq(ReimbursementAllowance::getReimbursementId, id)
                        .eq(ReimbursementAllowance::getTravelRecordKey, recordKey));
        for (ReimbursementAllowance allowance : allowances) {
            calendarMapper.delete(new LambdaQueryWrapper<ReimbursementAllowanceCalendar>()
                    .eq(ReimbursementAllowanceCalendar::getAllowanceId, allowance.getId()));
        }
        allowanceMapper.delete(new LambdaQueryWrapper<ReimbursementAllowance>()
                .eq(ReimbursementAllowance::getReimbursementId, id)
                .eq(ReimbursementAllowance::getTravelRecordKey, recordKey));
        travelRecordMapper.delete(new LambdaQueryWrapper<ReimbursementTravelRecord>()
                .eq(ReimbursementTravelRecord::getReimbursementId, id)
                .eq(ReimbursementTravelRecord::getRecordKey, recordKey));

        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
        rebuildSnapshot(id);
    }

    /**
     * 删除报销单主表及其所有关联子表数据。
     */
    @Override
    @Transactional
    public void delete(Long id, Long version) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        assertVersionMatches(record, version);
        beginReimbursementCacheDoubleDelete(id);
        childRecordService.deleteChildRecords(id);
        int deleted = baseMapper.delete(new LambdaQueryWrapper<ReimbursementRecord>()
                .eq(ReimbursementRecord::getId, id)
                .eq(ReimbursementRecord::getVersion, version));
        if (deleted == 0) {
            throw new ReimbursementVersionConflictException("报销单已被其他用户修改，请刷新后重试");
        }
    }

    /**
     * 提交报销单，并同步更新 content JSON 中的状态值。
     */
    @Override
    @Transactional
    public void submit(Long id, Long version) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        assertVersionMatches(record, version);
        beginReimbursementCacheDoubleDelete(id);
        ReimbursementDto dto = toDto(record);
        validator.validateForSubmit(dto);
        record.setStatus(1);
        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
        syncStatusToContent(record);
    }

    /**
     * 作废报销单，并同步更新 content JSON 中的状态值。
     */
    @Override
    @Transactional
    public void voidDocument(Long id, Long version) {
        ReimbursementRecord record = getById(id);
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");
        }
        assertVersionMatches(record, version);
        beginReimbursementCacheDoubleDelete(id);
        record.setStatus(2);
        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
        syncStatusToContent(record);
    }

    /**
     * 将主表中的状态值同步回 content JSON，保持两份数据一致。
     */
    private void syncStatusToContent(ReimbursementRecord record) {
        rebuildSnapshot(record.getId());
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
            record.setContent(objectMapper.writeValueAsString(buildSnapshotDto(record, dto)));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("报销单数据序列化失败", e);
        }
    }

    /**
     * 将主表记录和 content JSON 反序列化为统一的报销单 DTO。
     */
    private ReimbursementDto toListDto(ReimbursementRecord record) {
        try {
            ReimbursementDto dto = objectMapper.readValue(record.getContent(), ReimbursementDto.class);
            dto.setId(String.valueOf(record.getId()));
            dto.setDocumentNo(record.getDocumentNo());
            dto.setVersion(record.getVersion());
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

    private ReimbursementDto rebuildSnapshotAndLoadDetail(Long id) {
        refreshSnapshotContent(id);
        return toDto(getExistingReimbursementRecord(id));
    }

    private void rebuildSnapshot(Long id) {
        refreshSnapshotContent(id);
    }

    private ReimbursementDto buildSnapshotDto(ReimbursementRecord record, ReimbursementDto dto) {
        if (record.getId() != null) {
            dto.setId(String.valueOf(record.getId()));
        }
        if (StringUtils.hasText(record.getDocumentNo())) {
            dto.setDocumentNo(record.getDocumentNo());
        }
        dto.setVersion(record.getVersion());
        dto.setStatus(record.getStatus());
        dto.setRemark(record.getRemark());
        if (record.getCreatedAt() != null) {
            dto.setCreatedAt(record.getCreatedAt().toLocalDate().format(DATE_FMT));
        }
        if (!StringUtils.hasText(dto.getDocumentType())) {
            dto.setDocumentType("日常报销单");
        }
        if (dto.getAllowances() != null) {
            dto.setTotalAllowanceAmount(sumAllowanceAmount(dto.getAllowances()));
            dto.setTotalMealAmount(sumMealAmount(dto.getAllowances()));
            dto.setTotalTransportAmount(sumTransportAmount(dto.getAllowances()));
            dto.setTotalCommunicationAmount(sumCommunicationAmount(dto.getAllowances()));
        } else if (record.getTotalAllowanceAmount() != null) {
            dto.setTotalAllowanceAmount(record.getTotalAllowanceAmount().doubleValue());
        }
        return dto;
    }

    private String writeSnapshot(ReimbursementDto dto, ReimbursementRecord record) {
        try {
            return objectMapper.writeValueAsString(buildSnapshotDto(record, dto));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("报销单数据序列化失败", e);
        }
    }

    /**
     * 对报销单列表缓存执行双删，降低列表查询读到旧缓存的概率。
     */
    private void beginReimbursementListCacheDoubleDelete() {
        reimbursementCacheService.doubleDeleteReimbursementListCache();
    }

    /**
     * 对指定报销单详情缓存执行双删，降低详情页读到旧缓存的概率。
     */
    private void beginReimbursementDetailCacheDoubleDelete(Long id) {
        reimbursementCacheService.doubleDeleteReimbursementDetailCache(id);
    }

    /**
     * 对报销单列表和当前报销单详情一起执行双删。
     */
    private void beginReimbursementCacheDoubleDelete(Long id) {
        beginReimbursementListCacheDoubleDelete();
        beginReimbursementDetailCacheDoubleDelete(id);
    }

    /**
     * 校验前端传入的版本号是否与当前主表版本一致。
     */
    private void assertVersionMatches(ReimbursementRecord record, Long expectedVersion) {
        if (expectedVersion == null) {
            throw new IllegalArgumentException("version不能为空");
        }
        if (record == null || record.getVersion() == null || !record.getVersion().equals(expectedVersion)) {
            throw new ReimbursementVersionConflictException("报销单已被其他用户修改，请刷新后重试");
        }
    }

    /**
     * 按乐观锁版本更新主表，更新失败时说明当前报销单已被其他用户修改。
     */
    private void updateRecordWithVersionCheck(ReimbursementRecord record, Long expectedVersion) {
        assertVersionMatches(record, expectedVersion);
        record.setVersion(expectedVersion);
        int updated = baseMapper.updateById(record);
        if (updated == 0) {
            throw new ReimbursementVersionConflictException("报销单已被其他用户修改，请刷新后重试");
        }
    }

    /**
     * 仅刷新主表中的 content 快照，不再额外递增版本号。
     */
    private void refreshSnapshotContent(Long id) {
        ReimbursementRecord record = getExistingReimbursementRecord(id);
        ReimbursementDto snapshot = toDetailDto(record);
        String content = writeSnapshot(snapshot, record);
        baseMapper.update(
                null,
                new LambdaUpdateWrapper<ReimbursementRecord>()
                        .eq(ReimbursementRecord::getId, id)
                        .set(ReimbursementRecord::getContent, content));
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
     * 查询指定报销单下的全部分摊实体记录。
     */
    private List<ReimbursementCostAllocation> loadCostAllocationEntities(Long reimbursementId) {
        return costAllocationMapper.selectList(
                new LambdaQueryWrapper<ReimbursementCostAllocation>()
                        .eq(ReimbursementCostAllocation::getReimbursementId, reimbursementId)
                        .orderByAsc(ReimbursementCostAllocation::getSortOrder, ReimbursementCostAllocation::getId));
    }

    /**
     * 在分摊实体列表中定位要更新的目标记录。
     */
    private ReimbursementCostAllocation findCostAllocationEntity(
            List<ReimbursementCostAllocation> allocations,
            String allocationKey) {
        return allocations.stream()
                .filter(item -> allocationKey.equals(item.getAllocationKey()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("分摊信息不存在"));
    }

    /**
     * 构造“修改后”的分摊列表，用于执行整体验证。
     */
    private List<ReimbursementDto.CostAllocation> buildValidatedCostAllocationList(
            List<ReimbursementCostAllocation> allocations,
            String allocationKey,
            ReimbursementDto.CostAllocation newValue) {
        List<ReimbursementDto.CostAllocation> allocationDtos = allocations.stream()
                .map(this::toCostAllocationDto)
                .toList();
        ReimbursementDto.CostAllocation targetDto = allocationDtos.stream()
                .filter(item -> allocationKey.equals(item.getId()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("分摊信息不存在"));
        applyCostAllocationChange(targetDto, newValue);
        return allocationDtos;
    }

    private ReimbursementTravelRecord getTravelRecordEntity(Long reimbursementId, String recordKey) {
        ReimbursementTravelRecord record = travelRecordMapper.selectOne(
                new LambdaQueryWrapper<ReimbursementTravelRecord>()
                        .eq(ReimbursementTravelRecord::getReimbursementId, reimbursementId)
                        .eq(ReimbursementTravelRecord::getRecordKey, recordKey));
        if (record == null) {
            throw new IllegalArgumentException("补录行程不存在");
        }
        return record;
    }

    private ReimbursementTravelRecord toTravelRecordEntity(Long reimbursementId, ReimbursementDto.TravelRecord dto) {
        ReimbursementTravelRecord entity = new ReimbursementTravelRecord();
        entity.setReimbursementId(reimbursementId);
        applyTravelRecordChange(entity, dto);
        return entity;
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

    private void applyTravelRecordChange(ReimbursementTravelRecord target, ReimbursementDto.TravelRecord source) {
        target.setRecordKey(source.getId());
        target.setReimburserId(source.getReimburserId());
        target.setReimburserName(source.getReimburserName());
        target.setReimburserNo(source.getReimburserNo());
        target.setDepartureCityId(source.getDepartureCityId());
        target.setDepartureCityName(source.getDepartureCityName());
        target.setArrivalCityId(source.getArrivalCityId());
        target.setArrivalCityName(source.getArrivalCityName());
        target.setDepartureDate(source.getDepartureDate() != null ? LocalDate.parse(source.getDepartureDate()) : null);
        target.setArrivalDate(source.getArrivalDate() != null ? LocalDate.parse(source.getArrivalDate()) : null);
        target.setDepartureDatetime(source.getDepartureDatetime() != null ? LocalDateTime.parse(source.getDepartureDatetime(), DATETIME_FMT) : null);
        target.setArrivalDatetime(source.getArrivalDatetime() != null ? LocalDateTime.parse(source.getArrivalDatetime(), DATETIME_FMT) : null);
        target.setDescription(source.getDescription());
    }

    private ReimbursementDto.TravelRecord mergeTravelRecordDraft(
            ReimbursementDto.TravelRecord existing,
            ReimbursementDto.TravelRecord incoming) {
        ReimbursementDto.TravelRecord merged = new ReimbursementDto.TravelRecord();
        merged.setId(existing.getId());
        merged.setReimburserId(incoming.getReimburserId() != null ? incoming.getReimburserId() : existing.getReimburserId());
        merged.setReimburserName(incoming.getReimburserName() != null ? incoming.getReimburserName() : existing.getReimburserName());
        merged.setReimburserNo(incoming.getReimburserNo() != null ? incoming.getReimburserNo() : existing.getReimburserNo());
        merged.setDepartureCityId(incoming.getDepartureCityId() != null ? incoming.getDepartureCityId() : existing.getDepartureCityId());
        merged.setDepartureCityName(incoming.getDepartureCityName() != null ? incoming.getDepartureCityName() : existing.getDepartureCityName());
        merged.setArrivalCityId(incoming.getArrivalCityId() != null ? incoming.getArrivalCityId() : existing.getArrivalCityId());
        merged.setArrivalCityName(incoming.getArrivalCityName() != null ? incoming.getArrivalCityName() : existing.getArrivalCityName());
        merged.setDepartureDate(incoming.getDepartureDate() != null ? incoming.getDepartureDate() : existing.getDepartureDate());
        merged.setArrivalDate(incoming.getArrivalDate() != null ? incoming.getArrivalDate() : existing.getArrivalDate());
        merged.setDescription(incoming.getDescription() != null ? incoming.getDescription() : existing.getDescription());
        return merged;
    }

    private void validateTravelRecordList(List<ReimbursementDto.TravelRecord> travelRecords) {
        ReimbursementDto dto = new ReimbursementDto();
        dto.setTravelRecords(travelRecords);
        validator.validateForSave(dto);
    }

    /**
     * 合并当前分摊行已有值与本次请求值，避免未传字段被覆盖成空。
     */
    private ReimbursementDto.CostAllocation mergeCostAllocationDraft(
            ReimbursementDto.CostAllocation existing,
            ReimbursementDto.CostAllocation incoming) {
        ReimbursementDto.CostAllocation merged = new ReimbursementDto.CostAllocation();
        merged.setId(existing.getId());
        merged.setCompanyId(incoming.getCompanyId() != null ? incoming.getCompanyId() : existing.getCompanyId());
        merged.setCompanyName(incoming.getCompanyName() != null ? incoming.getCompanyName() : existing.getCompanyName());
        merged.setCompanyNo(incoming.getCompanyNo() != null ? incoming.getCompanyNo() : existing.getCompanyNo());
        merged.setProjectId(incoming.getProjectId() != null ? incoming.getProjectId() : existing.getProjectId());
        merged.setProjectName(incoming.getProjectName() != null ? incoming.getProjectName() : existing.getProjectName());
        merged.setProjectNo(incoming.getProjectNo() != null ? incoming.getProjectNo() : existing.getProjectNo());
        merged.setRatio(incoming.getRatio() != null ? incoming.getRatio() : existing.getRatio());
        merged.setAmount(incoming.getAmount() != null ? incoming.getAmount() : existing.getAmount());
        return merged;
    }

    /**
     * 按首行联动规则重算整张分摊表。
     */
    private void recalculateCostAllocationRows(
            List<ReimbursementCostAllocation> allocations,
            double totalAllowanceAmount) {
        if (allocations == null || allocations.isEmpty()) {
            return;
        }

        if (allocations.size() == 1) {
            ReimbursementCostAllocation first = allocations.get(0);
            first.setRatio(toRatioDecimal(1D));
            first.setAmount(toAmountDecimal(totalAllowanceAmount));
            return;
        }

        double otherRatioSum = 0D;
        double otherAmountSum = 0D;
        for (int i = 1; i < allocations.size(); i++) {
            ReimbursementCostAllocation allocation = allocations.get(i);
            otherRatioSum += allocation.getRatio() != null ? allocation.getRatio().doubleValue() : 0D;
            otherAmountSum += allocation.getAmount() != null ? allocation.getAmount().doubleValue() : 0D;
        }

        if (otherRatioSum > 1.0001D) {
            throw new IllegalArgumentException("除首行外分摊比例合计不能超过100%");
        }
        if (otherAmountSum - totalAllowanceAmount > 0.01D) {
            throw new IllegalArgumentException("除首行外分摊金额合计不能超过补助总金额");
        }

        ReimbursementCostAllocation first = allocations.get(0);
        first.setRatio(toRatioDecimal(Math.max(0D, 1D - otherRatioSum)));
        first.setAmount(toAmountDecimal(totalAllowanceAmount - otherAmountSum));
    }

    /**
     * 当整张分摊表已经填写完整时，执行最终的整表校验。
     */
    private void validateCostAllocationListIfComplete(
            List<ReimbursementCostAllocation> allocations,
            double totalAllowanceAmount) {
        List<ReimbursementDto.CostAllocation> allocationDtos = allocations.stream()
                .map(this::toCostAllocationDto)
                .toList();
        if (isCostAllocationListReadyForAggregateValidation(allocationDtos)) {
            validator.validateCostAllocations(allocationDtos, totalAllowanceAmount);
        }
    }

    /**
     * 将当前分摊实体列表批量更新回数据库。
     */
    private void updateCostAllocationEntities(List<ReimbursementCostAllocation> allocations) {
        for (ReimbursementCostAllocation allocation : allocations) {
            costAllocationMapper.updateById(allocation);
        }
    }

    private double getTotalAllowanceAmount(ReimbursementRecord record) {
        return record.getTotalAllowanceAmount() != null
                ? record.getTotalAllowanceAmount().doubleValue()
                : 0D;
    }

    /**
     * 校验单条分摊行的草稿数据，允许整张分摊表尚未填写完整。
     */
    private void validateCostAllocationDraft(ReimbursementDto.CostAllocation allocation) {
        if (allocation == null) {
            throw new IllegalArgumentException("分摊信息不能为空");
        }
        if (hasAnyText(allocation.getCompanyId(), allocation.getCompanyName(), allocation.getCompanyNo())
                && !hasAllText(allocation.getCompanyId(), allocation.getCompanyName(), allocation.getCompanyNo())) {
            throw new IllegalArgumentException("请选择完整的归属公司信息");
        }
        if (hasAnyText(allocation.getProjectId(), allocation.getProjectName(), allocation.getProjectNo())
                && !hasAllText(allocation.getProjectId(), allocation.getProjectName(), allocation.getProjectNo())) {
            throw new IllegalArgumentException("请选择完整的归属项目信息");
        }
        if (allocation.getRatio() != null && (allocation.getRatio() < 0 || allocation.getRatio() > 1)) {
            throw new IllegalArgumentException("分摊比例必须在0到1之间");
        }
        if (allocation.getAmount() != null && allocation.getAmount() < 0) {
            throw new IllegalArgumentException("分摊金额不能小于0");
        }
    }

    /**
     * 仅当所有分摊行都已具备完整字段时，才适合执行整表合计校验。
     */
    private boolean isCostAllocationListReadyForAggregateValidation(
            List<ReimbursementDto.CostAllocation> allocations) {
        if (allocations == null || allocations.isEmpty()) {
            return false;
        }
        return allocations.stream().allMatch(this::isCompleteCostAllocation);
    }

    /**
     * 判断单条分摊记录是否已经填写完整。
     */
    private boolean isCompleteCostAllocation(ReimbursementDto.CostAllocation allocation) {
        return allocation != null
                && hasAllText(allocation.getCompanyId(), allocation.getCompanyName(), allocation.getCompanyNo())
                && hasAllText(allocation.getProjectId(), allocation.getProjectName(), allocation.getProjectNo())
                && allocation.getRatio() != null
                && allocation.getAmount() != null;
    }

    private boolean hasAnyText(String... values) {
        for (String value : values) {
            if (StringUtils.hasText(value)) {
                return true;
            }
        }
        return false;
    }

    private boolean hasAllText(String... values) {
        for (String value : values) {
            if (!StringUtils.hasText(value)) {
                return false;
            }
        }
        return true;
    }

    private BigDecimal toRatioDecimal(double value) {
        return BigDecimal.valueOf(value).setScale(4, RoundingMode.HALF_EVEN);
    }

    private BigDecimal toAmountDecimal(double value) {
        return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_EVEN);
    }

    /**
     * 将新的分摊字段值写入 DTO 对象。
     */
    private void applyCostAllocationChange(
            ReimbursementDto.CostAllocation target,
            ReimbursementDto.CostAllocation source) {
        target.setCompanyId(source.getCompanyId());
        target.setCompanyName(source.getCompanyName());
        target.setCompanyNo(source.getCompanyNo());
        target.setProjectId(source.getProjectId());
        target.setProjectName(source.getProjectName());
        target.setProjectNo(source.getProjectNo());
        target.setRatio(source.getRatio());
        target.setAmount(source.getAmount());
    }

    /**
     * 将新的分摊字段值写入数据库实体对象。
     */
    private void applyCostAllocationChange(
            ReimbursementCostAllocation target,
            ReimbursementDto.CostAllocation source) {
        target.setCompanyId(source.getCompanyId());
        target.setCompanyName(source.getCompanyName());
        target.setCompanyNo(source.getCompanyNo());
        target.setProjectId(source.getProjectId());
        target.setProjectName(source.getProjectName());
        target.setProjectNo(source.getProjectNo());
        target.setRatio(source.getRatio() != null ? BigDecimal.valueOf(source.getRatio()) : null);
        target.setAmount(source.getAmount() != null ? BigDecimal.valueOf(source.getAmount()) : null);
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

    // ====================补助日历 CRUD ========================

    /**
     * 查询指定补助下的全部日历项。
     * 按日期升序排列。
     */
    @Override
    @Transactional(readOnly = true)
    public List<AllowanceCalendarDto> listAllowanceCalendars(Long reimbursementId, Long allowanceId) {
        getExistingReimbursementRecord(reimbursementId);
        getExistingAllowance(allowanceId);

        return calendarMapper.selectList(
                        new LambdaQueryWrapper<ReimbursementAllowanceCalendar>()
                                .eq(ReimbursementAllowanceCalendar::getAllowanceId, allowanceId)
                                .orderByAsc(ReimbursementAllowanceCalendar::getCalendarDate))
                .stream()
                .map(this::toAllowanceCalendarDto)
                .toList();
    }

    /**
     * 新增一条日历项（仅用于测试）。
     * 实际业务中日历项由 generateAllowances 接口自动生成。
     * 幂等：如果该补助下已存在相同日期的日历项，则返回已存在的记录而不新增。
     */
    @Override
    @Transactional
    public AllowanceCalendarAddResult addAllowanceCalendar(
            Long reimbursementId, Long allowanceId, Long version, AllowanceCalendarRequest request) {
        ReimbursementRecord record = getExistingReimbursementRecord(reimbursementId);
        ReimbursementAllowance allowance = getExistingAllowance(allowanceId);
        validateBelongsToReimbursement(record, allowance);
        assertVersionMatches(record, version);

        LocalDate calendarDate = LocalDate.parse(request.getDate());

        // 幂等：检查同补助同日期是否已存在，有则直接返回
        ReimbursementAllowanceCalendar existing = calendarMapper.selectOne(
                new LambdaQueryWrapper<ReimbursementAllowanceCalendar>()
                        .eq(ReimbursementAllowanceCalendar::getAllowanceId, allowanceId)
                        .eq(ReimbursementAllowanceCalendar::getCalendarDate, calendarDate));
        if (existing != null) {
            AllowanceCalendarAddResult result = new AllowanceCalendarAddResult();
            result.setCalendar(toAllowanceCalendarDto(existing));
            result.setNewlyCreated(false);
            return result;
        }

        // 校验：勾选为 false 时，金额必须为 0
        validateAmountConsistency(request);
        beginReimbursementCacheDoubleDelete(reimbursementId);

        ReimbursementAllowanceCalendar calendar = new ReimbursementAllowanceCalendar();
        calendar.setAllowanceId(allowanceId);
        calendar.setCalendarDate(calendarDate);
        calendar.setWeekday(request.getWeekday());
        calendar.setMealAllowance(toDecimal(request.getMealAllowance()));
        calendar.setTransportAllowance(toDecimal(request.getTransportAllowance()));
        calendar.setCommunicationAllowance(toDecimal(request.getCommunicationAllowance()));
        calendar.setMealSelected(request.getMealSelected() != null ? request.getMealSelected() : false);
        calendar.setTransportSelected(request.getTransportSelected() != null ? request.getTransportSelected() : false);
        calendar.setCommunicationSelected(request.getCommunicationSelected() != null ? request.getCommunicationSelected() : false);
        // 校验：勾选为 false 时，金额强制归零
        calendar.setMealAmount(calendar.getMealSelected() ? toDecimal(request.getMealAmount()) : BigDecimal.ZERO);
        calendar.setTransportAmount(calendar.getTransportSelected() ? toDecimal(request.getTransportAmount()) : BigDecimal.ZERO);
        calendar.setCommunicationAmount(calendar.getCommunicationSelected() ? toDecimal(request.getCommunicationAmount()) : BigDecimal.ZERO);
        calendarMapper.insert(calendar);

        recalculateAllowanceAmounts(allowance);
        recalculateReimbursementTotalAmount(record, version);

        AllowanceCalendarAddResult result = new AllowanceCalendarAddResult();
        result.setCalendar(toAllowanceCalendarDto(calendar));
        result.setNewlyCreated(true);
        return result;
    }

    /**
     * 更新单条补助日历项（勾选状态 + 实际金额）。
     * 更新后自动联动回写：
     * 1. 所属补助的 totalApplyAmount / totalAllowanceAmount
     * 2. 所属报销单的 totalAllowanceAmount
     */
    @Override
    @Transactional
    public AllowanceCalendarDto updateAllowanceCalendar(
            Long reimbursementId, Long allowanceId, Long calendarId, Long version, AllowanceCalendarRequest request) {
        ReimbursementRecord record = getExistingReimbursementRecord(reimbursementId);
        ReimbursementAllowance allowance = getExistingAllowance(allowanceId);
        ReimbursementAllowanceCalendar calendar = getExistingCalendar(calendarId);

        validateBelongsToAllowance(allowance, calendar);
        validateBelongsToReimbursement(record, allowance);
        assertVersionMatches(record, version);

        // 校验：勾选为 false 时，金额必须为 0
        validateAmountConsistency(request);
        beginReimbursementCacheDoubleDelete(reimbursementId);

        // 逐字段更新，仅当请求值不为 null 时才更新
        if (request.getMealSelected() != null) {
            calendar.setMealSelected(request.getMealSelected());
        }
        if (request.getTransportSelected() != null) {
            calendar.setTransportSelected(request.getTransportSelected());
        }
        if (request.getCommunicationSelected() != null) {
            calendar.setCommunicationSelected(request.getCommunicationSelected());
        }

        // 校验：勾选为 false 时，金额强制归零
        normalizeAmountBySelection(calendar, request);

        if (request.getMealAmount() != null) {
            calendar.setMealAmount(BigDecimal.valueOf(request.getMealAmount()));
        }
        if (request.getTransportAmount() != null) {
            calendar.setTransportAmount(BigDecimal.valueOf(request.getTransportAmount()));
        }
        if (request.getCommunicationAmount() != null) {
            calendar.setCommunicationAmount(BigDecimal.valueOf(request.getCommunicationAmount()));
        }
        calendarMapper.updateById(calendar);

        // 联动回写补助金额合计
        recalculateAllowanceAmounts(allowance);
        // 联动回写报销单补助总金额
        recalculateReimbursementTotalAmount(record, version);

        return toAllowanceCalendarDto(calendar);
    }

    /**
     * 批量更新多条补助日历项。
     * 用于前端全选保存场景，逐条校验归属后批量更新。
     * 更新后自动联动回写补助金额合计和报销单补助总金额。
     */
    @Override
    @Transactional
    public List<AllowanceCalendarDto> batchUpdateAllowanceCalendars(
            Long reimbursementId, Long allowanceId, Long version, List<AllowanceCalendarRequest> items) {
        ReimbursementRecord record = getExistingReimbursementRecord(reimbursementId);
        ReimbursementAllowance allowance = getExistingAllowance(allowanceId);
        validateBelongsToReimbursement(record, allowance);
        assertVersionMatches(record, version);

        if (items == null || items.isEmpty()) {
            throw new IllegalArgumentException("日历项列表不能为空");
        }
        beginReimbursementCacheDoubleDelete(reimbursementId);

        //逐条更新，每条均校验归属
        for (AllowanceCalendarRequest item : items) {
            ReimbursementAllowanceCalendar calendar = getExistingCalendar(item.getId());
            validateBelongsToAllowance(allowance, calendar);

            if (item.getMealSelected() != null) {
                calendar.setMealSelected(item.getMealSelected());
            }
            if (item.getTransportSelected() != null) {
                calendar.setTransportSelected(item.getTransportSelected());
            }
            if (item.getCommunicationSelected() != null) {
                calendar.setCommunicationSelected(item.getCommunicationSelected());
            }
            // 校验：勾选为 false 时，金额必须为 0
            validateAmountConsistency(item);
            // 归零处理
            normalizeAmountBySelection(calendar, item);
            if (item.getMealAmount() != null) {
                calendar.setMealAmount(BigDecimal.valueOf(item.getMealAmount()));
            }
            if (item.getTransportAmount() != null) {
                calendar.setTransportAmount(BigDecimal.valueOf(item.getTransportAmount()));
            }
            if (item.getCommunicationAmount() != null) {
                calendar.setCommunicationAmount(BigDecimal.valueOf(item.getCommunicationAmount()));
            }
            calendarMapper.updateById(calendar);
        }

        // 联动回写补助金额合计
        recalculateAllowanceAmounts(allowance);
        // 联动回写报销单补助总金额
        recalculateReimbursementTotalAmount(record, version);

        // 返回更新后该补助的全部日历项
        return listAllowanceCalendars(reimbursementId, allowanceId);
    }

    /**
     * 删除指定日历项。
     * 删除后自动联动回写补助金额合计和报销单补助总金额。
     */
    @Override
    @Transactional
    public void deleteAllowanceCalendar(Long reimbursementId, Long allowanceId, Long calendarId, Long version) {
        ReimbursementRecord record = getExistingReimbursementRecord(reimbursementId);
        ReimbursementAllowance allowance = getExistingAllowance(allowanceId);
        ReimbursementAllowanceCalendar calendar = getExistingCalendar(calendarId);

        validateBelongsToAllowance(allowance, calendar);
        validateBelongsToReimbursement(record, allowance);
        assertVersionMatches(record, version);
        beginReimbursementCacheDoubleDelete(reimbursementId);

        calendarMapper.deleteById(calendarId);

        // 联动回写补助金额合计
        recalculateAllowanceAmounts(allowance);
        // 联动回写报销单补助总金额
        recalculateReimbursementTotalAmount(record, version);
    }

    // ====================私有辅助方法 ========================

    /**
     * 获取补助信息，不存在则抛异常。
     */
    private ReimbursementAllowance getExistingAllowance(Long allowanceId) {
        ReimbursementAllowance allowance = allowanceMapper.selectById(allowanceId);
        if (allowance == null) {
            throw new IllegalArgumentException("补助信息不存在");
        }
        return allowance;
    }

    /**
     * 获取日历项，不存在则抛异常。
     */
    private ReimbursementAllowanceCalendar getExistingCalendar(Long calendarId) {
        ReimbursementAllowanceCalendar calendar = calendarMapper.selectById(calendarId);
        if (calendar == null) {
            throw new IllegalArgumentException("补助日历不存在");
        }
        return calendar;
    }

    /**
     * 校验金额与勾选状态的一致性：勾选为 false 时，金额必须为 0。
     * 不一致时抛出异常。
     */
    private void validateAmountConsistency(AllowanceCalendarRequest request) {
        if (Boolean.FALSE.equals(request.getMealSelected()) && request.getMealAmount() != null && request.getMealAmount() > 0) {
            throw new IllegalArgumentException("餐费补助金额应为0");
        }
        if (Boolean.FALSE.equals(request.getTransportSelected()) && request.getTransportAmount() != null && request.getTransportAmount() > 0) {
            throw new IllegalArgumentException("交通补助金额应为0");
        }
        if (Boolean.FALSE.equals(request.getCommunicationSelected()) && request.getCommunicationAmount() != null && request.getCommunicationAmount() > 0) {
            throw new IllegalArgumentException("通讯补助金额应为0");
        }
    }

    /**
     * 根据勾选状态强制归零金额：勾选为 false 时，对应金额字段强制设为 0。
     */
    private void normalizeAmountBySelection(ReimbursementAllowanceCalendar calendar, AllowanceCalendarRequest request) {
        if (Boolean.FALSE.equals(calendar.getMealSelected())) {
            calendar.setMealAmount(BigDecimal.ZERO);
        }
        if (Boolean.FALSE.equals(calendar.getTransportSelected())) {
            calendar.setTransportAmount(BigDecimal.ZERO);
        }
        if (Boolean.FALSE.equals(calendar.getCommunicationSelected())) {
            calendar.setCommunicationAmount(BigDecimal.ZERO);
        }
    }

    /**
     * 校验日历项是否属于指定补助。
     */
    private void validateBelongsToAllowance(ReimbursementAllowance allowance, ReimbursementAllowanceCalendar calendar) {
        if (!calendar.getAllowanceId().equals(allowance.getId())) {
            throw new IllegalArgumentException("该日历不属于指定的补助");
        }
    }

    /**
     * 校验补助是否属于指定报销单。
     */
    private void validateBelongsToReimbursement(ReimbursementRecord record, ReimbursementAllowance allowance) {
        if (!allowance.getReimbursementId().equals(record.getId())) {
            throw new IllegalArgumentException("该补助不属于指定的报销单");
        }
    }

    /**
     * 重新计算并回写指定补助的 totalApplyAmount 和 totalAllowanceAmount。
     * 计算规则：仅汇总被勾选的补助项。
     * - totalApplyAmount = Σ(标准金额 × 勾选状态)
     * - totalAllowanceAmount = Σ(实际金额 × 勾选状态)
     */
    private void recalculateAllowanceAmounts(ReimbursementAllowance allowance) {
        List<ReimbursementAllowanceCalendar> calendars = calendarMapper.selectList(
                new LambdaQueryWrapper<ReimbursementAllowanceCalendar>()
                        .eq(ReimbursementAllowanceCalendar::getAllowanceId, allowance.getId()));

        BigDecimal totalApplyAmount = BigDecimal.ZERO;
        BigDecimal totalAllowanceAmount = BigDecimal.ZERO;

        for (ReimbursementAllowanceCalendar c : calendars) {
            if (Boolean.TRUE.equals(c.getMealSelected())) {
                totalApplyAmount = totalApplyAmount.add(c.getMealAllowance());
                totalAllowanceAmount = totalAllowanceAmount.add(c.getMealAmount());
            }
            if (Boolean.TRUE.equals(c.getTransportSelected())) {
                totalApplyAmount = totalApplyAmount.add(c.getTransportAllowance());
                totalAllowanceAmount = totalAllowanceAmount.add(c.getTransportAmount());
            }
            if (Boolean.TRUE.equals(c.getCommunicationSelected())) {
                totalApplyAmount = totalApplyAmount.add(c.getCommunicationAllowance());
                totalAllowanceAmount = totalAllowanceAmount.add(c.getCommunicationAmount());
            }
        }

        allowance.setTotalApplyAmount(totalApplyAmount);
        allowance.setTotalAllowanceAmount(totalAllowanceAmount);
        allowanceMapper.updateById(allowance);
    }

    /**
     * 重新计算并回写指定报销单的 totalAllowanceAmount。
     * 为该报销单下所有补助的 totalAllowanceAmount 之和。
     */
    private void recalculateReimbursementTotalAmount(ReimbursementRecord record, Long version) {
        List<ReimbursementAllowance> allowances = allowanceMapper.selectList(
                new LambdaQueryWrapper<ReimbursementAllowance>()
                        .eq(ReimbursementAllowance::getReimbursementId, record.getId()));

        BigDecimal totalAmount = allowances.stream()
                .map(ReimbursementAllowance::getTotalAllowanceAmount)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        record.setTotalAllowanceAmount(totalAmount);
        record.setUpdatedAt(LocalDateTime.now());
        updateRecordWithVersionCheck(record, version);
    }

    /**
     * 将实体对象转换为 DTO。
     */
    private AllowanceCalendarDto toAllowanceCalendarDto(ReimbursementAllowanceCalendar calendar) {
        AllowanceCalendarDto dto = new AllowanceCalendarDto();
        dto.setId(calendar.getId());
        dto.setDate(calendar.getCalendarDate().toString());
        dto.setWeekday(calendar.getWeekday());
        dto.setMealAllowance(toDouble(calendar.getMealAllowance()));
        dto.setTransportAllowance(toDouble(calendar.getTransportAllowance()));
        dto.setCommunicationAllowance(toDouble(calendar.getCommunicationAllowance()));
        dto.setMealSelected(calendar.getMealSelected());
        dto.setTransportSelected(calendar.getTransportSelected());
        dto.setCommunicationSelected(calendar.getCommunicationSelected());
        dto.setMealAmount(toDouble(calendar.getMealAmount()));
        dto.setTransportAmount(toDouble(calendar.getTransportAmount()));
        dto.setCommunicationAmount(toDouble(calendar.getCommunicationAmount()));
        return dto;
    }

    /**
     * BigDecimal 转 Double，null 转为 0D。
     */
    private Double toDouble(BigDecimal value) {
        return value != null ? value.doubleValue() : 0D;
    }

    /**
     * Double 转 BigDecimal，null 转为 ZERO。
     */
    private BigDecimal toDecimal(Double value) {
        return value != null ? BigDecimal.valueOf(value) : BigDecimal.ZERO;
    }
}
