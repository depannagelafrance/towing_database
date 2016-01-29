SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

TRUNCATE T_INVOICE_BATCH_RUNS;
TRUNCATE T_INVOICES;
TRUNCATE T_INVOICE_CUSTOMERS;
TRUNCATE T_INVOICE_LINES;

UPDATE T_TOWING_VOUCHERS SET invoice_batch_run_id = null WHERE invoice_batch_run_id IS NOT NULL LIMIT 9999;
UPDATE T_TOWING_VOUCHERS SET status='READY FOR INVOICE' WHERE status='INVOICED' OR status='INVOICED WITHOUT STORAGE' LIMIT 9999;

DELETE FROM T_SEQUENCES WHERE code='INVOICE' LIMIT 1;
DELETE FROM T_SEQUENCES WHERE code='CN' LIMIT 1;

-- UPDATE T_INSURANCES SET customer_number = null LIMIT 100;
-- UPDATE T_COLLECTORS SET customer_number = null LIMIT 100;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;