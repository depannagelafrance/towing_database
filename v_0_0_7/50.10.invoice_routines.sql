SET GLOBAL event_scheduler = ON;
SET @@global.event_scheduler = ON;
SET GLOBAL event_scheduler = 1;
SET @@global.event_scheduler = 1;

DELIMITER $$

DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_BATCH $$
DROP PROCEDURE IF EXISTS R_INVOICE_START_BATCH $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_FOR_VOUCHER $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_PARTIAL_INSURANCE $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_PARTIAL_COLLECTOR $$
DROP PROCEDURE IF EXISTS R_INVOICE_CREATE_PARTIAL_CUSTOMER $$

DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_BATCH_INVOICES $$
DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_BATCH_INVOICE_CUSTOMER $$
DROP PROCEDURE IF EXISTS R_INVOICE_FETCH_BATCH_INVOICE_LINES $$

DROP FUNCTION IF EXISTS F_CREATE_INVOICE_NUMBER $$
DROP FUNCTION IF EXISTS F_CREATE_STRUCTURED_REFERENCE $$
DROP FUNCTION IF EXISTS F_CREATE_CUSTOMER_NUMBER_FOR_PRIVATE_PERSON $$
DROP FUNCTION IF EXISTS F_CUSTOMER_NUMBER_FOR_COLLECTOR $$
DROP FUNCTION IF EXISTS F_CUSTOMER_NUMBER_FOR_INSURANCE $$
DROP FUNCTION IF EXISTS F_CUSTOMER_NUMBER_FOR_COMPANY $$

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
        INSERT INTO T_INVOICE_BATCH_RUNS(id, batch_started, cd, cd_by)
        VALUES(v_batch_id, now(), now(), v_login);
--
--         UPDATE 	T_TOWING_VOUCHERS tv
--         SET 	invoice_batch_run_id = v_batch_id, ud = now(), ud_by = v_login
--         WHERE	tv.id IN (
-- 					SELECT * FROM (
-- 						SELECT 	tv2.id
-- 						FROM 	T_TOWING_VOUCHERS tv2, T_DOSSIERS d
--                         WHERE 	tv2.dossier_id = d.id
-- 								AND company_id = v_company_id
--                                 AND tv2.status = 'READY FOR INVOICE'
--                                 AND invoice_batch_run_id IS NULL
-- 						ORDER BY tv2.ud ASC) t)
-- 				AND tv.status='READY FOR INVOICE'
--         LIMIT 250;

		UPDATE T_TOWING_VOUCHERS tv
        SET invoice_batch_run_id = v_batch_id, ud = now(), ud_by = v_login
        WHERE tv.status='READY FOR INVOICE'
        LIMIT 250;

        SELECT v_batch_id AS invoice_batch_id;
	END IF;
END $$


-- ------------------------------------------------------------------------------------------
-- START PROCESSING VOUCHERS
-- ------------------------------------------------------------------------------------------
CREATE PROCEDURE R_INVOICE_START_BATCH(IN p_batch_id VARCHAR(36))
BEGIN
	DECLARE v_voucher_id BIGINT DEFAULT NULL;

	DECLARE no_rows_found BOOLEAN DEFAULT FALSE;

	DECLARE c CURSOR FOR 	SELECT 	id
												FROM 	T_TOWING_VOUCHERS
												WHERE 	invoice_batch_run_id = p_batch_id;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_rows_found = TRUE;

	OPEN c;
		
	read_loop: LOOP
		FETCH c INTO v_voucher_id;
        
		IF no_rows_found THEN
		  LEAVE read_loop;
		END IF;
        
        SELECT CONCAT('Processing voucher: ', v_voucher_id);
        
        CALL R_INVOICE_CREATE_FOR_VOUCHER(v_voucher_id, p_batch_id);
	END LOOP;    
END $$


