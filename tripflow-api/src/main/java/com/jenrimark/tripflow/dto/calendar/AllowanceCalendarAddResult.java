package com.jenrimark.tripflow.dto.calendar;

import lombok.Data;

/**
 * 新增日历项的返回结果封装。
 * 用于区分幂等返回（记录已存在）还是真正新增。
 */
@Data
public class AllowanceCalendarAddResult {
    private AllowanceCalendarDto calendar;
    /** true=新增，false=已存在（幂等） */
    private boolean newlyCreated;
}