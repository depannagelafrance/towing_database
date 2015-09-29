SET GLOBAL event_scheduler = ON;
SET @@global.event_scheduler = ON;
SET GLOBAL event_scheduler = 1;
SET @@global.event_scheduler = 1;

DELIMITER $$

DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_BATCH $$
DROP PROCEDURE IF EXISTS R_CREATE_INVOICE_BATCH_FOR_VOUCHER $$
DROP PROCEDURE IF EXISTS R_START_INVOICE_BATCH_FOR_VOUCHER $$
DROP PROCEDURE IF EXISTS R_START_INVOICE_STORAGE_BATCH_FOR_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_INVOICE_BATCH_INFO $$

DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_FOR_VOUCHER $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_PARTIAL_INSURANCE $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_PARTIAL_COLLECTOR $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_PARTIAL_CUSTOMER $$

DROP PROCEDURE IF EXISTS R_INVOICE_UPDATE_INVOICE $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_INVOICE $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_EMPTY_INVOICE $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREDIT_INVOICE $$

DROP PROCEDURE IF EXISTS R_INVOICE_UPDATE_INVOICE_LINE $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_INVOICE_LINE $$
DROP PROCEDURE IF EXISTS R_INVOICE_DELETE_INVOICE_LINE $$ 

DROP PROCEDURE IF EXISTS R_INVOICE_UPDATE_INVOICE_CUSTOMER $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_INVOICE_CUSTOMER $$

DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_BATCH_INVOICES $$
DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_BATCH_INVOICE_CUSTOMER $$
DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_BATCH_INVOICE_LINES $$
DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_ALL_BATCH_RUNS $$
DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_COMPANY_INVOICES $$
DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_COMPANY_INVOICE $$
DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_COMPANY_INVOICE_LINES $$ 
DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_COMPANY_INVOICE_CUSTOMER $$

DROP PROCEDURE IF EXISTS R_INVOICE_ATT_LINK_WITH_DOCUMENT $$
DROP PROCEDURE IF EXISTS R_INVOICE_CUSTOMER_FIND_OR_CREATE $$

DROP PROCEDURE IF EXISTS R_RECALCULATE_INVOICE_TOTAL $$

DROP FUNCTION IF EXISTS F_CREATE_INVOICE_UQ_SEQUENCE $$
DROP FUNCTION IF EXISTS F_CREATE_INVOICE_NUMBER $$
DROP FUNCTION IF EXISTS F_CREATE_CREDIT_NUMBER $$
DROP FUNCTION IF EXISTS F_CREATE_STRUCTURED_REFERENCE $$
DROP FUNCTION IF EXISTS F_CREATE_CUSTOMER_NUMBER_FOR_PRIVATE_PERSON $$
DROP FUNCTION IF EXISTS F_CUSTOMER_NUMBER_FOR_COLLECTOR $$
DROP FUNCTION IF EXISTS F_CUSTOMER_NUMBER_FOR_INSURANCE $$
DROP FUNCTION IF EXISTS F_CUSTOMER_NUMBER_FOR_COMPANY $$

DROP TRIGGER IF EXISTS TRG_BI_INVOICE_LINE $$
DROP TRIGGER IF EXISTS TRG_BU_INVOICE_LINE $$

DROP TRIGGER IF EXISTS TRG_AI_INVOICE $$
DROP TRIGGER IF EXISTS TRG_AI_INVOICE_CUSTOMER $$
DROP TRIGGER IF EXISTS TRG_AI_INVOICE_LINE $$

DROP TRIGGER IF EXISTS TRG_AU_INVOICE $$
DROP TRIGGER IF EXISTS TRG_AU_INVOICE_LINE $$

DROP TRIGGER IF EXISTS TRG_AU_INVOICE_CUSTOMER $$
DROP TRIGGER IF EXISTS TRG_BU_INVOICE_CUSTOMER $$

# ####################################################################################
# TRIGGERS
# ####################################################################################
CREATE TRIGGER `TRG_BI_INVOICE_LINE` BEFORE INSERT ON `T_INVOICE_LINES`
FOR EACH ROW
BEGIN
	SET NEW.item_total_excl_vat = NEW.item_amount * NEW.item_price_excl_vat;
    SET NEW.item_total_incl_vat = NEW.item_amount * NEW.item_price_incl_vat;
END $$

CREATE TRIGGER `TRG_AI_INVOICE_LINE` AFTER INSERT ON `T_INVOICE_LINES`
FOR EACH ROW
BEGIN
    CALL R_ADD_INVOICE_LINE_AUDIT_LOG(NEW.id);
    
    CALL R_RECALCULATE_INVOICE_TOTAL(NEW.invoice_id);
END $$

CREATE TRIGGER `TRG_BU_INVOICE_LINE` BEFORE UPDATE ON `T_INVOICE_LINES`
FOR EACH ROW
BEGIN
	SET NEW.item_total_excl_vat = NEW.item_amount * NEW.item_price_excl_vat;
    SET NEW.item_total_incl_vat = NEW.item_amount * NEW.item_price_incl_vat;
END $$

CREATE TRIGGER `TRG_AU_INVOICE_LINE` AFTER UPDATE ON `T_INVOICE_LINES`
FOR EACH ROW
BEGIN
	CALL R_ADD_INVOICE_LINE_AUDIT_LOG(NEW.id);
    
    CALL R_RECALCULATE_INVOICE_TOTAL(NEW.invoice_id);
END $$

CREATE TRIGGER `TRG_AU_INVOICE` AFTER UPDATE ON `T_INVOICES`
FOR EACH ROW
BEGIN
	CALL R_ADD_INVOICE_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AU_INVOICE_CUSTOMER` AFTER UPDATE ON `T_INVOICE_CUSTOMERS`
FOR EACH ROW
BEGIN
	CALL R_ADD_INVOICE_CUSTOMER_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_BU_INVOICE_CUSTOMER` BEFORE UPDATE ON `T_INVOICE_CUSTOMERS`
FOR EACH ROW
BEGIN
	IF NEW.customer_number IS NULL THEN
		IF TRIM(IFNULL(NEW.company_name, "")) != "" THEN
			SET NEW.customer_number = F_CUSTOMER_NUMBER_FOR_COMPANY(null, NEW.company_id);        
        ELSE 
			IF TRIM(IFNULL(NEW.last_name, "")) != "" THEN
				SET NEW.customer_number = F_CREATE_CUSTOMER_NUMBER_FOR_PRIVATE_PERSON(NEW.last_name);    
			END IF;
        END IF;
    END IF;
END $$

