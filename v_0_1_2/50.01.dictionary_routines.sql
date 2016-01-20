DELIMITER $$
-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_ADD_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_ADD_INSURANCE $$
DROP PROCEDURE IF EXISTS R_ADD_COLLECTOR $$
DROP PROCEDURE IF EXISTS R_ADD_CUSTOMER $$
DROP PROCEDURE IF EXISTS R_ADD_DIRECTION_INDICATOR $$
DROP PROCEDURE IF EXISTS R_ADD_DIRECTION $$

DROP PROCEDURE IF EXISTS R_UPDATE_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_UPDATE_INSURANCE $$
DROP PROCEDURE IF EXISTS R_UPDATE_COLLECTOR $$ 
DROP PROCEDURE IF EXISTS R_UPDATE_CUSTOMER $$
DROP PROCEDURE IF EXISTS R_UPDATE_DIRECTION $$
DROP PROCEDURE IF EXISTS R_UPDATE_DIRECTION_INDICATOR $$

DROP PROCEDURE IF EXISTS R_DELETE_DICTIONARY $$
DROP PROCEDURE IF EXISTS R_DELETE_INSURANCE $$
DROP PROCEDURE IF EXISTS R_DELETE_COLLECTOR $$
DROP PROCEDURE IF EXISTS R_DELETE_CUSTOMER $$
DROP PROCEDURE IF EXISTS R_DELETE_DIRECTION $$
DROP PROCEDURE IF EXISTS R_DELETE_DIRECTION_INDICATOR $$

DROP PROCEDURE IF EXISTS R_FETCH_ALL_INCIDENT_TYPES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_INSURANCES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_COLLECTORS $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_CUSTOMERS $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_CUSTOMERS_BY_TYPE $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TRAFFIC_LANES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_LICENCE_PLATE_COUNTRIES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_DIRECTIONS $$
DROP PROCEDURE IF EXISTS R_FETCH_DIRECTION_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_DIRECTION_INDICATOR_BY_ID $$


DROP PROCEDURE IF EXISTS R_FETCH_INDICATORS_BY_DIRECTION $$
DROP PROCEDURE IF EXISTS R_FETCH_COMPANIES_BY_DIRECTION_AND_INDICATOR $$

DROP PROCEDURE IF EXISTS R_FETCH_INSURANCE_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_COLLECTOR_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_CUSTOMER_BY_ID $$

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


CREATE PROCEDURE R_ADD_CUSTOMER(IN p_type ENUM('CUSTOMER', 'COLLECTOR', 'INSURANCE', 'OTHER'),
								IN p_customer_number VARCHAR(45),
                                IN p_name VARCHAR(255), IN p_vat VARCHAR(45), 
                                IN p_first_name VARCHAR(255), IN p_last_name VARCHAR(255),
								IN p_street VARCHAR(255), IN p_street_number VARCHAR(45), IN p_street_pobox VARCHAR(45), IN p_zip VARCHAR(45), IN p_city VARCHAR(45), IN p_country VARCHAR(255),
								IN p_invoice_excluded TINYINT(1), IN p_invoice_to ENUM('CUSTOMER', 'COLLECTOR', 'INSURANCE', 'OTHER'),
                                IN p_is_insurance TINYINT(1), IN p_is_collector TINYINT(1),
								IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);
	DECLAre v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id INTO v_id
        FROM 	T_CUSTOMERS
        WHERE 	customer_number = p_customer_number
				AND company_id = v_company_id
		LIMIT 0,1;
        
        IF v_id IS NULL THEN
			-- SELECT 'INSURANCE_ALREADY_EXISTS' as error, 409 as statusCode;
			INSERT INTO `P_towing_be`.`T_CUSTOMERS`(`type`,
													`customer_number`,
													`company_name`, `company_vat`,
													`first_name`, `last_name`,
													`street`, `street_number`, `street_pobox`, `zip`, `city`, `country`,
													`invoice_excluded`, `invoice_to`, `is_insurance`, `is_collector`,
													`company_id`,
													`cd`, `cd_by`)
			VALUES (
				p_type, 
				p_customer_number,
				p_name, p_vat,
				p_first_name, p_last_name,
				p_street, p_street_number, p_street_pobox, p_zip, p_city, p_country,
				p_invoice_excluded, p_invoice_to, p_is_insurance, p_is_collector,
				v_company_id,
				now(), F_RESOLVE_LOGIN(v_user_id, p_token));

			SET v_id = LAST_INSERT_ID();
		ELSE
			UPDATE 	T_CUSTOMERS
            SET 	company_name = p_name, 
					company_vat = p_vat,
					first_name = IFNULL(p_first_name, first_name), 
                    last_name = IFNULL(p_last_name, last_name),
                    street = p_street, 
                    street_number = p_street_number, 
                    street_pobox = p_street_pobox, 
                    zip = p_zip, 
                    city = p_city, 
                    country = p_country,
                    ud=now(), 
                    ud_by=F_RESOLVE_LOGIN(v_user_id, p_token)
			WHERE 	id = v_id
					AND company_id = v_company_id;
        END IF;
        
        
        CALL R_FETCH_CUSTOMER_BY_ID(v_id, p_token);
    END IF;
