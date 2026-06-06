package com.jenrimark.tripflow.service.reimbursement;

import com.jenrimark.tripflow.dto.reimbursement.ReimbursementDto;
import com.jenrimark.tripflow.entity.City;
import com.jenrimark.tripflow.mapper.CityMapper;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class ReimbursementAllowanceGenerationService {

    private static final String CITY_TYPE_FIRST_TIER = "1";
    private static final String CITY_TYPE_SECOND_TIER = "2";
    private static final double FIRST_TIER_MEAL_ALLOWANCE = 100D;
    private static final double SECOND_TIER_MEAL_ALLOWANCE = 80D;
    private static final double THIRD_TIER_MEAL_ALLOWANCE = 50D;
    private static final double TRANSPORT_ALLOWANCE = 40D;
    private static final double COMMUNICATION_ALLOWANCE = 40D;

    private final CityMapper cityMapper;

    public ReimbursementAllowanceGenerationService(CityMapper cityMapper) {
        this.cityMapper = cityMapper;
    }

    public List<ReimbursementDto.AllowanceInfo> generate(List<ReimbursementDto.TravelRecord> travelRecords) {
        List<ReimbursementDto.AllowanceInfo> allowances = new ArrayList<>();
        if (travelRecords == null || travelRecords.isEmpty()) {
            return allowances;
        }

        Map<String, City> cityMap = loadCities(travelRecords);
        int index = 1;
        for (ReimbursementDto.TravelRecord travelRecord : travelRecords) {
            allowances.add(buildAllowance(travelRecord, cityMap, index));
            index++;
        }
        return allowances;
    }

    private Map<String, City> loadCities(List<ReimbursementDto.TravelRecord> travelRecords) {
        Set<String> cityIds = new LinkedHashSet<>();
        for (ReimbursementDto.TravelRecord travelRecord : travelRecords) {
            if (travelRecord.getArrivalCityId() != null && !travelRecord.getArrivalCityId().trim().isEmpty()) {
                cityIds.add(travelRecord.getArrivalCityId());
            }
        }

        Map<String, City> cityMap = new HashMap<>();
        if (cityIds.isEmpty()) {
            return cityMap;
        }

        List<City> cities = cityMapper.selectBatchIds(cityIds);
        for (City city : cities) {
            cityMap.put(city.getCityNo(), city);
        }
        return cityMap;
    }

    private ReimbursementDto.AllowanceInfo buildAllowance(
            ReimbursementDto.TravelRecord travelRecord,
            Map<String, City> cityMap,
            int index) {
        LocalDate departureDate = LocalDate.parse(travelRecord.getDepartureDate());
        LocalDate arrivalDate = LocalDate.parse(travelRecord.getArrivalDate());

        ReimbursementDto.AllowanceInfo allowance = new ReimbursementDto.AllowanceInfo();
        allowance.setId(buildAllowanceKey(travelRecord, index));
        allowance.setTravelRecordId(travelRecord.getId());
        allowance.setReimburserId(travelRecord.getReimburserId());
        allowance.setReimburserName(travelRecord.getReimburserName());
        allowance.setDepartureDate(travelRecord.getDepartureDate());
        allowance.setArrivalDate(travelRecord.getArrivalDate());
        allowance.setAllowanceDays((int) ChronoUnit.DAYS.between(departureDate, arrivalDate) + 1);
        allowance.setDepartureCity(travelRecord.getDepartureCityName());
        allowance.setArrivalCity(travelRecord.getArrivalCityName());

        AllowanceStandard standard = resolveStandard(cityMap.get(travelRecord.getArrivalCityId()));
        List<ReimbursementDto.AllowanceCalendarItem> calendar = buildCalendar(departureDate, arrivalDate, standard);
        allowance.setCalendar(calendar);

        double totalApplyAmount = 0D;
        for (ReimbursementDto.AllowanceCalendarItem item : calendar) {
            totalApplyAmount += safe(item.getMealAllowance())
                    + safe(item.getTransportAllowance())
                    + safe(item.getCommunicationAllowance());
        }
        allowance.setTotalApplyAmount(totalApplyAmount);
        allowance.setTotalAllowanceAmount(0D);
        return allowance;
    }

    private List<ReimbursementDto.AllowanceCalendarItem> buildCalendar(
            LocalDate departureDate,
            LocalDate arrivalDate,
            AllowanceStandard standard) {
        List<ReimbursementDto.AllowanceCalendarItem> calendar = new ArrayList<>();
        LocalDate cursor = departureDate;
        while (!cursor.isAfter(arrivalDate)) {
            ReimbursementDto.AllowanceCalendarItem item = new ReimbursementDto.AllowanceCalendarItem();
            item.setDate(cursor.toString());
            item.setWeekday(toWeekday(cursor.getDayOfWeek()));
            item.setMealAllowance(standard.getMealAllowance());
            item.setTransportAllowance(standard.getTransportAllowance());
            item.setCommunicationAllowance(standard.getCommunicationAllowance());
            item.setMealSelected(Boolean.FALSE);
            item.setTransportSelected(Boolean.FALSE);
            item.setCommunicationSelected(Boolean.FALSE);
            item.setMealAmount(0D);
            item.setTransportAmount(0D);
            item.setCommunicationAmount(0D);
            calendar.add(item);
            cursor = cursor.plusDays(1);
        }
        return calendar;
    }

    private AllowanceStandard resolveStandard(City city) {
        if (city == null || city.getCityType() == null || city.getCityType().trim().isEmpty()) {
            return new AllowanceStandard(THIRD_TIER_MEAL_ALLOWANCE, TRANSPORT_ALLOWANCE, COMMUNICATION_ALLOWANCE);
        }
        if (CITY_TYPE_FIRST_TIER.equals(city.getCityType())) {
            return new AllowanceStandard(FIRST_TIER_MEAL_ALLOWANCE, TRANSPORT_ALLOWANCE, COMMUNICATION_ALLOWANCE);
        }
        if (CITY_TYPE_SECOND_TIER.equals(city.getCityType())) {
            return new AllowanceStandard(SECOND_TIER_MEAL_ALLOWANCE, TRANSPORT_ALLOWANCE, COMMUNICATION_ALLOWANCE);
        }
        return new AllowanceStandard(THIRD_TIER_MEAL_ALLOWANCE, TRANSPORT_ALLOWANCE, COMMUNICATION_ALLOWANCE);
    }

    private String buildAllowanceKey(ReimbursementDto.TravelRecord travelRecord, int index) {
        if (travelRecord.getId() != null && !travelRecord.getId().trim().isEmpty()) {
            return "allowance_" + travelRecord.getId();
        }
        return "allowance_" + System.currentTimeMillis() + "_" + index;
    }

    private String toWeekday(DayOfWeek dayOfWeek) {
        if (dayOfWeek == DayOfWeek.MONDAY) {
            return "周一";
        }
        if (dayOfWeek == DayOfWeek.TUESDAY) {
            return "周二";
        }
        if (dayOfWeek == DayOfWeek.WEDNESDAY) {
            return "周三";
        }
        if (dayOfWeek == DayOfWeek.THURSDAY) {
            return "周四";
        }
        if (dayOfWeek == DayOfWeek.FRIDAY) {
            return "周五";
        }
        if (dayOfWeek == DayOfWeek.SATURDAY) {
            return "周六";
        }
        return "周日";
    }

    private double safe(Double value) {
        return value != null ? value : 0D;
    }

    private static class AllowanceStandard {
        private final double mealAllowance;
        private final double transportAllowance;
        private final double communicationAllowance;

        private AllowanceStandard(double mealAllowance, double transportAllowance, double communicationAllowance) {
            this.mealAllowance = mealAllowance;
            this.transportAllowance = transportAllowance;
            this.communicationAllowance = communicationAllowance;
        }

        public double getMealAllowance() {
            return mealAllowance;
        }

        public double getTransportAllowance() {
            return transportAllowance;
        }

        public double getCommunicationAllowance() {
            return communicationAllowance;
        }
    }
}
