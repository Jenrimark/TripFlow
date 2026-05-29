package com.jenrimark.tripflow.service;

import com.jenrimark.tripflow.dto.master.ReimburserVo;
import com.jenrimark.tripflow.entity.BusinessType;
import com.jenrimark.tripflow.entity.City;
import com.jenrimark.tripflow.entity.Project;
import com.jenrimark.tripflow.entity.ReimCompany;
import com.jenrimark.tripflow.entity.ReimDepartment;

import java.util.List;

public interface MasterDataService {

    List<ReimCompany> listCompanies();

    List<ReimDepartment> listDepartments();

    List<ReimburserVo> listReimbursers();

    List<BusinessType> listBusinessTypes();

    List<City> listCities();

    List<Project> listProjects();
}
