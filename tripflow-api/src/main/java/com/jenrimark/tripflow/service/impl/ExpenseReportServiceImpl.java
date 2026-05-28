package com.jenrimark.tripflow.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.jenrimark.tripflow.entity.ExpenseReport;
import com.jenrimark.tripflow.mapper.ExpenseReportMapper;
import com.jenrimark.tripflow.service.ExpenseReportService;
import org.springframework.stereotype.Service;

@Service
public class ExpenseReportServiceImpl extends ServiceImpl<ExpenseReportMapper, ExpenseReport>
        implements ExpenseReportService {
}
