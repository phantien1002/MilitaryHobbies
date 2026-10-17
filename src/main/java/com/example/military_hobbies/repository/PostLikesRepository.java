package com.example.military_hobbies.repository;

import com.example.military_hobbies.entity.PostLikes;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostLikesRepository extends JpaRepository<PostLikes, PostLikes.PostLikeId> {
    long countByIdPostId(Long postId);
    boolean existsByIdPostIdAndIdUserId(Long postId, Long userId);
}
