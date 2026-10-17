package com.example.military_hobbies.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "events")
public class Events {
    @Id
    @Column(name = "id", nullable = false)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private String id;

    @Column(name = "organizer_id", nullable = false)
    private String organizerId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description")
    private String description;

    @Column(name = "location")
    private String location;

    @Column(name = "start_at", nullable = false, updatable = false)
    private LocalDateTime startAt;

    @Column(name = "end_at", nullable = false, updatable = false)
    private LocalDateTime endAt;

    @Column(name = "max_attendees")
    private String maxAttendees;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