-- ------------------------------------------------------------------------------------------
-- CREATE THE INVOICE FOR A VOUCHER
-- ------------------------------------------------------------------------------------------
CREATE PROCEDURE R_INVOICE_CREATE_FOR_VOUCHER(IN p_voucher_id BIGINT, IN p_batch_id VARCHAR(36))
BEGIN
	DECLARE v_has_insurance, v_has_collector BOOL;
    DECLARE v_insurance_id, v_collector_id BIGINT;
	DECLARE v_assurance_warranty, v_amount_customer DOUBLE(5,2);
    
    SELECT 	(insurance_id IS NOT NULL), insurance_id, (collector_id IS NOT NULL), collector_id
    INTO 	v_has_insurance, v_insurance_id, v_has_collector, v_collector_id
    FROM 	T_TOWING_VOUCHERS
    WHERE 	id = p_voucher_id
    LIMIT 	0,1;

	SELECT 	amount_guaranteed_by_insurance, amount_customer
	INTO	v_assurance_warranty, v_amount_customer
	FROM 	T_TOWING_VOUCHER_PAYMENTS
	WHERE 	towing_voucher_id = p_voucher_id;

    IF v_has_insurance 
    THEN
        CALL R_INVOICE_CREATE_PARTIAL_INSURANCE(p_voucher_id, v_insurance_id, p_batch_id);
    END IF;

    IF v_has_collector THEN
		-- IF THE COLLECTOR IS NOT THE CLIENT, ADD THE STORAGE COSTS TO THE CLIENT'S BILL
		IF (SELECT `type` FROM T_COLLECTORS WHERE id = v_collector_id) != 'CUSTOMER' 
        THEN
			IF (SELECT 	count(ta.code)
				FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
				WHERE 	ta.code='STALLING'
						AND taf.timeframe_activity_id = ta.id
						AND tac.activity_id = taf.id
						AND tac.towing_voucher_id=p_voucher_id) > 0
			THEN
				CALL R_INVOICE_CREATE_PARTIAL_COLLECTOR(p_voucher_id, v_collector_id, p_batch_id);
			END IF;
        END IF;
    END IF;

	-- CREATE AN INVOICE FOR THE CUSTOMER UNDER FOLLOWING CONDITIONS:
	-- (a) THERE IS NO INSURANCE INVOLVED
	-- (b) INSURANCE WAS INVOLVED, AND THERE IS A PART TO PAY BY THE CUSTOMER
	IF NOT v_has_insurance OR (v_has_insurance AND v_amount_customer IS NOT NULL AND v_amount_customer > 0) 
    THEN
		CALL R_INVOICE_CREATE_PARTIAL_CUSTOMER(p_voucher_id, p_batch_id);
	END IF;
END $$


