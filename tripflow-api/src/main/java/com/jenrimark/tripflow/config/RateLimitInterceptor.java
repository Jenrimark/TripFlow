package com.jenrimark.tripflow.config;

import com.jenrimark.tripflow.annotation.RateLimit;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.time.Duration;

/**
 * 基于 Redis 计数器的基础限流拦截器。
 */
@Component
public class RateLimitInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(RateLimitInterceptor.class);

    private final StringRedisTemplate stringRedisTemplate;

    public RateLimitInterceptor(StringRedisTemplate stringRedisTemplate) {
        this.stringRedisTemplate = stringRedisTemplate;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        if (!(handler instanceof HandlerMethod handlerMethod)) {
            return true;
        }

        RateLimit rateLimit = handlerMethod.getMethodAnnotation(RateLimit.class);
        if (rateLimit == null) {
            return true;
        }

        String clientIp = resolveClientIp(request);
        String requestPath = request.getRequestURI();
        String cacheKey = buildRateLimitKey(rateLimit.keyPrefix(), clientIp, requestPath);

        try {
            Long currentCount = stringRedisTemplate.opsForValue().increment(cacheKey);
            if (currentCount != null && currentCount == 1L) {
                stringRedisTemplate.expire(cacheKey, Duration.ofSeconds(rateLimit.windowSeconds()));
            }
            if (currentCount != null && currentCount > rateLimit.maxRequests()) {
                response.sendError(429, "请求过于频繁，请稍后再试");
                return false;
            }
        } catch (RuntimeException e) {
            // Redis 不可用时先降级放行，避免限流组件本身阻塞主流程。
            log.warn("限流检查失败，已降级放行。path={}, ip={}", requestPath, clientIp, e);
        }

        return true;
    }

    private String buildRateLimitKey(String keyPrefix, String clientIp, String requestPath) {
        return "rate-limit:" + keyPrefix + ":" + clientIp + ":" + requestPath;
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            int commaIndex = forwardedFor.indexOf(',');
            return commaIndex >= 0 ? forwardedFor.substring(0, commaIndex).trim() : forwardedFor.trim();
        }

        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.isBlank()) {
            return realIp.trim();
        }
        return request.getRemoteAddr();
    }
}
