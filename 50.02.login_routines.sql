DELIMITER $$
-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_LOGIN $$
DROP PROCEDURE IF EXISTS R_LOGIN_TOKEN $$
DROP PROCEDURE IF EXISTS R_RESOLVE_ACCOUNT_INFO $$

DROP PROCEDURE IF EXISTS R_NOT_AUTHORIZED $$
DROP PROCEDURE IF EXISTS R_NOT_FOUND $$

DROP FUNCTION IF EXISTS F_RESOLVE_LOGIN $$
-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_NOT_AUTHORIZED()
BEGIN
	SELECT 'NOT_AUTHORIZED' as error, 403 as statusCode;
END $$

CREATE PROCEDURE R_NOT_FOUND()
BEGIN
	SELECT 'NOT_FOUND' as error, 404 as statusCode;
END $$

CREATE PROCEDURE R_RESOLVE_ACCOUNT_INFO(IN p_token VARCHAR(255), OUT o_user_id VARCHAR(36), OUT o_company_id BIGINT)
BEGIN
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_company_id BIGINT;

	SELECT 	u.id, c.id
	INTO 	v_user_id, v_company_id
	FROM 	T_USER_TOKENS ut, T_USERS u, T_COMPANIES c
	WHERE	`token` = p_token
			AND ut.user_id = u.id
			AND u.company_id = c.id
	LIMIT 0,1;

	IF v_user_id IS NOT NULL AND v_company_id IS NOT NULL THEN
		SET o_user_id = v_user_id;
		SET o_company_id = v_company_id;
	END IF;
END $$

CREATE FUNCTION F_RESOLVE_LOGIN(p_user_id VARCHAR(36), p_token VARCHAR(255)) RETURNS VARCHAR(255)
BEGIN
	DECLARE v_login VARCHAR(255);

	SELECT 	login INTO v_login
	FROM 	T_USERS u, T_USER_TOKENS ut
	WHERE 	u.id = p_user_id
			AND u.id = ut.user_id
			AND ut.token = p_token;

	RETURN v_login;
END $$

CREATE PROCEDURE R_LOGIN(IN p_login VARCHAR(255), IN p_pwd VARCHAR(255))
BEGIN
	DECLARE v_id 		BIGINT;
	DECLARE v_token 	VARCHAR(255);
	DECLARE v_is_locked, v_login_attempts TINYINT;

	-- check if account is locked
	SELECT 	`id` INTO v_id
	FROM 	T_USERS u
	WHERE	lower(u.login) = lower(p_login)
			AND is_locked = 1;

	IF v_id IS NOT NULL THEN
		SELECT 'ACCOUNT_LOCKED' as error, 403 as statusCode;
	ELSE
		-- it is not locked, did you provide the correct pwd?
		SELECT 	u.`id`, SHA1(CONCAT(UUID(), u.id, login, now())) as `token`
		INTO	v_id, v_token
		FROM  	T_USERS u, T_USER_PASSWORDS up
		WHERE	lower(u.login) = lower(p_login)
				AND u.id = up.user_id
				AND u.is_active = 1 AND dd IS NULL
				AND up.pwd = PASSWORD(p_pwd);

		IF v_id IS NOT NULL AND v_token IS NOT NULL THEN
			SELECT 	`id` INTO v_id
			FROM 	T_USERS u
			WHERE	id = v_id
					AND is_locked = 0;

			IF v_id IS NULL THEN
				SELECT 'ACCOUNT_LOCKED' as error, 403 as statusCode;
			ELSE
				INSERT INTO `T_USER_TOKENS` (`user_id`, `token`) VALUES (v_id, v_token)
				ON DUPLICATE KEY UPDATE token = v_token;

				SELECT  `id`, `login`, `first_name`, `last_name`, v_token AS `token`
				FROM	T_USERS u
				WHERE	id = v_id;
			END IF;
		ELSE
			-- FAILED LOGIN, so update the login attempts
			SELECT 	id, IFNULL(login_attempts, 0), v_is_locked INTO v_id, v_login_attempts, v_is_locked
			FROM 	T_USERS
			WHERE 	lower(login) = lower(p_login) AND dd IS NULL
			LIMIT	0,1;

			IF v_id IS NOT NULL THEN
				UPDATE 	T_USERS
				SET 	login_attempts = v_login_attempts + 1, 
						is_locked = IF(v_login_attempts + 1 >= 5, 1, 0),
						locked_ts = IF(v_login_attempts + 1 >= 5, now(), NULL)
				WHERE	id = v_id AND dd IS NULL
				LIMIT	1; 
			END IF;

			CALL R_NOT_AUTHORIZED();
		END IF;
	END IF;


END $$

CREATE PROCEDURE R_LOGIN_TOKEN(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_id BIGINT;
	DECLARE v_token VARCHAR(255);

	SELECT 	u.`id`
	INTO	v_id
	FROM  	T_USERS u, T_USER_TOKENS ut
	WHERE	ut.token = p_token
			AND u.id = ut.user_id
			AND u.is_active = 1
	LIMIT 0,1;

	IF v_id IS NOT NULL THEN
		SELECT 	`id` INTO v_id
		FROM 	T_USERS u
		WHERE	id = v_id
				AND is_locked = 0;

		IF v_id IS NULL THEN
			SELECT 'ACCOUNT_LOCKED' as error, 403 as statusCode;
		ELSE
			SELECT 	SHA1(CONCAT(UUID(), u.id, login, now())) as `token` INTO v_token
			FROM 	T_USERS u
			WHERE   u.id = v_id;

			UPDATE T_USER_TOKENS SET token = v_token WHERE user_id = v_id LIMIT 1;

			SELECT  `id`, `login`, `first_name`, `last_name`, v_token AS `token`
			FROM	T_USERS u
			WHERE	id = v_id;
		END IF;
	ELSE
		SELECT 'NOT_AUTHORIZED' as error, 403 as statusCode;
	END IF;
END $$



DELIMITER ;