package com.jenrimark.tripflow.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.jenrimark.tripflow.entity.WorkflowTask;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface WorkflowTaskMapper extends BaseMapper<WorkflowTask> {
}
