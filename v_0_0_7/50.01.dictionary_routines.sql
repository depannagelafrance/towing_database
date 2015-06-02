DELIMITER $$
-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_ADD_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_ADD_INSURANCE $$
DROP PROCEDURE IF EXISTS R_ADD_COLLECTOR $$

DROP PROCEDURE IF EXISTS R_UPDATE_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_UPDATE_INSURANCE $$
DROP PROCEDURE IF EXISTS R_UPDATE_COLLECTOR $$ 

DROP PROCEDURE IF EXISTS R_DELETE_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_DELETE_INSURANCE $$
DROP PROCEDURE IF EXISTS R_DELETE_COLLECTOR $$

DROP PROCEDURE IF EXISTS R_FETCH_ALL_INCIDENT_TYPES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_INSURANCES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_COLLECTORS $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TRAFFIC_LANES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_LICENCE_PLATE_COUNTRIES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_DIRECTIONS $$
DROP PROCEDURE IF EXISTS R_FETCH_INDICATORS_BY_DIRECTION $$
DROP PROCEDURE IF EXISTS R_FETCH_COMPANIES_BY_DIRECTION_AND_INDICATOR $$

DROP PROCEDURE IF EXISTS R_FETCH_INSURANCE_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_COLLECTOR_BY_ID $$

DROP PROCEDURE IF EXISTS R_FETCH_ALL_DRIVERS_BY_TYPE $$


CREATE PROCEDURE R_ADD_DICTIONARY(IN p_category ENUM('COLLECTOR'), IN p_name VARCHAR(255), IN p_user VARCHAR(255))
BEGIN
	DECLARE v_id BIGINT;

	INSERT INTO P_DICTIONARY(category, name, cd, cd_by)
	VALUES(p_category, p_name, now(), p_user);

	SET v_id = last_insert_id();

	SELECT * FROM P_DICTIONARY WHERE id = v_id;
END $$

CREATE PROCEDURE R_UPDATE_DICTIONARY(IN p_id BIGINT, IN p_category ENUM('COLLECTOR'), IN p_name VARCHAR(255), IN p_user VARCHAR(255))
BEGIN
	UPDATE 	P_DICTIONARY
	SET 	category = p_category, 
			`name` = p_name, 
			ud = now(), 
			ud_by = p_user
	WHERE 	id = p_id;

	SELECT * FROM P_DICTIONARY WHERE id = p_id;
END $$

CREATE PROCEDURE R_DELETE_DICTIONARY(IN p_id BIGINT, IN p_category ENUM('COLLECTOR'), IN p_user VARCHAR(255))
BEGIN
	UPDATE 	P_DICTIONARY
	SET 	dd = now(), 
			dd_by = p_user
	WHERE 	id = p_id
			AND category = p_category;

	SELECT "OK" as result;
END $$

