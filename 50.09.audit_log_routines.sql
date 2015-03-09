DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS R_ADD_DICTIONARY_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_INSURANCE_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_USER_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_CREATE_AUDIT_LOG $$

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------

CREATE PROCEDURE R_CREATE_AUDIT_LOG(IN p_table_name VARCHAR(255), IN p_id BIGINT)
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
SELECT @sql;

		PREPARE STMT FROM @sql;
		EXECUTE STMT USING @id;
	END IF;
END $$

CREATE PROCEDURE R_ADD_DICTIONARY_AUDIT_LOG(IN p_id BIGINT)
BEGIN
	CALL R_CREATE_AUDIT_LOG('P_DICTIONARY', p_id);
END $$

CREATE PROCEDURE R_ADD_INSURANCE_AUDIT_LOG(IN p_id BIGINT)
BEGIN
	CALL R_CREATE_AUDIT_LOG('T_INSURANCES', p_id);
END $$

CREATE PROCEDURE R_ADD_USER_AUDIT_LOG(IN p_id BIGINT)
BEGIN
	CALL R_CREATE_AUDIT_LOG('T_USERS', p_id);
END $$

DELIMITER ;