package com.jenrimark.tripflow.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("reimbursement_travel_record")
public class ReimbursementTravelRecord {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long reimbursementId;
    private String recordKey;
    private String reimburserId;
    private String reimburserName;
    private String reimburserNo;
    private String departureCityId;
    private String departureCityName;
    private String arrivalCityId;
    private String arrivalCityName;
    private LocalDate departureDate;
    private LocalDate arrivalDate;
    private LocalDateTime departureDatetime;
    private LocalDateTime arrivalDatetime;
    private String description;
}
