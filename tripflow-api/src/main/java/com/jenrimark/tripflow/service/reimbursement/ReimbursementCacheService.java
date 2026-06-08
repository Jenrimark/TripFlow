package com.jenrimark.tripflow.service.reimbursement;

import com.jenrimark.tripflow.config.TripflowCacheNames;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Duration;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

/**
 * 统一处理报销单相关缓存的双删逻辑，尽量降低读到旧缓存的窗口。
 */
@Service
public class ReimbursementCacheService {

    private static final Logger log = LoggerFactory.getLogger(ReimbursementCacheService.class);
    private static final Duration REIMBURSEMENT_LIST_DOUBLE_DELETE_DELAY = Duration.ofMillis(300);

    private final CacheManager cacheManager;
    private final ScheduledExecutorService scheduler;

    public ReimbursementCacheService(CacheManager cacheManager) {
        this.cacheManager = cacheManager;
        this.scheduler = Executors.newSingleThreadScheduledExecutor(new CacheThreadFactory());
    }

    /**
     * 对报销单列表缓存执行双删：
     * 1. 写前先删一次
     * 2. 事务提交后立即删一次
     * 3. 再延迟补删一次，处理并发回填旧缓存的情况
     */
    public void doubleDeleteReimbursementListCache() {
        clearCacheSafely(TripflowCacheNames.REIMBURSEMENT_LIST);

        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    clearCacheSafely(TripflowCacheNames.REIMBURSEMENT_LIST);
                    scheduler.schedule(
                            () -> clearCacheSafely(TripflowCacheNames.REIMBURSEMENT_LIST),
                            REIMBURSEMENT_LIST_DOUBLE_DELETE_DELAY.toMillis(),
                            TimeUnit.MILLISECONDS);
                }
                });
            return;
        }

        scheduler.schedule(
                () -> clearCacheSafely(TripflowCacheNames.REIMBURSEMENT_LIST),
                REIMBURSEMENT_LIST_DOUBLE_DELETE_DELAY.toMillis(),
                TimeUnit.MILLISECONDS);
    }

    /**
     * 对单张报销单详情缓存执行双删，尽量降低详情页读到旧缓存的窗口。
     */
    public void doubleDeleteReimbursementDetailCache(Long id) {
        if (id == null) {
            return;
        }

        clearCacheEntrySafely(TripflowCacheNames.REIMBURSEMENT_DETAIL, id);

        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    clearCacheEntrySafely(TripflowCacheNames.REIMBURSEMENT_DETAIL, id);
                    scheduler.schedule(
                            () -> clearCacheEntrySafely(TripflowCacheNames.REIMBURSEMENT_DETAIL, id),
                            REIMBURSEMENT_LIST_DOUBLE_DELETE_DELAY.toMillis(),
                            TimeUnit.MILLISECONDS);
                }
            });
            return;
        }

        scheduler.schedule(
                () -> clearCacheEntrySafely(TripflowCacheNames.REIMBURSEMENT_DETAIL, id),
                REIMBURSEMENT_LIST_DOUBLE_DELETE_DELAY.toMillis(),
                TimeUnit.MILLISECONDS);
    }

    private void clearCacheSafely(String cacheName) {
        try {
            Cache cache = cacheManager.getCache(cacheName);
            if (cache != null) {
                cache.clear();
            }
        } catch (RuntimeException e) {
            log.warn("删除缓存失败。cache={}", cacheName, e);
        }
    }

    private void clearCacheEntrySafely(String cacheName, Object key) {
        try {
            Cache cache = cacheManager.getCache(cacheName);
            if (cache != null) {
                cache.evict(key);
            }
        } catch (RuntimeException e) {
            log.warn("删除缓存失败。cache={}, key={}", cacheName, key, e);
        }
    }

    @PreDestroy
    public void shutdown() {
        scheduler.shutdown();
    }

    private static final class CacheThreadFactory implements ThreadFactory {
        @Override
        public Thread newThread(Runnable runnable) {
            Thread thread = new Thread(runnable, "tripflow-cache-double-delete");
            thread.setDaemon(true);
            return thread;
        }
    }
}