CREATE TRIGGER `TRG_AI_INVOICE` AFTER INSERT ON `T_INVOICES`
FOR EACH ROW
BEGIN
    CALL R_ADD_INVOICE_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AI_INVOICE_CUSTOMER` AFTER INSERT ON `T_INVOICE_CUSTOMERS`
FOR EACH ROW
BEGIN
    CALL R_ADD_INVOICE_CUSTOMER_AUDIT_LOG(NEW.id);
END $$




# ####################################################################################
# PROCEDURES
# ####################################################################################
CREATE PROCEDURE R_RECALCULATE_INVOICE_TOTAL(IN p_invoice_id BIGINT)
BEGIN
	DECLARE v_invoice_total_excl_vat, v_invoice_total_incl_vat DOUBLE;
    
    SELECT 	SUM(il.item_total_excl_vat), SUM(il.item_total_incl_vat)
    INTO	v_invoice_total_excl_vat, v_invoice_total_incl_vat
    FROM 	T_INVOICE_LINES il
    WHERE 	il.invoice_id = p_invoice_id
			AND dd IS NULL;
    
	UPDATE 	T_INVOICES i
	SET 	i.invoice_total_excl_vat 	= v_invoice_total_excl_vat, 
			i.invoice_total_incl_vat 	= v_invoice_total_incl_vat,
			i.invoice_total_vat			= v_invoice_total_incl_vat - v_invoice_total_excl_vat
	WHERE 	i.id = p_invoice_id;   
END $$

CREATE PROCEDURE R_INVOICE_UPDATE_INVOICE(IN p_id BIGINT, 
										  IN p_ref VARCHAR(20),
                                          IN p_insurance_dossiernr VARCHAR(45),
										  -- IN p_invoice_total_excl_vat DOUBLE, IN p_invoice_total_incl_vat DOUBLE,
                                          -- IN p_vat_total DOUBLE, IN p_vat DOUBLE,
                                          IN p_paid DOUBLE, IN p_ptype ENUM('OTHER','CASH','BANKDEPOSIT','MAESTRO','VISA','CREDITCARD'),
                                          IN p_message TEXT,
										  IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE 	`T_INVOICES`
		SET
				`invoice_structured_reference` = p_ref,
				-- `vat_foreign_country` = <{vat_foreign_country: }>,
				-- `invoice_total_excl_vat` 	= p_invoice_total_excl_vat,
				-- `invoice_total_incl_vat` 	= p_invoice_total_incl_vat,
				-- `invoice_total_vat` 		= p_vat_total,
				-- `invoice_vat_percentage` 	= p_vat,
				`invoice_amount_paid` 		= p_paid,
                `invoice_payment_type` 		= p_ptype,
				`invoice_message` 			= p_message,
				`insurance_dossiernr` 		= p_insurance_dossiernr,
				`ud`						= now(),
                `ud_by`						= F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE 	`id` = p_id
				AND `company_id` = v_company_id
		LIMIT 1;
        
        CALL R_INVOICE_FETCH_COMPANY_INVOICE(p_id, p_token);

    END IF;
END $$

CREATE PROCEDURE R_INVOICE_CREATE_EMPTY_INVOICE(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_invoice_id, v_cust_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SET v_batch_id = UUID(); 
        
		-- CREATE A NEW BATCH
		INSERT INTO T_INVOICE_BATCH_RUNS(id, company_id, batch_started, cd, cd_by)
        VALUES(v_batch_id, v_company_id, now(), now(), F_RESOLVE_LOGIN(v_user_id, p_token));
        
    
		-- CREATE A NEW CUSTOMER
		INSERT INTO T_INVOICE_CUSTOMERS(company_id, cd, cd_by)
        VALUES(v_company_id, now(), F_RESOLVE_LOGIN(v_user_id, p_token));
        
        SET v_cust_id = LAST_INSERT_ID();
        
        -- CREATE A NEW INVOICE
		INSERT INTO `T_INVOICES`(
			`company_id`,
			`invoice_customer_id`,
			`invoice_batch_run_id`,
			`invoice_type`,
			`invoice_date`,
			`invoice_number`,
			`cd`,
			`cd_by`
        ) VALUES (
			v_company_id,
			v_cust_id, -- `invoice_customer_id`,
			v_batch_id, -- `invoice_batch_run_id`,
			'CUSTOMER', -- `invoice_type`,
			curdate(), -- `invoice_date`,
			F_CREATE_INVOICE_UQ_SEQUENCE(v_company_id, 'CUSTOMER'), -- `invoice_number`,
			now(), -- `cd`,
			F_RESOLVE_LOGIN(v_user_id, p_token) -- `cd_by`            
		);
    
		SET v_invoice_id = LAST_INSERT_ID();
    
		-- RETURN THE INVOICE
		CALL R_INVOICE_FETCH_COMPANY_INVOICE(v_invoice_id, p_token);
    END IF;
END $$


CREATE PROCEDURE R_INVOICE_CREATE_INVOICE(IN p_invoice_customer_id BIGINT,
										  IN p_ref VARCHAR(20),
                                          IN p_insurance_dossiernr VARCHAR(45),
										  IN p_invoice_total_excl_vat DOUBLE, IN p_invoice_total_incl_vat DOUBLE,
                                          IN p_vat_total DOUBLE, IN p_vat DOUBLE,
                                          IN p_paid DOUBLE, IN p_ptype ENUM('OTHER','CASH','BANKDEPOSIT','MAESTRO','VISA','CREDITCARD'),
                                          IN p_message TEXT,                                          
										  IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_invoice_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO `T_INVOICES`(
			`company_id`,
			`invoice_customer_id`,
			-- `invoice_batch_run_id`,
			-- `towing_voucher_id`,-- 
			`invoice_type`,
			`invoice_date`,
			`invoice_number`,
			`invoice_structured_reference`,
			-- `vat_foreign_country`,
			`invoice_total_excl_vat`,
			`invoice_total_incl_vat`,
			`invoice_total_vat`,
			`invoice_vat_percentage`,
			`invoice_amount_paid`,
            `invoice_payment_type`,
			`invoice_message`,
			`insurance_dossiernr`,
            `cd`,
            `cd_by`
        ) VALUES (
			v_company_id,
			p_invoice_customer_id,
			-- <{invoice_batch_run_id: }	>,
			-- <{towing_voucher_id: }>,
			'CUSTOMER',
			CURDATE(),
			F_CREATE_INVOICE_NUMBER(v_company_id),
			p_ref,
			-- <{vat_foreign_country: }>,
			p_invoice_total_excl_vat, p_invoice_total_incl_vat,
			p_vat_total, p_vat,
			p_paid, p_ptype,
            p_message,
            p_insurance_dossiernr,
            now(),
			F_RESOLVE_LOGIN(v_user_id, p_token));
    
		SET v_invoice_id = LAST_INSERT_ID();
        
        CALL R_INVOICE_FETCH_COMPANY_INVOICE(v_invoice_id, p_token);
    END IF;
END $$

CREATE PROCEDURE R_INVOICE_CREDIT_INVOICE(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_invoice_id, v_cn_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT	id INTO v_invoice_id
        FROM 	T_INVOICES
        WHERE	id = p_id AND company_id = v_company_id;
        
        IF v_invoice_id IS NOT NULL THEN
			-- CREATE A CREDITED INVOICE
			INSERT INTO T_INVOICES(company_id, invoice_customer_id, invoice_batch_run_id, towing_voucher_id, invoice_ref_id,
								   document_id, invoice_type, invoice_date, invoice_number, 
                                   vat_foreign_country, invoice_total_excl_vat, invoice_total_incl_vat, invoice_total_vat, invoice_vat_percentage, 
                                   -- invoice_amount_paid, invoice_payment_type,
                                   invoice_message, 
                                   insurance_dossiernr, 
                                   cd, cd_by)
            SELECT 	company_id, invoice_customer_id, invoice_batch_run_id, towing_voucher_id, v_invoice_id,
					null, 'CN', CURDATE(), F_CREATE_CREDIT_NUMBER(v_company_id), 
                    vat_foreign_country, invoice_total_excl_vat, invoice_total_incl_vat, invoice_total_vat, invoice_vat_percentage, 
                    -- invoice_amount_paid, invoice_payment_type, 
                    invoice_message, 
                    insurance_dossiernr, 
                    now(), F_RESOLVE_LOGIN(v_user_id, p_token)
            FROM 	T_INVOICES
            WHERE 	id = v_invoice_id
            LIMIT 	0,1;
            
            SET v_cn_id = LAST_INSERT_ID();
            
            -- SET REFERENCE TO THE CN	
            UPDATE 	T_INVOICES 
            SET 	invoice_ref_id = v_cn_id 
            WHERE 	id = v_invoice_id 
					AND company_id = v_company_id
            LIMIT 	1;
            
            -- CREATE THE INVOICED LINES
            INSERT INTO T_INVOICE_LINES(`invoice_id`, `item`, `item_amount`, `item_price_excl_vat`, `item_price_incl_vat`, `item_total_excl_vat`, `item_total_incl_vat`, `cd`, `cd_by`)
            SELECT 	v_cn_id, `item`, -`item_amount`, `item_price_excl_vat`, `item_price_incl_vat`, `item_total_excl_vat`, `item_total_incl_vat`, now(), F_RESOLVE_LOGIN(v_user_id, p_token)
            FROM 	T_INVOICE_LINES
            WHERE 	invoice_id = v_invoice_id
					AND dd IS NULL;
            
            -- RETURN THE NEWLY CREATED CN
            CALL R_INVOICE_FETCH_COMPANY_INVOICE(v_cn_id, p_token);
		END IF;
            
    END IF;
END $$

CREATE PROCEDURE R_INVOICE_UPDATE_INVOICE_LINE(IN p_id BIGINT, IN p_invoice_id BIGINT, 
											   IN p_item VARCHAR(255),
                                               IN p_amount DOUBLE, IN p_price_excl_vat DOUBLE, IN p_price_incl_vat DOUBLE,
                                               IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE `T_INVOICE_LINES`
		SET
			`item` 					= p_item,
			`item_amount` 			= p_amount,
			`item_price_excl_vat` 	= p_price_excl_vat,
			`item_price_incl_vat` 	= p_price_incl_vat,
			`item_total_excl_vat` 	= p_amount * p_price_excl_vat,
			`item_total_incl_vat` 	= p_amount * p_price_incl_vat,
			`ud` = now(),
			`ud_by` = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE 
			`id` = p_id 
            AND `invoice_id` = p_invoice_id
        LIMIT 1;
    END IF;
END $$

CREATE PROCEDURE R_INVOICE_CREATE_INVOICE_LINE(IN p_invoice_id BIGINT, 
											   IN p_item VARCHAR(255),
                                               IN p_amount DOUBLE, IN p_price_excl_vat DOUBLE, IN p_price_incl_vat DOUBLE,
                                               IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_invoice_line_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO `P_towing_be`.`T_INVOICE_LINES`(
			`invoice_id`,
			`item`,
			`item_amount`,
			`item_price_excl_vat`,
			`item_price_incl_vat`,
			`item_total_excl_vat`,
			`item_total_incl_vat`,
			`cd`,
			`cd_by`
		) VALUES (
			p_invoice_id,
			p_item,
			p_amount,
			p_price_excl_vat,
			p_price_incl_vat,
			p_amount * p_price_excl_vat,
			p_amount * p_price_incl_vat,
			now(),
            F_RESOLVE_LOGIN(v_user_id, p_token)
		);
        
        SET v_invoice_line_id = LAST_INSERT_ID();
        
        SELECT * FROM T_INVOICE_LINES WHERE id = v_invoice_line_id;
    END IF;
END $$

CREATE PROCEDURE R_INVOICE_DELETE_INVOICE_LINE(IN p_invoice_id BIGINT, IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_invoice_line_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	il.id INTO v_invoice_line_id
        FROM 	T_INVOICES i, T_INVOICE_LINES il
        WHERE 	i.id = p_invoice_id 
				AND i.company_id = v_company_id
				AND i.id = il.invoice_id
				AND il.id = p_id
		LIMIT 	0,1;
                
        IF v_invoice_line_id IS NOT NULL THEN
			UPDATE 	T_INVOICE_LINES
            SET 	dd = now(), dd_by = F_RESOLVE_LOGIN(v_user_id, p_token)
            WHERE 	id = p_id AND invoice_id = p_invoice_id
            LIMIT 	1;
		END IF;
                
		SELECT 'OK' AS result;
    END IF;
END $$

CREATE PROCEDURE R_INVOICE_UPDATE_INVOICE_CUSTOMER(IN p_id 				BIGINT,
												   IN p_cust_number 	VARCHAR(45),
												   IN p_company_name 	VARCHAR(255),
												   IN p_company_vat 	VARCHAR(45),
												   IN p_first_name		VARCHAR(45),
                                                   IN p_last_name		VARCHAR(45),
                                                   IN p_street			VARCHAR(255),
                                                   IN p_street_nr		VARCHAR(45),
                                                   IN p_street_pobox	VARCHAR(45),
                                                   IN p_zip				VARCHAR(45),
                                                   IN p_city			VARCHAR(45),
                                                   IN p_country			VARCHAR(255),
                                                   IN p_token			VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE `T_INVOICE_CUSTOMERS`
		SET
			`customer_number` = p_cust_number,
			`company_name` = p_company_name,
			`company_vat` = p_company_vat,
			`first_name` = p_first_name,
			`last_name` = p_last_name,
			`street` = p_street,
			`street_number` = p_street_nr,
			`street_pobox` = p_street_pobox,
			`zip` = p_zip,
			`city` = p_city,
			`country` = p_country,
            `ud` = now(),
			`ud_by` = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE 	`id` = p_id
				AND `company_id`= v_company_id
		LIMIT 1;
        
        
        SELECT * FROM T_INVOICE_CUSTOMERS WHERE id = p_id LIMIT 0,1;
    
    END IF;
END $$

CREATE PROCEDURE R_INVOICE_CREATE_INVOICE_CUSTOMER(IN p_cust_number 	VARCHAR(45),
												   IN p_company_name 	VARCHAR(255),
												   IN p_company_vat 	VARCHAR(45),
												   IN p_first_name		VARCHAR(45),
                                                   IN p_last_name		VARCHAR(45),
                                                   IN p_street			VARCHAR(255),
                                                   IN p_street_nr		VARCHAR(45),
                                                   IN p_street_pobox	VARCHAR(45),
                                                   IN p_zip				VARCHAR(45),
                                                   IN p_city			VARCHAR(45),
                                                   IN p_country			VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO `T_INVOICE_CUSTOMERS`(
			`customer_number`,
			`company_id`,
			`company_name`,
			`company_vat`,
			`first_name`,
			`last_name`,
			`street`,
			`street_number`,
			`street_pobox`,
			`zip`,
			`city`,
			`country`
		) VALUES (
			p_cust_number,
			v_company_id,
			p_company_name,
			p_company_vat,
			p_first_name,
			p_last_name,
			p_street,
			p_street_nr,
			p_street_pobox,
			p_zip,
			p_city,
			p_country);

		SELECT * FROM T_INVOICE_CUSTOMERS WHERE id = LAST_INSERT_ID();
    END IF;
END $$


CREATE PROCEDURE R_INVOICE_CREATE_BATCH(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);
    DECLARE v_login VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SET v_batch_id = UUID();

        SET v_login = F_RESOLVE_LOGIN(v_user_id, p_token);

        -- CREATE A NEW BATCH REQUEST
        INSERT INTO T_INVOICE_BATCH_RUNS(id, company_id, batch_started, cd, cd_by)
        VALUES(v_batch_id, v_company_id, now(), now(), v_login);

		UPDATE T_TOWING_VOUCHERS tv
        SET invoice_batch_run_id = v_batch_id, ud = now(), ud_by = v_login
        WHERE tv.status='READY FOR INVOICE'
        LIMIT 250;

        SELECT v_batch_id AS invoice_batch_id;
	END IF;
END $$

CREATE PROCEDURE R_CREATE_INVOICE_BATCH_FOR_VOUCHER(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);
    DECLARE v_login VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SET v_batch_id = UUID();

        SET v_login = F_RESOLVE_LOGIN(v_user_id, p_token);

        -- CREATE A NEW BATCH REQUEST
        INSERT INTO T_INVOICE_BATCH_RUNS(id, company_id, batch_started, cd, cd_by)
        VALUES(v_batch_id, v_company_id, now(), now(), v_login);

		UPDATE 	T_TOWING_VOUCHERS tv
        SET 	invoice_batch_run_id = v_batch_id, ud = now(), ud_by = v_login
        WHERE 	tv.status='READY FOR INVOICE'
				AND tv.id = p_voucher_id
        LIMIT 	1;

        SELECT v_batch_id AS invoice_batch_id;
	END IF;
END $$


CREATE PROCEDURE R_START_INVOICE_BATCH_FOR_VOUCHER(	IN p_voucher_id BIGINT, IN p_batch_id VARCHAR(36), 
-- 													IN p_customer_amount DOUBLE(9,2), IN p_customer_ptype VARCHAR(25),
-- 													IN p_collector_amount DOUBLE(9,2), IN p_collector_ptype VARCHAR(25),
--                                                     IN p_assurance_amount DOUBLE(9,2), IN p_assurance_ptype VARCHAR(25),
 													IN p_message TEXT, 
                                                    IN p_token VARCHAR(255))
BEGIN
	CALL R_INVOICE_CREATE_FOR_VOUCHER(p_voucher_id, p_batch_id, 
-- 									  p_customer_amount, p_customer_ptype,
-- 									  p_collector_amount, p_collector_ptype,
--                                       p_assurance_amount, p_assurance_ptype,
									  p_message);
    
    IF (SELECT count(*) FROM T_TOWING_VOUCHER_VALIDATION_MESSAGES WHERE towing_voucher_id = p_voucher_id) > 0 THEN
		SELECT "VALIDATION_ERRORS" as result;
    ELSE
		SELECT  UNIX_TIMESTAMP(call_date) AS call_date, call_number, 
				vehicule, vehicule_type, vehicule_licenceplate,
				UNIX_TIMESTAMP(DATE_ADD(current_date,INTERVAL 30 DAY)) as invoice_due_date,
                (SELECT default_depot = 1 FROM T_TOWING_DEPOTS WHERE voucher_id = tv.id LIMIT 0,1) as default_depot,
				vehicule_collected
		FROM	T_DOSSIERS d, T_TOWING_VOUCHERS tv
		WHERE	tv.id = p_voucher_id
				AND tv.dossier_id = d.id
		LIMIT 	0,1;
    END IF;
END $$

CREATE PROCEDURE R_FETCH_INVOICE_BATCH_INFO(IN p_invoice_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);
    DECLARE v_login VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT  i.invoice_batch_run_id,
				UNIX_TIMESTAMP(call_date) AS call_date, call_number, 
                tv.dossier_id, i.towing_voucher_id,
				vehicule, vehicule_type, vehicule_licenceplate,
				-- UNIX_TIMESTAMP(DATE_ADD(current_date,INTERVAL 30 DAY)) as invoice_due_date,
                (SELECT default_depot = 1 FROM T_TOWING_DEPOTS WHERE voucher_id = tv.id LIMIT 0,1) as default_depot,
				vehicule_collected,
                i.invoice_type,
				IF(i.invoice_type = 'CN', 
						(SELECT concat(LEFT(i2.invoice_number, 4), '/', SUBSTRING(i2.invoice_number,5)) FROM T_INVOICES i2 WHERE i2.id = i.invoice_ref_id) , 
						null) as invoice_ref_invoice_number,
				-- jaartal+maand+dag_FVH+factuurnummer_verkorte naam aannemer_PA of TA nummer_Perceel_nr autosnelweg
				-- e.g. 20150622_FVH562879_Hamse_TA00000953_P5_E313
				CONCAT(	YEAR(i.invoice_date), LPAD(MONTH(i.invoice_date), 2, '0'), LPAD(DAY(i.invoice_date), 2, '0'), '_',
						IF(i.invoice_type = 'CN', 'CN', 'FVH'), 
						i.invoice_number, '_', 
						(SELECT code FROM T_COMPANIES WHERE id = d.company_id LIMIT 0,1), '_',
						d.call_number, '_',
						(SELECT code FROM P_ALLOTMENT WHERE id = d.allotment_id LIMIT 0,1), '_',
						(SELECT REPLACE(REPLACE(name, '>', '_'), ' ', '') FROM P_ALLOTMENT_DIRECTIONS WHERE id = d.allotment_direction_id LIMIT 0,1), '.pdf') AS filename                
		FROM	T_DOSSIERS d, T_TOWING_VOUCHERS tv, T_INVOICES i
		WHERE	1 = 1
				AND tv.dossier_id = d.id
                AND i.towing_voucher_id = tv.id
                AND i.id = p_invoice_id
		LIMIT 	0,1;
	END IF;
END $$

CREATE PROCEDURE R_START_INVOICE_STORAGE_BATCH_FOR_VOUCHER(IN p_voucher_id BIGINT, IN p_batch_id VARCHAR(36), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_collector_id BIGINT;
    DECLARE v_vehicle_collected DATETIME;
    
    SELECT 	collector_id, vehicule_collected 
    INTO 	v_collector_id, v_vehicle_collected
    FROM	T_TOWING_VOUCHERS
    WHERE 	id = p_voucher_id
    LIMIT	0,1;
    
    IF v_collector_id IS NULL THEN
		CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(p_voucher_id, 'INVOICE_MISSING_COLLECTOR', 'Er werd geen afhaler toegkend voor het voertuig.');
    END IF;
    
    IF v_vehicle_collected IS NULL THEN
		CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(p_voucher_id, 'INVOICE_MISSING_COLLECTION_DATE', 'Er werd geen datum van afhaling toegkend voor het voertuig.');
    END IF;
    
    IF v_collector_id IS NOT NULL AND v_vehicle_collected IS NOT NULL THEN
		CALL R_INVOICE_CREATE_PARTIAL_COLLECTOR(p_voucher_id, v_collector_id, p_batch_id, null);
		
		SELECT  UNIX_TIMESTAMP(call_date) AS call_date, call_number, 
				vehicule, vehicule_type, vehicule_licenceplate,
				UNIX_TIMESTAMP(DATE_ADD(current_date,INTERVAL 30 DAY)) as invoice_due_date,
				(SELECT default_depot = 1 FROM T_TOWING_DEPOTS WHERE voucher_id = tv.id LIMIT 0,1) as default_depot,
				vehicule_collected
		FROM	T_DOSSIERS d, T_TOWING_VOUCHERS tv
		WHERE	tv.id = p_voucher_id
				AND tv.dossier_id = d.id
		LIMIT 	0,1;    
        
        UPDATE T_TOWING_VOUCHERS SET status='INVOICED' WHERE id = p_voucher_id LIMIT 1;
	ELSE
		SELECT "VALIDATION_ERRORS" as result;
	END IF;
END $$

-- ------------------------------------------------------------------------------------------
-- CREATE THE INVOICE FOR A VOUCHER
-- ------------------------------------------------------------------------------------------
CREATE PROCEDURE R_INVOICE_CREATE_FOR_VOUCHER(IN p_voucher_id BIGINT, IN p_batch_id VARCHAR(36), 
-- 											  IN p_customer_amount DOUBLE(9,2), IN p_customer_ptype VARCHAR(25),
-- 											  IN p_collector_amount DOUBLE(9,2), IN p_collector_ptype VARCHAR(25),
-- 											  IN p_assurance_amount DOUBLE(9,2), IN p_assurance_ptype VARCHAR(25),
											  IN p_message TEXT)
BEGIN
	DECLARE v_has_insurance, v_has_collector, v_insurance_excluded, v_foreign_vat_insurance, v_has_validation_messages, v_default_depot BOOL;
    DECLARE v_collector_foreign_vat BOOL;
    DECLARE v_insurance_id, v_collector_id BIGINT;
	DECLARE v_assurance_warranty, v_amount_customer_excl_vat, v_amount_customer_incl_vat, v_amount_customer, v_storage_costs DOUBLE(9,2);
    DECLARE v_insurance_custnum, v_collector_custnum, v_status, v_collector_type, v_insurance_invoice_number VARCHAR(45);
    DECLARE v_collector_vat, v_customer_vat VARCHAR(45);
    DECLARE v_call_date, v_vehicule_collected DATE;
    
    SELECT 	(insurance_id IS NOT NULL), insurance_id, insurance_invoice_number,
            (collector_id IS NOT NULL), collector_id,
            call_date, vehicule_collected
    INTO 	v_has_insurance, v_insurance_id, v_insurance_invoice_number,
            v_has_collector, v_collector_id,
            v_call_date, v_vehicule_collected
    FROM 	T_TOWING_VOUCHERS tv, T_DOSSIERS d
    WHERE 	tv.id = p_voucher_id
			AND d.id = tv.dossier_id
    LIMIT 	0,1;
    
    
    SELECT 	customer_number, IFNULL(invoice_excluded, FALSE), IFNULL(LEFT(vat, 2) != 'BE', FALSE)
    INTO	v_insurance_custnum, v_insurance_excluded, v_foreign_vat_insurance 
    FROM 	T_INSURANCES
    WHERE 	id = v_insurance_id
    LIMIT 	0,1;
    
    SELECT 	customer_number, type, LEFT(vat, 2) != 'BE', vat
    INTO 	v_collector_custnum, v_collector_type, v_collector_foreign_vat, v_collector_vat
    FROM 	T_COLLECTORS
    WHERE 	id = v_collector_id
    LIMIT 	0,1;

	SET v_has_validation_messages = FALSE;
    SET v_status = 'INVOICED';

	-- ------------------------------------------------------------------
	-- CHECK IF THE REQUIRED VALUES ARE SET FOR INSURANCES AND COLLECTORS
    -- ------------------------------------------------------------------
	DELETE FROM T_TOWING_VOUCHER_VALIDATION_MESSAGES WHERE towing_voucher_id = p_voucher_id;

	IF v_has_insurance AND NOT v_insurance_excluded AND (v_insurance_custnum IS NULL OR TRIM(v_insurance_custnum) = '') THEN
        CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(p_voucher_id, 'INVOICE_INSURANCE_MISSING_CUSTNUM', 'Het klantnummer werd niet ingevuld bij de assistance.');
        
        SET v_has_validation_messages = TRUE;
    END IF;
    
    IF v_has_insurance AND v_insurance_excluded THEN
		IF v_insurance_invoice_number IS NULL OR TRIM(v_insurance_invoice_number) = '' THEN
			CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(p_voucher_id, 'INVOICE_INSURANCE_INVOICE_NUM', 'Gelieve het factuurnummer voor de assistance op te geven.');
            
			SET v_has_validation_messages = TRUE;
        END IF;
    END IF;
    
    IF 	v_has_collector 
		AND (v_collector_custnum IS NULL OR TRIM(v_collector_custnum) = '') 
        AND v_collector_type != 'CUSTOMER'
        
	THEN
        CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(p_voucher_id, 'INVOICE_COLLECTOR_MISSING_CUSTNUM', 'Het klantnummer werd niet ingevuld bij de afhaler.');
        
        SET v_has_validation_messages = TRUE;    
    END IF;
    
    
    -- ------------------------------------------------------------------
    -- START THE INVOICING IF THERE ARE NO VALIDATION ERRORS
    -- ------------------------------------------------------------------
    IF NOT v_has_validation_messages THEN
		-- SELECT 	amount_guaranteed_by_insurance, amount_customer
		-- INTO	v_assurance_warranty, v_amount_customer
		-- FROM 	T_TOWING_VOUCHER_PAYMENTS
		-- WHERE 	towing_voucher_id = p_voucher_id;
        
        SELECT 	IF(foreign_vat, amount_excl_vat, amount_incl_vat) 
        INTO	v_assurance_warranty
        FROM 	T_TOWING_VOUCHER_PAYMENT_DETAILS tvpd, T_TOWING_VOUCHER_PAYMENTS tvp
        WHERE	tvp.id = tvpd.towing_voucher_payment_id
				AND tvp.voucher_id = p_voucher_id
                AND category='INSURANCE';
        
        SELECT 	IF(foreign_vat, amount_excl_vat, amount_incl_vat), amount_excl_vat, amount_incl_vat
        INTO	v_amount_customer, v_amount_customer_excl_vat, v_amount_customer_incl_vat
        FROM 	T_TOWING_VOUCHER_PAYMENT_DETAILS tvpd, T_TOWING_VOUCHER_PAYMENTS tvp
        WHERE	tvp.id = tvpd.towing_voucher_payment_id
				AND tvp.voucher_id = p_voucher_id
                AND category='CUSTOMER';
                
-- 
-- 		SELECT 	SUM(tac.cal_fee_excl_vat), SUM(tac.cal_fee_incl_vat)
-- 		INTO 	v_amount_customer_excl_vat, v_amount_customer_incl_vat
-- 		FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
-- 		WHERE 	1=1
-- 				AND taf.timeframe_activity_id = ta.id
-- 				AND tac.activity_id = taf.id
-- 				AND tac.towing_voucher_id=p_voucher_id; 
                
		SELECT 	IFNULL(company_vat, '')
        INTO 	v_customer_vat
        FROM 	T_TOWING_CUSTOMERS
        WHERE 	voucher_id = p_voucher_id
        LIMIT 	0,1;
        

		IF v_has_insurance AND NOT v_insurance_excluded
		THEN
			CALL R_INVOICE_CREATE_PARTIAL_INSURANCE(p_voucher_id, v_insurance_id, p_batch_id, p_message /*, p_assurance_amount, p_assurance_ptype */);
		END IF;

		IF v_has_collector THEN
			-- IF THE COLLECTOR IS NOT THE CLIENT, ADD THE STORAGE COSTS TO THE CLIENT'S BILL
            -- IF THE COLLECTOR AND INSURANCE ARE NOT THE SAME
            -- IF THE COLLECTOR IS NOT THE INVOICE CUSTOMER
			IF (SELECT `type` FROM T_COLLECTORS WHERE id = v_collector_id) != 'CUSTOMER' 
				AND v_collector_custnum != IFNULL(v_insurance_custnum, -1)
                AND LOWER(v_collector_vat) != LOWER(v_customer_vat)
			THEN
				IF (SELECT 	count(ta.code)
					FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
					WHERE 	ta.code='STALLING'
							AND taf.timeframe_activity_id = ta.id
							AND tac.activity_id = taf.id
							AND tac.towing_voucher_id=p_voucher_id) > 0
				THEN
					IF v_vehicule_collected IS NOT NULL THEN
						CALL R_INVOICE_CREATE_PARTIAL_COLLECTOR(p_voucher_id, v_collector_id, p_batch_id, p_message/*, p_collector_amount, p_collector_ptype*/);
					ELSE
						-- vehicule not collected
                        IF DATEDIFF(now(), v_call_date) > 30 THEN
							-- vehicule has not been collected after 30 days
							SET v_status = 'INVOICED WITHOUT STORAGE';
                        END IF;
					END IF;
				END IF;
			END IF;
		ELSE            
			-- no collector set
			SELECT 	default_depot = 1 INTO v_default_depot
			FROM 	T_TOWING_DEPOTS
			WHERE 	voucher_id = p_voucher_id
			LIMIT 	0,1;
            
            
			-- IF STILL IN STORAGE (NOT COLLECTED) AND NOT COLLECTED WITHIN 30DAYS 
			IF v_default_depot 
				AND v_vehicule_collected IS NULL 
                AND (SELECT datediff(now(), IFNULL(call_date, now())) FROM T_DOSSIERS d, T_TOWING_VOUCHERS tv WHERE tv.id = p_voucher_id AND d.id=tv.dossier_id ) > 30
			THEN
				SET v_status = 'INVOICED WITHOUT STORAGE';
            END IF;
		END IF;
	
    
		SELECT 	IF(v_collector_foreign_vat AND v_collector_type != 'CUSTOMER', tac.cal_fee_excl_vat, tac.cal_fee_incl_vat) 
		INTO 	v_storage_costs
		FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
		WHERE 	ta.code='STALLING'
				AND taf.timeframe_activity_id = ta.id
				AND tac.activity_id = taf.id
				AND tac.towing_voucher_id=p_voucher_id;
    

		-- CREATE AN INVOICE FOR THE CUSTOMER UNDER FOLLOWING CONDITIONS:
		-- (a) THERE IS NO INSURANCE INVOLVED
		-- (b) INSURANCE WAS INVOLVED, AND THERE IS A PART TO PAY BY THE CUSTOMER
		IF NOT v_has_insurance 
			OR (v_has_insurance 
				AND v_amount_customer != v_assurance_warranty 
                AND v_amount_customer > 0
				AND v_amount_customer != IFNULL(v_storage_costs, 0)) 
		THEN
			CALL R_INVOICE_CREATE_PARTIAL_CUSTOMER(p_voucher_id, p_batch_id, p_message/*, p_customer_amount, p_customer_ptype*/);
		END IF;
		
		-- CHANGE THE STATUS
		UPDATE T_TOWING_VOUCHERS SET status=v_status WHERE id = p_voucher_id LIMIT 1;
    END IF;
END $$


-- ------------------------------------------------------------------------------------------
-- CREATE THE INVOICE FOR AN INSURANCE COMPANY
-- ------------------------------------------------------------------------------------------
CREATE PROCEDURE R_INVOICE_CREATE_PARTIAL_INSURANCE(IN p_voucher_id BIGINT, IN p_insurance_id BIGINT, IN p_batch_id VARCHAR(36), IN p_message TEXT /*, IN p_paid DOUBLE(9,2), IN p_payment_type VARCHAR(25)*/)
BEGIN
	DECLARE v_foreign_vat  BOOL;
	DECLARE v_customer_number, v_collector_custnum, v_company_vat, v_street_number, v_street_pobox, v_zip, v_insurance_dossier_nr  VARCHAR(45);
	DECLARE v_company_name, v_street, v_city, v_country, v_payment_type VARCHAR(255);
	DECLARE	v_company_id, v_invoice_customer_id, v_invoice_id, v_voucher_number, v_invoice_number, v_collector_id BIGINT;
	DECLARE v_amount, v_amount_excl_vat, v_amount_incl_vat, v_vat DOUBLE;
    DECLARE v_invoice_total_excl_vat, v_invoice_total_incl_vat DOUBLE;
    DECLARE v_amount_paid_incl_vat, v_amount_paid_excl_vat DOUBLE;
    DECLARE v_amount_unpaid_incl_vat, v_amount_unpaid_excl_vat DOUBLE;
    DECLARE v_amount_customer DOUBLE;

	SET v_vat = 0.21;

    -- FETCH THE INSURANCE COMPANY INFORMATION FOR THE VOUCHER
	SET v_customer_number = F_CUSTOMER_NUMBER_FOR_INSURANCE(p_insurance_id);

	SELECT 	i.name, i.vat, i.street, i.street_number, i.street_pobox, i.zip, i.city, 
			d.company_id,
			tv.voucher_number,
            tv.insurance_dossiernr,
            tv.collector_id
	INTO 	v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, 
            v_company_id,
            v_voucher_number,
            v_insurance_dossier_nr,
            v_collector_id
    FROM 	T_INSURANCES i, T_TOWING_VOUCHERS tv, T_DOSSIERS d
    WHERE tv.id = p_voucher_id
			AND tv.dossier_id = d.id
			AND tv.insurance_id = i.id
			AND i.id = p_insurance_id;

	-- SELECT THE PAYMENT INFORMATION FOR THE INSURANCE PART
    SELECT 	amount_excl_vat, amount_incl_vat, foreign_vat, amount_unpaid_excl_vat, amount_unpaid_incl_vat,
			IF(amount_paid_cash > 0, 'CASH',
				IF(amount_paid_bankdeposit > 0, 'BANKDEPOSIT', 
					IF(amount_paid_maestro > 0, 'MAESTRO', 
						IF(amount_paid_visa > 0, 'VISA', null)
					)
				)
			) as payment_type
    INTO	v_amount_excl_vat, v_amount_incl_vat, v_foreign_vat, v_amount_unpaid_excl_vat, v_amount_unpaid_incl_vat,
			v_payment_type
    FROM 	T_TOWING_VOUCHER_PAYMENTS tvp, T_TOWING_VOUCHER_PAYMENT_DETAILS tvpd
    WHERE 	towing_voucher_id = p_voucher_id
			AND tvp.id = tvpd.towing_voucher_payment_id
			AND category = 'INSURANCE'
    LIMIT 	0,1;
    
    SELECT 	customer_number
    INTO	v_collector_custnum
    FROM 	T_COLLECTORS
    WHERE 	id = v_collector_id
    LIMIT	0,1;


    -- CREATE A NEW INVOICE CUSTOMER
    CALL R_INVOICE_CUSTOMER_FIND_OR_CREATE(
		   'ORGANISATION',
           p_voucher_id,
		   v_company_id, 
		   v_company_name, 
		   null, 
		   null, 
		   v_company_vat, 
		   v_street, 
		   v_street_number, 
		   v_street_pobox, 
		   v_zip, 
		   v_city, 
		   v_country,
           v_customer_number,
		   v_invoice_customer_id
    );
    
	SET v_invoice_number = F_CREATE_INVOICE_NUMBER(v_company_id);
    
    -- CREATE A NEW INVOICE
    INSERT INTO T_INVOICES(company_id, towing_voucher_id, invoice_batch_run_id,
						   invoice_customer_id, invoice_date, invoice_number, invoice_structured_reference,
						   vat_foreign_country,
						   invoice_total_excl_vat, invoice_total_incl_vat,
						   invoice_total_vat,
						   invoice_vat_percentage,
                           invoice_message,
                           invoice_type,
                           insurance_dossiernr,
                           invoice_amount_paid,
                           invoice_payment_type)
    VALUES(v_company_id, p_voucher_id, p_batch_id,
		   v_invoice_customer_id, CURDATE(), v_invoice_number, F_CREATE_STRUCTURED_REFERENCE(v_invoice_number),
           v_foreign_vat,
           v_amount_excl_vat, v_amount_incl_vat,
           v_amount_incl_vat-v_amount_excl_vat,
           IF(v_foreign_vat, 0.0, v_vat),
           p_message,
           'INSURANCE',
           v_insurance_dossier_nr,
           IF(v_foreign_vat, v_amount_excl_vat - v_amount_unpaid_excl_vat, v_amount_incl_vat - v_amount_unpaid_incl_vat),
           v_payment_type); -- TODO: set the payment type correct!

	SET v_invoice_id = LAST_INSERT_ID();

	
    IF v_collector_id IS NULL -- IF NO COLLECTOR IS SET, OR
		OR v_collector_custnum = v_customer_number -- IF THE COLLECTOR IS THE INSURANCE COMPANY
	THEN
		-- INSERT ALL ACTIVITIES FROM THE VOUCHER AS INVOICE_LINES
		INSERT INTO T_INVOICE_LINES(invoice_id,
									item,
									item_amount, item_price_excl_vat, item_price_incl_vat,
									item_total_excl_vat, item_total_incl_vat)
		SELECT 	v_invoice_id,
				ta.name,
				tac.amount, taf.fee_excl_vat, taf.fee_incl_vat,
				tac.cal_fee_excl_vat, tac.cal_fee_incl_vat
		FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
		WHERE 	1=1
				AND taf.timeframe_activity_id = ta.id
				AND tac.activity_id = taf.id
				AND tac.towing_voucher_id=p_voucher_id
		UNION
		SELECT	v_invoice_id,
				name,
				1, fee_excl_vat, fee_incl_vat,
				fee_excl_vat, fee_incl_vat
		FROM 	T_TOWING_ADDITIONAL_COSTS
		WHERE 	1=1
				AND towing_voucher_id = p_voucher_id;    
	ELSE
		INSERT INTO T_INVOICE_LINES(invoice_id,
									item,
									item_amount, item_price_excl_vat, item_price_incl_vat,
									item_total_excl_vat, item_total_incl_vat)
		SELECT 	v_invoice_id,
				ta.name,
				tac.amount, taf.fee_excl_vat, taf.fee_incl_vat,
				tac.cal_fee_excl_vat, tac.cal_fee_incl_vat
		FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
		WHERE 	ta.code!='STALLING'
				AND taf.timeframe_activity_id = ta.id
				AND tac.activity_id = taf.id
				AND tac.towing_voucher_id=p_voucher_id
		UNION
		SELECT	v_invoice_id,
				name,
				1, fee_excl_vat, fee_incl_vat,
				fee_excl_vat, fee_incl_vat
		FROM 	T_TOWING_ADDITIONAL_COSTS
		WHERE 	1=1
				AND towing_voucher_id = p_voucher_id;     
    END IF;
            
	-- INSERT THE INVOICE LINE FOR THE CUSTOMERS PART
    IF (SELECT 	amount_excl_vat 
		FROM 	T_TOWING_VOUCHER_PAYMENT_DETAILS tvpd, T_TOWING_VOUCHER_PAYMENTS tvp 
        WHERE 	tvp.id = towing_voucher_payment_id AND towing_voucher_id=p_voucher_id
				AND category='CUSTOMER') > 0 
		-- v_amount != v_amount_customer AND v_amount_customer > 0 /* AND NOT v_collector_id IS NULL */ 
    THEN
		INSERT INTO T_INVOICE_LINES(invoice_id,
									item,
									item_amount, item_price_excl_vat, item_price_incl_vat,
									item_total_excl_vat, item_total_incl_vat)
		SELECT 	v_invoice_id,
				CONCAT('Ten laste van klant, referentie takelbon B', v_voucher_number, ' - dossier: ', IFNULL(v_insurance_dossier_nr, 'N/A')),
				1, 
                -amount_excl_vat, -- -(v_amount_customer / (1+v_vat)), -v_amount_customer,
				-amount_incl_vat, -- -(v_amount_customer / (1+v_vat)), -v_amount_customer;
                -amount_excl_vat, -- -(v_amount_customer / (1+v_vat)), -v_amount_customer,
				-amount_incl_vat  -- -(v_amount_customer / (1+v_vat)), -v_amount_customer;
		FROM	T_TOWING_VOUCHER_PAYMENT_DETAILS tvpd, T_TOWING_VOUCHER_PAYMENTS tvp 
        WHERE 	tvp.id = towing_voucher_payment_id AND towing_voucher_id=p_voucher_id
				AND category='CUSTOMER';
			
	END IF;
            
	-- UPDATE THE TOTAL OF THE INVOICE WITH THE INFORMATION FROM THE INVOICE LINES
    CALL R_RECALCULATE_INVOICE_TOTAL(v_invoice_id);
END $$


-- ------------------------------------------------------------------------------------------
-- CREATE THE INVOICE FOR A COLLECTOR
-- ------------------------------------------------------------------------------------------
CREATE PROCEDURE R_INVOICE_CREATE_PARTIAL_COLLECTOR(IN p_voucher_id BIGINT, IN p_collector_id BIGINT, IN p_batch_id VARCHAR(36), IN p_message TEXT /*, IN p_paid DOUBLE(9,2), IN p_payment_type VARCHAR(25) */)
BEGIN
	DECLARE v_foreign_vat  BOOL;
	DECLARE v_customer_number, v_company_vat, v_street_number, v_street_pobox, v_zip  VARCHAR(45);
    DECLARE v_company_name, v_street, v_city, v_country, v_collector_type, v_first_name, v_last_name, v_payment_type VARCHAR(255);
    DECLARE	v_company_id, v_invoice_customer_id, v_invoice_id, v_voucher_number, v_invoice_number, v_collector_id BIGINT;
    DECLARE v_amount, v_amount_excl_vat, v_amount_incl_vat, v_vat, v_item_excl_vat, v_item_incl_vat DOUBLE;
    DECLARE v_amount_unpaid_excl_vat, v_amount_unpaid_incl_vat DOUBLE;

    SET v_vat = 0.21;

    SELECT 	taf.fee_excl_vat, taf.fee_incl_vat, tac.amount
    INTO 	v_item_excl_vat, v_item_incl_vat, v_amount
		FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
		WHERE 	ta.code='STALLING'
				AND taf.timeframe_activity_id = ta.id
				AND tac.activity_id = taf.id
				AND tac.towing_voucher_id=p_voucher_id;

	SELECT 	foreign_vat, amount_excl_vat, amount_incl_vat, amount_unpaid_excl_vat, amount_unpaid_incl_vat,
			IF(amount_paid_cash > 0, 'CASH',
				IF(amount_paid_bankdeposit > 0, 'BANKDEPOSIT', 
					IF(amount_paid_maestro > 0, 'MAESTRO', 
						IF(amount_paid_visa > 0, 'VISA', null)
					)
				)
			) as payment_type
    INTO	v_foreign_vat, v_amount_excl_vat, v_amount_incl_vat, v_amount_unpaid_excl_vat, v_amount_unpaid_incl_vat,
			v_payment_type
    FROM 	T_TOWING_VOUCHER_PAYMENT_DETAILS tvpd, T_TOWING_VOUCHER_PAYMENTS tvp
    WHERE	tvpd.towing_voucher_payment_id = tvp.id
			AND tvp.towing_voucher_id = p_voucher_id
			AND category='COLLECTOR';

    -- ONLY IF STALLING COST WAS APPLIED
    IF IFNULL(v_amount_excl_vat, 0.0) > 0
    THEN
		-- FETCH THE COLLECTOR COMPANY INFORMATION FOR THE VOUCHER
		SELECT c.name, c.vat, c.street, c.street_number, c.street_pobox, c.zip, c.city, c.country,
			   d.company_id,
			   tv.voucher_number,
               c.type
		INTO   v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country,
			   v_company_id,
			   v_voucher_number,
               v_collector_type
		FROM   T_COLLECTORS c, T_TOWING_VOUCHERS tv, T_DOSSIERS d
		WHERE  tv.id = p_voucher_id
				AND tv.dossier_id = d.id
				AND tv.collector_id = c.id
				AND c.id = p_collector_id;
                
		IF v_collector_type = 'CUSTOMER' THEN
			-- FETCH THE CUSTOMER INFORMATION FOR THE VOUCHER
			SELECT 	
					c.first_name, c.last_name, c.company_name, c.company_vat, c.street, c.street_number, c.street_pobox, c.zip, c.city, c.country,
					d.company_id,
					tv.voucher_number,
					tv.collector_id
			INTO 	
					v_first_name, v_last_name, v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country,
					v_company_id,
					v_voucher_number,
					v_collector_id
			FROM 	T_TOWING_CUSTOMERS c, T_TOWING_VOUCHERS tv, T_DOSSIERS d
			WHERE 	tv.id = p_voucher_id
					AND tv.dossier_id = d.id
					AND tv.id = c.voucher_id;

			-- CREATE A NEW INVOICE CUSTOMER    
			CALL R_INVOICE_CUSTOMER_FIND_OR_CREATE(
				   IF(v_company_name IS NULL OR TRIM(v_company_name) = '', 'PERSON', 'ORGANISATION'),
				   p_voucher_id,
				   v_company_id, 
				   v_company_name, 
				   v_first_name, 
				   v_last_name, 
				   v_company_vat, 
				   v_street, 
				   v_street_number, 
				   v_street_pobox, 
				   v_zip, 
				   v_city, 
				   v_country,
				   null,
				   v_invoice_customer_id
			);            
        ELSE
			SET v_customer_number = F_CUSTOMER_NUMBER_FOR_COLLECTOR(p_collector_id);
            
			-- CREATE A NEW INVOICE CUSTOMER
			CALL R_INVOICE_CUSTOMER_FIND_OR_CREATE(
				   'ORGANISATION',
				   p_voucher_id,
				   v_company_id, 
				   v_company_name, 
				   null, 
				   null, 
				   v_company_vat, 
				   v_street, 
				   v_street_number, 
				   v_street_pobox, 
				   v_zip, 
				   v_city, 
				   v_country,
				   v_customer_number,
				   v_invoice_customer_id
			);    
        END IF;

		SET v_invoice_number = F_CREATE_INVOICE_NUMBER(v_company_id);
        
		-- CREATE A NEW INVOICE
		INSERT INTO T_INVOICES(company_id, towing_voucher_id,
							   invoice_batch_run_id,
							   invoice_customer_id, invoice_date, invoice_number, invoice_structured_reference,
							   vat_foreign_country,
							   invoice_total_excl_vat, invoice_total_incl_vat,
							   invoice_total_vat,
							   invoice_vat_percentage,
                               invoice_message,
                               invoice_type,
                               invoice_amount_paid,
                               invoice_payment_type)
		VALUES(v_company_id, p_voucher_id,
			   p_batch_id,
			   v_invoice_customer_id, CURDATE(), v_invoice_number, F_CREATE_STRUCTURED_REFERENCE(v_invoice_number),
			   v_foreign_vat,
			   v_amount_excl_vat,v_amount_incl_vat,
			   v_amount_incl_vat - v_amount_excl_vat,
			   IF(v_foreign_vat, 0.0, v_vat),
               p_message,
               'COLLECTOR',
			   IF(v_foreign_vat, v_amount_excl_vat - v_amount_unpaid_excl_vat, v_amount_incl_vat - v_amount_unpaid_incl_vat),
			   v_payment_type);

		SET v_invoice_id = LAST_INSERT_ID();

		-- CREATE THE INVOICE LINES FOR THE CREATE INVOICE
		INSERT INTO T_INVOICE_LINES(invoice_id,
									item,
                                    item_amount, item_price_excl_vat, item_price_incl_vat,
									item_total_excl_vat, item_total_incl_vat)
		VALUES(v_invoice_id,
			   CONCAT('Stallingskost takelbon B', v_voucher_number),
               v_amount, v_item_excl_vat, IF(v_foreign_vat, v_item_excl_vat, v_item_incl_vat),
			   v_amount_excl_vat, IF(v_foreign_vat, v_amount_excl_vat, v_amount_incl_vat));
	ELSE
		SELECT concat("No storage costs found for voucher: ", p_voucher_id);
    END IF;
END $$


CREATE PROCEDURE R_INVOICE_CUSTOMER_FIND_OR_CREATE(IN p_type ENUM('PERSON', 'ORGANISATION'),
												   IN p_voucher_id BIGINT,
												   IN p_company_id BIGINT, 
                                                   IN p_company_name VARCHAR(255), 
                                                   IN p_first_name VARCHAR(45), 
                                                   IN p_last_name VARCHAR(45), 
                                                   IN p_company_vat VARCHAR(45), 
                                                   IN p_street VARCHAR(255), 
                                                   IN p_street_number VARCHAR(45), 
                                                   IN p_street_pobox VARCHAR(45), 
                                                   IN p_zip VARCHAR(45), 
                                                   IN p_city VARCHAR(255), 
                                                   IN p_country VARCHAR(255),
                                                   IN p_cust_num VARCHAR(45),
                                                   OUT v_customer_id BIGINT)
BEGIN
	DECLARE v_cust_id BIGINT;
    
    IF p_cust_num IS NOT NULL AND p_type != 'PERSON' THEN -- custnum for persons is the same for all
		SELECT 	id INTO v_cust_id 
        FROM 	T_INVOICE_CUSTOMERS 
		WHERE 	lower(customer_number) = lower(p_cust_num) 
				AND company_id = p_company_id
        LIMIT 	0,1;
	END IF;
    
    IF v_cust_id IS NULL THEN
		IF p_type = 'ORGANISATION' THEN
			IF p_company_vat IS NOT NULL AND TRIM(p_company_vat) != '' THEN
				SELECT 	id INTO v_cust_id 
                FROM 	T_INVOICE_CUSTOMERS 
                WHERE 	lower(company_vat) = lower(p_company_vat)
						AND company_id = p_company_id
				LIMIT 	0,1;
			ELSE
				SELECT 	id INTO v_cust_id 
                FROM 	T_INVOICE_CUSTOMERS 
                WHERE 	lower(company_name) = lower(p_company_name) 
						AND company_id = p_company_id
                LIMIT 	0,1;
			END IF;
		ELSE
			SELECT 	id INTO v_cust_id 
			FROM 	T_INVOICE_CUSTOMERS 
			WHERE 	1=1
					AND lower(last_name) = lower(p_last_name)
					AND lower(street) = lower(p_street)
					AND lower(city) = lower(p_city)
                    AND company_id = p_company_id
			LIMIT 0,1;
		END IF;
		
		IF v_cust_id IS NULL THEN
			INSERT INTO T_INVOICE_CUSTOMERS(customer_number, company_id, company_name, first_name, last_name, company_vat, street, street_number, street_pobox, zip, city, country)
			VALUES(IF(p_type = 'ORGANISATION', F_CUSTOMER_NUMBER_FOR_COMPANY(p_voucher_id, p_company_id) , 
											   F_CREATE_CUSTOMER_NUMBER_FOR_PRIVATE_PERSON(p_last_name)), 
				   p_company_id, 
				   p_company_name, p_first_name, p_last_name, p_company_vat, p_street, p_street_number, p_street_pobox, p_zip, p_city, p_country);
				   
			SET v_cust_id = LAST_INSERT_ID();
		END IF;
	END IF;

    
    SET v_customer_id = v_cust_id;
END $$

-- ------------------------------------------------------------------------------------------
-- CREATE THE INVOICE FOR A CUSTOMER
-- ------------------------------------------------------------------------------------------
CREATE PROCEDURE R_INVOICE_CREATE_PARTIAL_CUSTOMER(IN p_voucher_id BIGINT, IN p_batch_id VARCHAR(36), IN p_message TEXT /*, IN p_paid DOUBLE(9,2), IN p_payment_type VARCHAR(25)*/)
BEGIN
	DECLARE v_foreign_vat  BOOL;
	DECLARE v_customer_number, v_company_vat, v_street_number, v_street_pobox, v_zip, v_insurance_dossier_nr  VARCHAR(45);
	DECLARE v_company_name, v_street, v_city, v_country, v_first_name, v_last_name, v_payment_type VARCHAR(255);
	DECLARE	v_company_id, v_invoice_customer_id, v_invoice_id, v_collector_id, v_insurance_id, v_voucher_number, v_invoice_number BIGINT;
	DECLARE v_amount, v_amount_excl_vat, v_amount_incl_vat, v_vat, v_item_excl_vat, v_item_incl_vat DOUBLE;
    DECLARE v_amount_unpaid_excl_vat, v_amount_unpaid_incl_vat DOUBLE;
    DECLARE	v_invoice_total_excl_vat, v_invoice_total_incl_vat DOUBLE;

	SET v_vat = 0.21;

	-- FETCH THE INSURANCE COMPANY INFORMATION FOR THE VOUCHER
	SELECT 	
			c.first_name, c.last_name, c.company_name, c.company_vat, c.street, c.street_number, c.street_pobox, c.zip, c.city, c.country,
			d.company_id,
			tv.voucher_number,
            tv.collector_id,
            tv.insurance_id,
            tv.insurance_dossiernr
	INTO 	
			v_first_name, v_last_name, v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country,
			v_company_id,
			v_voucher_number,
            v_collector_id,
            v_insurance_id,
            v_insurance_dossier_nr
	FROM 	T_TOWING_CUSTOMERS c, T_TOWING_VOUCHERS tv, T_DOSSIERS d
	WHERE 	tv.id = p_voucher_id
			AND tv.dossier_id = d.id
			AND tv.id = c.voucher_id;
            
	SELECT 	foreign_vat, amount_excl_vat, amount_incl_vat, IFNULL(amount_unpaid_excl_vat, 0), IFNULL(amount_unpaid_incl_vat,0),
			IF(amount_paid_cash > 0, 'CASH',
				IF(amount_paid_bankdeposit > 0, 'BANKDEPOSIT', 
					IF(amount_paid_maestro > 0, 'MAESTRO', 
						IF(amount_paid_visa > 0, 'VISA', null)
					)
				)
			) as payment_type
    INTO	v_foreign_vat, v_amount_excl_vat, v_amount_incl_vat, v_amount_unpaid_excl_vat, v_amount_unpaid_incl_vat,
			v_payment_type
    FROM 	T_TOWING_VOUCHER_PAYMENT_DETAILS tvpd, T_TOWING_VOUCHER_PAYMENTS tvp
    WHERE	tvpd.towing_voucher_payment_id = tvp.id
			AND tvp.towing_voucher_id = p_voucher_id
            AND tvpd.category='CUSTOMER'
	LIMIT 	0,1;

	-- CREATE A NEW INVOICE CUSTOMER    
    CALL R_INVOICE_CUSTOMER_FIND_OR_CREATE(
		   IF(v_company_name IS NULL OR TRIM(v_company_name) = '', 'PERSON', 'ORGANISATION'),
           p_voucher_id,
		   v_company_id, 
		   v_company_name, 
		   v_first_name, 
		   v_last_name, 
		   v_company_vat, 
		   v_street, 
		   v_street_number, 
		   v_street_pobox, 
		   v_zip, 
		   v_city, 
		   v_country,
           null,
		   v_invoice_customer_id
    );
    
    SET v_invoice_number = F_CREATE_INVOICE_NUMBER(v_company_id);

	-- CREATE A NEW INVOICE
	INSERT INTO T_INVOICES(company_id, towing_voucher_id,
						   invoice_batch_run_id,
						   invoice_customer_id, invoice_date, invoice_number, invoice_structured_reference,
						   vat_foreign_country,
						   invoice_total_excl_vat, invoice_total_incl_vat,
						   invoice_total_vat,
						   invoice_vat_percentage,
                           invoice_message,
                           invoice_type,
                           invoice_amount_paid,
                           invoice_payment_type)
	VALUES(v_company_id, p_voucher_id,
		   p_batch_id,
		   v_invoice_customer_id, CURDATE(), v_invoice_number, F_CREATE_STRUCTURED_REFERENCE(v_invoice_number),
		   v_foreign_vat,
		   v_amount_excl_vat, v_amount_incl_vat,
		   v_amount_incl_vat - v_amount_excl_vat,
		   IF(v_foreign_vat, 0, v_vat),
           p_message,
           'CUSTOMER',
           IF(v_foreign_vat, v_amount_excl_vat - v_amount_unpaid_excl_vat,  v_amount_incl_vat - v_amount_unpaid_incl_vat),
           v_payment_type);

	SET v_invoice_id = LAST_INSERT_ID();

	-- CHECK IF THE COLLECTOR WAS SET, AND IF THE COLLECTOR IS OF TYPE 'CUSTOMER'
	IF v_collector_id IS NULL 
		OR (v_collector_id IS NOT NULL AND (SELECT `type` FROM T_COLLECTORS WHERE id = v_collector_id) = 'CUSTOMER')
        OR (v_collector_id IS NOT NULL AND v_company_vat IS NOT NULL AND TRIM(v_company_vat) != '' AND (SELECT lower(`vat`) FROM T_COLLECTORS WHERE id = v_collector_id) = lower(v_company_vat)) 
	THEN
		-- CREATE THE INVOICE LINES FOR THE CREATE INVOICE
		INSERT INTO T_INVOICE_LINES(invoice_id,
									item,
									item_amount, item_price_excl_vat, item_price_incl_vat,
									item_total_excl_vat, item_total_incl_vat)
		SELECT 	v_invoice_id,
				ta.name,
				tac.amount, taf.fee_excl_vat, taf.fee_incl_vat,
				tac.cal_fee_excl_vat, tac.cal_fee_incl_vat
		FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
		WHERE 	1=1
				AND taf.timeframe_activity_id = ta.id
				AND tac.activity_id = taf.id
				AND tac.towing_voucher_id=p_voucher_id
		UNION
		SELECT	v_invoice_id,
				name,
				1, fee_excl_vat, fee_incl_vat,
				fee_excl_vat, fee_incl_vat
		FROM 	T_TOWING_ADDITIONAL_COSTS
		WHERE 	1=1
				AND towing_voucher_id = p_voucher_id;                 
    ELSE
		-- IT SEEMS THAT THE CAR HAS BEEN COLLECTED BY SOMEONE ELSE THAN THE CUSTOMER HIMSELF, SO IGNORE STORAGE COSTS
		INSERT INTO T_INVOICE_LINES(invoice_id,
									item,
									item_amount, item_price_excl_vat, item_price_incl_vat,
									item_total_excl_vat, item_total_incl_vat)
		SELECT 	v_invoice_id,
				ta.name,
				tac.amount, taf.fee_excl_vat, taf.fee_incl_vat,
				tac.cal_fee_excl_vat, tac.cal_fee_incl_vat
		FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
		WHERE 	ta.code!='STALLING'
				AND taf.timeframe_activity_id = ta.id
				AND tac.activity_id = taf.id
				AND tac.towing_voucher_id=p_voucher_id
		UNION
		SELECT	v_invoice_id,
				name,
				1, fee_excl_vat, fee_incl_vat,
				fee_excl_vat, fee_incl_vat
		FROM 	T_TOWING_ADDITIONAL_COSTS
		WHERE 	1=1
				AND towing_voucher_id = p_voucher_id;                 
    END IF;
    
    IF v_insurance_id IS NOT NULL THEN
		SELECT 	amount_excl_vat, amount_incl_vat
		INTO	v_amount_excl_vat, v_amount_incl_vat
		FROM 	T_TOWING_VOUCHER_PAYMENT_DETAILS tvpd, T_TOWING_VOUCHER_PAYMENTS tvp
		WHERE	tvpd.towing_voucher_payment_id = tvp.id
				AND tvp.towing_voucher_id = p_voucher_id
				AND tvpd.category='INSURANCE'
		LIMIT 	0,1;    
    
		IF v_foreign_vat THEN
			SET v_amount_incl_vat = v_amount_excl_vat;
        END IF;
    
        -- CREATE THE INVOICE LINES FOR THE CREATE INVOICE
		INSERT INTO T_INVOICE_LINES(invoice_id,
									item, item_amount, item_price_excl_vat, item_price_incl_vat,
									item_total_excl_vat, item_total_incl_vat)
		VALUES(v_invoice_id,
			   CONCAT('Waarborg takelbon B', v_voucher_number, ' - Dossier: ', IFNULL(v_insurance_dossier_nr, 'N/A')), 1, -v_amount_excl_vat, -v_amount_incl_vat,
			   -v_amount_excl_vat, -v_amount_incl_vat);
    END IF;

	-- UPDATE THE TOTAL OF THE INVOICE WITH THE INFORMATION FROM THE INVOICE LINES
    CALL R_RECALCULATE_INVOICE_TOTAL(v_invoice_id);
END $$


CREATE PROCEDURE R_INVOICE_FETCH_BATCH_INVOICES(IN p_batch_id VARCHAR(36))
BEGIN
	SELECT 	i.id, i.company_id, i.invoice_customer_id, i.invoice_batch_run_id, i.towing_voucher_id, tv.dossier_id, i.invoice_ref_id,
			UNIX_TIMESTAMP(i.invoice_date) as invoice_date,
            i.invoice_number, 
            concat(LEFT(i.invoice_number, 4), '/', SUBSTRING(i.invoice_number,5)) as invoice_number_display,
            i.invoice_structured_reference,
            i.vat_foreign_country,
            i.invoice_total_excl_vat, 
            i.invoice_total_incl_vat,
            i.invoice_total_vat, 
            i.invoice_vat_percentage,
            i.invoice_amount_paid,
            i.invoice_payment_type,
            concat('B', tv.voucher_number) as voucher_number,
            UNIX_TIMESTAMP(d.call_date) as call_date, 
            d.call_number, 
            d.id AS dossier_id,
            -- tvp.paid_in_cash, tvp.paid_by_bank_deposit, tvp.paid_by_debit_card, tvp.paid_by_credit_card, 
			-- tvp.cal_amount_unpaid,
            -- tvp.amount_guaranteed_by_insurance,
            i.invoice_type, 
            i.invoice_message,
            i.insurance_dossiernr,
            IF(i.invoice_type = 'CN', 
					(SELECT concat(LEFT(i2.invoice_number, 4), '/', SUBSTRING(i2.invoice_number,5)) FROM T_INVOICES i2 WHERE i2.id = i.invoice_ref_id) , 
                    null) as invoice_ref_invoice_number,
            -- jaartal+maand+dag_FVH+factuurnummer_verkorte naam aannemer_PA of TA nummer_Perceel_nr autosnelweg
            -- e.g. 20150622_FVH562879_Hamse_TA00000953_P5_E313
            CONCAT(	YEAR(i.invoice_date), LPAD(MONTH(i.invoice_date), 2, '0'), LPAD(DAY(i.invoice_date), 2, '0'), '_',
					IF(i.invoice_type = 'CN', 'CN', 'FVH'), 
                    i.invoice_number, '_', 
                    (SELECT code FROM T_COMPANIES WHERE id = d.company_id LIMIT 0,1), '_',
                    d.call_number, '_',
                    (SELECT code FROM P_ALLOTMENT WHERE id = d.allotment_id LIMIT 0,1), '_',
                    (SELECT REPLACE(REPLACE(name, '>', '_'), ' ', '') FROM P_ALLOTMENT_DIRECTIONS WHERE id = d.allotment_direction_id LIMIT 0,1), '.pdf') AS filename
    FROM 	T_INVOICES i, T_TOWING_VOUCHERS tv, T_TOWING_VOUCHER_PAYMENTS tvp, T_DOSSIERS d
    WHERE 	i.invoice_batch_run_id = p_batch_id
			AND tv.id = i.towing_voucher_id
            AND tv.id = tvp.towing_voucher_id
            AND d.id = tv.dossier_id;
END $$

CREATE PROCEDURE R_INVOICE_FETCH_COMPANY_INVOICE(IN p_invoice_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);
    DECLARE v_login VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	i.id, i.company_id, 
				i.invoice_customer_id, 
                i.invoice_batch_run_id, 
                i.towing_voucher_id,
                i.invoice_ref_id,
                i.document_id,
				UNIX_TIMESTAMP(i.invoice_date) as invoice_date,
				i.invoice_number, 
                concat(IF(i.invoice_type='CN', 'CN', 'F'), LEFT(i.invoice_number, 4), '/', SUBSTRING(i.invoice_number,5)) as invoice_number_display,
				i.invoice_structured_reference,
				i.vat_foreign_country,
				i.invoice_total_excl_vat, 
                i.invoice_total_incl_vat,
				i.invoice_total_vat, 
                i.invoice_vat_percentage,
                IF(vat_foreign_country, 
					i.invoice_total_excl_vat - (SELECT SUM(item_total_excl_vat) FROM T_INVOICE_LINES WHERE invoice_id = i.id), 
                    i.invoice_total_incl_vat - (SELECT SUM(item_total_incl_vat) FROM T_INVOICE_LINES WHERE invoice_id = i.id)
				) AS cal_amount_unpaid,
				IF(i.towing_voucher_id IS NOT NULL, 
					concat('B', (SELECT voucher_number 
								 FROM T_TOWING_VOUCHERS tv, T_INVOICES i 
								 WHERE i.id = p_invoice_id
										AND i.towing_voucher_id = tv.id 
								 LIMIT 0,1)), 
					null) as voucher_number,
                i.invoice_message,
                i.invoice_type, 
                invoice_amount_paid, 
                invoice_payment_type,
                UNIX_TIMESTAMP(DATE_ADD(i.invoice_date,INTERVAL 30 DAY)) as invoice_due_date,
				IF(i.invoice_type = 'CN', 
						(SELECT concat(LEFT(i2.invoice_number, 4), '/', SUBSTRING(i2.invoice_number,5)) FROM T_INVOICES i2 WHERE i2.id = i.invoice_ref_id) , 
						null) as invoice_ref_invoice_number,
				-- jaartal+maand+dag_FVH+factuurnummer_verkorte naam aannemer_PA of TA nummer_Perceel_nr autosnelweg
				-- e.g. 20150622_FVH562879_Hamse_TA00000953_P5_E313
                IF(i.towing_voucher_id IS NOT NULL, 
					(SELECT CONCAT(	YEAR(i.invoice_date), LPAD(MONTH(i.invoice_date), 2, '0'), LPAD(DAY(i.invoice_date), 2, '0'), '_',
							IF(i.invoice_type = 'CN', 'CN', 'FVH'), 
							i.invoice_number, '_', 
							(SELECT code FROM T_COMPANIES WHERE id = d.company_id LIMIT 0,1), '_',
							d.call_number, '_',
							(SELECT code FROM P_ALLOTMENT WHERE id = d.allotment_id LIMIT 0,1), '_',
							(SELECT REPLACE(REPLACE(name, '>', '_'), ' ', '') FROM P_ALLOTMENT_DIRECTIONS WHERE id = d.allotment_direction_id LIMIT 0,1), '.pdf')
					 FROM T_DOSSIERS d, T_TOWING_VOUCHERS tv WHERE d.id = tv.dossier_id AND tv.id = i.towing_voucher_id
                     LIMIT 0,1),
					CONCAT(i.invoice_number, ".pdf")) AS filename                
		FROM 	T_INVOICES i
		WHERE 	i.id = p_invoice_id
				AND i.company_id = v_company_id
		LIMIT	0,1;    
    END IF;
END $$

CREATE PROCEDURE R_INVOICE_FETCH_COMPANY_INVOICE_CUSTOMER(IN p_invoice_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);
    DECLARE v_login VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT ic.id, customer_number, company_name, company_vat, first_name, last_name, street, street_number, street_pobox, zip, city, country
        FROM T_INVOICE_CUSTOMERS ic, T_INVOICES i
        WHERE
			ic.id = i.invoice_customer_id
            AND i.id = p_invoice_id
            AND i.company_id = v_company_id
            AND dd IS NULL
		LIMIT 0,1;
    END IF;
END $$

CREATE PROCEDURE R_INVOICE_FETCH_COMPANY_INVOICE_LINES(IN p_invoice_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);
    DECLARE v_login VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	il.*
		FROM 	T_INVOICES i, T_INVOICE_LINES il
		WHERE 	i.id = p_invoice_id
				AND i.company_id = v_company_id
				AND i.id = il.invoice_id
                AND il.dd IS NULL
		ORDER	BY item;    
    END IF;
END $$

CREATE PROCEDURE R_INVOICE_FETCH_COMPANY_INVOICES(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);
    DECLARE v_login VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	i.id as invoice_id, 
				UNIX_TIMESTAMP(invoice_date) AS invoice_date,
				i.invoice_number,
                concat(IF(i.invoice_type='CN', 'CN', 'F'), LEFT(i.invoice_number, 4), '/', SUBSTRING(i.invoice_number,5)) as invoice_number_display,
                i.invoice_type,
                i.document_id,
                i.invoice_ref_id,
				tv.voucher_number,
				ic.company_name,
				ic.company_vat,
				ic.first_name,
				ic.last_name,
				ic.street,
				ic.street_number,
				ic.street_pobox,
				ic.zip,
				ic.city,
				ic.country
		FROM 	T_INVOICES i
				LEFT JOIN T_INVOICE_CUSTOMERS ic ON i.invoice_customer_id = ic.id
				LEFT JOIN T_TOWING_VOUCHERS tv ON i.towing_voucher_id = tv.id
                LEFT JOIN T_DOSSIERS d ON tv.dossier_id = d.id
		WHERE 	i.company_id = v_company_id
		ORDER 	BY invoice_number DESC
        LIMIT	0,1000;
	END IF;
END $$

CREATE PROCEDURE R_INVOICE_FETCH_BATCH_INVOICE_CUSTOMER(IN p_invoice_id BIGINT, IN p_batch_id VARCHAR(36))
BEGIN
	SELECT	ic.id, ic.customer_number, ic.company_id, 
			ic.company_name, ic.company_vat, 
            ic.first_name, ic.last_name,
            ic.street, ic.street_number, ic.street_pobox, ic.zip, ic.city, ic.country
    FROM	T_INVOICES i, T_INVOICE_CUSTOMERS ic
    WHERE	i.id = p_invoice_id
			AND i.invoice_customer_id = ic.id
            AND invoice_batch_run_id = p_batch_id
	LIMIT 	0,1;
END $$

CREATE PROCEDURE R_INVOICE_FETCH_BATCH_INVOICE_LINES(IN p_invoice_id BIGINT, IN p_batch_id VARCHAR(36))
BEGIN
	SELECT 	il.*
    FROM 	T_INVOICES i, T_INVOICE_LINES il
    WHERE 	i.id = il.invoice_id
			AND i.id = p_invoice_id
            AND invoice_batch_run_id = p_batch_id
            AND il.dd IS NULL;
END $$

CREATE PROCEDURE R_INVOICE_FETCH_ALL_BATCH_RUNS(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);
    DECLARE v_login VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT	id, company_id, 
				UNIX_TIMESTAMP(batch_started) as batch_started,
                UNIX_TIMESTAMP(batch_completed) as batch_completed,
                cd,
                cd_by
		FROM	T_INVOICE_BATCH_RUNS
        WHERE	company_id = v_company_id
        ORDER 	BY batch_started DESC;
	END IF;
END $$

CREATE PROCEDURE R_INVOICE_ATT_LINK_WITH_DOCUMENT(IN p_invoice_id BIGINT, IN p_document_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_batch_id VARCHAR(36);
    DECLARE v_login VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE 	T_INVOICES
        SET 	document_id = p_document_id
        WHERE 	id = p_invoice_id
        LIMIT 	1;
    END IF;
END $$

CREATE FUNCTION F_CREATE_INVOICE_UQ_SEQUENCE(p_company_id BIGINT, p_type VARCHAR(45)) RETURNS BIGINT
BEGIN
	DECLARE v_seq_val BIGINT;

    SELECT 	seq_val
    INTO 	v_seq_val
    FROM 	T_SEQUENCES
    WHERE 	company_id = p_company_id
			AND code=p_type
	LIMIT 	0,1;

    IF v_seq_val IS NOT NULL AND LEFT(v_seq_val, 4) = YEAR(CURDATE()) THEN
		SET v_seq_val := v_seq_val + 1;

        UPDATE T_SEQUENCES SET seq_val = v_seq_val WHERE code=p_type AND company_id = p_company_id LIMIT 1;

        RETURN v_seq_val;
	ELSE
		SET @v_id := concat(YEAR(CURDATE()), LPAD(1,6,0));

        IF v_seq_val IS NULL THEN
			INSERT INTO T_SEQUENCES(code, company_id, seq_val) VALUES(p_type, p_company_id, @v_id)
			ON DUPLICATE KEY UPDATE seq_val=@v_id:=seq_val+1;
		ELSE
			UPDATE T_SEQUENCES SET seq_val = @v_id WHERE code=p_type AND company_id = p_company_id LIMIT 1;
		END IF;

		RETURN @v_id;
    END IF;
END $$

CREATE FUNCTION F_CREATE_INVOICE_NUMBER(p_company_id BIGINT) RETURNS BIGINT
BEGIN
	RETURN F_CREATE_INVOICE_UQ_SEQUENCE(p_company_id, 'INVOICE');
END $$


CREATE FUNCTION F_CREATE_CREDIT_NUMBER(p_company_id BIGINT) RETURNS BIGINT
BEGIN
	RETURN F_CREATE_INVOICE_UQ_SEQUENCE(p_company_id, 'CN');
END $$


CREATE FUNCTION F_CREATE_STRUCTURED_REFERENCE(v_invoice_number VARCHAR(10)) RETURNS VARCHAR(20)
BEGIN
	/*RETURN CONCAT(	'+++', 
					LEFT(v_invoice_number, 2), 
					'/',  
					SUBSTRING(v_invoice_number, 3),
					'/',
					LPAD(MOD(v_invoice_number, 97), 2, 0),
					'+++');*/
                    
	RETURN CONCAT(LEFT(v_invoice_number, 4), '/', SUBSTRING(v_invoice_number, 5)) ;
END $$

CREATE FUNCTION F_CREATE_CUSTOMER_NUMBER_FOR_PRIVATE_PERSON(p_last_name VARCHAR(255)) RETURNS VARCHAR(36)
BEGIN
	DECLARE v_first_letter VARCHAR(1);
	DECLARE v_customer_number VARCHAR(36);

	IF p_last_name IS NULL OR TRIM(p_last_name) = '' THEN
		SET v_customer_number = '01999';    
	ELSE
		SET v_first_letter = LEFT(UPPER(p_last_name), 1);

		IF ASCII('A') > ASCII(v_first_letter) OR ASCII(v_first_letter) > ASCII('Z') THEN
			SET v_customer_number = '01999';
		ELSE
			SET v_customer_number = CONCAT(LPAD((ASCII(v_first_letter)-ASCII('A'))+1, 3, 0), 100);
		END IF;    
    END IF;

	RETURN v_customer_number;
END $$

CREATE FUNCTION F_CUSTOMER_NUMBER_FOR_COLLECTOR(p_collector_id BIGINT) RETURNS VARCHAR(36)
BEGIN
	DECLARE v_customer_number VARCHAR(36);

	SELECT 	customer_number
	INTO		v_customer_number
	FROM 		T_COLLECTORS
	WHERE		id = p_collector_id
	LIMIT		0,1;

	/*IF v_customer_number IS NULL OR TRIM(v_customer_number) = '' THEN
		SET v_customer_number = CONCAT(1, LPAD((ASCII('Z')-ASCII('A'))+1, 2, 0), 100);

		UPDATE 	T_COLLECTORS SET customer_number = v_customer_number
		WHERE 	id = p_collector_id
		LIMIT 	1;
	END IF;*/

	RETURN v_customer_number;
END $$


CREATE FUNCTION F_CUSTOMER_NUMBER_FOR_INSURANCE(p_insurance_id BIGINT) RETURNS VARCHAR(36)
BEGIN
	DECLARE v_customer_number VARCHAR(36);

	SELECT 	customer_number
	INTO		v_customer_number
	FROM 		T_INSURANCES
	WHERE		id = p_insurance_id
	LIMIT		0,1;

	/*IF v_customer_number IS NULL OR TRIM(v_customer_number) = '' THEN
		SET v_customer_number = CONCAT(2, LPAD((ASCII('Z')-ASCII('A'))+1, 2, 0), 100);

		UPDATE 	T_INSURANCES SET customer_number = v_customer_number
		WHERE 	id = p_insurance_id
		LIMIT 	1;
	END IF; */

	RETURN v_customer_number;
END $$

CREATE FUNCTION F_CUSTOMER_NUMBER_FOR_COMPANY(p_voucher_id BIGINT, p_company_id BIGINT) RETURNS VARCHAR(36)
BEGIN
	DECLARE v_seq_val BIGINT;

    SELECT 	seq_val
    INTO 	v_seq_val
    FROM 	T_SEQUENCES
    WHERE 	company_id = p_company_id
			AND code='INVOICE_CUSTNUM_ORG'
	LIMIT 	0,1;

    IF v_seq_val IS NOT NULL  THEN
		SET v_seq_val := v_seq_val + 1;

        UPDATE T_SEQUENCES SET seq_val = v_seq_val WHERE code='INVOICE_CUSTNUM_ORG' AND company_id = p_company_id LIMIT 1;

        RETURN v_seq_val;
	ELSE
		SET @v_id := 110000;

		INSERT INTO T_SEQUENCES(code, company_id, seq_val) VALUES('INVOICE_CUSTNUM_ORG', p_company_id, @v_id)
		ON DUPLICATE KEY UPDATE seq_val=@v_id:=seq_val+1;

		RETURN @v_id;
    END IF;
END $$

DELIMITER ;
