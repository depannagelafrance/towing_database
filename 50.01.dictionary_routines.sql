DELIMITER $$
-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_ADD_DICTIONARY_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_ADD_INSURANCE $$
DROP PROCEDURE IF EXISTS R_ADD_COLLECTOR $$

DROP PROCEDURE IF EXISTS R_UPDATE_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_UPDATE_INSURANCE $$
DROP PROCEDURE IF EXISTS R_UPDATE_COLLECTOR $$ 

DROP PROCEDURE IF EXISTS R_DELETE_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_DELETE_INSURANCE $$
DROP PROCEDURE IF EXISTS R_DELETE_COLLECTOR $$

DROP PROCEDURE IF EXISTS R_FETCH_ALL_INSURANCES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_COLLECTORS $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TRAFFIC_LANES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_LICENCE_PLATE_COUNTRIES $$

DROP PROCEDURE IF EXISTS R_FETCH_INSURANCE_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_COLLECTOR_BY_ID $$

DROP PROCEDURE IF EXISTS R_CREATE_AUDIT_LOG $$

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_ADD_DICTIONARY_AUDIT_LOG(IN p_id BIGINT)
BEGIN
	CALL R_CREATE_AUDIT_LOG('P_DICTIONARY', p_id);
END $$

CREATE PROCEDURE R_ADD_DICTIONARY(IN p_category ENUM('INSURANCE', 'COLLECTOR'), IN p_name VARCHAR(255), IN p_user VARCHAR(255))
BEGIN
	DECLARE v_id BIGINT;

	INSERT INTO P_DICTIONARY(category, name, cd, cd_by)
	VALUES(p_category, p_name, now(), p_user);

	SET v_id = last_insert_id();

	CALL R_ADD_DICTIONARY_AUDIT_LOG(v_id);

	SELECT * FROM P_DICTIONARY WHERE id = v_id;
END $$

CREATE PROCEDURE R_UPDATE_DICTIONARY(IN p_id BIGINT, IN p_category ENUM('INSURANCE', 'COLLECTOR'), IN p_name VARCHAR(255), IN p_user VARCHAR(255))
BEGIN
	UPDATE 	P_DICTIONARY
	SET 	category = p_category, 
			`name` = p_name, 
			ud = now(), 
			ud_by = p_user
	WHERE 	id = p_id;

	CALL R_ADD_DICTIONARY_AUDIT_LOG(p_id);

	SELECT * FROM P_DICTIONARY WHERE id = p_id;
END $$

CREATE PROCEDURE R_DELETE_DICTIONARY(IN p_id BIGINT, IN p_category ENUM('INSURANCE', 'COLLECTOR'), IN p_user VARCHAR(255))
BEGIN
	UPDATE 	P_DICTIONARY
	SET 	dd = now(), 
			dd_by = p_user
	WHERE 	id = p_id
			AND category = p_category;

	CALL R_ADD_DICTIONARY_AUDIT_LOG(p_id);

	SELECT "OK" as result;
END $$

CREATE PROCEDURE R_ADD_INSURANCE(IN p_name VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		CALL R_ADD_DICTIONARY('INSURANCE', p_name, F_RESOLVE_LOGIN(v_user_id, p_token));
	END IF;
END $$

CREATE PROCEDURE R_ADD_COLLECTOR(IN p_name VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		CALL R_ADD_DICTIONARY('COLLECTOR', p_name, F_RESOLVE_LOGIN(v_user_id, p_token));
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_INSURANCE(IN p_id BIGINT, IN p_name VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		CALL R_UPDATE_DICTIONARY(p_id, 'INSURANCE', p_name, F_RESOLVE_LOGIN(v_user_id, p_token));
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_COLLECTOR(IN p_id BIGINT, IN p_name VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		CALL R_UPDATE_DICTIONARY(p_id, 'COLLECTOR', p_name, F_RESOLVE_LOGIN(v_user_id, p_token));
	END IF;
END $$

CREATE PROCEDURE R_DELETE_INSURANCE(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		CALL R_DELETE_DICTIONARY(p_id, 'INSURANCE', F_RESOLVE_LOGIN(v_user_id, p_token));
	END IF;
END $$

CREATE PROCEDURE R_DELETE_COLLECTOR(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		CALL R_DELETE_DICTIONARY(p_id, 'COLLECTOR', F_RESOLVE_LOGIN(v_user_id, p_token));
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_INSURANCES(IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id, `name`
		FROM 	P_DICTIONARY
		WHERE	dd IS NULL AND category = 'INSURANCE'
		ORDER BY `name`;		
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_COLLECTORS(IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id, `name`
		FROM 	P_DICTIONARY
		WHERE	dd IS NULL AND category = 'COLLECTOR'
		ORDER BY `name`;		
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_TRAFFIC_LANES(IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id, `name`
		FROM 	P_DICTIONARY
		WHERE	dd IS NULL AND category = 'TRAFFIC_LANE'
		ORDER BY `name`;		
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_LICENCE_PLATE_COUNTRIES(IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id, `name`
		FROM 	P_DICTIONARY
		WHERE	dd IS NULL AND category = 'COUNTRY_LICENCE_PLATE'
		ORDER BY `name`;		
	END IF;
END $$


CREATE PROCEDURE R_FETCH_INSURANCE_BY_ID(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`id`, `name`
		FROM 	P_DICTIONARY
		WHERE 	id = p_id
				AND category = 'INSURANCE'
				AND dd IS NULL;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_COLLECTOR_BY_ID(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`id`, `name`
		FROM 	P_DICTIONARY
		WHERE 	id = p_id
				AND category = 'COLLECTOR'
				AND dd IS NULL;
	END IF;
END $$

CREATE PROCEDURE R_CREATE_AUDIT_LOG(IN p_table_name VARCHAR(255), IN p_id BIGINT)
BEGIN
	DECLARE v_cols VARCHAR(1024);
	DECLARE v_log_table VARCHAR(1024);

	-- check if an audit log table exists
	SELECT 	table_name INTO v_log_table
	FROM 	information_schema.TABLES 
	WHERE 	table_schema = schema() 
			AND table_name=upper(concat(p_table_name, '_AUDIT_LOG'))
	LIMIT 	0,1;

	IF v_log_table IS NOT NULL THEN
		-- concat all the columns
		SELECT 		GROUP_CONCAT(concat('`', column_name, '`') SEPARATOR ', ')
		INTO 		v_cols
		FROM 		information_schema.COLUMNS 
		WHERE 		table_schema = schema()
					AND table_name = p_table_name
		GROUP BY 	table_name;

		SET @id = p_id;
		SET @log_table = CONCAT('`', v_log_table, '`');
		SET @cols = v_cols;
		SET @tbl = p_table_name;
		SET @sql = concat("INSERT INTO ", @log_table, "(", @cols, ") SELECT ", @cols, " FROM ", @tbl, " WHERE id = ?");

		PREPARE STMT FROM @sql;
		EXECUTE STMT USING @id;
	END IF;
END $$


DELIMITER ;