package com.example.military_hobbies.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "build_logs")
public class BuildLogs {

    @Id
    @Column(name = "id", nullable = false)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private String id;

    @Column(name = "project_id", nullable = false)
    private String projectId;

    @Column(name = "title")
    private String title;

    @Column(name = "content", nullable = false)
    private String content;

    @Column(name = "hours_spent")
    private BigDecimal hoursSpent;

    @Column(name = "logged_at", nullable = false, updatable = false)
    private LocalDateTime loggedAt;

}
