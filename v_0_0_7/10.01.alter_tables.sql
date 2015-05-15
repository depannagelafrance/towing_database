-- MySQL Workbench Synchronization
-- Generated: 2015-05-13 08:09
-- Model: New Model
-- Version: 1.0
-- Project: Name of the project
-- Author: Kris Vandermast

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE TABLE IF NOT EXISTS `P_towing_be`.`T_INVOICE_BATCH_RUNS` (
  `id` VARCHAR(36) NOT NULL,
  `batch_started` DATETIME NOT NULL,
  `batch_completed` DATETIME NULL,
  `cd` DATETIME NOT NULL,
  `cd_by` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `P_towing_be`.`T_INVOICES` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `company_id` BIGINT(20) NOT NULL,
  `invoice_customer_id` BIGINT(20) NOT NULL,
  `invoice_date` DATE NOT NULL,
  `invoice_number` INT(10) ZEROFILL NOT NULL,
  `vat_foreign_country` TINYINT(1) NULL DEFAULT NULL,
  `invoice_total_excl_vat` DOUBLE(5,2) NOT NULL,
  `invoice_total_incl_vat` DOUBLE(5,2) NOT NULL,
  `invoice_total_vat` DOUBLE(5,2) NOT NULL,
  `invoice_vat_percentage` DOUBLE(2,2) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_T_INVOICES_T_COMPANIES1_idx` (`company_id` ASC),
  INDEX `fk_T_INVOICES_T_INVOICE_CUSTOMERS1_idx` (`invoice_customer_id` ASC),
  CONSTRAINT `fk_T_INVOICES_T_COMPANIES1`
    FOREIGN KEY (`company_id`)
    REFERENCES `P_towing_be`.`T_COMPANIES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_T_INVOICES_T_INVOICE_CUSTOMERS1`
    FOREIGN KEY (`invoice_customer_id`)
    REFERENCES `P_towing_be`.`T_INVOICE_CUSTOMERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE TABLE IF NOT EXISTS `P_towing_be`.`T_INVOICE_LINES` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `invoice_id` BIGINT(20) NOT NULL,
  `item` VARCHAR(255) NOT NULL,
  `item_amount` DOUBLE(5,2) NOT NULL,
  `item_price_excl_vat` DOUBLE(5,2) NOT NULL,
  `item_price_incl_vat` DOUBLE(5,2) NOT NULL,
  `item_total_excl_vat` DOUBLE(5,2) NOT NULL,
  `item_total_incl_vat` DOUBLE(5,2) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_T_INVOICE_LINES_T_INVOICES1_idx` (`invoice_id` ASC),
  CONSTRAINT `fk_T_INVOICE_LINES_T_INVOICES1`
    FOREIGN KEY (`invoice_id`)
    REFERENCES `P_towing_be`.`T_INVOICES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

CREATE TABLE IF NOT EXISTS `P_towing_be`.`T_INVOICE_CUSTOMERS` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `customer_number` VARCHAR(45) NOT NULL,
  `company_id` BIGINT(20) NOT NULL,
  `company_name` VARCHAR(255) NULL DEFAULT NULL,
  `company_vat` VARCHAR(45) NULL DEFAULT NULL,
  `first_name` VARCHAR(45) NULL DEFAULT NULL,
  `last_name` VARCHAR(45) NULL DEFAULT NULL,
  `street` VARCHAR(255) NULL DEFAULT NULL,
  `street_number` VARCHAR(45) NULL DEFAULT NULL,
  `street_pobox` VARCHAR(45) NULL DEFAULT NULL,
  `zip` VARCHAR(45) NULL DEFAULT NULL,
  `city` VARCHAR(255) NULL DEFAULT NULL,
  `country` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_T_INVOICE_CUSTOMERS_T_COMPANIES1_idx` (`company_id` ASC),
  CONSTRAINT `fk_T_INVOICE_CUSTOMERS_T_COMPANIES1`
    FOREIGN KEY (`company_id`)
    REFERENCES `P_towing_be`.`T_COMPANIES` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;

ALTER TABLE `P_towing_be`.`T_COLLECTORS` 
ADD COLUMN `customer_number` VARCHAR(45) NULL AFTER `id`;

ALTER TABLE `P_towing_be`.`T_INSURANCES` 
ADD COLUMN `customer_number` VARCHAR(45) NULL AFTER `id`;

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
ADD COLUMN `invoice_id` BIGINT NULL DEFAULT NULL AFTER `insurance_id`,
ADD COLUMN `invoice_batch_run_id` VARCHAR(36) NULL DEFAULT NULL AFTER `invoice_id`,
ADD INDEX `fk_vouchers_invoices_idx` (`invoice_id` ASC),
ADD INDEX `fk_vouchers_invoice_batch_runs_idx` (`invoice_batch_run_id` ASC);
ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
ADD CONSTRAINT `fk_vouchers_invoices`
  FOREIGN KEY (`invoice_id`)
  REFERENCES `P_towing_be`.`T_INVOICES` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION,
ADD CONSTRAINT `fk_vouchers_invoice_batch_runs`
  FOREIGN KEY (`invoice_batch_run_id`)
  REFERENCES `P_towing_be`.`T_INVOICE_BATCH_RUNS` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `P_towing_be`.`T_INVOICES` 
ADD COLUMN `invoice_batch_run_id` VARCHAR(36) NOT NULL AFTER `invoice_customer_id`,
ADD INDEX `fk_invoices_invoice_batch_run_idx` (`invoice_batch_run_id` ASC);
ALTER TABLE `P_towing_be`.`T_INVOICES` 
ADD CONSTRAINT `fk_invoices_invoice_batch_run`
  FOREIGN KEY (`invoice_batch_run_id`)
  REFERENCES `P_towing_be`.`T_INVOICE_BATCH_RUNS` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `P_towing_be`.`T_SEQUENCES` 
CHANGE COLUMN `code` `code` ENUM('DOSSIER','TOWING_VOUCHER', 'INVOICE') NOT NULL ;

  

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
