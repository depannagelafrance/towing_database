-- SELECT id, invoice_number, left(invoice_number, 4), right(invoice_number, 5) FROM T_INVOICES;

ALTER TABLE `P_towing_be`.`T_INVOICES` 
CHANGE COLUMN `invoice_number` `invoice_number` INT(9) UNSIGNED ZEROFILL NOT NULL ;

ALTER TABLE `AUDIT_P_towing_be`.`T_INVOICES` 
CHANGE COLUMN `invoice_number` `invoice_number` INT(9) UNSIGNED ZEROFILL NOT NULL ;

UPDATE T_INVOICES
SET invoice_number = CONCAT(left(invoice_number, 4), right(invoice_number, 5));

UPDATE AUDIT_P_towing_be.T_INVOICES
SET invoice_number = CONCAT(left(invoice_number, 4), right(invoice_number, 5));

ALTER TABLE `P_towing_be`.`T_INVOICES` 
ADD COLUMN `exported_to_expertm` TINYINT(1) NULL AFTER `invoice_payment_type`;

ALTER TABLE `AUDIT_P_towing_be`.`T_INVOICES` 
ADD COLUMN `exported_to_expertm` TINYINT(1) NULL AFTER `invoice_payment_type`;
