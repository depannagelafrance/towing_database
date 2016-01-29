SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

ALTER TABLE `P_towing_be`.`T_INVOICES` 
ADD COLUMN `invoice_doc_ref` VARCHAR(45) NULL AFTER `invoice_structured_reference`;

ALTER TABLE `AUDIT_P_towing_be`.`T_INVOICES` 
ADD COLUMN `invoice_doc_ref` VARCHAR(45) NULL AFTER `invoice_structured_reference`;

UPDATE T_INVOICES i
SET invoice_doc_ref = (SELECT voucher_number FROM T_TOWING_VOUCHERS WHERE id = i.towing_voucher_id)
WHERE i.towing_voucher_id IS NOT NULL;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
