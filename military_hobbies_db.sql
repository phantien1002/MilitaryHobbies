-- =====================================================================
-- Military Hobbies - MySQL 8.0.16+ schema + sample data (v3: types aligned with JPA entities)
-- Spring Boot + Java 17 + MySQL 8.0.16+
-- IMPORTANT: This development script DROPS and recreates military_hobbies.
-- BACK UP ANY EXISTING DATA before running. Do not use this reset script in production.
-- Sample login password for ALL five sample users: Military@123
-- Passwords below are BCrypt hashes, not plaintext.
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS military_hobbies;
CREATE DATABASE military_hobbies CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE military_hobbies;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. USERS & ROLES
CREATE TABLE roles (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(30) NOT NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_roles_name (name)
) ENGINE=InnoDB;

CREATE TABLE users (
  id BIGINT NOT NULL AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL COMMENT 'BCrypt hash only; never plaintext',
  display_name VARCHAR(100) NULL,
  avatar_url VARCHAR(500) NULL,
  bio VARCHAR(500) NULL,
  country_code VARCHAR(2) NULL,
  status ENUM('ACTIVE','LOCKED','DELETED') NOT NULL DEFAULT 'ACTIVE',
  email_verified TINYINT(1) NOT NULL DEFAULT 0,
  last_login_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_users_username (username), UNIQUE KEY uq_users_email (email),
  INDEX idx_users_status_created (status, created_at),
  CONSTRAINT chk_users_email_verified CHECK (email_verified IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE user_roles (
  user_id BIGINT NOT NULL, role_id BIGINT NOT NULL,
  PRIMARY KEY (user_id, role_id), INDEX idx_user_roles_role (role_id),
  CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE refresh_tokens (
  id BIGINT NOT NULL AUTO_INCREMENT, user_id BIGINT NOT NULL,
  token_hash VARCHAR(64) NOT NULL COMMENT 'SHA-256 hash of refresh token',
  expires_at DATETIME NOT NULL, revoked TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_refresh_tokens_hash (token_hash), INDEX idx_rt_user (user_id),
  INDEX idx_rt_expiry_revoked (expires_at, revoked),
  CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_refresh_tokens_revoked CHECK (revoked IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE follows (
  follower_id BIGINT NOT NULL, followee_id BIGINT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (follower_id, followee_id), INDEX idx_follows_followee (followee_id),
  CONSTRAINT fk_follows_follower FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_follows_followee FOREIGN KEY (followee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_follows_not_self CHECK (follower_id <> followee_id)
) ENGINE=InnoDB;

-- 2. LOOKUP TABLES
CREATE TABLE categories (
  id BIGINT NOT NULL AUTO_INCREMENT, parent_id BIGINT NULL,
  name VARCHAR(100) NOT NULL, slug VARCHAR(120) NOT NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_categories_slug (slug), INDEX idx_categories_parent (parent_id),
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
  -- Prevent category cycles and self-parenting in the service layer. A CHECK here conflicts with SET NULL.
) ENGINE=InnoDB;

CREATE TABLE brands (
  id BIGINT NOT NULL AUTO_INCREMENT, name VARCHAR(100) NOT NULL,
  country_code VARCHAR(2) NULL, website VARCHAR(255) NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_brands_name (name)
) ENGINE=InnoDB;

CREATE TABLE scales (
  id BIGINT NOT NULL AUTO_INCREMENT, label VARCHAR(20) NOT NULL, ratio DECIMAL(10,6) NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_scales_label (label),
  CONSTRAINT chk_scales_ratio CHECK (ratio IS NULL OR ratio > 0)
) ENGINE=InnoDB;

CREATE TABLE eras (
  id BIGINT NOT NULL AUTO_INCREMENT, name VARCHAR(100) NOT NULL,
  year_from INT NULL, year_to INT NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_eras_name (name),
  CONSTRAINT chk_eras_year_range CHECK (year_from IS NULL OR year_to IS NULL OR year_from <= year_to)
) ENGINE=InnoDB;

CREATE TABLE tags (
  id BIGINT NOT NULL AUTO_INCREMENT, name VARCHAR(50) NOT NULL,
  PRIMARY KEY (id), UNIQUE KEY uq_tags_name (name)
) ENGINE=InnoDB;

-- 3. SHARED PRODUCT CATALOG
CREATE TABLE products (
  id BIGINT NOT NULL AUTO_INCREMENT, category_id BIGINT NOT NULL,
  brand_id BIGINT NULL, scale_id BIGINT NULL, era_id BIGINT NULL,
  name VARCHAR(255) NOT NULL, model_code VARCHAR(60) NULL, subject_country VARCHAR(2) NULL,
  description TEXT NULL, release_year SMALLINT NULL, cover_url VARCHAR(500) NULL,
  created_by BIGINT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_product_brand_code (brand_id, model_code),
  INDEX idx_product_category (category_id), INDEX idx_product_brand (brand_id),
  INDEX idx_product_scale (scale_id), INDEX idx_product_era (era_id), INDEX idx_product_created_by (created_by),
  FULLTEXT KEY ft_product_name_description (name, description),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
  CONSTRAINT fk_products_brand FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE SET NULL,
  CONSTRAINT fk_products_scale FOREIGN KEY (scale_id) REFERENCES scales(id) ON DELETE SET NULL,
  CONSTRAINT fk_products_era FOREIGN KEY (era_id) REFERENCES eras(id) ON DELETE SET NULL,
  CONSTRAINT fk_products_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE product_tags (
  product_id BIGINT NOT NULL, tag_id BIGINT NOT NULL,
  PRIMARY KEY (product_id, tag_id), INDEX idx_product_tags_tag (tag_id),
  CONSTRAINT fk_product_tags_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  CONSTRAINT fk_product_tags_tag FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. USER COLLECTIONS
CREATE TABLE collections (
  id BIGINT NOT NULL AUTO_INCREMENT, user_id BIGINT NOT NULL,
  name VARCHAR(150) NOT NULL, description TEXT NULL,
  visibility ENUM('PRIVATE','FOLLOWERS','PUBLIC') NOT NULL DEFAULT 'PUBLIC',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), INDEX idx_col_user (user_id), INDEX idx_col_visibility_created (visibility, created_at),
  CONSTRAINT fk_collections_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE collection_items (
  id BIGINT NOT NULL AUTO_INCREMENT, collection_id BIGINT NOT NULL,
  product_id BIGINT NULL, custom_name VARCHAR(255) NULL,
  status ENUM('WISHLIST','UNBUILT','IN_PROGRESS','COMPLETED','SOLD') NOT NULL DEFAULT 'UNBUILT',
  item_condition ENUM('NEW','OPENED','BUILT','USED','DAMAGED') NULL,
  quantity INT NOT NULL DEFAULT 1, purchase_price DECIMAL(12,2) NULL,
  currency VARCHAR(3) NULL, purchase_date DATE NULL, notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), INDEX idx_ci_collection (collection_id), INDEX idx_ci_product (product_id), INDEX idx_ci_status (status),
  CONSTRAINT fk_collection_items_collection FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
  CONSTRAINT fk_collection_items_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
  -- Do not put product_id in a CHECK because ON DELETE SET NULL must remain valid.
  CONSTRAINT chk_collection_item_custom_name CHECK (custom_name IS NULL OR CHAR_LENGTH(TRIM(custom_name)) > 0),
  CONSTRAINT chk_collection_item_quantity CHECK (quantity > 0),
  CONSTRAINT chk_collection_item_price CHECK (purchase_price IS NULL OR purchase_price >= 0)
) ENGINE=InnoDB;

-- 5. BUILD PROJECTS AND LOGS
CREATE TABLE build_projects (
  id BIGINT NOT NULL AUTO_INCREMENT, user_id BIGINT NOT NULL,
  collection_item_id BIGINT NULL, title VARCHAR(200) NOT NULL, summary TEXT NULL,
  status ENUM('PLANNING','BUILDING','PAINTING','FINISHED','ABANDONED') NOT NULL DEFAULT 'PLANNING',
  started_at DATE NULL, finished_at DATE NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), INDEX idx_bp_user (user_id), INDEX idx_bp_status (status), INDEX idx_bp_user_status (user_id,status),
  CONSTRAINT fk_build_projects_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_build_projects_collection_item FOREIGN KEY (collection_item_id) REFERENCES collection_items(id) ON DELETE SET NULL,
  CONSTRAINT chk_build_project_dates CHECK (started_at IS NULL OR finished_at IS NULL OR started_at <= finished_at)
) ENGINE=InnoDB;

CREATE TABLE build_logs (
  id BIGINT NOT NULL AUTO_INCREMENT, project_id BIGINT NOT NULL,
  title VARCHAR(200) NULL, content MEDIUMTEXT NOT NULL, hours_spent DECIMAL(5,2) NULL,
  logged_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), INDEX idx_bl_project_logged (project_id,logged_at),
  CONSTRAINT fk_build_logs_project FOREIGN KEY (project_id) REFERENCES build_projects(id) ON DELETE CASCADE,
  CONSTRAINT chk_build_logs_hours CHECK (hours_spent IS NULL OR hours_spent >= 0)
) ENGINE=InnoDB;

-- 6. COMMUNITY
CREATE TABLE posts (
  id BIGINT NOT NULL AUTO_INCREMENT, user_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL, content MEDIUMTEXT NOT NULL, category_id BIGINT NULL,
  project_id BIGINT NULL, status ENUM('DRAFT','PUBLISHED','HIDDEN') NOT NULL DEFAULT 'PUBLISHED',
  view_count INT NOT NULL DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), INDEX idx_post_user (user_id), INDEX idx_post_status_created (status,created_at),
  INDEX idx_post_category (category_id), INDEX idx_post_project (project_id), FULLTEXT KEY ft_post_title_content (title,content),
  CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_posts_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
  CONSTRAINT fk_posts_project FOREIGN KEY (project_id) REFERENCES build_projects(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE post_tags (
  post_id BIGINT NOT NULL, tag_id BIGINT NOT NULL,
  PRIMARY KEY (post_id,tag_id), INDEX idx_post_tags_tag (tag_id),
  CONSTRAINT fk_post_tags_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_post_tags_tag FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE comments (
  id BIGINT NOT NULL AUTO_INCREMENT, post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL, parent_id BIGINT NULL,
  content TEXT NOT NULL, is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_comments_id_post (id,post_id),
  INDEX idx_cmt_post_created (post_id,created_at), INDEX idx_cmt_parent_post (parent_id,post_id), INDEX idx_cmt_user (user_id),
  CONSTRAINT fk_comments_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_comments_parent_same_post FOREIGN KEY (parent_id,post_id) REFERENCES comments(id,post_id) ON DELETE CASCADE,
  CONSTRAINT chk_comments_is_deleted CHECK (is_deleted IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE post_likes (
  post_id BIGINT NOT NULL, user_id BIGINT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (post_id,user_id), INDEX idx_post_likes_user (user_id),
  CONSTRAINT fk_post_likes_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_post_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. MEDIA. Polymorphic owner existence/ownership must be checked by the service layer.
CREATE TABLE media (
  id BIGINT NOT NULL AUTO_INCREMENT, user_id BIGINT NOT NULL,
  owner_type ENUM('PRODUCT','COLLECTION_ITEM','BUILD_LOG','POST','EVENT') NOT NULL,
  owner_id BIGINT NOT NULL, url VARCHAR(500) NOT NULL,
  media_type ENUM('IMAGE','VIDEO') NOT NULL DEFAULT 'IMAGE', caption VARCHAR(255) NULL,
  sort_order SMALLINT NOT NULL DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), INDEX idx_media_owner (owner_type,owner_id,sort_order), INDEX idx_media_user_created (user_id,created_at),
  CONSTRAINT fk_media_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 8. EVENTS
CREATE TABLE events (
  id BIGINT NOT NULL AUTO_INCREMENT, organizer_id BIGINT NOT NULL,
  title VARCHAR(200) NOT NULL, description TEXT NULL, location VARCHAR(255) NULL,
  start_at DATETIME NOT NULL, end_at DATETIME NULL, max_attendees INT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), INDEX idx_event_start (start_at), INDEX idx_event_organizer (organizer_id),
  CONSTRAINT fk_events_organizer FOREIGN KEY (organizer_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_events_date_range CHECK (end_at IS NULL OR end_at >= start_at),
  CONSTRAINT chk_events_max_attendees CHECK (max_attendees IS NULL OR max_attendees > 0)
) ENGINE=InnoDB;

CREATE TABLE event_attendees (
  event_id BIGINT NOT NULL, user_id BIGINT NOT NULL,
  status ENUM('GOING','INTERESTED','CANCELLED') NOT NULL DEFAULT 'GOING',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (event_id,user_id), INDEX idx_event_attendees_user_status (user_id,status),
  CONSTRAINT fk_event_attendees_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  CONSTRAINT fk_event_attendees_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- SAMPLE DATA: at least 5 rows per table. Development/testing only.
-- All sample accounts use the same BCrypt hash for password Military@123.
-- =====================================================================
INSERT INTO roles (id,name) VALUES
 (1,'ROLE_USER'),(2,'ROLE_MODERATOR'),(3,'ROLE_ADMIN'),(4,'ROLE_COLLECTOR'),(5,'ROLE_EVENT_ORGANIZER');

INSERT INTO users (id,username,email,password_hash,display_name,bio,country_code,status,email_verified) VALUES
(1,'collector1','collector1@example.com','$2a$10$PY7aHXGDf.RPicp5nUSQZ.Ch9KqwnGbGCA6uEju68iGZ9GSuymuqW','Collector One','WWII aircraft model collector','VN','ACTIVE',1),
(2,'collector2','collector2@example.com','$2a$10$PY7aHXGDf.RPicp5nUSQZ.Ch9KqwnGbGCA6uEju68iGZ9GSuymuqW','Collector Two','Scale model builder','US','ACTIVE',1),
(3,'moderator1','moderator1@example.com','$2a$10$PY7aHXGDf.RPicp5nUSQZ.Ch9KqwnGbGCA6uEju68iGZ9GSuymuqW','Moderator One','Community moderator','GB','ACTIVE',1),
(4,'organizer1','organizer1@example.com','$2a$10$PY7aHXGDf.RPicp5nUSQZ.Ch9KqwnGbGCA6uEju68iGZ9GSuymuqW','Event Organizer','Military history event organizer','VN','ACTIVE',1),
(5,'admin','admin@example.com','$2a$10$PY7aHXGDf.RPicp5nUSQZ.Ch9KqwnGbGCA6uEju68iGZ9GSuymuqW','Site Admin','Development administrator','VN','ACTIVE',1);

INSERT INTO user_roles (user_id,role_id) VALUES (1,1),(2,4),(3,2),(4,5),(5,3);
INSERT INTO refresh_tokens (id,user_id,token_hash,expires_at,revoked) VALUES
(1,1,SHA2('sample-refresh-token-1',256),DATE_ADD(NOW(),INTERVAL 30 DAY),0),
(2,2,SHA2('sample-refresh-token-2',256),DATE_ADD(NOW(),INTERVAL 30 DAY),0),
(3,3,SHA2('sample-refresh-token-3',256),DATE_ADD(NOW(),INTERVAL 30 DAY),0),
(4,4,SHA2('sample-refresh-token-4',256),DATE_ADD(NOW(),INTERVAL 30 DAY),0),
(5,5,SHA2('sample-refresh-token-5',256),DATE_ADD(NOW(),INTERVAL 30 DAY),0);
INSERT INTO follows (follower_id,followee_id) VALUES (1,2),(2,3),(3,4),(4,5),(5,1);

INSERT INTO categories (id,parent_id,name,slug) VALUES
(1,NULL,'Aircraft','aircraft'),(2,NULL,'Armored Vehicles','armored-vehicles'),
(3,NULL,'Ships','ships'),(4,2,'Tanks','tanks'),(5,NULL,'Militaria','militaria');
INSERT INTO brands (id,name,country_code,website) VALUES
(1,'Tamiya','JP','https://www.tamiya.com'),(2,'Dragon Models','HK','https://www.dragon-models.com'),
(3,'Trumpeter','CN','https://www.trumpeter-china.com'),(4,'Revell','DE','https://www.revell.com'),
(5,'Academy','KR','https://www.academy.co.kr');
INSERT INTO scales (id,label,ratio) VALUES (1,'1/35',0.028571),(2,'1/48',0.020833),(3,'1/72',0.013889),(4,'1/100',0.010000),(5,'1/144',0.006944);
INSERT INTO eras (id,name,year_from,year_to) VALUES
(1,'World War I',1914,1918),(2,'World War II',1939,1945),(3,'Cold War',1947,1991),
(4,'Vietnam War',1955,1975),(5,'Modern Era',1991,NULL);
INSERT INTO tags (id,name) VALUES (1,'aircraft'),(2,'tank'),(3,'naval'),(4,'wwii'),(5,'beginner-friendly');

INSERT INTO products (id,category_id,brand_id,scale_id,era_id,name,model_code,subject_country,description,release_year,created_by) VALUES
(1,1,1,2,2,'Mitsubishi A6M Zero','TAM-61102','JP','WWII Japanese fighter aircraft model',2018,1),
(2,4,2,1,2,'Tiger I Heavy Tank','DML-6600','DE','WWII German heavy tank model',2020,2),
(3,3,3,3,2,'USS Arizona','TR-05720','US','WWII battleship scale model',2019,3),
(4,2,4,1,3,'M1 Abrams','REV-03260','US','Modern main battle tank model',2021,4),
(5,1,5,3,3,'MiG-21 Fishbed','ACA-12456','SU','Cold War era jet aircraft model',2022,5);
INSERT INTO product_tags (product_id,tag_id) VALUES (1,1),(2,2),(3,3),(4,5),(5,4);

INSERT INTO collections (id,user_id,name,description,visibility) VALUES
(1,1,'Aircraft Shelf','Aircraft kits and completed builds','PUBLIC'),
(2,2,'Armor Collection','Tanks and armored vehicles','PUBLIC'),
(3,3,'Naval Models','Warships and naval kits','FOLLOWERS'),
(4,4,'Cold War Projects','Cold War era models','PRIVATE'),
(5,5,'Featured Collection','Selected showcase models','PUBLIC');
INSERT INTO collection_items (id,collection_id,product_id,custom_name,status,item_condition,quantity,purchase_price,currency,purchase_date,notes) VALUES
(1,1,1,NULL,'COMPLETED','BUILT',1,35.00,'USD','2025-01-15','Airbrushed finish'),
(2,2,2,NULL,'IN_PROGRESS','OPENED',1,48.50,'USD','2025-02-10','Assembly underway'),
(3,3,3,NULL,'UNBUILT','NEW',1,52.00,'USD','2025-03-12','Waiting for display base'),
(4,4,4,NULL,'WISHLIST',NULL,1,NULL,NULL,NULL,'Plan to purchase'),
(5,5,5,NULL,'SOLD','USED',1,20.00,'USD','2024-11-01','Sold to another collector');

INSERT INTO build_projects (id,user_id,collection_item_id,title,summary,status,started_at,finished_at) VALUES
(1,1,1,'A6M Zero build','Aircraft assembly and painting','FINISHED','2025-01-10','2025-02-01'),
(2,2,2,'Tiger I assembly','Detailed armor build','BUILDING','2025-02-12',NULL),
(3,3,3,'USS Arizona project','Ship hull and deck','PLANNING',NULL,NULL),
(4,4,4,'Abrams weathering','Modern tank weathering practice','PAINTING','2025-04-01',NULL),
(5,5,5,'MiG-21 showcase','Cold War aircraft display','ABANDONED','2024-06-01',NULL);
INSERT INTO build_logs (id,project_id,title,content,hours_spent,logged_at) VALUES
(1,1,'Initial assembly','Completed fuselage and wings.',2.50,'2025-01-11 10:00:00'),
(2,2,'Track assembly','Assembled the first track run.',3.00,'2025-02-14 15:30:00'),
(3,3,'Research','Collected reference photos and plans.',1.25,'2025-03-01 09:00:00'),
(4,4,'Primer coat','Applied primer and checked seams.',2.00,'2025-04-03 13:00:00'),
(5,5,'Project notes','Recorded planned paint scheme.',0.50,'2024-06-02 11:00:00');

INSERT INTO posts (id,user_id,title,content,category_id,project_id,status,view_count) VALUES
(1,1,'My first aircraft build','Sharing progress on a WWII aircraft model.',1,1,'PUBLISHED',15),
(2,2,'Tiger I track tips','A few tips for assembling tank tracks.',4,2,'PUBLISHED',28),
(3,3,'Battleship reference guide','Useful references for naval modelers.',3,3,'PUBLISHED',9),
(4,4,'Weathering modern armor','Testing dust and mud effects.',2,4,'DRAFT',3),
(5,5,'Cold War aircraft display','Ideas for a compact display base.',1,5,'PUBLISHED',11);
INSERT INTO post_tags (post_id,tag_id) VALUES (1,1),(2,2),(3,3),(4,5),(5,4);
INSERT INTO comments (id,post_id,user_id,parent_id,content,is_deleted) VALUES
(1,1,2,NULL,'Great paint finish!',0),(2,2,3,NULL,'The track tips are helpful.',0),
(3,3,4,NULL,'Thanks for sharing the references.',0),(4,4,5,NULL,'Try adding pigments for dust.',0),
(5,5,1,NULL,'A display base would look great.',0);
INSERT INTO post_likes (post_id,user_id) VALUES (1,2),(2,3),(3,4),(4,5),(5,1);
INSERT INTO media (id,user_id,owner_type,owner_id,url,media_type,caption,sort_order) VALUES
(1,1,'POST',1,'https://example.com/media/a6m.jpg','IMAGE','A6M Zero build',0),
(2,2,'POST',2,'https://example.com/media/tiger.jpg','IMAGE','Tiger I tracks',0),
(3,3,'POST',3,'https://example.com/media/arizona.jpg','IMAGE','USS Arizona reference',0),
(4,4,'POST',4,'https://example.com/media/abrams.jpg','IMAGE','Abrams weathering',0),
(5,5,'POST',5,'https://example.com/media/mig21.mp4','VIDEO','MiG-21 display video',0);

INSERT INTO events (id,organizer_id,title,description,location,start_at,end_at,max_attendees) VALUES
(1,1,'Monthly Model Meetup','Bring current builds to share.','Nha Trang','2027-01-10 09:00:00','2027-01-10 12:00:00',30),
(2,2,'Armor Model Workshop','Assembly and weathering workshop.','Ho Chi Minh City','2027-02-14 13:00:00','2027-02-14 17:00:00',25),
(3,3,'Naval Modeling Online','Online discussion for ship modelers.','Online','2027-03-20 19:00:00','2027-03-20 20:30:00',100),
(4,4,'Military History Exhibition','Community display and talks.','Hanoi','2027-04-18 08:30:00','2027-04-18 16:00:00',200),
(5,5,'Beginner Painting Session','Introductory model painting session.','Da Nang','2027-05-09 09:00:00','2027-05-09 11:30:00',20);
INSERT INTO event_attendees (event_id,user_id,status) VALUES
(1,2,'GOING'),(2,3,'INTERESTED'),(3,4,'GOING'),(4,1,'GOING'),(5,2,'CANCELLED');

-- End of script. Check table row counts after execution.
