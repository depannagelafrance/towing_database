DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_CREATE_USER $$
DROP PROCEDURE IF EXISTS R_FETCH_USER_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_USERS $$
DROP PROCEDURE IF EXISTS R_UNLOCK_USER $$
DROP PROCEDURE IF EXISTS R_DELETE_USER $$

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_CREATE_USER(IN p_login VARCHAR(255), IN p_firstname VARCHAR(255), IN p_lastname VARCHAR(255), IN p_email VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id INTO v_guid
		FROM 	T_USERS
		WHERE 	lower(login) = lower(p_login)
		LIMIT 	0,1;

		IF v_guid IS NULL THEN
			SET v_guid = UUID();

			INSERT INTO `T_USERS` (`id`, `company_id`, `login`, `first_name`, `last_name`, `email`, `is_active`, `is_locked`, `locked_ts`, `cd`, `cd_by`, `dd`, `dd_by`) 
			VALUES (v_guid, v_company_id, p_login, p_firstname, p_lastname, p_email, 1, 0, NULL, now(), F_RESOLVE_LOGIN(v_user_id, p_token),  NULL, NULL);

			SELECT v_guid AS id;
		ELSE
			SELECT 'LOGIN_ALREADY_EXISTS' as error, 409 as statusCode;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_USER_BY_ID(IN p_id VARCHAR(36), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id INTO v_guid
		FROM 	T_USERS
		WHERE 	id = p_id AND company_id = v_company_id;

		IF v_guid IS NULL THEN
			CALL R_NOT_AUTHORIZED;
		ELSE
			SELECT 	`id`, `login`, `first_name`, `last_name`, `email`, `is_active`, `is_locked`, `locked_ts`
			FROM 	T_USERS
			WHERE 	id = p_id 
					AND company_id = v_company_id;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_USERS(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`id`, `login`, `first_name`, `last_name`, `email`, `is_active`, `is_locked`, `locked_ts`
		FROM 	T_USERS
		WHERE 	1 = 1
				AND company_id = v_company_id
		ORDER BY last_name, first_name;
	END IF;
END $$


CREATE PROCEDURE R_UNLOCK_USER(IN p_id VARCHAR(36), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id INTO v_guid
		FROM 	T_USERS
		WHERE 	id = p_id AND company_id = v_company_id
				AND is_locked = 1;

		IF v_guid IS NULL THEN
			CALL R_NOT_AUTHORIZED;
		ELSE
			UPDATE 	T_USERS
			SET 	is_locked = 0, locked_ts = null, login_attempts=0
			WHERE 	id = v_guid AND company_id = v_company_id;

			SELECT v_guid AS id; 
		END IF;

	END IF;
END $$

CREATE PROCEDURE R_DELETE_USER(IN p_id VARCHAR(36), IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE 	T_USERS
		SET 	dd = now(), dd_by = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE 	id = p_id 
				AND company_id = v_company_id
				AND dd IS NULL
		LIMIT 	1;
	END IF;
END $$

DELIMITER ;