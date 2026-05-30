package com.jenrimark.tripflow.dto.reimbursement;

import lombok.Data;

import java.util.List;

@Data
public class ReimbursementDto {

    private String id;
    private String documentNo;
    private String documentType;
    private Integer status;
    private String createdAt;
    private BasicInfo basicInfo;
    private List<TravelRecord> travelRecords;
    private List<AllowanceInfo> allowances;
    private List<CostAllocation> costAllocations;
    private String remark;
    private Double totalAllowanceAmount;
    private Double totalMealAmount;
    private Double totalTransportAmount;
    private Double totalCommunicationAmount;

    @Data
    public static class BasicInfo {
        private String title;
        private String reason;
        private String reimburserId;
        private String reimburserName;
        private String reimburserNo;
        private String departmentId;
        private String departmentName;
        private String departmentNo;
        private String companyId;
        private String companyName;
        private String companyNo;
        private String businessTypeId;
        private String businessTypeName;
        private String businessTypeNo;
    }

    @Data
    public static class TravelRecord {
        private String id;
        private String reimburserId;
        private String reimburserName;
        private String reimburserNo;
        private String departureCityId;
        private String departureCityName;
        private String arrivalCityId;
        private String arrivalCityName;
        private String departureDate;
        private String arrivalDate;
        private String description;
    }

    @Data
    public static class AllowanceCalendarItem {
        private String date;
        private String weekday;
        private Double mealAllowance;
        private Double transportAllowance;
        private Double communicationAllowance;
        private Boolean mealSelected;
        private Boolean transportSelected;
        private Boolean communicationSelected;
        private Double mealAmount;
        private Double transportAmount;
        private Double communicationAmount;
    }

    @Data
    public static class AllowanceInfo {
        private String id;
        private String travelRecordId;
        private String reimburserId;
        private String reimburserName;
        private String departureDate;
        private String arrivalDate;
        private Integer allowanceDays;
        private String departureCity;
        private String arrivalCity;
        private List<AllowanceCalendarItem> calendar;
        private Double totalApplyAmount;
        private Double totalAllowanceAmount;
    }

    @Data
    public static class CostAllocation {
        private String id;
        private String companyId;
        private String companyName;
        private String companyNo;
        private String projectId;
        private String projectName;
        private String projectNo;
        private Double ratio;
        private Double amount;
    }
}