-- ------------------------------------------------------------------------------------------
-- CREATE THE INVOICE FOR AN INSURANCE COMPANY
-- ------------------------------------------------------------------------------------------
CREATE PROCEDURE R_INVOICE_CREATE_PARTIAL_INSURANCE(IN p_voucher_id BIGINT, IN p_insurance_id BIGINT, IN p_batch_id VARCHAR(36))
BEGIN
	DECLARE v_foreign_vat  BOOL;
	DECLARE v_customer_number, v_company_vat, v_street_number, v_street_pobox, v_zip, v_insurance_dossier_nr  VARCHAR(45);
	DECLARE v_company_name, v_street, v_city, v_country VARCHAR(255);
	DECLARE	v_company_id, v_invoice_customer_id, v_invoice_id, v_voucher_number, v_invoice_number BIGINT;
	DECLARE v_amount, v_amount_excl_vat, v_amount_incl_vat, v_vat DOUBLE(5,2);

	SET v_vat = 0.21;

    -- FETCH THE INSURANCE COMPANY INFORMATION FOR THE VOUCHER
	SET v_customer_number = F_CUSTOMER_NUMBER_FOR_INSURANCE(p_insurance_id);

	SELECT 	i.name, i.vat, i.street, i.street_number, i.street_pobox, i.zip, i.city, 
			IF(i.vat IS NULL, 0,  UPPER(LEFT(i.vat, 2)) != 'BE'),
			d.company_id,
			tv.voucher_number,
            tv.insurance_dossiernr
	INTO 	v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, 
			v_foreign_vat, 
            v_company_id,
            v_voucher_number,
            v_insurance_dossier_nr
    FROM 	T_INSURANCES i, T_TOWING_VOUCHERS tv, T_DOSSIERS d
    WHERE tv.id = p_voucher_id
			AND tv.dossier_id = d.id
			AND tv.insurance_id = i.id
			AND i.id = p_insurance_id;

	-- SELECT THE PAYMENT INFORMATION FOR THE INSURANCE PART
    SELECT 	amount_guaranteed_by_insurance
    INTO	v_amount
    FROM 	T_TOWING_VOUCHER_PAYMENTS
    WHERE 	towing_voucher_id = p_voucher_id
    LIMIT 	0,1;

    IF v_foreign_vat THEN
		SET v_amount_excl_vat = v_amount;
        SET v_amount_incl_vat = v_amount;
	ELSE
		SET v_amount_excl_vat = v_amount / (1 + v_vat);
        SET v_amount_incl_vat = v_amount;
    END IF;


    -- CREATE A NEW INVOICE CUSTOMER
    INSERT INTO T_INVOICE_CUSTOMERS(customer_number, company_id, company_name, company_vat, street, street_number, street_pobox, zip, city, country)
    VALUES(v_customer_number, v_company_id, v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country);

    SET v_invoice_customer_id = LAST_INSERT_ID();

	SET v_invoice_number = F_CREATE_INVOICE_NUMBER(v_company_id);
    -- CREATE A NEW INVOICE
    INSERT INTO T_INVOICES(company_id, towing_voucher_id, invoice_batch_run_id,
						   invoice_customer_id, invoice_date, invoice_number, invoice_structured_reference,
						   vat_foreign_country,
						   invoice_total_excl_vat, invoice_total_incl_vat,
						   invoice_total_vat,
						   invoice_vat_percentage)
    VALUES(v_company_id, p_voucher_id, p_batch_id,
		   v_invoice_customer_id, CURDATE(), v_invoice_number, F_CREATE_STRUCTURED_REFERENCE(v_invoice_number),
           v_foreign_vat,
           v_amount_excl_vat, v_amount_incl_vat,
           v_amount_incl_vat - v_amount_excl_vat,
           IF(v_foreign_vat, 0.0, v_vat));

	SET v_invoice_id = LAST_INSERT_ID();

    -- CREATE THE INVOICE LINES FOR THE CREATE INVOICE
    INSERT INTO T_INVOICE_LINES(invoice_id,
								item, item_amount, item_price_excl_vat, item_price_incl_vat,
								item_total_excl_vat, item_total_incl_vat)
    VALUES(v_invoice_id,
		   CONCAT('Waarborg takelbon B', v_voucher_number, ' - Dossier: ', IFNULL(v_insurance_dossier_nr, 'N/A')), 1, v_amount_excl_vat, v_amount_incl_vat,
           v_amount_excl_vat, v_amount_incl_vat);
END $$


