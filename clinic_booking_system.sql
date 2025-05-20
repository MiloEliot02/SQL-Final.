-- Clinic Booking System Database
-- Created: May 20, 2025

-- Drop database if it exists and create a new one
DROP DATABASE IF EXISTS clinic_booking;
CREATE DATABASE clinic_booking;
USE clinic_booking;

-- Table for storing patient information
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20) NOT NULL,
    address VARCHAR(255),
    insurance_number VARCHAR(50),
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    medical_history TEXT,
    INDEX idx_patient_name (last_name, first_name),
    INDEX idx_dob (date_of_birth)
) ENGINE=InnoDB;

-- Table for medical specialties
CREATE TABLE specialties (
    specialty_id INT AUTO_INCREMENT PRIMARY KEY,
    specialty_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
) ENGINE=InnoDB;

-- Table for medical staff/doctors
CREATE TABLE medical_staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialty_id INT,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    hire_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id) ON DELETE SET NULL,
    INDEX idx_staff_name (last_name, first_name)
) ENGINE=InnoDB;

-- Table for clinic locations
CREATE TABLE clinic_locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(20) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    opening_hours VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- Table for available time slots
CREATE TABLE time_slots (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    location_id INT NOT NULL,
    slot_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES clinic_locations(location_id) ON DELETE CASCADE,
    UNIQUE KEY unique_slot (staff_id, location_id, slot_date, start_time),
    INDEX idx_availability (is_available, slot_date)
) ENGINE=InnoDB;

-- Table for appointment status types
CREATE TABLE appointment_status (
    status_id INT AUTO_INCREMENT PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255)
) ENGINE=InnoDB;

-- Table for appointments
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    slot_id INT NOT NULL,
    status_id INT NOT NULL,
    appointment_type VARCHAR(50) NOT NULL,
    reason_for_visit TEXT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES time_slots(slot_id) ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES appointment_status(status_id) ON DELETE RESTRICT,
    INDEX idx_appointment_date (created_at)
) ENGINE=InnoDB;

