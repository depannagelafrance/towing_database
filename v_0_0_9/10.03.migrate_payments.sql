DELIMITER $$

DROP TABLE IF EXISTS TEMP_T_TOWING_VOUCHER_PAYMENTS $$

CREATE TABLE TEMP_T_TOWING_VOUCHER_PAYMENTS AS SELECT * FROM T_TOWING_VOUCHER_PAYMENTS $$

TRUNCATE TABLE T_TOWING_VOUCHER_PAYMENT_DETAILS $$

DROP PROCEDURE IF EXISTS R_MIGRATE_TOWING_VOUCHER_PAYMENTS $$
DROP FUNCTION IF EXISTS F_CAL_PAID $$

CREATE FUNCTION F_CAL_PAID(p_amount DOUBLE, p_paid DOUBLE) RETURNS DOUBLE
BEGIN
	IF IFNULL(p_amount,0) > IFNULL(p_paid, 0) THEN
		RETURN p_amount - p_paid;
	ELSE
		RETURN p_paid;
	END IF;
END $$


CREATE PROCEDURE R_MIGRATE_TOWING_VOUCHER_PAYMENTS()
BEGIN
	DECLARE no_rows_found BOOLEAN DEFAULT FALSE;
	DECLARE v_towing_voucher_id, v_towing_voucher_payment_id, v_collector_id, v_insurance_id BIGINT;
    DECLARE v_insurance_detail_id, v_customer_detail_id, v_collector_detail_id BIGINT;
    DECLARE v_amount_insurance, v_amount_collector, v_amount_customer, v_amount_open_customer, v_paid_in_cash, v_paid_bank, v_paid_maestro, v_paid_visa, v_paid, v_unpaid DOUBLE(10,2);
    DECLARE v_collector_custnum, v_collector_vat, v_insurance_custnum, v_customer_vat VARCHAR(45);
    DECLARE v_collector_foreign_vat BOOLEAN;
    
	DECLARE c CURSOR FOR 
						SELECT 
							tv.id AS towing_voucher_id,
							tvp.id AS towing_voucher_payment_id,
							tv.collector_id,
							tv.insurance_id,
							tvp.amount_guaranteed_by_insurance, tvp.amount_customer, tvp.paid_in_cash, tvp.paid_by_bank_deposit, tvp.paid_by_debit_card, tvp.paid_by_credit_card, tvp.cal_amount_paid, tvp.cal_amount_unpaid
						FROM T_TOWING_VOUCHERS tv, T_TOWING_VOUCHER_PAYMENTS tvp
						WHERE tv.id = tvp.towing_voucher_id;
                        
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_rows_found = TRUE;
    
    
	OPEN c;

	REPEAT
		FETCH c INTO v_towing_voucher_id, v_towing_voucher_payment_id, v_collector_id, v_insurance_id,
					 v_amount_insurance, v_amount_open_customer, 
                     v_paid_in_cash, v_paid_bank, v_paid_maestro, v_paid_visa, 
                     v_paid, v_unpaid;

		IF NOT no_rows_found 
        THEN
			IF v_insurance_custnum IS NOT NULL THEN
				SELECT 	customer_number
				INTO	v_insurance_custnum
				FROM 	T_INSURANCES
				WHERE 	id = v_insurance_id
				LIMIT 	0,1;
			ELSE
				SET v_insurance_custnum = NULL;
			END IF;
			
			IF v_collector_id IS NOT NULL THEN
				SELECT 	customer_number, vat, LEFT(UPPER(IFNULL(vat, '')), 2) != 'BE'
				INTO	v_collector_custnum, v_collector_vat, v_collector_foreign_vat
				FROM 	T_COLLECTORS
				WHERE 	id = v_collector_id
				LIMIT 	0,1;
			ELSE
				SET v_collector_custnum = null;
				SET v_collector_vat = null;
				SET v_collector_foreign_vat = false;
			END IF;
		
			SELECT 	IFNULL(company_vat, "")
			INTO 	v_customer_vat
			FROM 	T_TOWING_CUSTOMERS tc, T_TOWING_VOUCHERS tv
			WHERE	tv.id = v_towing_voucher_id
					AND tc.voucher_id = tv.id
			LIMIT	0,1;
			
            -- ---------------------------------------------------------
            -- CREATE THE DETAIL LINES FOR EVERY VOUCHER
            -- ---------------------------------------------------------
			
			INSERT INTO T_TOWING_VOUCHER_PAYMENT_DETAILS(towing_voucher_payment_id, category) VALUES(v_towing_voucher_id, 'INSURANCE');
			SET v_insurance_detail_id = LAST_INSERT_ID();
			
			INSERT INTO T_TOWING_VOUCHER_PAYMENT_DETAILS(towing_voucher_payment_id, category) VALUES(v_towing_voucher_id, 'CUSTOMER');
			SET v_customer_detail_id = LAST_INSERT_ID();
			
			INSERT INTO T_TOWING_VOUCHER_PAYMENT_DETAILS(towing_voucher_payment_id, category) VALUES(v_towing_voucher_id, 'COLLECTOR');
			SET v_collector_detail_id = LAST_INSERT_ID();
			
            -- ---------------------------------------------------------
            -- SET THE INFORMATION FOR THE INSURANCE
            -- ---------------------------------------------------------
            
			IF v_insurance_id IS NOT NULL THEN
				IF(SELECT LEFT(UPPER(IFNULL(vat, '')), 2) = 'BE'  FROM T_INSURANCES WHERE id = v_insurance_id LIMIT 0,1) THEN
					UPDATE 	T_TOWING_VOUCHER_PAYMENT_DETAILS
					SET 	foreign_vat = 0, 
							amount_excl_vat = v_amount_insurance/1.21, amount_incl_vat = v_amount_insurance,
                            amount_unpaid_excl_vat = v_amount_insurance/1.21, amount_unpaid_incl_vat = v_amount_insurance
					WHERE 	id = v_insurance_detail_id;                
				ELSE
					UPDATE 	T_TOWING_VOUCHER_PAYMENT_DETAILS
					SET 	foreign_vat = 1, 
							amount_excl_vat = v_amount_insurance, amount_incl_vat = v_amount_insurance * 1.21,
                            amount_unpaid_excl_vat = v_amount_insurance, amount_unpaid_incl_vat = v_amount_insurance * 1.21
					WHERE 	id = v_insurance_detail_id;
				END IF;
			END IF; 
			
            
            -- ---------------------------------------------------------
            -- SET THE INFORMATION FOR THE COLLECTOR
            -- ---------------------------------------------------------
			IF v_collector_id IS NOT NULL
			THEN
				IF (SELECT `type` FROM T_COLLECTORS WHERE id = v_collector_id) != 'CUSTOMER' 
					AND IFNULL(v_collector_custnum, -2) != IFNULL(v_insurance_custnum, -1)
					AND LOWER(IFNULL(v_collector_vat, "")) != LOWER(IFNULL(v_customer_vat, ""))
				THEN
					IF (SELECT 	count(ta.code)
						FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
						WHERE 	ta.code='STALLING'
								AND taf.timeframe_activity_id = ta.id
								AND tac.activity_id = taf.id
								AND tac.towing_voucher_id=v_towing_voucher_id) > 0
					THEN  
						SELECT 	tac.cal_fee_excl_vat
						INTO 	v_amount_collector
						FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
						WHERE 	ta.code='STALLING'
								AND taf.timeframe_activity_id = ta.id
								AND tac.activity_id = taf.id
								AND tac.towing_voucher_id=v_towing_voucher_id;  
                                
						IF TRIM(IFNULL(v_collector_vat, "")) = "" OR NOT v_collector_foreign_vat THEN                    
							UPDATE 	T_TOWING_VOUCHER_PAYMENT_DETAILS
							SET 	foreign_vat 			= 0, 
									amount_excl_vat 		= v_amount_collector/1.21, amount_incl_vat = v_amount_collector,
                                    amount_paid_cash 		= IF(IFNULL(v_paid_in_cash, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_in_cash), 0.0),
                                    amount_paid_bankdeposit = IF(IFNULL(v_paid_bank, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_bank), 0.0),
                                    amount_paid_maestro 	= IF(IFNULL(v_paid_maestro, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_maestro), 0.0),
                                    amount_paid_visa 		= IF(IFNULL(v_paid_visa, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_visa), 0.0)
							WHERE 	id = v_collector_detail_id;
						ELSE  
							UPDATE 	T_TOWING_VOUCHER_PAYMENT_DETAILS
							SET 	foreign_vat 			= 1, 
									amount_excl_vat 		= v_amount_collector, amount_incl_vat = v_amount_collector * 1.21,
                                    amount_paid_cash 		= IF(IFNULL(v_paid_in_cash, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_in_cash), 0.0),
                                    amount_paid_bankdeposit = IF(IFNULL(v_paid_bank, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_bank), 0.0),
                                    amount_paid_maestro 	= IF(IFNULL(v_paid_maestro, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_maestro), 0.0),
                                    amount_paid_visa 		= IF(IFNULL(v_paid_visa, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_visa), 0.0)
                                    
							WHERE 	id = v_collector_detail_id;
						
						END IF;
					END IF;
				END IF; 
