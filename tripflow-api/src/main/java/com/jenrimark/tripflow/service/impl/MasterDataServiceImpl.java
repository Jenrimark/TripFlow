package com.jenrimark.tripflow.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.jenrimark.tripflow.config.TripflowCacheNames;
import com.jenrimark.tripflow.dto.master.ReimburserVo;
import com.jenrimark.tripflow.entity.BusinessType;
import com.jenrimark.tripflow.entity.City;
import com.jenrimark.tripflow.entity.Project;
import com.jenrimark.tripflow.entity.ReimCompany;
import com.jenrimark.tripflow.entity.ReimDepartment;
import com.jenrimark.tripflow.entity.Reimburser;
import com.jenrimark.tripflow.mapper.BusinessTypeMapper;
import com.jenrimark.tripflow.mapper.CityMapper;
import com.jenrimark.tripflow.mapper.ProjectMapper;
import com.jenrimark.tripflow.mapper.ReimCompanyMapper;
import com.jenrimark.tripflow.mapper.ReimDepartmentMapper;
import com.jenrimark.tripflow.mapper.ReimburserMapper;
import com.jenrimark.tripflow.service.MasterDataService;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class MasterDataServiceImpl implements MasterDataService {

    private final ReimCompanyMapper companyMapper;
    private final ReimDepartmentMapper departmentMapper;
    private final ReimburserMapper reimburserMapper;
    private final BusinessTypeMapper businessTypeMapper;
    private final CityMapper cityMapper;
    private final ProjectMapper projectMapper;

    public MasterDataServiceImpl(
            ReimCompanyMapper companyMapper,
            ReimDepartmentMapper departmentMapper,
            ReimburserMapper reimburserMapper,
            BusinessTypeMapper businessTypeMapper,
            CityMapper cityMapper,
            ProjectMapper projectMapper) {
        this.companyMapper = companyMapper;
        this.departmentMapper = departmentMapper;
        this.reimburserMapper = reimburserMapper;
        this.businessTypeMapper = businessTypeMapper;
        this.cityMapper = cityMapper;
        this.projectMapper = projectMapper;
    }

    @Override
    @Cacheable(cacheNames = TripflowCacheNames.MASTER_COMPANIES, key = "'all'")
    public List<ReimCompany> listCompanies() {
        return companyMapper.selectList(new LambdaQueryWrapper<ReimCompany>()
                .orderByAsc(ReimCompany::getReimCompanyNo));
    }

    @Override
    @Cacheable(cacheNames = TripflowCacheNames.MASTER_DEPARTMENTS, key = "'all'")
    public List<ReimDepartment> listDepartments() {
        return departmentMapper.selectList(new LambdaQueryWrapper<ReimDepartment>()
                .orderByAsc(ReimDepartment::getReimDepartmentNo));
    }

    @Override
    @Cacheable(cacheNames = TripflowCacheNames.MASTER_REIMBURSERS, key = "'all'")
    public List<ReimburserVo> listReimbursers() {
        Map<String, ReimDepartment> deptMap = departmentMapper.selectList(null).stream()
                .collect(Collectors.toMap(ReimDepartment::getReimDepartmentId, d -> d));
        return reimburserMapper.selectList(new LambdaQueryWrapper<Reimburser>()
                        .orderByAsc(Reimburser::getReimburserNo))
                .stream()
                .map(r -> toReimburserVo(r, deptMap.get(r.getDepartmentId())))
                .toList();
    }

    @Override
    @Cacheable(cacheNames = TripflowCacheNames.MASTER_BUSINESS_TYPES, key = "'all'")
    public List<BusinessType> listBusinessTypes() {
        return businessTypeMapper.selectList(new LambdaQueryWrapper<BusinessType>()
                .orderByAsc(BusinessType::getBusinessTypeNo));
    }

    @Override
    @Cacheable(cacheNames = TripflowCacheNames.MASTER_CITIES, key = "'all'")
    public List<City> listCities() {
        return cityMapper.selectList(new LambdaQueryWrapper<City>()
                .orderByAsc(City::getCityNo));
    }

    @Override
    @Cacheable(cacheNames = TripflowCacheNames.MASTER_PROJECTS, key = "'all'")
    public List<Project> listProjects() {
        return projectMapper.selectList(new LambdaQueryWrapper<Project>()
                .orderByAsc(Project::getProjectNo));
    }

    private ReimburserVo toReimburserVo(Reimburser reimburser, ReimDepartment department) {
        ReimburserVo vo = new ReimburserVo();
        vo.setReimburserId(reimburser.getReimburserId());
        vo.setReimburserNo(reimburser.getReimburserNo());
        vo.setReimburserName(reimburser.getReimburserName());
        if (department != null) {
            vo.setDepartmentId(department.getReimDepartmentId());
            vo.setDepartmentName(department.getReimDepartmentName());
            vo.setDepartmentNo(department.getReimDepartmentNo());
        } else {
            vo.setDepartmentId(reimburser.getDepartmentId());
        }
        return vo;
    }
}
