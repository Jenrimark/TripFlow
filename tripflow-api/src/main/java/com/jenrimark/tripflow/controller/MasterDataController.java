package com.jenrimark.tripflow.controller;

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

@RestController
@RequestMapping("/master")
public class MasterDataController {

    private final MasterDataService masterDataService;

    public MasterDataController(MasterDataService masterDataService) {
        this.masterDataService = masterDataService;
    }

    @GetMapping("/companies")
    public List<ReimCompany> companies() {
        return masterDataService.listCompanies();
    }

    @GetMapping("/departments")
    public List<ReimDepartment> departments() {
        return masterDataService.listDepartments();
    }

    @GetMapping("/reimbursers")
    public List<ReimburserVo> reimbursers() {
        return masterDataService.listReimbursers();
    }

    @GetMapping("/business-types")
    public List<BusinessType> businessTypes() {
        return masterDataService.listBusinessTypes();
    }

    @GetMapping("/cities")
    public List<City> cities() {
        return masterDataService.listCities();
    }

    @GetMapping("/projects")
    public List<Project> projects() {
        return masterDataService.listProjects();
    }
}
