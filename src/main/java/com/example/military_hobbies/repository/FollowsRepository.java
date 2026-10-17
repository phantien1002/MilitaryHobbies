package com.example.military_hobbies.repository;

import com.example.military_hobbies.entity.Follows;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FollowsRepository extends JpaRepository<Follows, Follows.FollowId> {
    long countByIdFolloweeId(Long followeeId);
    boolean existsByIdFollowerIdAndIdFolloweeId(Long followerId, Long followeeId);
}
