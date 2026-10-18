package com.example.military_hobbies.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
@Tag(name = "Health", description = "Kiểm tra trạng thái server")
public class ServerController {
    @GetMapping
    @Operation(summary = "Kiểm tra server đang chạy")
    public Map<String, Object> health() {
        return Map.of("status", "UP", "time", LocalDateTime.now().toString());
    }
}
