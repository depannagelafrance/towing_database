-- MySQL Workbench Synchronization
-- Generated: 2015-05-13 08:09
-- Model: New Model
-- Version: 1.0
-- Project: Name of the project
-- Author: Kris Vandermast

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

ALTER TABLE `AUDIT_P_towing_be`.`T_INVOICES` 
CHANGE COLUMN `invoice_structured_reference` `invoice_structured_reference` VARCHAR(20) NULL ,
CHANGE COLUMN `invoice_total_excl_vat` `invoice_total_excl_vat` DOUBLE(10,2) NULL ,
CHANGE COLUMN `invoice_total_incl_vat` `invoice_total_incl_vat` DOUBLE(10,2) NULL ,
CHANGE COLUMN `invoice_total_vat` `invoice_total_vat` DOUBLE(10,2) NULL ,
CHANGE COLUMN `invoice_vat_percentage` `invoice_vat_percentage` DOUBLE(2,2) NULL ;

ALTER TABLE `AUDIT_P_towing_be`.`T_INVOICE_CUSTOMERS` 
CHANGE COLUMN `customer_number` `customer_number` VARCHAR(45) NULL ;

CREATE TABLE `AUDIT_P_towing_be`.`T_TOWING_VOUCHER_PAYMENT_DETAILS` (
  `id` BIGINT NOT NULL,
  `towing_voucher_payment_id` BIGINT NOT NULL,
  `category` ENUM('INSURANCE', 'CUSTOMER', 'COLLECTOR') NOT NULL,
  `foreign_vat` VARCHAR(45) NULL,
  `amount_excl_vat` DOUBLE(10,2) NULL,
  `amount_incl_vat` DOUBLE(10,2) NULL,
  `amount_paid_cash` DOUBLE(10,2) NULL,
  `amount_paid_bankdeposit` DOUBLE(10,2) NULL,
  `amount_paid_maestro` DOUBLE(10,2) NULL,
  `amount_paid_visa` DOUBLE(10,2) NULL,
  `amount_unpaid_excl_vat` DOUBLE(10,2) NULL,
  `amount_unpaid_incl_vat` DOUBLE(10,2) NULL,
  INDEX `fk_voucher_payments__detail_idx` (`towing_voucher_payment_id` ASC));
    


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
