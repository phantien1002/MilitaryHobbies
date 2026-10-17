package com.example.military_hobbies.entity;

import jakarta.persistence.*;
import lombok.*;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "follows")
public class Follows {
    @EmbeddedId
    private FollowId id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("followerId")
    @JoinColumn(name = "follower_id")
    private Users follower;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("followeeId")
    @JoinColumn(name = "followee_id")
    private Users followee;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public Follows(Users follower, Users followee) {
        this.follower = follower;
        this.followee = followee;
        this.id = new FollowId(follower.getId(), followee.getId());
        this.createdAt = LocalDateTime.now();
    }

    @Embeddable
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    public static class FollowId implements Serializable {
        @Serial
        private static final long serialVersionUID = 1L;

        @Column(name = "follower_id")
        private Long followerId;

        @Column(name = "followee_id")
        private Long followeeId;
    }
}
