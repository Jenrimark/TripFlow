package com.jenrimark.tripflow;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.jenrimark.tripflow.mapper")
public class TripflowApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(TripflowApiApplication.class, args);
    }
}