CREATE PROCEDURE R_ADD_INSURANCE(IN p_name VARCHAR(255), IN p_vat VARCHAR(45), 
								 IN p_street VARCHAR(255), IN p_street_number VARCHAR(45), IN p_street_pobox VARCHAR(45), IN p_zip VARCHAR(45), IN p_city VARCHAR(45),
                                 IN p_invoice_excluded TINYINT(1),
								 IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);
	DECLAre v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT id INTO v_id FROM T_INSURANCES WHERE `name` = p_name AND dd IS NULL;

		IF v_id IS NULL THEN
			INSERT INTO T_INSURANCES(name, vat, street, street_number, street_pobox, zip, city, invoice_excluded, cd, cd_by)
			VALUES(p_name, p_vat, p_street, p_street_number, p_street_pobox, p_zip, p_city, p_invoice_excluded, now(), F_RESOLVE_LOGIN(v_user_id, p_token));

			SELECT * FROM T_INSURANCES WHERE id = LAST_INSERT_ID();
		ELSE
			SELECT 'INSURANCE_ALREADY_EXISTS' as error, 409 as statusCode;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_ADD_COLLECTOR(IN p_name VARCHAR(255), IN p_vat VARCHAR(45), 
								 IN p_street VARCHAR(255), IN p_street_number VARCHAR(45), IN p_street_pobox VARCHAR(45), 
								 IN p_zip VARCHAR(45), IN p_city VARCHAR(45),IN p_country VARCHAR(255),
							     IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- CALL R_ADD_DICTIONARY('COLLECTOR', p_name, F_RESOLVE_LOGIN(v_user_id, p_token));
		INSERT INTO T_COLLECTORS(name, vat, street, street_number, street_pobox, zip, city, country, cd, cd_by)
		VALUES(p_name, p_vat, p_street, p_street_number, p_street_pobox, p_zip, p_city, p_country, now(), F_RESOLVE_LOGIN(v_user_id, p_token));

		SELECT * FROM T_COLLECTORS WHERE id = last_insert_id();
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_INSURANCE(IN p_id BIGINT, IN p_name VARCHAR(255), IN p_vat VARCHAR(45), 
								    IN p_street VARCHAR(255), IN p_street_number VARCHAR(45), IN p_street_pobox VARCHAR(45), IN p_zip VARCHAR(45), IN p_city VARCHAR(45),
                                    IN p_invoice_excluded TINYINT(1),
								    IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE T_INSURANCES 
		SET 	`name` = p_name,
				vat = p_vat,
				street = p_street,
				street_number = p_street_number,
				street_pobox = p_street_pobox,
				zip = p_zip,
				city = p_city,
                invoice_excluded = p_invoice_excluded,
				ud = now(),
				ud_by = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE id = p_id
		LIMIT 1;

		SELECT * FROM T_INSURANCES WHERE id = p_id;
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_COLLECTOR(IN p_id BIGINT, IN p_name VARCHAR(255), IN p_vat VARCHAR(45), 
								    IN p_street VARCHAR(255), IN p_street_number VARCHAR(45), IN p_street_pobox VARCHAR(45), 
								    IN p_zip VARCHAR(45), IN p_city VARCHAR(45),IN p_country VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- CALL R_UPDATE_DICTIONARY(p_id, 'COLLECTOR', p_name, F_RESOLVE_LOGIN(v_user_id, p_token));
		UPDATE T_COLLECTORS
		SET name = p_name,
			vat = p_vat, street = p_street, street_number = p_street_number,
			street_pobox = p_street_pobox, zip = p_zip, city = p_city, country = p_country,
			ud = now(), ud_by = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE id = p_id;

		SELECT * FROM T_COLLECTORS WHERE id = p_id;
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
		UPDATE 	T_INSURANCES
		SET 	dd = now(), 
				dd_by = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE 	id = p_id 
		LIMIT 	1;
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
		-- CALL R_DELETE_DICTIONARY(p_id, 'COLLECTOR', F_RESOLVE_LOGIN(v_user_id, p_token));
		UPDATE T_COLLECTORS
		SET dd = now(), dd_by = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE id = p_id;

		SELECT "OK" as result;
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
		SELECT 	id, `name`, vat, street, street_number, street_pobox, zip, city
		FROM 	T_INSURANCES
		WHERE	dd IS NULL
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
		SELECT 	id, `name`, vat, street, street_number, street_pobox, zip, city, country
		FROM 	T_COLLECTORS
		WHERE	dd IS NULL 
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

CREATE PROCEDURE R_FETCH_ALL_DIRECTIONS(IN p_token VARCHAR(255)) 
BEGIN 
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`id`, `name`
		FROM 	P_ALLOTMENT_DIRECTIONS
		ORDER BY `name`;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_INCIDENT_TYPES(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`id`, `name`
		FROM 	P_INCIDENT_TYPES
		ORDER BY `name`;
	END IF;
END $$


CREATE PROCEDURE R_FETCH_INDICATORS_BY_DIRECTION(IN p_direction_id INT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`id`, `name`, `sequence`
		FROM 	P_ALLOTMENT_DIRECTION_INDICATORS
		WHERE	allotment_directions_id = p_direction_id
		ORDER BY `sequence`, `name`;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_COMPANIES_BY_DIRECTION_AND_INDICATOR(IN p_direction_id INT, IN p_indicator_id INT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		IF p_indicator_id IS NULL THEN
			SELECT  c.id, c.code, c.name, c.phone
			FROM 	`P_ALLOTMENT_MAP` ap, `P_ALLOTMENT` a, `T_COMPANY_ALLOTMENTS` ca, `T_COMPANIES` c
			WHERE 	a.id = ap.allotment_id
					AND a.id = ca.allotment_id
					AND c.id = ca.company_id
					AND direction_id = p_direction_id
			ORDER BY c.name;
		ELSE
			SELECT  c.id, c.code, c.name, c.phone
			FROM 	`P_ALLOTMENT_MAP` ap, `P_ALLOTMENT` a, `T_COMPANY_ALLOTMENTS` ca, `T_COMPANIES` c
			WHERE 	a.id = ap.allotment_id
					AND a.id = ca.allotment_id
					AND c.id = ca.company_id
					AND direction_id = p_direction_id
					AND indicator_id = p_indicator_id
			ORDER BY c.name;
		END IF;
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
		SELECT 	`id`, `name`, vat, street, street_number, street_pobox, zip, city, invoice_excluded
		FROM 	T_INSURANCES
		WHERE 	id = p_id
				AND dd IS NULL
		LIMIT 	0,1;
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
		SELECT 	`id`, `name`, name, vat, street, street_number, street_pobox, zip, city, country
		FROM 	T_COLLECTORS
		WHERE 	id = p_id
				AND dd IS NULL;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_DRIVERS_BY_TYPE(IN p_type ENUM('signa', 'towing'), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		IF p_type = 'signa' THEN
			SELECT 	u.id, CONCAT(IFNULL(last_name, ''), ' ', IFNULL(first_name, ' ')) as `name`, cv.name as vehicle, UPPER(licence_plate) as licence_plate
			FROM 	T_USERS u, T_COMPANY_VEHICLES cv
			WHERE 	u.company_id = v_company_id
					AND u.dd IS NULL
					AND u.is_signa=1
					AND u.vehicle_id = cv.id
			ORDER BY last_name, first_name;
		ELSE
			SELECT 	`id`, CONCAT(IFNULL(last_name, ''), ' ', IFNULL(first_name, ' ')) as `name`, '' as vehicule, '' as licence_plate
			FROM 	T_USERS
			WHERE 	company_id = v_company_id
					AND dd IS NULL
					AND is_towing=1
			ORDER BY last_name, first_name;
		END IF;
	END IF;
END $$

DROP TRIGGER IF EXISTS TRG_AI_DICTIONARY $$
DROP TRIGGER IF EXISTS TRG_AU_DICTIONARY $$

DROP TRIGGER IF EXISTS TRG_AI_COLLECTORS $$
DROP TRIGGER IF EXISTS TRG_AU_COLLECTORS $$

DROP TRIGGER IF EXISTS TRG_AI_INSURANCES $$
DROP TRIGGER IF EXISTS TRG_AU_INSURANCES $$


CREATE TRIGGER `TRG_AI_DICTIONARY` AFTER INSERT ON `P_DICTIONARY`
FOR EACH ROW
BEGIN
	CALL R_ADD_DICTIONARY_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AU_DICTIONARY` AFTER UPDATE ON `P_DICTIONARY`
FOR EACH ROW
BEGIN
	CALL R_ADD_DICTIONARY_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AI_COLLECTORS` AFTER INSERT ON `T_COLLECTORS`
FOR EACH ROW
BEGIN
	CALL R_ADD_COLLECTOR_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AU_COLLECTORS` AFTER UPDATE ON `T_COLLECTORS`
FOR EACH ROW
BEGIN
	CALL R_ADD_COLLECTOR_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AI_INSURANCES` AFTER INSERT ON `T_INSURANCES`
FOR EACH ROW
BEGIN
	CALL R_ADD_INSURANCE_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AU_INSURANCES` AFTER UPDATE ON `T_INSURANCES`
FOR EACH ROW
BEGIN
	CALL R_ADD_INSURANCE_AUDIT_LOG(NEW.id);
END $$

DELIMITER ;