package com.jenrimark.tripflow.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("project")
public class Project {

    @TableId
    private String projectId;
    private String projectNo;
    private String projectName;
}
