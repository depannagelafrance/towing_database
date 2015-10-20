-- MySQL Workbench Synchronization
-- Generated: 2015-05-13 08:09
-- Model: New Model
-- Version: 1.0
-- Project: Name of the project
-- Author: Kris Vandermast

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

DROP TABLE IF EXISTS `P_towing_be`.`T_CUSTOMERS`;

CREATE TABLE `P_towing_be`.`T_CUSTOMERS` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
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
  `dd_by`VARCHAR(255),  
PRIMARY KEY (`id`));

INSERT INTO `P_towing_be`.`T_CUSTOMERS`(original_id, type, customer_number, company_name, vat, first_name, last_name, street, street_number, street_pobox, zip, city, country, invoice_excluded, cd, cd_by, ud, ud_by, dd, dd_by)
SELECT id, 'INSURANCE', customer_number, name, vat, null, null, street, street_number, street_pobox, zip, city, null, invoice_excluded, cd, cd_by, ud, ud_by, dd, dd_by
FROM T_INSURANCES;

INSERT INTO `P_towing_be`.`T_CUSTOMERS`(original_id, type, customer_number, company_name, vat, first_name, last_name, street, street_number, street_pobox, zip, city, country, invoice_excluded, cd, cd_by, ud, ud_by, dd, dd_by)
SELECT id, IF(type='OTHER', 'COLLECTOR', type), customer_number, name, vat, null, null, street, street_number, street_pobox, zip, city, country, null, cd, cd_by, ud, ud_by, dd, dd_by
FROM T_COLLECTORS;

DROP TRIGGER IF EXISTS TRG_AU_TOWING_VOUCHER;
DROP TRIGGER IF EXISTS TRG_BU_TOWING_VOUCHER;
DROP TRIGGER IF EXISTS TRG_AI_TOWING_VOUCHER;

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
DROP FOREIGN KEY `fk_T_TOWING_VOUCHERS_T_INSURANCES1`;

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
ADD COLUMN `insurance_id2` BIGINT(20) NULL AFTER `insurance_id`;

UPDATE T_TOWING_VOUCHERS tv, T_CUSTOMERS c
SET insurance_id2 = c.id
WHERE insurance_id = c.original_id;

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
ADD COLUMN `collector_id2` BIGINT(20) NULL AFTER `collector_id`;

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
DROP FOREIGN KEY `fk_vouchers_collectors`;

UPDATE T_TOWING_VOUCHERS tv, T_CUSTOMERS c
SET collector_id2 = c.id
WHERE collector_id = c.original_id;

UPDATE T_TOWING_VOUCHERS
SET collector_id=collector_id2, insurance_id=insurance_id2;

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
DROP COLUMN `insurance_id2`,
DROP COLUMN `collector_id2`;

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
ADD CONSTRAINT `fk_vouchers_insurance`
  FOREIGN KEY (`insurance_id`)
  REFERENCES `P_towing_be`.`T_CUSTOMERS` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION,
ADD CONSTRAINT `fk_vouchers_collector`
  FOREIGN KEY (`collector_id`)
  REFERENCES `P_towing_be`.`T_CUSTOMERS` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `P_towing_be`.`T_CUSTOMERS` 
ADD COLUMN `company_id` BIGINT(20) NULL AFTER `original_id`;

UPDATE T_CUSTOMERS SET company_id=1;
  
ALTER TABLE `P_towing_be`.`T_CUSTOMERS` 
ADD INDEX `fk_customer_company_idx` (`company_id` ASC);
ALTER TABLE `P_towing_be`.`T_CUSTOMERS` 
ADD CONSTRAINT `fk_customer_company`
  FOREIGN KEY (`company_id`)
  REFERENCES `P_towing_be`.`T_COMPANIES` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `P_towing_be`.`T_CUSTOMERS` 
CHANGE COLUMN `vat` `company_vat` VARCHAR(45) NULL DEFAULT NULL ;

ALTER TABLE `P_towing_be`.`T_CUSTOMERS` 
ADD COLUMN `is_insurance` TINYINT(1) NULL DEFAULT 0 AFTER `invoice_excluded`,
ADD COLUMN `is_collector` TINYINT(1) NULL DEFAULT 0 AFTER `is_insurance`;

UPDATE `P_towing_be`.`T_CUSTOMERS` 
SET is_insurance = (type = 'INSURANCE'),
	is_collector = (type = 'COLLECTOR' OR type='CUSTOMER');

  


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
