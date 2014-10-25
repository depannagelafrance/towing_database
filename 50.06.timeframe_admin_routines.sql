DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TIMEFRAMES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TIMEFRAME_ACTIVITIES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TIMEFRAME_ACTIVITY_FEES $$


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
		SELECT 	* 
		FROM 	P_TIMEFRAME_ACTIVITY_FEE 
		WHERE 	timeframe_id = p_timeframe_id;
	END IF;
END $$

DELIMITER ;