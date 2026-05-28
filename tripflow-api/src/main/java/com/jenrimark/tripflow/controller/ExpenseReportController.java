package com.jenrimark.tripflow.controller;

import com.jenrimark.tripflow.entity.ExpenseReport;
import com.jenrimark.tripflow.service.ExpenseReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/expense")
public class ExpenseReportController {

    @Autowired
    private ExpenseReportService expenseReportService;

    @GetMapping("/list")
    public List<ExpenseReport> list() {
        return expenseReportService.list();
    }
}