-- 			ELSE
-- 				SELECT 	SUM(tac.cal_fee_excl_vat)
-- 				INTO 	v_amount_collector
-- 				FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
-- 				WHERE 	ta.code='STALLING'
-- 						AND taf.timeframe_activity_id = ta.id
-- 						AND tac.activity_id = taf.id
-- 						AND tac.towing_voucher_id=v_towing_voucher_id;  
-- 						
-- 				-- no collector know, but has STALLING maybe? No need to set payment info
-- 				UPDATE 	T_TOWING_VOUCHER_PAYMENT_DETAILS
-- 				SET 	foreign_vat 			= 0, 
-- 						amount_excl_vat 		= v_amount_collector/1.21, amount_incl_vat = v_amount_collector                 
-- 				WHERE 	id = v_collector_detail_id;
			END IF;  
			
			
            -- ---------------------------------------------------------
            -- SET THE INFORMATION FOR THE CUSTOMER
            -- ---------------------------------------------------------
			SELECT  
				   (SELECT 	SUM(tac.cal_fee_excl_vat)
					FROM 	P_TIMEFRAME_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, T_TOWING_ACTIVITIES tac
					WHERE 	1=1
							AND taf.timeframe_activity_id = ta.id
							AND tac.activity_id = taf.id
							AND tac.towing_voucher_id=v_towing_voucher_id)
					+
                    (SELECT IFNULL(SUM(fee_excl_vat), 0.0)
					 FROM	T_TOWING_ADDITIONAL_COSTS
                     WHERE  towing_voucher_id = v_towing_voucher_id)
					- 
                    (SELECT IFNULL(SUM(amount_excl_vat), 0.0) FROM T_TOWING_VOUCHER_PAYMENT_DETAILS WHERE id IN (v_collector_detail_id, v_insurance_detail_id))
			INTO v_amount_customer;
			
			UPDATE 	T_TOWING_VOUCHER_PAYMENT_DETAILS
			SET 	foreign_vat 			= IF(TRIM(IFNULL(v_customer_vat, "")) = "", 0, LEFT(UPPER(v_customer_vat), 2) != 'BE'), 
					amount_excl_vat 		= IFNULL(v_amount_customer, 0.0), amount_incl_vat = IF(v_amount_customer IS NULL, 0.0, v_amount_customer * 1.21),
					amount_paid_cash 		= IF(IFNULL(v_paid_in_cash, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_in_cash), 0.0),
					amount_paid_bankdeposit = IF(IFNULL(v_paid_bank, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_bank), 0.0),
					amount_paid_maestro 	= IF(IFNULL(v_paid_maestro, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_maestro), 0.0),
					amount_paid_visa 		= IF(IFNULL(v_paid_visa, 0) > 0, F_CAL_PAID(v_amount_collector, v_paid_visa), 0.0)
			WHERE 	id = v_customer_detail_id;   
            
            
        END IF;
	UNTIL no_rows_found END REPEAT;    
END $$

CALL R_MIGRATE_TOWING_VOUCHER_PAYMENTS $$

DROP PROCEDURE IF EXISTS R_MIGRATE_TOWING_VOUCHER_PAYMENTS $$

DELIMITER ;