END $$
                                


CREATE PROCEDURE R_UPDATE_CUSTOMER( IN p_id BIGINT,
									IN p_customer_number VARCHAR(45),
									IN p_name VARCHAR(255), IN p_vat VARCHAR(45), 
									IN p_first_name VARCHAR(255), IN p_last_name VARCHAR(255),
									IN p_street VARCHAR(255), IN p_street_number VARCHAR(45), IN p_street_pobox VARCHAR(45), IN p_zip VARCHAR(45), IN p_city VARCHAR(45), IN p_country VARCHAR(255),
									IN p_invoice_excluded TINYINT(1), IN p_invoice_to ENUM('CUSTOMER', 'COLLECTOR', 'INSURANCE', 'OTHER'), 
                                    IN p_is_insurance TINYINT(1), IN p_is_collector TINYINT(1),
									IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);
	DECLARE v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- SELECT 'INSURANCE_ALREADY_EXISTS' as error, 409 as statusCode;
		UPDATE `P_towing_be`.`T_CUSTOMERS`
        SET customer_number = p_customer_number	,
            company_name	= p_name, 
            company_vat		= p_vat,
            first_name		= p_first_name, 
            last_name		= p_last_name,
            street			= p_street,
            street_number 	= p_street_number, 
            street_pobox	= p_street_pobox, 
            zip				= p_zip, 
            city			= p_city, 
            country			= p_country,
            invoice_excluded = p_invoice_excluded,
            invoice_to		= p_invoice_to,
            is_insurance	= p_is_insurance,
            is_collector	= p_is_collector,
            ud				= now(), 
            ud_by			= F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE
			id = p_id
			AND company_id = v_company_id;
            
		CALL R_FETCH_CUSTOMER_BY_ID(p_id, p_token);
    END IF;
END $$

