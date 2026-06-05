package com.jenrimark.tripflow.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.dto.reimbursement.ReimbursementListResult;
import com.jenrimark.tripflow.entity.ReimbursementRecord;
import com.jenrimark.tripflow.mapper.ReimbursementMapper;
import com.jenrimark.tripflow.service.ReimbursementService;
import com.jenrimark.tripflow.service.reimbursement.ReimbursementChildRecordService;
import com.jenrimark.tripflow.service.reimbursement.ReimbursementValidator;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Service
public class ReimbursementServiceImpl extends ServiceImpl<ReimbursementMapper, ReimbursementRecord>
        implements ReimbursementService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;

    private final ObjectMapper objectMapper;
    private final ReimbursementValidator validator;
    private final ReimbursementChildRecordService childRecordService;

    public ReimbursementServiceImpl(
            ObjectMapper objectMapper,
            ReimbursementValidator validator,
            ReimbursementChildRecordService childRecordService) {
        this.objectMapper = objectMapper;
        this.validator = validator;
        this.childRecordService = childRecordService;
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

        // 列表页只查询主表中的可检索字段，详情页再从 content JSON 恢复完整表单。
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
        // 草稿保存只做基础合法性校验；提交时会追加必填项和金额分摊校验。
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
    @Transactional  // 事务
    public ReimbursementDto update(Long id, ReimbursementDto dto) {
        // 根据id查找报销单
        ReimbursementRecord record = getById(id);
        // 校验报销单是否存在
        if (record == null) {
            throw new IllegalArgumentException("报销单不存在");  // 抛出异常
        }

        // 校验数据（只校验必填数据）
        validator.validateForSave(dto);
        // 修改更新时间
        record.setUpdatedAt(LocalDateTime.now());
        // 把前端传来的dto写到record
        applyDtoToRecord(dto, record);
        // 更新reimbursement主表
        updateById(record);
        // 更新子表数据（删除原本的子表记录，在插入新的子表）
        childRecordService.replaceChildRecords(id, dto);
        return toDto(record);
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

        // 复用现有保存校验，保证新增行程与当前草稿整体规则一致。
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
        ReimbursementDto.TravelRecord existing = findTravelRecord(dto, recordKey);

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
        // 提交是状态流转入口，必须基于持久化快照重新校验，避免前端绕过校验。
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
            // 主表 status 用于列表快速筛选，content 中也同步一份，保证详情回显一致。
            ReimbursementDto dto = objectMapper.readValue(record.getContent(), ReimbursementDto.class);
            dto.setStatus(record.getStatus());
            record.setContent(objectMapper.writeValueAsString(dto));
            updateById(record);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("报销单数据解析失败", e);
        }
    }

    private String generateDocumentNo() {
        // 单号格式：REIM + 日期 + 毫秒尾号，便于演示环境快速生成可读编号。
        return "REIM" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
                + String.format("%04d", System.currentTimeMillis() % 10000);
    }

    private void applyDtoToRecord(ReimbursementDto dto, ReimbursementRecord record) {
        // 将详情表单中的关键字段冗余到主表，支撑列表查询、排序和统计。
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
            // content 保存完整表单快照，子表仅用于查询扩展和报表统计。
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
            // 详情响应以 JSON 快照为主体，再用主表字段覆盖运行态关键信息。
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
            if (dto.getDocumentType() == null || dto.getDocumentType().isBlank()) {
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
}
