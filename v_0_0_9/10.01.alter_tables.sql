-- MySQL Workbench Synchronization
-- Generated: 2015-05-13 08:09
-- Model: New Model
-- Version: 1.0
-- Project: Name of the project
-- Author: Kris Vandermast

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';


ALTER TABLE `P_towing_be`.`T_INVOICES` 
CHANGE COLUMN `invoice_structured_reference` `invoice_structured_reference` VARCHAR(20) NULL ,
CHANGE COLUMN `invoice_total_excl_vat` `invoice_total_excl_vat` DOUBLE(10,2) NULL ,
CHANGE COLUMN `invoice_total_incl_vat` `invoice_total_incl_vat` DOUBLE(10,2) NULL ,
CHANGE COLUMN `invoice_total_vat` `invoice_total_vat` DOUBLE(10,2) NULL ,
CHANGE COLUMN `cd` `cd` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
CHANGE COLUMN `invoice_vat_percentage` `invoice_vat_percentage` DOUBLE(2,2) NULL ;

ALTER TABLE `P_towing_be`.`T_INVOICE_CUSTOMERS` 
CHANGE COLUMN `customer_number` `customer_number` VARCHAR(45) NULL ;

CREATE TABLE `P_towing_be`.`T_TOWING_VOUCHER_PAYMENT_DETAILS` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
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
  PRIMARY KEY (`id`),
  INDEX `fk_voucher_payments__detail_idx` (`towing_voucher_payment_id` ASC),
  CONSTRAINT `fk_voucher_payments__detail`
    FOREIGN KEY (`towing_voucher_payment_id`)
    REFERENCES `P_towing_be`.`T_TOWING_VOUCHER_PAYMENTS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
    

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHER_PAYMENTS` 
DROP COLUMN `cal_amount_unpaid`,
DROP COLUMN `cal_amount_paid`,
DROP COLUMN `paid_by_credit_card`,
DROP COLUMN `paid_by_debit_card`,
DROP COLUMN `paid_by_bank_deposit`,
DROP COLUMN `paid_in_cash`,
DROP COLUMN `amount_customer`,
DROP COLUMN `amount_guaranteed_by_insurance`;

ALTER TABLE `P_towing_be`.`T_INVOICE_LINES` 
CHANGE COLUMN `item_amount` `item_amount` DOUBLE NOT NULL ,
CHANGE COLUMN `item_price_excl_vat` `item_price_excl_vat` DOUBLE NOT NULL ,
CHANGE COLUMN `item_price_incl_vat` `item_price_incl_vat` DOUBLE NOT NULL ,
CHANGE COLUMN `item_total_excl_vat` `item_total_excl_vat` DOUBLE NOT NULL ,
CHANGE COLUMN `item_total_incl_vat` `item_total_incl_vat` DOUBLE NOT NULL ;

ALTER TABLE `P_towing_be`.`T_INVOICES` 
CHANGE COLUMN `invoice_total_excl_vat` `invoice_total_excl_vat` DOUBLE NULL DEFAULT NULL ,
CHANGE COLUMN `invoice_total_incl_vat` `invoice_total_incl_vat` DOUBLE NULL DEFAULT NULL ,
CHANGE COLUMN `invoice_total_vat` `invoice_total_vat` DOUBLE NULL DEFAULT NULL ,
CHANGE COLUMN `invoice_vat_percentage` `invoice_vat_percentage` DOUBLE NULL DEFAULT NULL ,
CHANGE COLUMN `invoice_amount_paid` `invoice_amount_paid` DOUBLE NULL DEFAULT NULL ;

ALTER TABLE `P_towing_be`.`T_SEQUENCES` 
ADD COLUMN `valid_from` DATE NULL AFTER `seq_val`,
ADD COLUMN `valid_until` DATE NULL AFTER `valid_from`;

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
ADD COLUMN `police_not_present` TINYINT(4) NULL AFTER `police_signature_dt`;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
