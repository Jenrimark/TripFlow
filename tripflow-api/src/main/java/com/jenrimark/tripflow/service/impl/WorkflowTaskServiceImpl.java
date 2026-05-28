package com.jenrimark.tripflow.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.jenrimark.tripflow.entity.WorkflowTask;
import com.jenrimark.tripflow.mapper.WorkflowTaskMapper;
import com.jenrimark.tripflow.service.WorkflowTaskService;
import org.springframework.stereotype.Service;

@Service
public class WorkflowTaskServiceImpl extends ServiceImpl<WorkflowTaskMapper, WorkflowTask>
        implements WorkflowTaskService {
}
