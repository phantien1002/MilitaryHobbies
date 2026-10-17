package com.example.military_hobbies.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "scales")
public class Scales {
    @Id
    @Column(name = "id", nullable = false)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "label", nullable = false, unique = true, length = 20)
    private String label;

    @Column(name = "ratio", precision = 10, scale = 6)
    private BigDecimal ratio;
}
