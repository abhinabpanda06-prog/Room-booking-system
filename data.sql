-- 1. Setup Database
CREATE DATABASE IF NOT EXISTS university_booking;
USE university_booking;

-- 2. Drop tables if they exist (Careful: this deletes existing data)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS classrooms;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- 3. Create Users Table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('student', 'faculty') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 4. Create Classrooms Table
CREATE TABLE classrooms (
    classroom_id INT AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    building ENUM('AB1', 'AB2', 'AB3', 'AB4') NOT NULL,
    floor ENUM('Ground', 'First', 'Second', 'Third') NOT NULL,
    capacity INT DEFAULT 30,
    UNIQUE KEY unique_room (room_number, building)
) ENGINE=InnoDB;

-- 5. Create Bookings Table
CREATE TABLE bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    classroom_id INT NOT NULL,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    expected_attendees INT NOT NULL,
    pdf_attachment_path VARCHAR(255),
    status ENUM('pending', 'confirmed', 'cancelled') DEFAULT 'confirmed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(classroom_id) ON DELETE CASCADE,
    
    -- Indexing for performance when searching schedules
    INDEX idx_schedule (classroom_id, booking_date)
) ENGINE=InnoDB;

-- 6. Automation: Script to populate all 480 rooms
DELIMITER //

CREATE PROCEDURE PopulateClassrooms()
BEGIN
    DECLARE b_idx INT DEFAULT 1;
    DECLARE f_idx INT DEFAULT 0;
    DECLARE r_idx INT DEFAULT 1;
    DECLARE b_name VARCHAR(5);
    DECLARE f_name VARCHAR(10);
    DECLARE r_name VARCHAR(5);

    WHILE b_idx <= 4 DO
        SET b_name = CONCAT('AB', b_idx);
        SET f_idx = 0;
        
        WHILE f_idx <= 3 DO
            -- Map floor index to names
            SET f_name = CASE 
                WHEN f_idx = 0 THEN 'Ground'
                WHEN f_idx = 1 THEN 'First'
                WHEN f_idx = 2 THEN 'Second'
                WHEN f_idx = 3 THEN 'Third'
            END;
            
            SET r_idx = 1;
            WHILE r_idx <= 30 DO
                -- Format room number: e.g., Floor 0 + Room 1 = 001, Floor 1 + Room 1 = 101
                SET r_name = LPAD((f_idx * 100) + r_idx, 3, '0');
                
                INSERT INTO classrooms (room_number, building, floor) 
                VALUES (r_name, b_name, f_name);
                
                SET r_idx = r_idx + 1;
            END WHILE;
            
            SET f_idx = f_idx + 1;
        END WHILE;
        
        SET b_idx = b_idx + 1;
    END WHILE;
END //

DELIMITER ;

-- Run the procedure to fill the table
CALL PopulateClassrooms();

-- Remove the procedure after use
DROP PROCEDURE PopulateClassrooms;
