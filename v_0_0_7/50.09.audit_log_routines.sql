DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS R_ADD_DICTIONARY_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_INSURANCE_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_HOLIDAY_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_USER_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_USER_TOKEN_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_CREATE_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_COMPANY_VEHICLE_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_DOSSIER_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_TOWING_CUSTOMER_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_TOWING_CAUSER_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_TOWING_DEPOT_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_TOWING_PAYMENTS_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_TOWING_VOUCHER_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_COLLECTOR_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_TOWING_ADDITIONAL_COSTS_AUDIT_LOG $$

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------

CREATE PROCEDURE R_CREATE_AUDIT_LOG(IN p_table_name VARCHAR(255), IN p_id VARCHAR(255))
deterministic
BEGIN
	DECLARE v_cols VARCHAR(2048);
	DECLARE v_log_table VARCHAR(2048);

	-- check if an audit log table exists
	SELECT 	table_name INTO v_log_table
	FROM 	information_schema.TABLES 
	WHERE 	table_schema = 'AUDIT_P_towing_be' 
			AND table_name=upper(p_table_name)
	LIMIT 	0,1;

	IF v_log_table IS NOT NULL THEN
		-- concat all the columns
		SELECT 		GROUP_CONCAT(concat('`', column_name, '`') SEPARATOR ', ')
		INTO 		v_cols
		FROM 		information_schema.COLUMNS 
		WHERE 		table_schema = 'AUDIT_P_towing_be'
					AND table_name = p_table_name
		GROUP BY 	table_name;

		SET @id = p_id;
		SET @log_table = CONCAT('`AUDIT_P_towing_be`.`', v_log_table, '`');
		SET @cols = v_cols;
		SET @tbl = p_table_name;
		SET @sql = concat("INSERT INTO ", @log_table, "(", @cols, ") SELECT ", @cols, " FROM `", @tbl, "` WHERE `id` = ?");


		PREPARE STMT FROM @sql;
		EXECUTE STMT USING @id;
	END IF;
END $$

CREATE PROCEDURE R_ADD_DICTIONARY_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`P_DICTIONARY`
	SELECT * FROM P_DICTIONARY WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_INSURANCE_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_INSURANCES`
	SELECT * FROM T_INSURANCES WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_USER_AUDIT_LOG(IN p_id VARCHAR(255))
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_USERS`
	SELECT * FROM T_USERS WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_USER_TOKEN_AUDIT_LOG(IN p_user_id VARCHAR(36), IN p_user_token VARCHAR(255))
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_USER_TOKENS`(user_id, token)
	VALUES(p_user_id, p_user_token);
END $$

CREATE PROCEDURE R_ADD_HOLIDAY_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`P_HOLIDAYS`
	SELECT * FROM P_HOLIDAYS WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_COMPANY_VEHICLE_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_COMPANY_VEHICLES`
	SELECT * FROM T_COMPANY_VEHICLES WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_DOSSIER_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_DOSSIERS`
	SELECT * FROM T_DOSSIERS WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_TOWING_CUSTOMER_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_TOWING_CUSTOMERS`
	SELECT * FROM T_TOWING_CUSTOMERS WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_TOWING_DEPOT_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_TOWING_DEPOTS`
	SELECT * FROM T_TOWING_DEPOTS WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_TOWING_CAUSER_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_TOWING_INCIDENT_CAUSERS`
	SELECT * FROM T_TOWING_INCIDENT_CAUSERS WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_TOWING_PAYMENTS_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_TOWING_VOUCHER_PAYMENTS`
	SELECT * FROM T_TOWING_VOUCHER_PAYMENTS WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_TOWING_VOUCHER_AUDIT_LOG(IN p_id BIGINT)
deterministic
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_TOWING_VOUCHERS`
	SELECT * FROM T_TOWING_VOUCHERS WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_COLLECTOR_AUDIT_LOG(IN p_id BIGINT)
BEGIN 
	INSERT INTO `AUDIT_P_towing_be`.`T_COLLECTORS`
	SELECT * FROM T_COLLECTORS WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_TOWING_ADDITIONAL_COSTS_AUDIT_LOG(IN p_id BIGINT)
BEGIN
	INSERT INTO `AUDIT_P_towing_be`.`T_TOWING_ADDITIONAL_COSTS`
    SELECT * FROM T_TOWING_ADDITIONAL_COSTS WHERE id = p_id;
END $$


DELIMITER ;