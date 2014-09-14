DELIMITER $$
-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_ADD_CALENDAR_ITEM $$
DROP PROCEDURE IF EXISTS R_UPDATE_CALENDAR_ITEM $$
DROP PROCEDURE IF EXISTS R_DELETE_CALENDAR_ITEM $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_CALENDAR_ITEMS $$
DROP PROCEDURE IF EXISTS R_CALENDAR_ITEM_BY_ID $$

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_ADD_CALENDAR_ITEM(IN p_item VARCHAR(255), IN p_date DATE, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO `P_HOLIDAYS` (`year`, `name`, `holiday`, `cd`, `cd_by`) 
		VALUES (YEAR(p_date), p_item, p_date, now(), F_RESOLVE_LOGIN(v_user_id, p_token));
	
		SELECT LAST_INSERT_ID() as `id`;
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_CALENDAR_ITEM(IN p_id INT, IN p_item VARCHAR(255), IN p_date DATE, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE 	`P_HOLIDAYS` 
		SET 	`year` = YEAR(p_date), `name` = p_item, `holiday` = p_date, `ud` = now(), `ud_by`= F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE 	id = p_id
		LIMIT 	1;

		SELECT p_id as `id`;
	END IF;
END $$


CREATE PROCEDURE R_DELETE_CALENDAR_ITEM(IN p_id INT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE 	`P_HOLIDAYS` 
		SET 	`dd` = now(), `dd_by`= F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE 	id = p_id
		LIMIT 	1;

		SELECT 'ok' as result;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_CALENDAR_ITEMS(IN p_year INT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT	`id`, `year`, `name`, `holiday`
		FROM 	`P_HOLIDAYS`
		WHERE	`year` = p_year
				AND dd IS NULL
		ORDER BY `holiday`;
	END IF;
END $$

CREATE PROCEDURE R_CALENDAR_ITEM_BY_ID(IN p_id INT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT	`id`, `year`, `name`, `holiday`
		FROM 	`P_HOLIDAYS`
		WHERE 	id = p_id
		LIMIT 	1;

		CALL R_CALENDAR_ITEM_BY_ID(p_id, p_token);
	END IF;
END $$

DELIMITER ;