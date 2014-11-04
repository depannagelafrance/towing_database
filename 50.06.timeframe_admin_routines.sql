DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TIMEFRAMES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TIMEFRAME_ACTIVITIES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TIMEFRAME_ACTIVITY_FEES $$

DROP PROCEDURE IF EXISTS R_UPDATE_TIMEFRAME_ACTIVITY_FEE $$


-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_FETCH_ALL_TIMEFRAMES(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT * FROM P_TIMEFRAMES;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_TIMEFRAME_ACTIVITIES(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT * FROM P_TIMEFRAME_ACTIVITIES;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_TIMEFRAME_ACTIVITY_FEES(IN p_timeframe_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id, timeframe_id, timeframe_activity_id, 
				format(fee_excl_vat, 2) fee_excl_vat, 
				format(fee_incl_vat, 2) fee_incl_vat, 
				valid_from, valid_until 
		FROM 	P_TIMEFRAME_ACTIVITY_FEE 
		WHERE 	timeframe_id = p_timeframe_id
				AND now() BETWEEN valid_from AND valid_until;
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_TIMEFRAME_ACTIVITY_FEE(IN p_timeframe_id BIGINT, IN p_timeframe_activity_id BIGINT, IN p_fee_excl_vat DOUBLE, IN p_fee_incl_vat DOUBLE, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id INTO v_id
		FROM 	P_TIMEFRAME_ACTIVITY_FEE 
		WHERE 	id = p_timeframe_activity_id
				AND timeframe_id = p_timeframe_id;

		IF v_id IS NULL THEN
			CALL R_NOT_FOUND;
		ELSE
			UPDATE P_TIMEFRAME_ACTIVITY_FEE
			SET    valid_until = now()
			WHERE id = v_id;

			INSERT INTO P_TIMEFRAME_ACTIVITY_FEE(timeframe_id, timeframe_activity_id, fee_excl_vat, fee_incl_vat, valid_from, valid_until)
			SELECT 	p_timeframe_id, timeframe_activity_id, p_fee_excl_vat, p_fee_incl_vat, now(), '2099-12-31' 
			FROM 	P_TIMEFRAME_ACTIVITY_FEE 
			WHERE 	id = v_id;

			SELECT LAST_INSERT_ID() as id, 'OK' as result;
		END IF;
	END IF;
END $$

DELIMITER ;