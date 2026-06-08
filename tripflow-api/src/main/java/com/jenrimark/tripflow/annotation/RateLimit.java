package com.jenrimark.tripflow.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 声明接口的基础限流规则。
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface RateLimit {

    /**
     * 限流 key 前缀，便于区分不同接口。
     */
    String keyPrefix();

    /**
     * 时间窗口秒数。
     */
    long windowSeconds();

    /**
     * 时间窗口内允许的最大请求数。
     */
    long maxRequests();
}
