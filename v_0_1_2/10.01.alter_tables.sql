SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE TABLE `P_towing_be`.`T_TOWING_VOUCHER_LOCATION_TRACKINGS` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `towing_voucher_id` BIGINT NOT NULL,
  `category` ENUM('signa_arrival', 'towing_arrival', 'towing_start', 'towing_completed') NOT NULL,
  `lat` DOUBLE NULL,
  `long` DOUBLE NULL,
  `tracking_ts` DATETIME NOT NULL,
  `cd` DATETIME NOT NULL,
  `cd_by` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_voucher_location_tracking_voucher_idx` (`towing_voucher_id` ASC),
  CONSTRAINT `fk_voucher_location_tracking_voucher`
    FOREIGN KEY (`towing_voucher_id`)
    REFERENCES `P_towing_be`.`T_TOWING_VOUCHERS` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
    
ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHER_LOCATION_TRACKINGS` 
ADD UNIQUE INDEX `uq_voucher_location_tracking` (`towing_voucher_id` ASC, `category` ASC);

ALTER TABLE `P_towing_be`.`T_TOWING_VOUCHERS` 
ADD COLUMN `police_name` VARCHAR(255) NULL AFTER `police_not_present`;

    



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