-- ------------------------------------------------------------------------------------------
-- CREATE THE INVOICE FOR A COLLECTOR
-- ------------------------------------------------------------------------------------------
CREATE PROCEDURE R_INVOICE_CREATE_PARTIAL_COLLECTOR(IN p_voucher_id BIGINT, IN p_collector_id BIGINT, IN p_batch_id VARCHAR(36))
BEGIN
	DECLARE v_foreign_vat  BOOL;
	DECLARE v_customer_number, v_company_vat, v_street_number, v_street_pobox, v_zip  VARCHAR(45);
    DECLARE v_company_name, v_street, v_city, v_country VARCHAR(255);
    DECLARE	v_company_id, v_invoice_customer_id, v_invoice_id, v_voucher_number, v_invoice_number BIGINT;
    DECLARE v_amount, v_amount_excl_vat, v_amount_incl_vat, v_vat, v_item_excl_vat, v_item_incl_vat DOUBLE(5,2);

    SET v_vat = 0.21;

    SELECT 	tac.amount, tac.cal_fee_excl_vat, tac.cal_fee_incl_vat, taf.fee_excl_vat, taf.fee_incl_vat
    INTO 	v_amount, v_amount_excl_vat, v_amount_incl_vat, v_item_excl_vat, v_item_incl_vat
		FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
		WHERE 	ta.code='STALLING'
				AND taf.timeframe_activity_id = ta.id
				AND tac.activity_id = taf.id
				AND tac.towing_voucher_id=p_voucher_id;

    -- ONLY IF STALLING COST WAS APPLIED
    IF v_amount IS NOT NULL AND v_amount > 0 AND v_amount_excl_vat IS NOT NULL AND v_amount_incl_vat IS NOT NULL
    THEN
		SET v_customer_number = F_CUSTOMER_NUMBER_FOR_COLLECTOR(p_collector_id);

		-- FETCH THE INSURANCE COMPANY INFORMATION FOR THE VOUCHER
		SELECT c.name, c.vat, c.street, c.street_number, c.street_pobox, c.zip, c.city, c.country,
			   IF(c.vat IS NULL, 0,  UPPER(LEFT(c.vat, 2)) != 'BE'),
			   d.company_id,
			   tv.voucher_number
		INTO   v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country,
			   v_foreign_vat,
			   v_company_id,
			   v_voucher_number
		FROM   T_COLLECTORS c, T_TOWING_VOUCHERS tv, T_DOSSIERS d
		WHERE  tv.id = p_voucher_id
				AND tv.dossier_id = d.id
				AND tv.collector_id = c.id
				AND c.id = p_collector_id;

		-- CREATE A NEW INVOICE CUSTOMER
		INSERT INTO T_INVOICE_CUSTOMERS(customer_number, company_id, company_name, company_vat, street, street_number, street_pobox, zip, city, country)
		VALUES(v_customer_number, v_company_id, v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country);

		SET v_invoice_customer_id = LAST_INSERT_ID();
		SET v_invoice_number = F_CREATE_INVOICE_NUMBER(v_company_id);
        
		-- CREATE A NEW INVOICE
		INSERT INTO T_INVOICES(company_id, towing_voucher_id,
							   invoice_batch_run_id,
							   invoice_customer_id, invoice_date, invoice_number, invoice_structured_reference,
							   vat_foreign_country,
							   invoice_total_excl_vat, invoice_total_incl_vat,
							   invoice_total_vat,
							   invoice_vat_percentage)
		VALUES(v_company_id, p_voucher_id,
			   p_batch_id,
			   v_invoice_customer_id, CURDATE(), v_invoice_number, F_CREATE_STRUCTURED_REFERENCE(v_invoice_number),
			   v_foreign_vat,
			   v_amount_excl_vat, IF(v_foreign_vat, v_amount_excl_vat, v_amount_incl_vat),
			   IF(v_foreign_vat, v_amount_excl_vat, v_amount_incl_vat) - v_amount_excl_vat,
			   IF(v_foreign_vat, 0.0, v_vat));

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