-- Table for medical records
CREATE TABLE medical_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    appointment_id INT NOT NULL,
    staff_id INT NOT NULL,
    diagnosis TEXT,
    treatment TEXT,
    prescription TEXT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(staff_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Table for billing
CREATE TABLE billing (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    patient_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    insurance_coverage DECIMAL(10, 2) DEFAULT 0.00,
    patient_responsibility DECIMAL(10, 2) AS (amount - insurance_coverage) STORED,
    payment_status ENUM('Pending', 'Paid', 'Partially Paid', 'Insurance Processing', 'Rejected') DEFAULT 'Pending',
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    payment_date DATE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    INDEX idx_payment_status (payment_status)
) ENGINE=InnoDB;

-- Table for many-to-many relationship between staff and locations (which staff works at which locations)
CREATE TABLE staff_locations (
    staff_id INT NOT NULL,
    location_id INT NOT NULL,
    PRIMARY KEY (staff_id, location_id),
    FOREIGN KEY (staff_id) REFERENCES medical_staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES clinic_locations(location_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Table for lab tests
CREATE TABLE lab_tests (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    description TEXT,
    standard_cost DECIMAL(10, 2) NOT NULL,
    preparation_instructions TEXT
) ENGINE=InnoDB;

-- Table for ordered lab tests (many-to-many between appointments and tests)
CREATE TABLE ordered_tests (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    test_id INT NOT NULL,
    ordered_by INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    scheduled_date DATE,
    results TEXT,
    result_date DATETIME,
    status ENUM('Ordered', 'Scheduled', 'Completed', 'Cancelled') DEFAULT 'Ordered',
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (test_id) REFERENCES lab_tests(test_id) ON DELETE RESTRICT,
    FOREIGN KEY (ordered_by) REFERENCES medical_staff(staff_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Table for medication catalog
CREATE TABLE medications (
    medication_id INT AUTO_INCREMENT PRIMARY KEY,
    medication_name VARCHAR(100) NOT NULL,
    generic_name VARCHAR(100),
    description TEXT,
    dosage_form VARCHAR(50),
    standard_dose VARCHAR(50),
    contraindications TEXT,
    side_effects TEXT
) ENGINE=InnoDB;

-- Table for prescriptions (many-to-many between medical records and medications)
CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    record_id INT NOT NULL,
    medication_id INT NOT NULL,
    dosage VARCHAR(50) NOT NULL,
    frequency VARCHAR(50) NOT NULL,
    duration VARCHAR(50) NOT NULL,
    instructions TEXT,
    prescribed_by INT NOT NULL,
    prescribed_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (record_id) REFERENCES medical_records(record_id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(medication_id) ON DELETE RESTRICT,
    FOREIGN KEY (prescribed_by) REFERENCES medical_staff(staff_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Insert initial data for appointment status
INSERT INTO appointment_status (status_name, description) VALUES
('Scheduled', 'Appointment has been booked'),
('Confirmed', 'Patient has confirmed attendance'),
('Checked In', 'Patient has arrived and checked in'),
('In Progress', 'Patient is currently seeing the doctor'),
('Completed', 'Appointment has been completed'),
('Cancelled', 'Appointment was cancelled'),
('No Show', 'Patient did not attend the appointment');

-- Create a view for available appointment slots
CREATE VIEW available_slots AS
SELECT 
    ts.slot_id,
    ms.first_name AS doctor_first_name,
    ms.last_name AS doctor_last_name,
    sp.specialty_name,
    cl.location_name,
    cl.address,
    cl.city,
    ts.slot_date,
    ts.start_time,
    ts.end_time
FROM 
    time_slots ts
JOIN 
    medical_staff ms ON ts.staff_id = ms.staff_id
JOIN 
    specialties sp ON ms.specialty_id = sp.specialty_id
JOIN 
    clinic_locations cl ON ts.location_id = cl.location_id
WHERE 
    ts.is_available = TRUE AND
    ts.slot_date >= CURDATE();

-- Create a view for upcoming appointments
CREATE VIEW upcoming_appointments AS
SELECT 
    a.appointment_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    ms.first_name AS doctor_first_name,
    ms.last_name AS doctor_last_name,
    sp.specialty_name,
    cl.location_name,
    ts.slot_date,
    ts.start_time,
    ts.end_time,
    ast.status_name,
    a.appointment_type,
    a.reason_for_visit
FROM 
    appointments a
JOIN 
    patients p ON a.patient_id = p.patient_id
JOIN 
    time_slots ts ON a.slot_id = ts.slot_id
JOIN 
    medical_staff ms ON ts.staff_id = ms.staff_id
JOIN 
    specialties sp ON ms.specialty_id = sp.specialty_id
JOIN 
    clinic_locations cl ON ts.location_id = cl.location_id
JOIN 
    appointment_status ast ON a.status_id = ast.status_id
WHERE 
    ts.slot_date >= CURDATE()
ORDER BY 
    ts.slot_date, ts.start_time;

-- Create a stored procedure for booking an appointment
DELIMITER //
CREATE PROCEDURE book_appointment(
    IN p_patient_id INT,
    IN p_slot_id INT,
    IN p_appointment_type VARCHAR(50),
    IN p_reason_for_visit TEXT
)
BEGIN
    DECLARE slot_available BOOLEAN;
    
    -- Check if the slot is available
    SELECT is_available INTO slot_available 
    FROM time_slots 
    WHERE slot_id = p_slot_id;
    
    IF slot_available THEN
        -- Begin transaction
        START TRANSACTION;
        
        -- Update slot availability
        UPDATE time_slots SET is_available = FALSE WHERE slot_id = p_slot_id;
        
        -- Create appointment
        INSERT INTO appointments (patient_id, slot_id, status_id, appointment_type, reason_for_visit)
        VALUES (p_patient_id, p_slot_id, 1, p_appointment_type, p_reason_for_visit);
        
        -- Commit transaction
        COMMIT;
        
        SELECT 'Appointment booked successfully' AS message, LAST_INSERT_ID() AS appointment_id;
    ELSE
        SELECT 'Slot is no longer available' AS message;
    END IF;
END //
DELIMITER ;

-- Create a stored procedure for cancelling an appointment
DELIMITER //
CREATE PROCEDURE cancel_appointment(
    IN p_appointment_id INT
)
BEGIN
    DECLARE v_slot_id INT;
    
    -- Begin transaction
    START TRANSACTION;
    
    -- Get the slot_id
    SELECT slot_id INTO v_slot_id FROM appointments WHERE appointment_id = p_appointment_id;
    
    -- Update appointment status to cancelled
    UPDATE appointments SET status_id = 6 WHERE appointment_id = p_appointment_id;
    
    -- Make the time slot available again
    UPDATE time_slots SET is_available = TRUE WHERE slot_id = v_slot_id;
    
    -- Commit transaction
    COMMIT;
    
    SELECT 'Appointment cancelled successfully' AS message;
END //
DELIMITER ;

-- Create a trigger to update time slot availability when an appointment is deleted
DELIMITER //
CREATE TRIGGER after_appointment_delete
AFTER DELETE ON appointments
FOR EACH ROW
BEGIN
    UPDATE time_slots SET is_available = TRUE WHERE slot_id = OLD.slot_id;
END //
DELIMITER ;

-- Create a trigger to check appointment time conflicts
DELIMITER //
CREATE TRIGGER before_appointment_insert
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
    DECLARE conflict_count INT;
    
    -- Check if patient already has an appointment at the same time
    SELECT COUNT(*) INTO conflict_count
    FROM appointments a
    JOIN time_slots ts1 ON a.slot_id = ts1.slot_id
    JOIN time_slots ts2 ON ts2.slot_id = NEW.slot_id
    WHERE a.patient_id = NEW.patient_id
    AND a.status_id NOT IN (6, 7) -- Not cancelled or no-show
    AND ts1.slot_date = ts2.slot_date
    AND ((ts1.start_time <= ts2.start_time AND ts1.end_time > ts2.start_time)
         OR (ts1.start_time < ts2.end_time AND ts1.end_time >= ts2.end_time)
         OR (ts1.start_time >= ts2.start_time AND ts1.end_time <= ts2.end_time));
    
    IF conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Patient already has an appointment scheduled at this time';
    END IF;
END //
DELIMITER ;

-- Create an index for searching patients
CREATE FULLTEXT INDEX ft_patient_search ON patients(first_name, last_name, email, phone, insurance_number);

-- Create an event to automatically update the status of past appointments
DELIMITER //
CREATE EVENT update_past_appointments
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    -- Update no-shows (status still scheduled/confirmed but date has passed)
    UPDATE appointments a
    JOIN time_slots ts ON a.slot_id = ts.slot_id
    SET a.status_id = 7 -- No Show
    WHERE a.status_id IN (1, 2) -- Scheduled or Confirmed
    AND CONCAT(ts.slot_date, ' ', ts.end_time) < NOW();
END //
DELIMITER ;