CREATE PROCEDURE R_DELETE_CUSTOMER(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);
	DECLARE v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE T_CUSTOMERS
        SET		dd = now(),
				dd_by = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE 	id = p_id
				AND company_id = v_company_id;
		
        SELECT "OK" as result;
    END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_CUSTOMERS(IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_ALL_CUSTOMERS_BY_TYPE('ALL', p_token);
END $$

CREATE PROCEDURE R_FETCH_ALL_CUSTOMERS_BY_TYPE(IN p_type ENUM('ALL', 'COLLECTOR', 'INSURANCE'), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);
	DECLARE v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
    
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		IF p_type = 'ALL' THEN
			SELECT 	id, 
					type, 
					customer_number, 
					company_name, company_vat,
					first_name, last_name,
					street, street_number, street_pobox, zip, city, country,
					invoice_excluded, is_insurance, is_collector
			FROM 	T_CUSTOMERS
			WHERE 
					dd IS NULL
					AND company_id = v_company_id
			ORDER 	BY `company_name`;        
		ELSE 
			SELECT 	id, 
					type, 
					customer_number, 
					company_name, company_vat,
					first_name, last_name,
					street, street_number, street_pobox, zip, city, country,
					invoice_excluded, is_insurance, is_collector
			FROM 	T_CUSTOMERS
			WHERE 
					dd IS NULL
					AND company_id = v_company_id
                    AND `is_insurance`=(p_type = 'INSURANCE')
                    AND `is_collector`=(p_type = 'COLLECTOR' OR p_type='CUSTOMER')
			ORDER 	BY`company_name`;	
		END IF;
    END IF;
END $$

CREATE PROCEDURE R_FETCH_CUSTOMER_BY_ID(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);
	DECLARE v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id, 
				type, 
                customer_number, 
                company_name, company_vat,
                first_name, last_name,
                street, street_number, street_pobox, zip, city, country,
                invoice_excluded, invoice_to, 
                is_insurance, is_collector
        FROM 	T_CUSTOMERS
        WHERE 
				dd IS NULL
                AND company_id = v_company_id
                AND id = p_id
        ORDER 	BY `company_name`;
    END IF;
END $$


CREATE PROCEDURE R_FETCH_ALL_INSURANCES(IN p_token VARCHAR(255)) 
BEGIN
	CALL R_FETCH_ALL_CUSTOMERS_BY_TYPE('INSURANCE', p_token);
END $$

CREATE PROCEDURE R_FETCH_ALL_COLLECTORS(IN p_token VARCHAR(255)) 
BEGIN
	CALL R_FETCH_ALL_CUSTOMERS_BY_TYPE('COLLECTOR', p_token);
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
        WHERE	dd IS NULL
		ORDER BY `name`;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_DIRECTION_BY_ID(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`id`, `name`
		FROM 	P_ALLOTMENT_DIRECTIONS
		WHERE 	id = p_id
        LIMIT	0,1;
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
		SELECT 	`id`, `name`, `sequence`, `zip`, `city`, `lat`, `long`
		FROM 	P_ALLOTMENT_DIRECTION_INDICATORS
		WHERE	allotment_directions_id = p_direction_id
				AND dd IS NULL
		ORDER BY `sequence`, `name`;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_DIRECTION_INDICATOR_BY_ID(IN p_indicator_id INT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	id, allotment_directions_id, `name`,lat, `long`, zip, city, sequence
        FROM 	P_ALLOTMENT_DIRECTION_INDICATORS
        WHERE 	id = p_indicator_id
        LIMIT 	0,1;
    END IF;
END $$

CREATE PROCEDURE R_ADD_DIRECTION(IN p_name VARCHAR(45), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);
	DECLAre v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO P_ALLOTMENT_DIRECTIONS(`name`, `cd`, `cd_by`)
        VALUES(p_name, now(), F_RESOLVE_LOGIN(v_user_id, p_token));
        
        CALL R_FETCH_DIRECTION_BY_ID(LAST_INSERT_ID(), p_token);
    END IF;
END $$


CREATE PROCEDURE R_UPDATE_DIRECTION(IN p_id BIGINT, IN p_name VARCHAR(45), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);
	DECLAre v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE 	P_ALLOTMENT_DIRECTIONS
        SET 	`name` = p_name, 
				ud=now(), 
				ud_by=F_RESOLVE_LOGIN(v_user_id, p_token)
        WHERE 
				id = p_id;
        
        CALL R_FETCH_DIRECTION_BY_ID(LAST_INSERT_ID(), p_token);
    END IF;
END $$


CREATE PROCEDURE R_DELETE_DIRECTION(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);
	DECLAre v_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE 	P_ALLOTMENT_DIRECTIONS
        SET 	dd=now(), 
				dd_by=F_RESOLVE_LOGIN(v_user_id, p_token)
        WHERE 	id = p_id;
        
        SELECT "OK" as result;
    END IF;
END $$

CREATE PROCEDURE R_ADD_DIRECTION_INDICATOR( IN p_direction_id INT, 
											IN p_name VARCHAR(255),
                                            IN p_zip VARCHAR(4),
                                            IN p_city VARCHAR(255),
                                            IN p_lat double,
                                            IN p_long double,
                                            IN p_sequence INT,
											IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO `P_ALLOTMENT_DIRECTION_INDICATORS`(`allotment_directions_id`, `name`, `lat`, `long`, `zip`, `city`, `sequence`, `cd`, `cd_by`)
		VALUES (p_direction_id, p_name, p_lat, p_long, p_zip, p_city, p_sequence, now(), F_RESOLVE_LOGIN(v_user_id, p_token));
        
        SET v_id = LAST_INSERT_ID();
        
        -- CREATE A MAP BETWEEN YOUR COMPANY'S ALLOTMENT AND THE ADDED INDICATOR
        INSERT INTO P_ALLOTMENT_MAP(allotment_id, direction_id, indicator_id)
        SELECT 	allotment_id, p_direction_id, v_id
        FROM 	T_COMPANY_ALLOTMENTS 
        WHERE 	company_id = v_company_id;

		-- RETURN THEN INDICATOR
		CALL R_FETCH_DIRECTION_INDICATOR_BY_ID(v_id, p_token);
    END IF;
END $$

CREATE PROCEDURE R_UPDATE_DIRECTION_INDICATOR( 	IN p_id INT,
												IN p_direction_id INT, 
												IN p_name VARCHAR(255),
												IN p_zip VARCHAR(4),
												IN p_city VARCHAR(255),
												IN p_lat double,
												IN p_long double,
												IN p_sequence INT,
												IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE 	P_ALLOTMENT_DIRECTION_INDICATORS
        SET 	name = p_name, lat = p_lat, `long`=p_long, zip = p_zip, city = p_city, sequence = p_sequence,
				ud = now(), ud_by = F_RESOLVE_LOGIN(v_user_id, p_token)
        WHERE 	id = p_id 
				AND allotment_directions_id = p_direction_id;
        
        CALL R_FETCH_DIRECTION_INDICATOR_BY_ID(p_id, p_token);
    END IF;
END $$

CREATE PROCEDURE R_DELETE_DIRECTION_INDICATOR(IN p_id INT, IN p_direction_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id, v_guid VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);
	
	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
   		UPDATE 	P_ALLOTMENT_DIRECTION_INDICATORS
        SET 	dd = now(), dd_by = F_RESOLVE_LOGIN(v_user_id, p_token)
        WHERE 	id = p_id 
				AND allotment_directions_id = p_direction_id;
                
		SELECT "OK" as result;
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
	CALL R_FETCH_CUSTOMER_BY_ID(p_id, p_token);
END $$

CREATE PROCEDURE R_FETCH_COLLECTOR_BY_ID(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_CUSTOMER_BY_ID(p_id, p_token);
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

DELIMITER ;