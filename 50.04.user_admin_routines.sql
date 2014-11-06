DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_CREATE_USER $$
DROP PROCEDURE IF EXISTS R_UPDATE_USER $$
DROP PROCEDURE IF EXISTS R_FETCH_USER_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_USERS $$
DROP PROCEDURE IF EXISTS R_UNLOCK_USER $$
DROP PROCEDURE IF EXISTS R_DELETE_USER $$
DROP PROCEDURE IF EXISTS R_PURGE_USER_ROLES $$
DROP PROCEDURE IF EXISTS R_ASSIGN_USER_ROLE $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_USER_ROLES $$
DROP PROCEDURE IF EXISTS R_FETCH_AVAILABLE_ROLES $$
DROP PROCEDURE IF EXISTS R_ASSIGN_ROLE $$
DROP PROCEDURE IF EXISTS R_REVOKE_ROLE $$
DROP PROCEDURE IF EXISTS R_FETCH_ROLES_FOR_USER $$
DROP PROCEDURE IF EXISTS R_FETCH_USER_ROLES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_ROLES $$
DROP PROCEDURE IF EXISTS R_FETCH_USER_MODULES $$
DROP PROCEDURE IF EXISTS R_FETCH_USER_COMPANY $$
DROP PROCEDURE IF EXISTS R_ADD_SIGNATURE_TO_USER_PROFILE $$

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_CREATE_USER(IN p_login VARCHAR(255), IN p_firstname VARCHAR(255), IN p_lastname VARCHAR(255), IN p_email VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid, v_pwd VARCHAR(36);

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

			SET v_pwd = SUBSTRING(MD5(RAND()) FROM 1 FOR 8);	

			INSERT INTO `T_USERS` (`id`, `company_id`, `login`, `first_name`, `last_name`, `email`, `is_active`, `is_locked`, `locked_ts`, `cd`, `cd_by`, `dd`, `dd_by`) 
			VALUES (v_guid, v_company_id, p_login, p_firstname, p_lastname, p_email, 1, 0, NULL, now(), F_RESOLVE_LOGIN(v_user_id, p_token),  NULL, NULL);

			INSERT INTO `T_USER_PASSWORDS` (user_id, pwd) VALUES (v_guid, PASSWORD(v_pwd));

			SELECT v_guid AS id, v_pwd AS generated_password;
		ELSE
			SELECT 'LOGIN_ALREADY_EXISTS' as error, 409 as statusCode;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_USER(IN p_id VARCHAR(36), IN p_firstname VARCHAR(255), IN p_lastname VARCHAR(255), IN p_email VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE `T_USERS`
		SET `first_name` = p_firstname, `last_name` = p_lastname, `email` = p_email, `ud` = now(), `ud_by` = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE `id` = p_id;

		CALL R_FETCH_USER_BY_ID(p_id, p_token);
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
				AND dd IS NULL
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

		CALL R_PURGE_USER_ROLES(p_id, p_token);

		SELECT "ok" as result;
	END IF;
END $$


CREATE PROCEDURE R_PURGE_USER_ROLES(IN p_id VARCHAR(36), IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		DELETE FROM T_USER_ROLES
		WHERE user_id = p_id
		LIMIT 100;
	END IF;
END $$

CREATE PROCEDURE R_ASSIGN_USER_ROLE(IN p_user_id VARCHAR(36), IN p_role_id INT, IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO T_USER_ROLES(user_id, role_id)
		VALUES(p_user_id, p_role_id);
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_USER_ROLES(IN p_id VARCHAR(36), IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	r.`id`, `code`, `name`
		FROM 	`P_ROLES` r, `T_USER_ROLES` ur
		WHERE 	r.`dd` IS NULL
				AND r.id = ur.role_id AND ur.user_id = p_id;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_AVAILABLE_ROLES(IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	r.id, r.code, r.name, m.name as module_name
		FROM 	P_COMPANY_MODULES cm, P_MODULES m, P_MODULE_ROLES mr, P_ROLES r
		WHERE 	cm.dd IS NULL AND r.dd IS NULL
				AND cm.module_id = m.id
				AND m.id = mr.module_id
				and mr.role_id = r.id
				AND cm.company_id = v_company_id;
	END IF;
END $$


CREATE PROCEDURE R_ASSIGN_ROLE(IN p_user_id VARCHAR(36), IN p_role_id INT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- TODO: check if user is comapny admin or admin
		-- TODO: check for company admin if user is added for correct company
		INSERT INTO `T_USER_ROLES` (`role_id`, `user_id`) VALUES (p_role_id, p_user_id);
	END IF;
END $$

CREATE PROCEDURE R_REVOKE_ROLE(IN p_user_id VARCHAR(36), IN p_role_id INT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- TODO: check if user is comapny admin or admin
		-- TODO: check for company admin if user is added for correct company
		DELETE FROM `T_USER_ROLES` WHERE (`role_id` = p_role_id AND `user_id` = p_user_id);
	END IF;
END $$


CREATE PROCEDURE R_FETCH_ROLES_FOR_USER(IN p_user_id VARCHAR(36), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	r.`id`, r.`code`, r.`name`
		FROM 	`P_ROLES` r, `T_USER_ROLES` ur
		WHERE 	dd IS NULL
				AND r.id = ur.role_id
				AND ur.user_id = p_user_id;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_USER_ROLES(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		CALL R_FETCH_ROLES_FOR_USER(v_user_id, p_token);
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_ROLES(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	r.`id`, r.`code`, r.`name`
		FROM 	`P_ROLES` r
		WHERE 	dd IS NULL;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_USER_MODULES(IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	m.code, m.name 
		FROM 	P_COMPANY_MODULES cm, P_MODULES m, P_MODULE_ROLES mr
		WHERE 	dd IS NULL
				AND cm.module_id = m.id
				AND m.id = mr.module_id
				AND (cm.company_id, mr.role_id) IN (SELECT 	company_id, ur.role_id 
													FROM 	`T_USERS` u, `T_USER_ROLES` ur 
													WHERE 	u.id =v_user_id 
															AND u.id = ur.user_id);
	END IF;
END $$

CREATE PROCEDURE R_FETCH_USER_COMPANY(IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`id`,
				`name`, `code`,
				`street`, `street_number`, `street_pobox`, `zip`, `city`,
				`phone`, `fax`, `email`, `website`, `vat`
		FROM 	`T_COMPANIES` 
		WHERE 	id = v_company_id;
	END IF;
END $$

CREATE PROCEDURE R_ADD_SIGNATURE_TO_USER_PROFILE(IN p_content_type VARCHAR(255), IN p_file_size INT,
									   IN p_content LONGTEXT,
									   IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_doc_id, v_blob_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT signature_document_id INTO v_doc_id
		FROM T_USERS WHERE id = v_user_id
		LIMIT 0,1;

		IF v_doc_id IS NULL THEN
			INSERT INTO `T_DOCUMENT_BLOB`(`content`) VALUES(p_content);

			SET v_blob_id = LAST_INSERT_ID();

			INSERT INTO `T_DOCUMENTS` (`document_blob_id`, `name`, `content_type`, `file_size`, `cd`, `cd_by`)
			VALUES (v_blob_id, 'signature_user.png', p_content_type, p_file_size, now(), F_RESOLVE_LOGIN(v_user_id, p_token));

			SET v_doc_id = LAST_INSERT_ID();

			UPDATE T_USERS SET signature_document_id = v_doc_id WHERE id = v_user_id LIMIT 1;
		ELSE
			SELECT document_blob_id INTO v_blob_id FROM T_DOCUMENTS WHERE id = v_doc_id LIMIT 0,1;

			UPDATE T_DOCUMENT_BLOB SET content = p_content WHERE id = v_blob_id;
		END IF;

		SELECT v_doc_id as attachment_id, 'OK' as result;
	END IF;
END $$


DELIMITER ;