package com.jenrimark.tripflow.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.jenrimark.tripflow.entity.ReimbursementRecord;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ReimbursementMapper extends BaseMapper<ReimbursementRecord> {
}