-- ------------------------------------------------------------------------------------------
-- CREATE THE INVOICE FOR A CUSTOMER
-- ------------------------------------------------------------------------------------------
CREATE PROCEDURE R_INVOICE_CREATE_PARTIAL_CUSTOMER(IN p_voucher_id BIGINT, IN p_batch_id VARCHAR(36))
BEGIN
	DECLARE v_foreign_vat  BOOL;
	DECLARE v_customer_number, v_company_vat, v_street_number, v_street_pobox, v_zip, v_insurance_dossier_nr  VARCHAR(45);
	DECLARE v_company_name, v_street, v_city, v_country, v_first_name, v_last_name VARCHAR(255);
	DECLARE	v_company_id, v_invoice_customer_id, v_invoice_id, v_collector_id, v_insurance_id, v_voucher_number, v_invoice_number BIGINT;
	DECLARE v_amount, v_amount_excl_vat, v_amount_incl_vat, v_vat, v_item_excl_vat, v_item_incl_vat DOUBLE(5,2);
    DECLARE	v_invoice_total_excl_vat, v_invoice_total_incl_vat DOUBLE(5,2);

	SET v_vat = 0.21;

	-- FETCH THE INSURANCE COMPANY INFORMATION FOR THE VOUCHER
	SELECT 	IF(c.company_name IS NULL OR TRIM(c.company_name) = '', 
			F_CREATE_CUSTOMER_NUMBER_FOR_PRIVATE_PERSON(c.last_name), 
			F_CUSTOMER_NUMBER_FOR_COMPANY(p_voucher_id)),
			c.first_name, c.last_name, c.company_name, c.company_vat, c.street, c.street_number, c.street_pobox, c.zip, c.city, c.country,
			IF(c.company_vat IS NULL OR TRIM(c.company_vat) = '', 0,  UPPER(LEFT(c.company_vat, 2)) != 'BE'),
			d.company_id,
			tv.voucher_number,
            tv.collector_id,
            tv.insurance_id,
            tv.insurance_dossiernr
	INTO 	v_customer_number,
			v_first_name, v_last_name, v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country,
			v_foreign_vat,
			v_company_id,
			v_voucher_number,
            v_collector_id,
            v_insurance_id,
            v_insurance_dossier_nr
	FROM 	T_TOWING_CUSTOMERS c, T_TOWING_VOUCHERS tv, T_DOSSIERS d
	WHERE 	tv.id = p_voucher_id
			AND tv.dossier_id = d.id
			AND tv.id = c.voucher_id;

	-- CREATE A NEW INVOICE CUSTOMER
	INSERT INTO T_INVOICE_CUSTOMERS(customer_number, company_id, company_name, first_name, last_name, company_vat, street, street_number, street_pobox, zip, city, country)
	VALUES(v_customer_number, v_company_id, v_company_name, v_first_name, v_last_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country);

	SET v_invoice_customer_id = LAST_INSERT_ID();
    SET v_invoice_number = F_CREATE_INVOICE_NUMBER(v_company_id);

	-- CREATE A NEW INVOICE
	INSERT INTO T_INVOICES(company_id, towing_voucher_id,
						   invoice_batch_run_id,
						   invoice_customer_id, invoice_date, invoice_number, invoice_structured_reference,
						   vat_foreign_country,
						   invoice_total_excl_vat, invoice_total_incl_vat,
						   invoice_total_vat,
						   invoice_vat_percentage)
	VALUES(v_company_id, p_voucher_id,
		   p_batch_id,
		   v_invoice_customer_id, CURDATE(), v_invoice_number, F_CREATE_STRUCTURED_REFERENCE(v_invoice_number),
		   v_foreign_vat,
		   0.0, 0.0,
		   0.0,
		   IF(v_foreign_vat, 0, v_vat));

	SET v_invoice_id = LAST_INSERT_ID();


	-- CHECK IF THE COLLECTOR WAS SET, AND IF THE COLLECTOR IS OF TYPE 'CUSTOMER'
	IF v_collector_id IS NULL OR (v_collector_id IS NOT NULL AND (SELECT `type` FROM T_COLLECTORS WHERE id = v_collector_id) = 'CUSTOMER') THEN
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
				AND tac.towing_voucher_id=p_voucher_id;    
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
				AND tac.towing_voucher_id=p_voucher_id;    
    END IF;
    
    IF v_insurance_id IS NOT NULL THEN
        SELECT 	amount_guaranteed_by_insurance
		INTO	v_amount
		FROM 	T_TOWING_VOUCHER_PAYMENTS
		WHERE 	towing_voucher_id = p_voucher_id
		LIMIT 	0,1;

		IF v_foreign_vat THEN
			SET v_amount_excl_vat = v_amount;
			SET v_amount_incl_vat = v_amount;
		ELSE
			SET v_amount_excl_vat = v_amount / (1 + v_vat);
			SET v_amount_incl_vat = v_amount;
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
    SELECT 	SUM(il.item_total_excl_vat), SUM(il.item_total_incl_vat)
    INTO	v_invoice_total_excl_vat, v_invoice_total_incl_vat
    FROM 	T_INVOICE_LINES il
    WHERE 	il.invoice_id = v_invoice_id;
    
	UPDATE 	T_INVOICES i
	SET 	i.invoice_total_excl_vat 	= v_invoice_total_excl_vat, 
			i.invoice_total_incl_vat 	= v_invoice_total_incl_vat,
			i.invoice_total_vat			= v_invoice_total_incl_vat - v_invoice_total_excl_vat
	WHERE 	i.id = v_invoice_id;
END $$


