package com.jenrimark.tripflow.config;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.JsonTypeInfo;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.jsontype.BasicPolymorphicTypeValidator;
import com.fasterxml.jackson.databind.jsontype.PolymorphicTypeValidator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.Cache;
import org.springframework.cache.interceptor.CacheErrorHandler;
import org.springframework.boot.autoconfigure.cache.RedisCacheManagerBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;

import java.time.Duration;

/**
 * 配置 Redis 缓存名称、序列化方式和每类缓存的 TTL。
 */
@Configuration
public class RedisCacheConfig {

    private static final Logger log = LoggerFactory.getLogger(RedisCacheConfig.class);

    @Bean
    public RedisCacheManagerBuilderCustomizer redisCacheManagerBuilderCustomizer() {
        PolymorphicTypeValidator ptv = BasicPolymorphicTypeValidator.builder()
                .allowIfBaseType(Object.class).build();
        ObjectMapper om = new ObjectMapper();
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        om.activateDefaultTyping(ptv, ObjectMapper.DefaultTyping.NON_FINAL, JsonTypeInfo.As.PROPERTY);

        Jackson2JsonRedisSerializer<Object> jacksonSerializer =
                new Jackson2JsonRedisSerializer<>(om, Object.class);

        RedisSerializationContext.SerializationPair<Object> serializer =
                RedisSerializationContext.SerializationPair.fromSerializer(jacksonSerializer);

        RedisCacheConfiguration defaultConfig = RedisCacheConfiguration.defaultCacheConfig()
                .disableCachingNullValues()
                .serializeValuesWith(serializer)
                .entryTtl(Duration.ofHours(12));

        return builder -> builder
                .cacheDefaults(defaultConfig)
                .withCacheConfiguration(
                        TripflowCacheNames.MASTER_COMPANIES,
                        defaultConfig.entryTtl(Duration.ofHours(12)))
                .withCacheConfiguration(
                        TripflowCacheNames.MASTER_DEPARTMENTS,
                        defaultConfig.entryTtl(Duration.ofHours(12)))
                .withCacheConfiguration(
                        TripflowCacheNames.MASTER_REIMBURSERS,
                        defaultConfig.entryTtl(Duration.ofHours(1)))
                .withCacheConfiguration(
                        TripflowCacheNames.MASTER_BUSINESS_TYPES,
                        defaultConfig.entryTtl(Duration.ofHours(12)))
                .withCacheConfiguration(
                        TripflowCacheNames.MASTER_CITIES,
                        defaultConfig.entryTtl(Duration.ofHours(12)))
                .withCacheConfiguration(
                        TripflowCacheNames.MASTER_PROJECTS,
                        defaultConfig.entryTtl(Duration.ofHours(12)))
                .withCacheConfiguration(
                        TripflowCacheNames.REIMBURSEMENT_LIST,
                        defaultConfig.entryTtl(Duration.ofSeconds(60)))
                .withCacheConfiguration(
                        TripflowCacheNames.REIMBURSEMENT_DETAIL,
                        defaultConfig.entryTtl(Duration.ofSeconds(60)));
    }

    /**
     * Redis 异常时降级为直接访问数据库，避免缓存故障影响主流程。
     */
    @Bean
    public CacheErrorHandler cacheErrorHandler() {
        return new CacheErrorHandler() {
            @Override
            public void handleCacheGetError(RuntimeException exception, Cache cache, Object key) {
                log.warn("Redis读取缓存失败，改为直接查询数据库。cache={}, key={}", cache != null ? cache.getName() : "", key,
                        exception);
            }

            @Override
            public void handleCachePutError(RuntimeException exception, Cache cache, Object key, Object value) {
                log.warn("Redis写入缓存失败。cache={}, key={}", cache != null ? cache.getName() : "", key, exception);
            }

            @Override
            public void handleCacheEvictError(RuntimeException exception, Cache cache, Object key) {
                log.warn("Redis删除缓存失败。cache={}, key={}", cache != null ? cache.getName() : "", key, exception);
            }

            @Override
            public void handleCacheClearError(RuntimeException exception, Cache cache) {
                log.warn("Redis清空缓存失败。cache={}", cache != null ? cache.getName() : "", exception);
            }
        };
    }
}
