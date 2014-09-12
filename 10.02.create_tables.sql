-- MySQL Script generated by MySQL Workbench
-- Fri Sep 12 20:08:48 2014
-- Model: New Model    Version: 1.0
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Table `P_DICTIONARY`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_DICTIONARY` ;

CREATE TABLE IF NOT EXISTS `P_DICTIONARY` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `category` ENUM('INSURANCE', 'COUNTRY_LICENCE_PLATE', 'COLLECTOR', 'TRAFFIC_LANE') NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `cd` TIMESTAMP NOT NULL,
  `cd_by` VARCHAR(255) NULL,
  `ud` TIMESTAMP NULL,
  `ud_by` VARCHAR(255) NULL,
  `dd` TIMESTAMP NULL,
  `dd_by` VARCHAR(255) NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `P_DICTIONARY_AUDIT_LOG`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_DICTIONARY_AUDIT_LOG` ;

CREATE TABLE IF NOT EXISTS `P_DICTIONARY_AUDIT_LOG` (
  `id` VARCHAR(45) NOT NULL,
  `dictionary_id` BIGINT NOT NULL,
  `category` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `cd` TIMESTAMP NOT NULL,
  `cd_by` VARCHAR(255) NULL,
  `ud` TIMESTAMP NULL,
  `ud_by` VARCHAR(255) NULL,
  `dd` TIMESTAMP NULL,
  `dd_by` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_P_DICTIONARY_AUDIT_LOG_P_DICTIONARY1`
    FOREIGN KEY (`dictionary_id`)
    REFERENCES `P_DICTIONARY` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_P_DICTIONARY_AUDIT_LOG_P_DICTIONARY1_idx` ON `P_DICTIONARY_AUDIT_LOG` (`dictionary_id` ASC);


-- -----------------------------------------------------
-- Table `T_COMPANIES`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_COMPANIES` ;

CREATE TABLE IF NOT EXISTS `T_COMPANIES` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `code` VARCHAR(45) NOT NULL,
  `street` VARCHAR(255) NOT NULL,
  `street_number` VARCHAR(45) NULL,
  `street_pobox` VARCHAR(45) NULL,
  `zip` VARCHAR(4) NULL,
  `city` VARCHAR(255) NULL,
  `phone` VARCHAR(45) NOT NULL,
  `fax` VARCHAR(45) NULL,
  `email` VARCHAR(255) NULL,
  `website` VARCHAR(255) NULL,
  `depot` VARCHAR(255) NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `P_ALLOTMENT`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_ALLOTMENT` ;

CREATE TABLE IF NOT EXISTS `P_ALLOTMENT` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `P_ALLOTMENT_DIRECTIONS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_ALLOTMENT_DIRECTIONS` ;

CREATE TABLE IF NOT EXISTS `P_ALLOTMENT_DIRECTIONS` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `allotment_id` INT NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_ALLOTMENT_DIRECTIONS_T_ALLOTMENT1`
    FOREIGN KEY (`allotment_id`)
    REFERENCES `P_ALLOTMENT` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_ALLOTMENT_DIRECTIONS_T_ALLOTMENT1_idx` ON `P_ALLOTMENT_DIRECTIONS` (`allotment_id` ASC);


-- -----------------------------------------------------
-- Table `P_ALLOTMENT_DIRECTION_INDICATORS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_ALLOTMENT_DIRECTION_INDICATORS` ;

CREATE TABLE IF NOT EXISTS `P_ALLOTMENT_DIRECTION_INDICATORS` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `allotment_directions_id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_ALLOTMENT_DIRECTION_INDICATORS_T_ALLOTMENT_DIRECTIONS1`
    FOREIGN KEY (`allotment_directions_id`)
    REFERENCES `P_ALLOTMENT_DIRECTIONS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_ALLOTMENT_DIRECTION_INDICATORS_T_ALLOTMENT_DIRECTIONS1_idx` ON `P_ALLOTMENT_DIRECTION_INDICATORS` (`allotment_directions_id` ASC);


-- -----------------------------------------------------
-- Table `P_POLICE_TRAFFIC_POSTS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_POLICE_TRAFFIC_POSTS` ;

CREATE TABLE IF NOT EXISTS `P_POLICE_TRAFFIC_POSTS` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `allotment_id` INT NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  `code` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_POLICE_TRAFFIC_POST_T_ALLOTMENT1`
    FOREIGN KEY (`allotment_id`)
    REFERENCES `P_ALLOTMENT` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_POLICE_TRAFFIC_POST_T_ALLOTMENT1_idx` ON `P_POLICE_TRAFFIC_POSTS` (`allotment_id` ASC);


-- -----------------------------------------------------
-- Table `P_INCIDENT_TYPES`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_INCIDENT_TYPES` ;

CREATE TABLE IF NOT EXISTS `P_INCIDENT_TYPES` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL,
  `code` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `P_TIMEFRAMES`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_TIMEFRAMES` ;

CREATE TABLE IF NOT EXISTS `P_TIMEFRAMES` (
  `id` INT NOT NULL,
  `name` VARCHAR(45) NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `T_DOSSIERS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_DOSSIERS` ;

CREATE TABLE IF NOT EXISTS `T_DOSSIERS` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `timeframe_id` INT NOT NULL,
  `company_id` BIGINT NULL,
  `police_traffic_post_id` INT NULL,
  `incident_type_id` INT NULL,
  `allotment_id` INT NULL,
  `allotment_direction_indicator_id` INT NULL,
  `allotment_direction_id` INT NULL,
  `traffic_lane_id` BIGINT NULL,
  `dossier_number` INT(9) ZEROFILL NOT NULL,
  `status` ENUM('NEW', 'IN PROGRESS', 'COMPLETED', 'TO CHECK', 'READY FOR INVOICE', 'INVOICED', 'CLOSED') NOT NULL,
  `call_date` DATETIME NULL,
  `call_number` VARCHAR(45) NULL,
  `cd` TIMESTAMP NOT NULL,
  `cd_by` VARCHAR(255) NOT NULL,
  `ud` TIMESTAMP NULL,
  `ud_by` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_DOSSIERS_T_COMPANIES1`
    FOREIGN KEY (`company_id`)
    REFERENCES `T_COMPANIES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_DOSSIERS_T_ALLOTMENT1`
    FOREIGN KEY (`allotment_id`)
    REFERENCES `P_ALLOTMENT` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_DOSSIERS_T_ALLOTMENT_DIRECTIONS1`
    FOREIGN KEY (`allotment_direction_id`)
    REFERENCES `P_ALLOTMENT_DIRECTIONS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_DOSSIERS_T_ALLOTMENT_DIRECTION_INDICATORS1`
    FOREIGN KEY (`allotment_direction_indicator_id`)
    REFERENCES `P_ALLOTMENT_DIRECTION_INDICATORS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_DOSSIERS_T_POLICE_TRAFFIC_POST1`
    FOREIGN KEY (`police_traffic_post_id`)
    REFERENCES `P_POLICE_TRAFFIC_POSTS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_DOSSIERS_P_INCIDENT_TYPES1`
    FOREIGN KEY (`incident_type_id`)
    REFERENCES `P_INCIDENT_TYPES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_DOSSIERS_P_DICTIONARY1`
    FOREIGN KEY (`traffic_lane_id`)
    REFERENCES `P_DICTIONARY` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_DOSSIERS_P_TIMEFRAMES1`
    FOREIGN KEY (`timeframe_id`)
    REFERENCES `P_TIMEFRAMES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_DOSSIERS_T_COMPANIES1_idx` ON `T_DOSSIERS` (`company_id` ASC);

CREATE UNIQUE INDEX `dossier_number_UNIQUE` ON `T_DOSSIERS` (`dossier_number` ASC);

CREATE INDEX `fk_T_DOSSIERS_T_ALLOTMENT1_idx` ON `T_DOSSIERS` (`allotment_id` ASC);

CREATE INDEX `fk_T_DOSSIERS_T_ALLOTMENT_DIRECTIONS1_idx` ON `T_DOSSIERS` (`allotment_direction_id` ASC);

CREATE INDEX `fk_T_DOSSIERS_T_ALLOTMENT_DIRECTION_INDICATORS1_idx` ON `T_DOSSIERS` (`allotment_direction_indicator_id` ASC);

CREATE INDEX `fk_T_DOSSIERS_T_POLICE_TRAFFIC_POST1_idx` ON `T_DOSSIERS` (`police_traffic_post_id` ASC);

CREATE INDEX `fk_T_DOSSIERS_P_INCIDENT_TYPES1_idx` ON `T_DOSSIERS` (`incident_type_id` ASC);

CREATE INDEX `fk_T_DOSSIERS_P_DICTIONARY1_idx` ON `T_DOSSIERS` (`traffic_lane_id` ASC);

CREATE INDEX `fk_T_DOSSIERS_P_TIMEFRAMES1_idx` ON `T_DOSSIERS` (`timeframe_id` ASC);


-- -----------------------------------------------------
-- Table `T_TOWING_VOUCHERS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_TOWING_VOUCHERS` ;

CREATE TABLE IF NOT EXISTS `T_TOWING_VOUCHERS` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `dossier_id` BIGINT NOT NULL,
  `insurance_id` BIGINT NULL,
  `collector_id` BIGINT NULL,
  `voucher_number` INT(5) ZEROFILL NULL,
  `police_signature_dt` DATETIME NULL,
  `recipient_signature_dt` DATETIME NULL,
  `insurance_dossiernr` VARCHAR(45) NULL,
  `insurance_warranty_held_by` VARCHAR(255) NULL,
  `vehicule_type` VARCHAR(255) NULL,
  `vehicule_licenceplate` VARCHAR(15) NULL,
  `vehicule_country` VARCHAR(5) NULL,
  `vehicule_collected` DATETIME NULL,
  `towed_by` VARCHAR(45) NULL,
  `towed_by_vehicle` VARCHAR(15) NULL,
  `towing_called` DATETIME NULL,
  `towing_arrival` DATETIME NULL,
  `towing_start` DATETIME NULL,
  `towing_completed` DATETIME NULL,
  `towing_depot` VARCHAR(512) NULL,
  `signa_by` VARCHAR(45) NULL,
  `signa_by_vehicle` VARCHAR(15) NULL,
  `signa_arrival` DATETIME NULL,
  `cic` DATETIME NULL,
  `additional_info` TEXT NULL,
  `cd` TIMESTAMP NOT NULL,
  `cd_by` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_TOWING_VOUCHER_T_DOSSIER1`
    FOREIGN KEY (`dossier_id`)
    REFERENCES `T_DOSSIERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_TOWING_VOUCHER_P_DICTIONARY1`
    FOREIGN KEY (`insurance_id`)
    REFERENCES `P_DICTIONARY` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_TOWING_VOUCHERS_P_DICTIONARY1`
    FOREIGN KEY (`collector_id`)
    REFERENCES `P_DICTIONARY` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_TOWING_VOUCHER_T_DOSSIER1_idx` ON `T_TOWING_VOUCHERS` (`dossier_id` ASC);

CREATE INDEX `fk_T_TOWING_VOUCHER_P_DICTIONARY1_idx` ON `T_TOWING_VOUCHERS` (`insurance_id` ASC);

CREATE INDEX `fk_T_TOWING_VOUCHERS_P_DICTIONARY1_idx` ON `T_TOWING_VOUCHERS` (`collector_id` ASC);


-- -----------------------------------------------------
-- Table `T_TOWING_VOUCHER_ATTS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_TOWING_VOUCHER_ATTS` ;

CREATE TABLE IF NOT EXISTS `T_TOWING_VOUCHER_ATTS` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `towing_voucher_id` BIGINT NOT NULL,
  `category` ENUM('SIGNATURE_RECIPIENT', 'SIGNATURE_POLICE', 'SIGNATURE_ORIGINATOR', 'ASSISTANCE_ATT', 'ATT') NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_TOWING_VOUCHER_ATTACHMENT_T_TOWING_VOUCHER1`
    FOREIGN KEY (`towing_voucher_id`)
    REFERENCES `T_TOWING_VOUCHERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_TOWING_VOUCHER_ATTACHMENT_T_TOWING_VOUCHER1_idx` ON `T_TOWING_VOUCHER_ATTS` (`towing_voucher_id` ASC);


-- -----------------------------------------------------
-- Table `T_DOSSIER_COMMUNICATIONS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_DOSSIER_COMMUNICATIONS` ;

CREATE TABLE IF NOT EXISTS `T_DOSSIER_COMMUNICATIONS` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `dossier_id` BIGINT NOT NULL,
  `towing_voucher_id` BIGINT NULL,
  `type` ENUM('INTERNAL', 'EMAIL') NOT NULL,
  `subject` VARCHAR(255) NULL,
  `message` LONGTEXT NOT NULL,
  `cd` TIMESTAMP NOT NULL,
  `cd_by` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_DOSSIER_COMMUNICATIONS_T_DOSSIERS1`
    FOREIGN KEY (`dossier_id`)
    REFERENCES `T_DOSSIERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_DOSSIER_COMMUNICATIONS_T_TOWING_VOUCHERS1`
    FOREIGN KEY (`towing_voucher_id`)
    REFERENCES `T_TOWING_VOUCHERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_DOSSIER_COMMUNICATIONS_T_DOSSIERS1_idx` ON `T_DOSSIER_COMMUNICATIONS` (`dossier_id` ASC);

CREATE INDEX `fk_T_DOSSIER_COMMUNICATIONS_T_TOWING_VOUCHERS1_idx` ON `T_DOSSIER_COMMUNICATIONS` (`towing_voucher_id` ASC);


-- -----------------------------------------------------
-- Table `T_DOSSIER_COMM_ATTS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_DOSSIER_COMM_ATTS` ;

CREATE TABLE IF NOT EXISTS `T_DOSSIER_COMM_ATTS` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `dossier_communications_id` BIGINT NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  `content_type` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_DOSSIER_COMM_ATTS_T_DOSSIER_COMMUNICATIONS1`
    FOREIGN KEY (`dossier_communications_id`)
    REFERENCES `T_DOSSIER_COMMUNICATIONS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_DOSSIER_COMM_ATTS_T_DOSSIER_COMMUNICATIONS1_idx` ON `T_DOSSIER_COMM_ATTS` (`dossier_communications_id` ASC);


-- -----------------------------------------------------
-- Table `T_RECIPIENTS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_RECIPIENTS` ;

CREATE TABLE IF NOT EXISTS `T_RECIPIENTS` (
  `id` VARCHAR(45) NOT NULL,
  `dossier_communications_id` BIGINT NOT NULL,
  `type` ENUM('TO', 'CC', 'BCC') NOT NULL,
  `email_address` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_RECIPIENTS_T_DOSSIER_COMMUNICATIONS1`
    FOREIGN KEY (`dossier_communications_id`)
    REFERENCES `T_DOSSIER_COMMUNICATIONS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_RECIPIENTS_T_DOSSIER_COMMUNICATIONS1_idx` ON `T_RECIPIENTS` (`dossier_communications_id` ASC);


-- -----------------------------------------------------
-- Table `T_USERS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_USERS` ;

CREATE TABLE IF NOT EXISTS `T_USERS` (
  `id` VARCHAR(36) NOT NULL,
  `company_id` BIGINT NOT NULL,
  `login` VARCHAR(255) NOT NULL,
  `first_name` VARCHAR(255) NOT NULL,
  `last_name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NULL,
  `is_active` TINYINT(1) NOT NULL,
  `login_attempts` TINYINT NULL,
  `is_locked` TINYINT(1) NOT NULL,
  `locked_ts` TIMESTAMP NULL,
  `cd` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cd_by` VARCHAR(255) NOT NULL DEFAULT 'SYSTEM',
  `dd` TIMESTAMP NULL,
  `dd_by` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_USERS_T_COMPANIES1`
    FOREIGN KEY (`company_id`)
    REFERENCES `T_COMPANIES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `ix_users_login` ON `T_USERS` (`login` ASC);

CREATE INDEX `fk_T_USERS_T_COMPANIES1_idx` ON `T_USERS` (`company_id` ASC);


-- -----------------------------------------------------
-- Table `P_ROLES`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_ROLES` ;

CREATE TABLE IF NOT EXISTS `P_ROLES` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(45) NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  `dd` TIMESTAMP NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `T_USER_ROLES`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_USER_ROLES` ;

CREATE TABLE IF NOT EXISTS `T_USER_ROLES` (
  `role_id` INT NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  PRIMARY KEY (`role_id`, `user_id`),
  CONSTRAINT `fk_T_USER_ROLES_T_ROLES1`
    FOREIGN KEY (`role_id`)
    REFERENCES `P_ROLES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_USER_ROLES_T_USERS1`
    FOREIGN KEY (`user_id`)
    REFERENCES `T_USERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_USER_ROLES_T_ROLES1_idx` ON `T_USER_ROLES` (`role_id` ASC);

CREATE INDEX `fk_T_USER_ROLES_T_USERS1_idx` ON `T_USER_ROLES` (`user_id` ASC);


-- -----------------------------------------------------
-- Table `T_USER_PASSWORDS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_USER_PASSWORDS` ;

CREATE TABLE IF NOT EXISTS `T_USER_PASSWORDS` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(36) NOT NULL,
  `pwd` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_USER_PASSWORDS_T_USERS1`
    FOREIGN KEY (`user_id`)
    REFERENCES `T_USERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `ix_fk_user_id` ON `T_USER_PASSWORDS` (`user_id` ASC);


-- -----------------------------------------------------
-- Table `T_COMPANY_ALLOTMENTS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_COMPANY_ALLOTMENTS` ;

CREATE TABLE IF NOT EXISTS `T_COMPANY_ALLOTMENTS` (
  `company_id` BIGINT NOT NULL,
  `allotment_id` INT NOT NULL,
  PRIMARY KEY (`company_id`, `allotment_id`),
  CONSTRAINT `fk_T_COMPANY_ALLOTMENTS_T_COMPANIES1`
    FOREIGN KEY (`company_id`)
    REFERENCES `T_COMPANIES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_COMPANY_ALLOTMENTS_T_ALLOTMENT1`
    FOREIGN KEY (`allotment_id`)
    REFERENCES `P_ALLOTMENT` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_COMPANY_ALLOTMENTS_T_ALLOTMENT1_idx` ON `T_COMPANY_ALLOTMENTS` (`allotment_id` ASC);


-- -----------------------------------------------------
-- Table `T_USER_TOKENS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_USER_TOKENS` ;

CREATE TABLE IF NOT EXISTS `T_USER_TOKENS` (
  `user_id` VARCHAR(36) NOT NULL,
  `token` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_T_USER_TOKENS_T_USERS1`
    FOREIGN KEY (`user_id`)
    REFERENCES `T_USERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE UNIQUE INDEX `token_UNIQUE` ON `T_USER_TOKENS` (`token` ASC);


-- -----------------------------------------------------
-- Table `T_SEQUENCES`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_SEQUENCES` ;

CREATE TABLE IF NOT EXISTS `T_SEQUENCES` (
  `code` ENUM('DOSSIER', 'TOWING_VOUCHER') NOT NULL,
  `seq_val` INT NOT NULL,
  PRIMARY KEY (`code`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `T_TOWING_VOUCHER_INVOICE_LINES`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_TOWING_VOUCHER_INVOICE_LINES` ;

CREATE TABLE IF NOT EXISTS `T_TOWING_VOUCHER_INVOICE_LINES` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `towing_voucher_id` BIGINT NOT NULL,
  `activity` VARCHAR(45) NULL,
  `amount` DOUBLE NOT NULL,
  `price_excl_vat` DOUBLE NULL,
  `price_incl_vat` DOUBLE NULL,
  `price_cal_excl_vat` DOUBLE NULL,
  `price_cal_incl_vat` DOUBLE NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_TOWING_VOUCHER_INVOICE_LINES_T_TOWING_VOUCHERS1`
    FOREIGN KEY (`towing_voucher_id`)
    REFERENCES `T_TOWING_VOUCHERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_TOWING_VOUCHER_INVOICE_LINES_T_TOWING_VOUCHERS1_idx` ON `T_TOWING_VOUCHER_INVOICE_LINES` (`towing_voucher_id` ASC);


-- -----------------------------------------------------
-- Table `T_TOWING_VOUCHER_PAYMENTS`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_TOWING_VOUCHER_PAYMENTS` ;

CREATE TABLE IF NOT EXISTS `T_TOWING_VOUCHER_PAYMENTS` (
  `id` BIGINT NOT NULL,
  `towing_voucher_id` BIGINT NOT NULL,
  `amount_guaranteed_by_insurance` DOUBLE NULL,
  `amount_customer` DOUBLE NULL,
  `paid_in_cash` DOUBLE NULL,
  `paid_by_bank_deposit` DOUBLE NULL,
  `paid_by_debit_card` DOUBLE NULL,
  `paid_by_credit_card` DOUBLE NULL,
  `cal_amount_paid` DOUBLE NULL,
  `cal_amount_unpaid` DOUBLE NULL,
  `cd` TIMESTAMP NOT NULL,
  `cd_by` VARCHAR(45) NOT NULL,
  `ud` TIMESTAMP NULL,
  `ud_by` VARCHAR(45) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_T_TOWING_VOUCHER_PAYMENTS_T_TOWING_VOUCHERS1`
    FOREIGN KEY (`towing_voucher_id`)
    REFERENCES `T_TOWING_VOUCHERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_TOWING_VOUCHER_PAYMENTS_T_TOWING_VOUCHERS1_idx` ON `T_TOWING_VOUCHER_PAYMENTS` (`towing_voucher_id` ASC);


-- -----------------------------------------------------
-- Table `P_TIMEFRAME_VALIDITY`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_TIMEFRAME_VALIDITY` ;

CREATE TABLE IF NOT EXISTS `P_TIMEFRAME_VALIDITY` (
  `id` INT NOT NULL,
  `timeframe_id` INT NOT NULL,
  `category` ENUM('WORKDAY', 'SATURDAY', 'SUNDAY', 'HOLIDAY') NOT NULL,
  `from` TIME NOT NULL,
  `till` TIME NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_P_TIMEFRAME_VALIDITY_P_TIMEFRAMES1`
    FOREIGN KEY (`timeframe_id`)
    REFERENCES `P_TIMEFRAMES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_P_TIMEFRAME_VALIDITY_P_TIMEFRAMES1_idx` ON `P_TIMEFRAME_VALIDITY` (`timeframe_id` ASC);


-- -----------------------------------------------------
-- Table `P_TIMEFRAME_ACTIVITIES`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_TIMEFRAME_ACTIVITIES` ;

CREATE TABLE IF NOT EXISTS `P_TIMEFRAME_ACTIVITIES` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `code` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `P_TIMEFRAME_ACTIVITY_FEE`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `P_TIMEFRAME_ACTIVITY_FEE` ;

CREATE TABLE IF NOT EXISTS `P_TIMEFRAME_ACTIVITY_FEE` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `timeframe_id` INT NOT NULL,
  `timeframe_activity_id` INT NOT NULL,
  `fee_excl_vat` DOUBLE NOT NULL,
  `fee_incl_vat` DOUBLE NOT NULL,
  `valid_from` DATETIME NOT NULL,
  `valid_until` DATETIME NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_P_TIMEFRAME_ACTIVITY_FEE_P_TIMEFRAMES1`
    FOREIGN KEY (`timeframe_id`)
    REFERENCES `P_TIMEFRAMES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_P_TIMEFRAME_ACTIVITY_FEE_P_TIMEFRAME_ACTIVITIES1`
    FOREIGN KEY (`timeframe_activity_id`)
    REFERENCES `P_TIMEFRAME_ACTIVITIES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_P_TIMEFRAME_ACTIVITY_FEE_P_TIMEFRAMES1_idx` ON `P_TIMEFRAME_ACTIVITY_FEE` (`timeframe_id` ASC);

CREATE INDEX `fk_P_TIMEFRAME_ACTIVITY_FEE_P_TIMEFRAME_ACTIVITIES1_idx` ON `P_TIMEFRAME_ACTIVITY_FEE` (`timeframe_activity_id` ASC);


-- -----------------------------------------------------
-- Table `T_TOWING_ACTIVITIES`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `T_TOWING_ACTIVITIES` ;

CREATE TABLE IF NOT EXISTS `T_TOWING_ACTIVITIES` (
  `towing_voucher_id` BIGINT NOT NULL,
  `activity_id` INT NOT NULL,
  `amount` DOUBLE NOT NULL,
  PRIMARY KEY (`towing_voucher_id`, `activity_id`),
  CONSTRAINT `fk_T_TOWING_ACTIVITIES_T_TOWING_VOUCHERS1`
    FOREIGN KEY (`towing_voucher_id`)
    REFERENCES `T_TOWING_VOUCHERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_TOWING_ACTIVITIES_P_TIMEFRAME_ACTIVITY_FEE1`
    FOREIGN KEY (`activity_id`)
    REFERENCES `P_TIMEFRAME_ACTIVITY_FEE` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_T_TOWING_ACTIVITIES_T_TOWING_VOUCHERS1_idx` ON `T_TOWING_ACTIVITIES` (`towing_voucher_id` ASC);

CREATE INDEX `fk_T_TOWING_ACTIVITIES_P_TIMEFRAME_ACTIVITY_FEE1_idx` ON `T_TOWING_ACTIVITIES` (`activity_id` ASC);


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
