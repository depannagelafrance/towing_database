DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_FETCH_ALL_VEHICLES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_VEHICLES_BY_TYPE $$
DROP PROCEDURE IF EXISTS R_FETCH_VEHICLE_BY_ID $$

DROP PROCEDURE IF EXISTS R_CREATE_VEHICLE $$
DROP PROCEDURE IF EXISTS R_UPDATE_VEHICLE $$
DROP PROCEDURE IF EXISTS R_DELETE_VEHICLE $$



-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_FETCH_ALL_VEHICLES(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	*
		FROM 	T_COMPANY_VEHICLES
		WHERE 	company_id = v_company_id
				AND dd IS NULL
		ORDER BY type, name;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_VEHICLES_BY_TYPE(IN p_type ENUM('SIGNA', 'TOWING'), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		IF p_type = 'SIGNA' THEN
			SELECT 	id, `name`, licence_plate, `type`
			FROM 	T_COMPANY_VEHICLES
			WHERE 	company_id = v_company_id 
					AND dd IS NULL
					AND `type` = 'SIGNA'
			ORDER BY `name`;
		ELSE
			SELECT 	id, `name`, licence_plate, `type`
			FROM 	T_COMPANY_VEHICLES
			WHERE 	company_id = v_company_id 
					AND dd IS NULL
					AND `type` != 'SIGNA'
			ORDER BY `name`;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_VEHICLE_BY_ID(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	*
		FROM 	T_COMPANY_VEHICLES
		WHERE 	company_id = v_company_id
				AND id = p_id;
	END IF;
END $$


CREATE PROCEDURE R_CREATE_VEHICLE(IN p_name VARCHAR(255), IN p_licence_plate VARCHAR(45), IN p_type VARCHAR(10), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO T_COMPANY_VEHICLES(company_id, name, licence_plate, type, cd, cd_by)
		VALUES(v_company_id, p_name, p_licence_plate, p_type, now(), F_RESOLVE_LOGIN(v_user_id, p_token));

		CALL R_FETCH_VEHICLE_BY_ID(LAST_INSERT_ID(), p_token);
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_VEHICLE(IN p_id BIGINT, IN p_name VARCHAR(255), IN p_licence_plate VARCHAR(45), IN p_type VARCHAR(10), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE T_COMPANY_VEHICLES SET 
			name = p_name, 
			licence_plate = p_licence_plate,
			type = p_type,
			ud = now(),
			ud_by = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE
			id = p_id
			AND company_id = v_company_id
		LIMIT 1;

		CALL R_FETCH_VEHICLE_BY_ID(p_id, p_token);
	END IF;
END $$

CREATE PROCEDURE R_DELETE_VEHICLE(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE T_COMPANY_VEHICLES SET 
			dd = now(), 
			dd_by = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE
			id = p_id
			AND company_id = v_company_id
		LIMIT 1;		
	END IF;
END $$


DELIMITER ;