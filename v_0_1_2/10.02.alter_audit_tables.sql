-- MySQL Workbench Synchronization
-- Generated: 2015-05-13 08:09
-- Model: New Model
-- Version: 1.0
-- Project: Name of the project
-- Author: Kris Vandermast

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE TABLE `AUDIT_P_towing_be`.`T_TOWING_VOUCHER_LOCATION_TRACKINGS` (
  `id` BIGINT NOT NULL,
  `towing_voucher_id` BIGINT NOT NULL,
  `category` ENUM('signa_arrival', 'towing_arrival', 'towing_start', 'towing_completed') NOT NULL,
  `lat` DOUBLE NULL,
  `long` DOUBLE NULL,
  `tracking_ts` DATETIME NOT NULL,
  `cd` DATETIME NOT NULL,
  `cd_by` VARCHAR(255) NOT NULL,
  INDEX `fk_voucher_location_tracking_voucher_idx` (`towing_voucher_id` ASC));

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
