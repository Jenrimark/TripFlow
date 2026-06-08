package com.jenrimark.tripflow;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
@MapperScan("com.jenrimark.tripflow.mapper")
public class TripflowApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(TripflowApiApplication.class, args);
    }
}
