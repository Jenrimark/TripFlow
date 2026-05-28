package com.jenrimark.tripflow.controller;

import com.jenrimark.tripflow.entity.WorkflowTask;
import com.jenrimark.tripflow.service.WorkflowTaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/workflow")
public class WorkflowTaskController {

    @Autowired
    private WorkflowTaskService workflowTaskService;

    @GetMapping("/tasks")
    public List<WorkflowTask> tasks() {
        return workflowTaskService.list();
    }
}
