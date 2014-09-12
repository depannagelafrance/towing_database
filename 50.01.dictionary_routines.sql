DELIMITER $$
-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_ADD_DICTIONARY_AUDIT_LOG $$
DROP PROCEDURE IF EXISTS R_ADD_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_ADD_INSURANCE $$
DROP PROCEDURE IF EXISTS R_UPDATE_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_UPDATE_INSURANCE $$
DROP PROCEDURE IF EXISTS R_DELETE_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_DELETE_INSURANCE $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_INSURANCES $$
DROP PROCEDURE IF EXISTS R_FETCH_INSURANCE_BY_ID $$

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_ADD_DICTIONARY_AUDIT_LOG(IN p_id BIGINT)
BEGIN
	INSERT INTO P_DICTIONARY_AUDIT_LOG(id, dictionary_id, category, name, cd, cd_by, ud, ud_by, dd, dd_by)
	SELECT uuid(), id, category, name, cd, cd_by, ud, ud_by, dd, dd_by FROM P_DICTIONARY WHERE id = p_id;
END $$

CREATE PROCEDURE R_ADD_DICTIONARY(IN p_category ENUM('INSURANCE'), IN p_name VARCHAR(255), IN p_user VARCHAR(255))
BEGIN
	DECLARE v_id BIGINT;

	INSERT INTO P_DICTIONARY(category, name, cd, cd_by)
	VALUES(p_category, p_name, now(), p_user);

	SET v_id = last_insert_id();

	CALL R_ADD_DICTIONARY_AUDIT_LOG(v_id);

	SELECT * FROM P_DICTIONARY WHERE id = v_id;
END $$

CREATE PROCEDURE R_UPDATE_DICTIONARY(IN p_id BIGINT, IN p_category ENUM('INSURANCE'), IN p_name VARCHAR(255), IN p_user VARCHAR(255))
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

CREATE PROCEDURE R_DELETE_DICTIONARY(IN p_id BIGINT, IN p_user VARCHAR(255))
BEGIN
	UPDATE 	P_DICTIONARY
	SET 	dd = now(), 
			dd_by = p_user
	WHERE 	id = p_id;

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

CREATE PROCEDURE R_DELETE_INSURANCE(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		CALL R_DELETE_DICTIONARY(p_id, F_RESOLVE_LOGIN(v_user_id, p_token));
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

DELIMITER ;