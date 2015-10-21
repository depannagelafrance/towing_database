-- MySQL Workbench Synchronization
-- Generated: 2015-05-13 08:09
-- Model: New Model
-- Version: 1.0
-- Project: Name of the project
-- Author: Kris Vandermast

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

DROP TABLE IF EXISTS `AUDIT_P_towing_be`.`T_CUSTOMERS`;

CREATE TABLE `AUDIT_P_towing_be`.`T_CUSTOMERS` (
  `id` BIGINT(20) NOT NULL,
  `original_id` BIGINT(20),
  `type`ENUM('CUSTOMER', 'COLLECTOR', 'INSURANCE', 'OTHER'),
  `customer_number` VARCHAR(45),
  `company_name` VARCHAR(255),
  `vat` VARCHAR(45),
  `first_name` VARCHAR(255),
  `last_name` VARCHAR(255),
  `street` VARCHAR(255),
  `street_number` VARCHAR(45),
  `street_pobox` VARCHAR(45),
  `zip` VARCHAR(45),
  `city` VARCHAR(255),
  `country` VARCHAR(255),
  `invoice_excluded` TINYINT(1),
  `cd` DATETIME,
  `cd_by`VARCHAR(255),
  `ud` DATETIME,
  `ud_by` VARCHAR(255),
  `dd` DATETIME,
  `dd_by`VARCHAR(255));

INSERT INTO `AUDIT_P_towing_be`.`T_CUSTOMERS`(id, original_id, type, customer_number, company_name, vat, first_name, last_name, street, street_number, street_pobox, zip, city, country, invoice_excluded, cd, cd_by, ud, ud_by, dd, dd_by)
SELECT id, id, 'INSURANCE', customer_number, name, vat, null, null, street, street_number, street_pobox, zip, city, null, invoice_excluded, cd, cd_by, ud, ud_by, dd, dd_by
FROM AUDIT_P_towing_be.T_INSURANCES;

INSERT INTO `AUDIT_P_towing_be`.`T_CUSTOMERS`(id, original_id, type, customer_number, company_name, vat, first_name, last_name, street, street_number, street_pobox, zip, city, country, invoice_excluded, cd, cd_by, ud, ud_by, dd, dd_by)
SELECT id, id, IF(type='OTHER', 'COLLECTOR', type), customer_number, name, vat, null, null, street, street_number, street_pobox, zip, city, country, null, cd, cd_by, ud, ud_by, dd, dd_by
FROM AUDIT_P_towing_be.T_COLLECTORS;


ALTER TABLE `AUDIT_P_towing_be`.`T_CUSTOMERS` 
ADD COLUMN `company_id` BIGINT(20) NULL AFTER `original_id`;

UPDATE AUDIT_P_towing_be.T_CUSTOMERS SET company_id=1;

ALTER TABLE `AUDIT_P_towing_be`.`T_CUSTOMERS` 
CHANGE COLUMN `vat` `company_vat` VARCHAR(45) NULL DEFAULT NULL ;

ALTER TABLE `AUDIT_P_towing_be`.`T_CUSTOMERS` 
ADD COLUMN `is_insurance` TINYINT(1) NULL DEFAULT 0 AFTER `invoice_excluded`,
ADD COLUMN `is_collector` TINYINT(1) NULL DEFAULT 0 AFTER `is_insurance`;

UPDATE `AUDIT_P_towing_be`.`T_CUSTOMERS` 
SET is_insurance = (type = 'INSURANCE'),
	is_collector = (type = 'COLLECTOR' OR type='CUSTOMER');
    
ALTER TABLE `AUDIT_P_towing_be`.`T_INVOICES` 
CHANGE COLUMN `cd_by` `cd_by` VARCHAR(255) NULL ;
    
ALTER TABLE `AUDIT_P_towing_be`.`T_INVOICE_CUSTOMERS` 
CHANGE COLUMN `cd` `cd` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
CHANGE COLUMN `cd_by` `cd_by` VARCHAR(255) NULL ;

ALTER TABLE `AUDIT_P_towing_be`.`T_INVOICE_LINES` 
CHANGE COLUMN `cd` `cd` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ,
CHANGE COLUMN `cd_by` `cd_by` VARCHAR(255) NULL ;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
