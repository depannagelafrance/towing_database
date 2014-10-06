DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_FETCH_COMPANY_DEPOT $$

DROP FUNCTION IF EXISTS F_COMPANY_DEPOT_DISPLAY_NAME $$


-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------


CREATE PROCEDURE R_FETCH_COMPANY_DEPOT(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	*, F_COMPANY_DEPOT_DISPLAY_NAME(id) as display_name
		FROM 	T_COMPANY_DEPOTS
		WHERE 	company_id = v_company_id
		LIMIT 	0,1;
	END IF;
END $$

CREATE FUNCTION F_COMPANY_DEPOT_DISPLAY_NAME(p_id BIGINT) RETURNS VARCHAR(500)
BEGIN
	DECLARE v_name, v_street, v_street_number, v_street_pobox, v_zip, v_city VARCHAR(255);
	DECLARE v_display_name VARCHAR(500);

	SELECT 	`name`, street, street_number, street_pobox, zip, city
	INTO 	v_name, v_street, v_street_number, v_street_pobox, v_zip, v_city
	FROM 	T_COMPANY_DEPOTS
	WHERE 	id = p_id
	LIMIT 	0,1;

	IF v_name IS NOT NULL THEN
		SET v_display_name = v_name;

		SET v_display_name = trim(concat(v_display_name, ', ', IFNULL(v_street, '')));
		SET v_display_name = trim(concat(v_display_name, ' ', IFNULL(v_street_number, '')));
	
		IF v_street_pobox IS NOT NULL THEN
			SET v_display_name = trim(concat(v_display_name, '/', IFNULL(v_street_pobox, '')));
		END IF;

		SET v_display_name = trim(concat(v_display_name, ', ', IFNULL(v_zip, '')));
		SET v_display_name = trim(concat(v_display_name, ' ', IFNULL(v_city, '')));

		return v_display_name;
	ELSE
		RETURN '';
	END IF;

END $$




DELIMITER ;