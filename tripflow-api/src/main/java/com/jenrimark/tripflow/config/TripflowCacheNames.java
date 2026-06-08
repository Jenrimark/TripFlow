package com.jenrimark.tripflow.config;

/**
 * 统一维护项目中使用的缓存名称。
 */
public final class TripflowCacheNames {

    public static final String MASTER_COMPANIES = "master:companies";
    public static final String MASTER_DEPARTMENTS = "master:departments";
    public static final String MASTER_REIMBURSERS = "master:reimbursers";
    public static final String MASTER_BUSINESS_TYPES = "master:business-types";
    public static final String MASTER_CITIES = "master:cities";
    public static final String MASTER_PROJECTS = "master:projects";
    public static final String REIMBURSEMENT_LIST = "reimbursement:list";
    public static final String REIMBURSEMENT_DETAIL = "reimbursement:detail";

    private TripflowCacheNames() {
    }
}