CREATE PROCEDURE R_INVOICE_FETCH_BATCH_INVOICES(IN p_batch_id VARCHAR(36))
BEGIN
	SELECT 	i.id, i.company_id, i.invoice_customer_id, i.invoice_batch_run_id, i.towing_voucher_id,
			UNIX_TIMESTAMP(i.invoice_date) as invoice_date,
            i.invoice_number, concat(LEFT(i.invoice_number, 4), '/', SUBSTRING(i.invoice_number,5)) as invoice_number_display,
            i.invoice_structured_reference,
            i.vat_foreign_country,
            i.invoice_total_excl_vat, i.invoice_total_incl_vat,
            i.invoice_total_vat, i.invoice_vat_percentage,
            concat('B', tv.voucher_number) as voucher_number
    FROM 	T_INVOICES i, T_TOWING_VOUCHERS tv
    WHERE 	i.invoice_batch_run_id = p_batch_id
			AND tv.id = i.towing_voucher_id;
END $$

CREATE PROCEDURE R_INVOICE_FETCH_BATCH_INVOICE_CUSTOMER(IN p_invoice_id BIGINT, IN p_batch_id VARCHAR(36))
BEGIN
	SELECT	ic.*
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
            AND invoice_batch_run_id = p_batch_id;
END $$

CREATE FUNCTION F_CREATE_INVOICE_NUMBER(p_company_id BIGINT) RETURNS BIGINT
BEGIN
	DECLARE v_seq_val BIGINT;

    SELECT 	seq_val
    INTO 	v_seq_val
    FROM 	T_SEQUENCES
    WHERE 	company_id = p_company_id
			AND code='INVOICE'
	LIMIT 	0,1;

    IF v_seq_val IS NOT NULL AND LEFT(v_seq_val, 4) = YEAR(CURDATE()) THEN
		SET v_seq_val := v_seq_val + 1;

        UPDATE T_SEQUENCES SET seq_val = v_seq_val WHERE code='INVOICE' AND company_id = p_company_id LIMIT 1;

        RETURN v_seq_val;
	ELSE
		SET @v_id := concat(YEAR(CURDATE()), LPAD(1,6,0));

        IF v_seq_val IS NULL THEN
			INSERT INTO T_SEQUENCES(code, company_id, seq_val) VALUES('INVOICE', p_company_id, @v_id)
			ON DUPLICATE KEY UPDATE seq_val=@v_id:=seq_val+1;
		ELSE
			UPDATE T_SEQUENCES SET seq_val = @v_id WHERE code='INVOICE' AND company_id = p_company_id LIMIT 1;
		END IF;

		RETURN @v_id;
    END IF;
END $$

CREATE FUNCTION F_CREATE_STRUCTURED_REFERENCE(v_invoice_number VARCHAR(10)) RETURNS VARCHAR(20)
BEGIN
	RETURN CONCAT(	'+++', 
					LEFT(v_invoice_number, 2), 
					'/',  
					SUBSTRING(v_invoice_number, 3),
					'/',
					LPAD(MOD(v_invoice_number, 97), 2, 0),
					'+++');
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

	IF v_customer_number IS NULL OR TRIM(v_customer_number) = '' THEN
		SET v_customer_number = CONCAT(1, LPAD((ASCII('Z')-ASCII('A'))+1, 2, 0), 100);

		UPDATE 	T_COLLECTORS SET customer_number = v_customer_number
		WHERE 	id = p_collector_id
		LIMIT 	1;
	END IF;

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

	IF v_customer_number IS NULL OR TRIM(v_customer_number) = '' THEN
		SET v_customer_number = CONCAT(2, LPAD((ASCII('Z')-ASCII('A'))+1, 2, 0), 100);

		UPDATE 	T_INSURANCES SET customer_number = v_customer_number
		WHERE 	id = p_insurance_id
		LIMIT 	1;
	END IF;

	RETURN v_customer_number;
END $$

CREATE FUNCTION F_CUSTOMER_NUMBER_FOR_COMPANY(p_voucher_id BIGINT) RETURNS VARCHAR(36)
BEGIN
	RETURN CONCAT('V', p_voucher_id);
END $$

DELIMITER ;
