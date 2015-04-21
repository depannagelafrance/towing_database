CREATE TABLE `T_TOWING_ADDITIONAL_COSTS` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `towing_voucher_id` BIGINT NULL,
  `name` VARCHAR(255) NOT NULL,
  `fee_excl_vat` DOUBLE NOT NULL,
  `fee_incl_vat` DOUBLE NOT NULL,
  `cd` DATETIME NOT NULL,
  `cd_by` VARCHAR(255) NOT NULL,
  `ud` DATETIME NULL,
  `ud_by` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_addition_costs_towing_voucher_idx` (`towing_voucher_id` ASC),
  CONSTRAINT `fk_addition_costs_towing_voucher`
    FOREIGN KEY (`towing_voucher_id`)
    REFERENCES `P_towing_be`.`T_TOWING_VOUCHERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
    
ALTER TABLE `T_TOWING_ADDITIONAL_COSTS` 
ADD COLUMN `dd` DATETIME NULL AFTER `ud_by`,
ADD COLUMN `dd_by` VARCHAR(255) NULL AFTER `dd`;
    

CREATE TABLE `AUDIT_P_towing_be`.`T_TOWING_ADDITIONAL_COSTS` (
  `id` BIGINT NOT NULL,
  `towing_voucher_id` BIGINT NULL,
  `name` VARCHAR(255) NOT NULL,
  `fee_excl_vat` DOUBLE NOT NULL,
  `fee_incl_vat` DOUBLE NOT NULL,
  `cd` DATETIME NOT NULL,
  `cd_by` VARCHAR(255) NOT NULL,
  `ud` DATETIME NULL,
  `ud_by` VARCHAR(255) NULL
);

ALTER TABLE `AUDIT_P_towing_be`.`T_TOWING_ADDITIONAL_COSTS` 
ADD COLUMN `dd` DATETIME NULL AFTER `ud_by`,
ADD COLUMN `dd_by` VARCHAR(255) NULL AFTER `dd`;
