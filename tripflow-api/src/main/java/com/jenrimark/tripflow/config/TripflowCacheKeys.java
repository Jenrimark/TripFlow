package com.jenrimark.tripflow.config;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * 统一维护复杂查询场景下的缓存 key 生成逻辑。
 */
public final class TripflowCacheKeys {

    private TripflowCacheKeys() {
    }

    /**
     * 生成报销单列表查询缓存 key，避免相同筛选条件重复查询数据库。
     */
    public static String reimbursementListKey(
            String documentNo,
            String title,
            String reason,
            List<String> companyIds,
            List<String> departmentIds,
            List<String> reimburserIds,
            List<String> businessTypeIds,
            int page,
            int pageSize) {
        return String.join("|",
                normalizeText(documentNo),
                normalizeText(title),
                normalizeText(reason),
                normalizeList(companyIds),
                normalizeList(departmentIds),
                normalizeList(reimburserIds),
                normalizeList(businessTypeIds),
                String.valueOf(page),
                String.valueOf(pageSize));
    }

    private static String normalizeText(String value) {
        return value == null ? "" : value.trim();
    }

    private static String normalizeList(List<String> values) {
        if (values == null || values.isEmpty()) {
            return "";
        }
        List<String> normalized = new ArrayList<>();
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                normalized.add(value.trim());
            }
        }
        Collections.sort(normalized);
        return String.join(",", normalized);
    }
}
