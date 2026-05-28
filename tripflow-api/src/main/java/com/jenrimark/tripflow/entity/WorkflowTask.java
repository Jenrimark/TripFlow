package com.jenrimark.tripflow.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("workflow_task")
public class WorkflowTask {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String title;

    /** expense_approval | general */
    private String taskType;

    /** todo | in_progress | done */
    private String kanbanStatus;

    /** pending | approved | rejected */
    private String approvalStatus;

    private Long assigneeId;

    private Long bizId;

    private LocalDateTime createdAt;
}
