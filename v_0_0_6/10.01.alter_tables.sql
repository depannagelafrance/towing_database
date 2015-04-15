ALTER TABLE `P_ALLOTMENT_DIRECTION_INDICATORS` 
ADD COLUMN `sequence` BIGINT NULL AFTER `city`;

ALTER TABLE `T_TOWING_VOUCHERS` 
ADD COLUMN `causer_not_present` TINYINT NULL AFTER `recipient_signature_dt`;

ALTER TABLE `AUDIT_P_towing_be`.`T_TOWING_VOUCHERS` 
ADD COLUMN `causer_not_present` TINYINT NULL AFTER `recipient_signature_dt`;

