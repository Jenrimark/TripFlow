package com.jenrimark.tripflow.controller;

import com.jenrimark.tripflow.annotation.RateLimit;
import com.jenrimark.tripflow.dto.master.ReimburserVo;
import com.jenrimark.tripflow.entity.BusinessType;
import com.jenrimark.tripflow.entity.City;
import com.jenrimark.tripflow.entity.Project;
import com.jenrimark.tripflow.entity.ReimCompany;
import com.jenrimark.tripflow.entity.ReimDepartment;
import com.jenrimark.tripflow.service.MasterDataService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
/**
 * 查询主数据
 * */
@RestController
@RequestMapping("/master")
public class MasterDataController {

    private final MasterDataService masterDataService;

    public MasterDataController(MasterDataService masterDataService) {
        this.masterDataService = masterDataService;
    }

    @GetMapping("/companies")
    @RateLimit(keyPrefix = "master-companies", windowSeconds = 60, maxRequests = 120)
    public List<ReimCompany> companies() {
        return masterDataService.listCompanies();
    }

    @GetMapping("/departments")
    @RateLimit(keyPrefix = "master-departments", windowSeconds = 60, maxRequests = 120)
    public List<ReimDepartment> departments() {
        return masterDataService.listDepartments();
    }

    @GetMapping("/reimbursers")
    @RateLimit(keyPrefix = "master-reimbursers", windowSeconds = 60, maxRequests = 120)
    public List<ReimburserVo> reimbursers() {
        return masterDataService.listReimbursers();
    }

    @GetMapping("/business-types")
    @RateLimit(keyPrefix = "master-business-types", windowSeconds = 60, maxRequests = 120)
    public List<BusinessType> businessTypes() {
        return masterDataService.listBusinessTypes();
    }

    @GetMapping("/cities")
    @RateLimit(keyPrefix = "master-cities", windowSeconds = 60, maxRequests = 120)
    public List<City> cities() {
        return masterDataService.listCities();
    }

    @GetMapping("/projects")
    @RateLimit(keyPrefix = "master-projects", windowSeconds = 60, maxRequests = 120)
    public List<Project> projects() {
        return masterDataService.listProjects();
    }
}
