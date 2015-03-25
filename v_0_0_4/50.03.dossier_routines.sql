SET GLOBAL event_scheduler = ON;
SET @@global.event_scheduler = ON;
SET GLOBAL event_scheduler = 1;
SET @@global.event_scheduler = 1;

DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_CREATE_DOSSIER $$
DROP PROCEDURE IF EXISTS R_UPDATE_DOSSIER $$
DROP PROCEDURE IF EXISTS R_CREATE_TOWING_VOUCHER $$
DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_VOUCHER $$
DROP PROCEDURE IF EXISTS R_MARK_VOUCHER_AS_IDLE $$

DROP PROCEDURE IF EXISTS R_FETCH_TOWING_DEPOT  		$$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_CUSTOMER 	$$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_CAUSER 		$$

DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_DEPOT 		$$
DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_CUSTOMER 	$$
DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_CUSTOMER_TO_AGENCY $$
DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_CAUSER		$$

DROP PROCEDURE IF EXISTS R_CREATE_DEFAULT_TOWING_VOUCHER_ACTIVITIES $$
DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_VOUCHER_ACTIVITY $$
DROP PROCEDURE IF EXISTS R_REMOVE_TOWING_VOUCHER_ACTIVITY $$

DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_VOUCHER_PAYMENTS $$

DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_STORAGE_COST $$
DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_STORAGE_COST_FOR_VOUCHER $$
DROP PROCEDURE IF EXISTS R_UPDATE_EXTRA_TIME_SIGNA $$
DROP PROCEDURE IF EXISTS R_UPDATE_EXTRA_TIME_ACCIDENT $$

DROP PROCEDURE IF EXISTS R_FETCH_DOSSIER_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_DOSSIER_BY_NUMBER $$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_VOUCHERS_BY_DOSSIER $$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_ACTIVITIES_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_PAYMENTS_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_COMPANY_BY_DOSSIER $$
DROP PROCEDURE IF EXISTS R_FETCH_ALLOTMENT_AGENCY_BY_ALLOTMENT $$

DROP PROCEDURE IF EXISTS R_FETCH_ALL_DOSSIERS_BY_FILTER $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_DOSSIERS_ASSIGNED_TO_ME_BY_FILTER $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_VOUCHERS_BY_FILTER $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_AVAILABLE_ACTIVITIES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TOWING_ACTIVITIES $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_ALLOTMENTS_BY_DIRECTION $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_COMPANIES_BY_ALLOTMENT $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_TRAFFIC_POSTS_BY_ALLOTMENT $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_DOSSIER_TRAFFIC_LANES $$

DROP PROCEDURE IF EXISTS R_ADD_BLOB_TO_VOUCHER $$
DROP PROCEDURE IF EXISTS R_ADD_COLLECTOR_SIGNATURE $$
DROP PROCEDURE IF EXISTS R_ADD_CAUSER_SIGNATURE $$
DROP PROCEDURE IF EXISTS R_ADD_POLICE_SIGNATURE $$
DROP PROCEDURE IF EXISTS R_ADD_INSURANCE_DOCUMENT $$
DROP PROCEDURE IF EXISTS R_ADD_VEHICLE_DAMAGE_DOCUMENT $$
DROP PROCEDURE IF EXISTS R_ADD_ANY_DOCUMENT $$

DROP PROCEDURE IF EXISTS R_FETCH_SIGNATURE_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_CAUSER_SIGNATURE_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_CAUSER_SIGNATURE_BLOB_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_COLLECTOR_SIGNATURE_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_COLLECTOR_SIGNATURE_BLOB_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_TRAFFIC_POST_SIGNATURE_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_TRAFFIC_POST_SIGNATURE_BLOB_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_VOUCHER_SIGNATURE $$
DROP PROCEDURE IF EXISTS R_FETCH_DOCUMENT_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_COMM_AND_ATT_SUMMARY $$

DROP PROCEDURE IF EXISTS R_FETCH_ALL_DOSSIER_COMMUNICATIONS $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_INTERNAL_COMMUNICATIONS $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_EMAIL_COMMUNICATIONS $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_DOSSIER_COMM_RECIPIENTS $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_VOUCHER_DOCUMENTS $$

DROP PROCEDURE IF EXISTS R_CREATE_DOSSIER_COMMUNICATION $$
DROP PROCEDURE IF EXISTS R_CREATE_DOSSIER_COMM_RECIPIENT $$

DROP PROCEDURE IF EXISTS R_SEARCH_TOWING_VOUCHER $$
DROP PROCEDURE IF EXISTS R_SEARCH_TOWING_VOUCHER_BY_NUMBER $$

DROP PROCEDURE IF EXISTS R_PURGE_DOSSIER_TRAFFIC_LANES $$
DROP PROCEDURE IF EXISTS R_CREATE_DOSSIER_TRAFFIC_LANES $$

DROP PROCEDURE IF EXISTS R_CREATE_VOUCHER_VALIDATION_MESSAGE $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_VOUCHER_VALIDATION_MESSAGES $$

DROP FUNCTION IF EXISTS F_NEXT_DOSSIER_NUMBER $$
DROP FUNCTION IF EXISTS F_NEXT_TOWING_VOUCHER_NUMBER $$
DROP FUNCTION IF EXISTS F_RESOLVE_TIMEFRAME_CATEGORY $$
DROP FUNCTION IF EXISTS F_IS_VOUCHER_VIABLE_FOR_FOREIGN_VAT $$

DROP TRIGGER IF EXISTS TRG_AI_DOSSIER $$
DROP TRIGGER IF EXISTS TRG_AU_DOSSIER $$
DROP TRIGGER IF EXISTS TRG_AI_TOWING_VOUCHER $$
DROP TRIGGER IF EXISTS TRG_BU_TOWING_VOUCHER $$
DROP TRIGGER IF EXISTS TRG_AU_TOWING_VOUCHER $$
DROP TRIGGER IF EXISTS TRG_AI_TOWING_ACTIVITY $$
DROP TRIGGER IF EXISTS TRG_BU_TOWING_ACTIVITY $$
DROP TRIGGER IF EXISTS TRG_AU_TOWING_ACTIVITY $$
DROP TRIGGER IF EXISTS TRG_AI_TOWING_CUSTOMER $$
DROP TRIGGER IF EXISTS TRG_AU_TOWING_CUSTOMER $$
DROP TRIGGER IF EXISTS TRG_AI_TOWING_CAUSER $$
DROP TRIGGER IF EXISTS TRG_AU_TOWING_CAUSER $$
DROP TRIGGER IF EXISTS TRG_AI_TOWING_DEPOT $$
DROP TRIGGER IF EXISTS TRG_AU_TOWING_DEPOT $$
DROP TRIGGER IF EXISTS TRG_AI_TOWING_PAYMENTS $$
DROP TRIGGER IF EXISTS TRG_AU_TOWING_PAYMENTS $$

DROP EVENT IF EXISTS E_UPDATE_TOWING_STORAGE_COST $$
DROP EVENT IF EXISTS E_UPDATE_SIGNA_EXTRA_TIME $$
DROP EVENT IF EXISTS E_UPDATE_ACCIDENT_EXTRA_TIME $$

-- ---------------------------------------------------------------------
-- CREATE FUNCTIONS
-- ---------------------------------------------------------------------
CREATE FUNCTION F_NEXT_DOSSIER_NUMBER(p_company_id BIGINT) RETURNS INT
BEGIN
	SET @v_id = 1;

	INSERT INTO T_SEQUENCES(`code`, `seq_val`, company_id)
	VALUES('DOSSIER', 1, p_company_id)
	ON DUPLICATE KEY UPDATE seq_val=@v_id:=seq_val+1;

	RETURN @v_id;
END $$

CREATE FUNCTION F_NEXT_TOWING_VOUCHER_NUMBER(p_company_id BIGINT) RETURNS INT
BEGIN
	SET @v_id = 1;

	INSERT INTO T_SEQUENCES(`code`, `seq_val`, company_id)
	VALUES('TOWING_VOUCHER', 1, p_company_id)
	ON DUPLICATE KEY UPDATE seq_val=@v_id:=seq_val+1;

	RETURN @v_id;
END $$

CREATE FUNCTION F_RESOLVE_TIMEFRAME_CATEGORY() RETURNS VARCHAR(15)
BEGIN
	DECLARE v_id INT;

	SELECT 	id INTO v_id
	FROM 	`P_HOLIDAYS`	
	WHERE 	`holiday` = CURRENT_DATE
	LIMIT 	0,1;

	IF v_id IS NULL THEN 
		CASE dayofweek(now())
			WHEN 1 THEN return 'SUNDAY';
			WHEN 7 THEN return 'SATURDAY';
			ELSE RETURN 'WORKDAY';
		END CASE;
	ELSE
		RETURN 'HOLIDAY';
	END IF; 
END $$


CREATE FUNCTION F_IS_VOUCHER_VIABLE_FOR_FOREIGN_VAT(p_voucher_id BIGINT) RETURNS BOOL
BEGIN
	DECLARE v_foreign_vat BOOL;

	-- check if insurance was set
	IF (SELECT insurance_id FROM T_TOWING_VOUCHERS WHERE id = p_voucher_id) IS NULL THEN
		SELECT (IFNULL(company_vat_foreign_country, 0) = 1) INTO v_foreign_vat
		FROM `T_TOWING_CUSTOMERS`
		WHERE voucher_id = p_voucher_id 
		LIMIT 0,1;
	ELSE
		-- insurances was set, check if foreign vat
		SELECT IF(i.vat IS NULL, 0,  UPPER(LEFT(i.vat, 2)) != 'BE') INTO v_foreign_vat
		FROM T_TOWING_VOUCHERS tv, T_INSURANCES i
		WHERE tv.id = p_voucher_id AND tv.insurance_id = i.id
		LIMIT 0,1;
	END IF;

	return v_foreign_vat;
END $$ 

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_CREATE_DOSSIER(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id, v_towing_voucher_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_timeframe_id INT;
	DECLARE v_timeframe_category VARCHAR(15);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SET v_timeframe_category = F_RESOLVE_TIMEFRAME_CATEGORY();

		-- determine the timeframe of the incident
		SELECT 	t.id INTO v_timeframe_id
		FROM 	P_TIMEFRAMES t, P_TIMEFRAME_VALIDITY tv
		WHERE	t.id = tv.timeframe_id
				AND current_time() BETWEEN `from` AND `till`
				AND tv.category = v_timeframe_category;

		-- create a new dossier
		INSERT INTO `T_DOSSIERS` (`company_id`, `dossier_number`, `call_date`, `call_date_is_holiday`, `timeframe_id`, `cd`, `cd_by`) 
		VALUES (v_company_id, F_NEXT_DOSSIER_NUMBER(v_company_id), CURRENT_TIMESTAMP, (v_timeframe_category = 'HOLIDAY'), v_timeframe_id, CURRENT_TIMESTAMP, F_RESOLVE_LOGIN(v_user_id, p_token));

		SET v_dossier_id = LAST_INSERT_ID();

		SELECT v_dossier_id as `id`;

		-- automatically insert a new towing voucher for each new dossier
		INSERT INTO `T_TOWING_VOUCHERS` (`dossier_id`, `voucher_number`, `cd`, `cd_by`) 
		VALUES (v_dossier_id, F_NEXT_TOWING_VOUCHER_NUMBER(v_company_id), now(), F_RESOLVE_LOGIN(v_user_id, p_token));
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_DOSSIER(IN p_dossier_id BIGINT, IN p_call_number VARCHAR(45), IN p_company_id BIGINT, 
                                  IN p_incident_type_id INT, IN p_allotment_id INT, IN p_direction_id INT, 
                                  IN p_direction_indicator_id INT, IN p_police_traffic_post_id INT,
								  IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE	
		UPDATE `T_DOSSIERS`
		SET incident_type_id 		= p_incident_type_id,
			call_number 			= p_call_number,
			allotment_id 			= p_allotment_id,
			allotment_direction_id 	= p_direction_id,
			allotment_direction_indicator_id = p_direction_indicator_id,
			police_traffic_post_id  = p_police_traffic_post_id,
			company_id 				= p_company_id,
			ud						= now(),
			ud_by					= F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE id = p_dossier_id
		LIMIT 1;

		CALL R_FETCH_DOSSIER_BY_ID(p_dossier_id, p_token);
			
	END IF;
END $$


CREATE PROCEDURE R_CREATE_TOWING_VOUCHER(IN p_dossier_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id, v_timeframe_id, v_taf_id, v_voucher_id BIGINT;
	DECLARE v_nr_of_vouchers INT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_incident_type_code VARCHAR(255);
	DECLARE v_fee_incl_vat, v_fee_excl_vat DOUBLE(10,2);
	DECLARE v_voucher_number INT;
	DECLARE v_call_date DATETIME;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- TODO: check link with company
		SELECT 	d.id, d.timeframe_id, count(dossier_id) INTO v_dossier_id, v_timeframe_id, v_nr_of_vouchers
		FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv
		WHERE	d.id = p_dossier_id
				AND d.id = tv.dossier_id
		GROUP BY 1, 2;

		IF v_dossier_id IS NULL THEN
			CALL R_NOT_FOUND;
		ELSE
			SELECT 	`code`, d.timeframe_id, d.call_date INTO v_incident_type_code, v_timeframe_id, v_call_date
			FROM	`P_INCIDENT_TYPES` it, T_DOSSIERS d
			WHERE 	d.incident_type_id = it.id AND d.id = v_dossier_id
			LIMIT	0,1;

			SET v_voucher_number = F_NEXT_TOWING_VOUCHER_NUMBER(v_company_id);

			INSERT INTO `T_TOWING_VOUCHERS` (`dossier_id`, `voucher_number`, `cd`, `cd_by`, `signa_id`, `signa_by`, `signa_by_vehicle`, `signa_arrival`) 
			SELECT 	v_dossier_id, v_voucher_number, now(), F_RESOLVE_LOGIN(v_user_id, p_token), signa_id, signa_by, signa_by_vehicle, signa_arrival 
			FROM 	T_TOWING_VOUCHERS 
			WHERE 	dossier_id = v_dossier_id
			ORDER 	BY id 
			LIMIT 	0,1;
			-- VALUES (v_dossier_id, F_NEXT_TOWING_VOUCHER_NUMBER(), now(), F_RESOLVE_LOGIN(v_user_id, p_token));
			
			SET v_voucher_id = LAST_INSERT_ID();


			-- create a copy of the base activities
			INSERT IGNORE INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
			SELECT 	id, t.activity_id, t.default_value, t.fee_excl_vat, t.fee_incl_vat 
			FROM 	T_TOWING_VOUCHERS tv,
					(SELECT taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat, ta.default_value
					 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
					 WHERE 	taf.timeframe_activity_id = ta.id 
							AND taf.timeframe_id = v_timeframe_id
							AND `code` = v_incident_type_code
							AND v_call_date BETWEEN taf.valid_from AND taf.valid_until) t
			WHERE tv.dossier_id = v_dossier_id
					AND tv.id = v_voucher_id;


			-- create new signa activity
			SELECT 	taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat INTO v_taf_id, v_fee_excl_vat, v_fee_incl_vat
			FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
			WHERE 	taf.timeframe_activity_id = ta.id 
					AND taf.timeframe_id = v_timeframe_id
					AND `code` = 'SIGNALISATIE'
					AND v_call_date BETWEEN taf.valid_from AND taf.valid_until;

			IF v_taf_id IS NOT NULL THEN
				INSERT IGNORE INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
				SELECT 	LAST_INSERT_ID(), v_taf_id, ROUND(1.0/(v_nr_of_vouchers+1), 2), v_fee_excl_vat, v_fee_incl_vat;
				
				-- update to split
				UPDATE 	T_TOWING_ACTIVITIES ta, T_TOWING_VOUCHERS tv
				SET 	amount = ROUND(1.0/(v_nr_of_vouchers+1), 2)
				WHERE 	tv.id = ta.towing_voucher_id
						AND tv.dossier_id = v_dossier_id
						AND ta.activity_id = v_taf_id;
			END IF;
		END IF;
	END IF;
END $$


CREATE PROCEDURE R_MARK_VOUCHER_AS_IDLE(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id, v_timeframe_id, v_taf_id, v_voucher_id BIGINT;
	DECLARE v_nr_of_vouchers INT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_incident_type_code VARCHAR(255);
	DECLARE v_fee_incl_vat, v_fee_excl_vat DOUBLE(10,2);
	DECLARE v_call_date DATETIME;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- REMOVE ALL ACTIVITIES AND INSERT THE "LOZE RIT"	
		DELETE FROM T_TOWING_ACTIVITIES
		WHERE towing_voucher_id = p_voucher_id;

		SELECT 	timeframe_id, IFNULL(d.call_date, now()) INTO v_timeframe_id, v_call_date
		FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv
		WHERE 	tv.id = p_voucher_id 
				AND tv.dossier_id = d.id;

		INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
		SELECT 	id, t.activity_id, t.default_value, t.fee_excl_vat, t.fee_incl_vat 
		FROM 	T_TOWING_VOUCHERS tv,
				(SELECT taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat, ta.default_value
				 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
				 WHERE 	taf.timeframe_activity_id = ta.id 
						AND taf.timeframe_id = v_timeframe_id
						AND `code` IN ('LOZE_RIT')
						AND v_call_date BETWEEN taf.valid_from AND taf.valid_until) t
		WHERE tv.id = p_voucher_id;	

		-- UPDATE CUSTOMER TO AGENCY
		CALL R_UPDATE_TOWING_CUSTOMER_TO_AGENCY(p_voucher_id, p_token);

		-- UPDATE THE START AND STOP TOWING TIMING 
		UPDATE T_TOWING_VOUCHERS SET towing_start = NOW(), towing_completed=NOW() WHERE id = p_voucher_id LIMIT 1;
	END IF;
END $$

CREATE PROCEDURE R_CREATE_DEFAULT_TOWING_VOUCHER_ACTIVITIES(IN p_dossier_id BIGINT, IN p_incident_type_id BIGINT, IN p_timeframe_id BIGINT)
BEGIN
		DECLARE v_incident_type_code VARCHAR(255);
		DECLARE v_call_date DATETIME;

		-- attach default activities based on selected timeframe
		SELECT 	`code` INTO v_incident_type_code
		FROM	`P_INCIDENT_TYPES`
		WHERE 	id = p_incident_type_id
		LIMIT	0,1;

		SELECT 	IFNULL(call_date, now()) INTO v_call_date
		FROM 	T_DOSSIERS
		WHERE 	id = p_dossier_id
		LIMIT 	0,1;

		CASE 
			WHEN v_incident_type_code = 'PANNE' OR v_incident_type_code = 'ONGEVAL' OR v_incident_type_code = 'ACHTERGELATEN_VOERTUIG' THEN
				INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
				SELECT 	id, t.activity_id, t.default_value, t.fee_excl_vat, t.fee_incl_vat 
				FROM 	T_TOWING_VOUCHERS tv,
						(SELECT taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat, ta.default_value
						 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
						 WHERE 	taf.timeframe_activity_id = ta.id 
								AND taf.timeframe_id = p_timeframe_id
								AND `code` IN (v_incident_type_code, 'SIGNALISATIE')
								AND v_call_date BETWEEN taf.valid_from AND taf.valid_until) t
				WHERE tv.dossier_id = p_dossier_id;
			ELSE
				INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
				SELECT 	id, t.activity_id, t.default_value, t.fee_excl_vat, t.fee_incl_vat 
				FROM 	T_TOWING_VOUCHERS tv,
						(SELECT taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat, ta.default_value
						 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
						 WHERE 	taf.timeframe_activity_id = ta.id 
								AND taf.timeframe_id = p_timeframe_id
								AND `code` IN (v_incident_type_code)
								AND v_call_date BETWEEN taf.valid_from AND taf.valid_until) t
				WHERE tv.dossier_id = p_dossier_id;	
		END CASE;
END $$


CREATE PROCEDURE  R_UPDATE_TOWING_VOUCHER(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT,
										  IN p_insurance_id BIGINT, IN p_insurance_dossier_nr VARCHAR(45), IN p_warranty_holder VARCHAR(255),
										  IN p_collector_id BIGINT,
										  IN p_vehicule VARCHAR(255), IN p_vehicule_type VARCHAR(255), IN p_vehicule_color VARCHAR(255), IN p_keys_present BOOL,
										  IN p_vehicule_licence_plate VARCHAR(15), IN p_vehicule_country VARCHAR(5),
										  IN p_vehicule_impact_remarks TEXT,
										  IN p_signa_id VARCHAR(36), IN p_signa_by VARCHAR(255), IN p_signa_by_vehicule VARCHAR(15), IN p_signa_arrival TIMESTAMP, 
										  IN p_towing_id VARCHAR(36), IN p_towed_by VARCHAR(255), IN p_towing_vehicle_id BIGINT, IN p_towed_by_vehicule VARCHAR(15), 
										  IN p_towing_called TIMESTAMP, IN p_towing_arrival TIMESTAMP, IN p_towing_start TIMESTAMP, IN p_towing_end TIMESTAMP,
										  IN p_police_signature TIMESTAMP, IN p_recipient_signature TIMESTAMP, IN p_vehicule_collected TIMESTAMP,
										  IN p_cic TIMESTAMP,
										  IN p_additional_info TEXT, 
										  IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE 	`T_TOWING_VOUCHERS`
		SET
			insurance_id 			= p_insurance_id, 
			insurance_dossiernr 	= p_insurance_dossier_nr, 
			insurance_warranty_held_by = p_warranty_holder,
			collector_id 			= p_collector_id, 
			recipient_signature_dt 	= p_recipient_signature, 
			vehicule				= p_vehicule,
			vehicule_type 			= p_vehicule_type, 
			vehicule_color			= p_vehicule_color,
			vehicule_keys_present	= p_keys_present,
			vehicule_licenceplate 	= p_vehicule_licence_plate, 
			vehicule_country 		= p_vehicule_country,
			vehicule_collected 		= p_vehicule_collected, 
			vehicule_impact_remarks = p_vehicule_impact_remarks,
			towing_id				= IF(TRIM(p_towing_id) = '', null, p_towing_id),
			towing_vehicle_id		= p_towing_vehicle_id,
			towing_called 			= p_towing_called, 
			towing_arrival 			= p_towing_arrival, 
			towing_start 			= p_towing_start, 
			towing_completed 		= p_towing_end, 
			signa_id				= IF(TRIM(p_signa_id) = '', null, p_signa_id),
			signa_arrival 			= p_signa_arrival, 
			cic 					= p_cic, 
			additional_info 		= p_additional_info, 
			ud						= now(), 
			ud_by					= F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE 	id = p_voucher_id
				AND dossier_id = p_dossier_id
		LIMIT 	1;

		SELECT p_voucher_id AS id;
	END IF;

END $$

CREATE PROCEDURE R_FETCH_DOSSIER_BY_ID(IN p_dossier_id BIGINT, IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id, v_dossier_id, v_traffic_lanes_count BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_traffic_lanes_name VARCHAR(255);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- TODO: check link with company
		SELECT 	`id` INTO v_dossier_id
		FROM 	T_DOSSIERS
		WHERE	`id` = p_dossier_id;

		IF v_dossier_id IS NULL THEN
			CALL R_NOT_FOUND;
		ELSE
			SELECT 	GROUP_CONCAT(DISTINCT name ORDER BY name SEPARATOR ', '), COUNT(DISTINCT name) INTO v_traffic_lanes_name, v_traffic_lanes_count
			FROM 	P_DICTIONARY d, T_INCIDENT_TRAFFIC_LANES itl
			WHERE 	d.id = itl.traffic_lane_id
					AND itl.dossier_id = v_dossier_id;

			SELECT	d.`id`, d.`dossier_number`, d.`call_date`, d.`call_date_is_holiday`, d.`call_number`, 
					d.`police_traffic_post_id`, ptp.`name` as `traffic_post_name`, ptp.`phone` as `traffic_post_phone`,
					d.`incident_type_id`, it.code as `incident_type_code`, it.code_agency as `incident_type_code_agency`, it.name `incident_type_name`,
					d.`timeframe_id`, t.`name` as "timeframe_name",
					d.`allotment_id`, (SELECT `name` FROM P_ALLOTMENT WHERE id = d.`allotment_id`) as `allotment_name`,
					d.`allotment_direction_indicator_id`, adi.name as `indicator_name`, adi.zip as `indicator_zip`, adi.city as `indicator_city`,
					d.`allotment_direction_id`, ad.`name` as `direction_name`,
					d.`company_id`, (SELECT `name` FROM T_COMPANIES WHERE id = d.`company_id`) as `company_name`,
					v_traffic_lanes_name as traffic_lane_name, v_traffic_lanes_count as nr_of_block_lanes
			FROM 	P_TIMEFRAMES t, T_DOSSIERS d 
					LEFT JOIN P_INCIDENT_TYPES it 					ON d.incident_type_id = it.id
					LEFT JOIN P_ALLOTMENT_DIRECTIONS ad				ON ad.id = d.`allotment_direction_id`			
					LEFT JOIN P_ALLOTMENT_DIRECTION_INDICATORS adi  ON adi.id = d.allotment_direction_indicator_id
					LEFT JOIN P_POLICE_TRAFFIC_POSTS ptp 			ON ptp.id = d.`police_traffic_post_id`
			WHERE	d.`id` = v_dossier_id
					AND t.id = d.timeframe_id
			LIMIT	0, 1;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALLOTMENT_AGENCY_BY_ALLOTMENT(IN p_allotment_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	pa.*
		FROM 	P_ALLOTMENT a, P_ALLOTMENT_AGENCY pa
		WHERE 	a.allotment_agency_id = pa.id
		LIMIT 	0,1;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_DOSSIER_BY_NUMBER(IN p_dossier_nr INT, IN p_token VARCHAR(255)) 
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- TODO: check link with company
		SELECT 	`id` INTO v_dossier_id
		FROM 	T_DOSSIERS
		WHERE	`dossier_number` = p_dossier_nr
				AND company_id IN (SELECT v_company_id UNION SELECT delegate_company_id FROM T_COMPANY_MAP WHERE supervisor_company_id = v_company_id);

		IF v_dossier_id IS NULL THEN
			CALL R_NOT_FOUND;
		ELSE
			CALL R_FETCH_DOSSIER_BY_ID(v_dossier_id, p_token) ;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_TOWING_VOUCHERS_BY_DOSSIER(IN p_dossier_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- TODO: check link with company
		SELECT 	DISTINCT d.id INTO v_dossier_id
		FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv
		WHERE	d.id = p_dossier_id
				AND d.id = tv.dossier_id;

		IF v_dossier_id IS NULL THEN
			CALL R_NOT_FOUND;
		ELSE
			SELECT	`id`,
					`dossier_id`,
					`insurance_id`,
					`collector_id`,
					`voucher_number`,
					unix_timestamp(`police_signature_dt`) as police_signature_dt,
					unix_timestamp(`recipient_signature_dt`) as recipient_signature_dt,
					`insurance_dossiernr`,
					`insurance_warranty_held_by`,
					`vehicule`, `vehicule_color`, `vehicule_keys_present`, `vehicule_impact_remarks`,
					`vehicule_type`,
					`vehicule_licenceplate`,
					`vehicule_country`,
					unix_timestamp(`vehicule_collected`) as vehicule_collected,
					`towing_id`,
					(SELECT concat_ws(' ', first_name, last_name) FROM `T_USERS` WHERE id = `towing_id`) AS `towed_by`,
					`towing_vehicle_id`,
					`towed_by_vehicle`,
					unix_timestamp(`towing_called`) as towing_called,
					unix_timestamp(`towing_arrival`) as towing_arrival,
					unix_timestamp(`towing_start`) as towing_start,
					unix_timestamp(`towing_completed`) as towing_completed,
					`signa_id`,
					(SELECT concat_ws(' ', first_name, last_name) FROM `T_USERS` WHERE id = `signa_id`) AS`signa_by`,
					`signa_by_vehicle`,
					unix_timestamp(`signa_arrival`) as signa_arrival,
					unix_timestamp(`cic`) as cic,
					`status`,
					`additional_info`,
					`cd`,
					`cd_by`,
					`ud`,
					`ud_by`, 
					(SELECT `name` FROM P_DICTIONARY WHERE id = tv.`collector_id`) as `collector_name`,
					(SELECT `name` FROM T_INSURANCES WHERE id = tv.`insurance_id`) as `insurance_name`
			FROM 	T_TOWING_VOUCHERS tv
			WHERE	`dossier_id` = v_dossier_id;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_TOWING_ACTIVITIES_BY_VOUCHER(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_total_incl, v_total_excl DOUBLE(10,2);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		IF p_dossier_id IS NULL THEN
			SELECT 	dossier_id INTO v_dossier_id
			FROM 	T_TOWING_VOUCHERS
			WHERE 	id = p_voucher_id 
			LIMIT 	0,1;
		ELSE
			-- TODO: check link with company
			SELECT 	DISTINCT d.id INTO v_dossier_id
			FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv
			WHERE	d.id = p_dossier_id
					AND d.id = tv.dossier_id;
		END IF; 

		IF v_dossier_id IS NULL THEN
			CALL R_NOT_FOUND;
		ELSE
			SELECT 	sum(ta.cal_fee_excl_vat), sum(ta.cal_fee_incl_vat)
			INTO 	v_total_excl, v_total_incl
			FROM 	T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, P_TIMEFRAME_ACTIVITIES tia
			WHERE 	ta.towing_voucher_id = p_voucher_id
					AND ta.activity_id = taf.id
					AND taf.timeframe_activity_id = tia.id;

			SELECT ta.towing_voucher_id, ta.activity_id, tia.code, tia.name, tia.id as timeframe_activity_id, tia.default_value, tia.is_modifiable,
				   taf.fee_incl_vat, -- format(taf.fee_incl_vat, 2) as fee_incl_vat, 
				   taf.fee_excl_vat, -- format(taf.fee_excl_vat, 2) as fee_excl_vat, 
				   ta.amount, 
				   format(ta.cal_fee_excl_vat, 2, 'nl_BE') as cal_fee_excl_vat, 
				   format(ta.cal_fee_incl_vat, 2, 'nl_BE') as cal_fee_incl_vat ,
				   v_total_incl as total_bill_incl_vat,
				   v_total_excl as total_bill_excl_vat
			FROM T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, P_TIMEFRAME_ACTIVITIES tia
			WHERE ta.towing_voucher_id = p_voucher_id
				AND ta.activity_id = taf.id
				AND taf.timeframe_activity_id = tia.id; 
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_TOWING_PAYMENTS_BY_VOUCHER(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_cal_fee_excl_vat, v_cal_fee_incl_vat DOUBLE(10,2);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- TODO: check link with company
		SELECT 	DISTINCT d.id INTO v_dossier_id
		FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv
		WHERE	d.id = p_dossier_id
				AND d.id = tv.dossier_id
				AND tv.id = p_voucher_id;

		IF v_dossier_id IS NULL THEN
			CALL R_NOT_FOUND;
		ELSE
			SELECT 	sum(cal_fee_excl_vat), sum(cal_fee_incl_vat) INTO v_cal_fee_excl_vat, v_cal_fee_incl_vat
			FROM 	T_TOWING_ACTIVITIES
			WHERE 	towing_voucher_id = p_voucher_id;

			SELECT	*, v_cal_fee_excl_vat as total_excl_vat, v_cal_fee_incl_vat as total_incl_vat
			FROM 	T_TOWING_VOUCHER_PAYMENTS
			WHERE	`towing_voucher_id` = p_voucher_id;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_TOWING_DEPOT(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_name, v_street, v_street_number, v_street_pobox, v_zip, v_city VARCHAR(255);
	DECLARE v_display_name VARCHAR(500);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`name`, street, street_number, street_pobox, zip, city
		INTO 	v_name, v_street, v_street_number, v_street_pobox, v_zip, v_city
		FROM 	T_TOWING_DEPOTS
		WHERE 	voucher_id = p_voucher_id
		LIMIT 	0,1;

		IF v_name IS NOT NULL THEN
			SET v_display_name = v_name;

			SET v_display_name = trim(concat(v_display_name, ', ', IFNULL(v_street, '')));
			SET v_display_name = trim(concat(v_display_name, ' ', IFNULL(v_street_number, '')));
		
			IF v_street_pobox IS NOT NULL AND trim(v_street_pobox) != '' THEN
				SET v_display_name = trim(concat(v_display_name, '/', IFNULL(v_street_pobox, '')));
			END IF;

			SET v_display_name = trim(concat(v_display_name, ', ', IFNULL(v_zip, '')));
			SET v_display_name = trim(concat(v_display_name, ' ', IFNULL(v_city, '')));
		END IF;

		SELECT 	id, name, street, street_number, street_pobox, zip, city, default_depot, v_display_name as display_name 
		FROM 	T_TOWING_DEPOTS
		WHERE 	voucher_id = p_voucher_id
		LIMIT 	0,1;
	END IF;
END $$


CREATE PROCEDURE R_UPDATE_TOWING_DEPOT(IN p_depot_id BIGINT, IN p_voucher_id BIGINT, 
                                       IN p_name VARCHAR(255), IN p_street VARCHAR(255), 
									   IN p_number VARCHAR(45), IN p_pobox VARCHAR(45), IN p_zip VARCHAR(45),
									   IN p_city VARCHAR(255),
									   IN p_default_depot BOOL,
									   IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE `T_TOWING_DEPOTS`
		SET
			`name` = p_name,
			`street` = p_street,
			`street_number` = p_number,
			`street_pobox` = p_pobox,
			`zip` = p_zip,
			`city` = p_city,
			`default_depot` = p_default_depot,
			`ud` = now(),
			`ud_by` = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE `id` = p_depot_id AND `voucher_id` = p_voucher_id;

		SELECT p_depot_id as id;
	END IF; 
END $$

CREATE PROCEDURE R_UPDATE_TOWING_CUSTOMER_TO_AGENCY(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	DECLARE v_company_name, v_company_vat, v_street, v_city, v_country, v_email VARCHAR(255);
	DECLARE v_street_number, v_street_pobox, v_zip, v_phone VARCHAR(45);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	aa.company_name, aa.company_vat, aa.street, aa.street_number, aa.street_pobox, aa.zip, aa.city, aa.country, aa.phone, aa.email
		INTO	v_company_name, v_company_vat, v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country, v_phone, v_email
		FROM 	P_ALLOTMENT_AGENCY aa, 
				P_ALLOTMENT a, 
				T_DOSSIERS d, 
				T_TOWING_VOUCHERS tv
		WHERE 	a.allotment_agency_id = aa.id
				AND a.id = d.allotment_id
				AND d.id = tv.dossier_id
				AND tv.id = p_voucher_id
		LIMIT 0,1;

		CALL R_UPDATE_TOWING_CUSTOMER((SELECT id FROM T_TOWING_CUSTOMERS WHERE voucher_id = p_voucher_id LIMIT 0,1),
									  p_voucher_id, 'AGENCY', null, null, v_company_name, v_company_vat,
									  v_street, v_street_number, v_street_pobox, v_zip, v_city, v_country, v_phone, v_email,
									  null,
									  p_token);
	END IF;
END $$


CREATE PROCEDURE R_UPDATE_TOWING_CUSTOMER(IN p_id BIGINT, IN p_voucher_id BIGINT,
										  IN p_type ENUM('DEFAULT', 'AGENCY'),
										  IN p_firstname VARCHAR(255), IN p_lastname VARCHAR(255),
										  IN p_company_name VARCHAR(255), IN p_company_vat VARCHAR(255),
										  IN p_street VARCHAR(255), IN p_street_number VARCHAR(45), IN p_street_pobox VARCHAR(45),
										  IN p_zip VARCHAR(45), IN p_city VARCHAR(255), IN p_country VARCHAR(255),
										  IN p_phone VARCHAR(45), IN p_email VARCHAR(255),
										  IN p_invoice_ref VARCHAR(255),
										  IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE `T_TOWING_CUSTOMERS`
		SET
			`type` = IFNULL(p_type, 'DEFAULT'),
			`first_name` = p_firstname,
			`last_name` = p_lastname,
			`company_name` = p_company_name,
			`company_vat` = p_company_vat,
			`company_vat_foreign_country` = IF(TRIM(IFNULL(p_company_vat, '')) = '', null, UPPER(LEFT(p_company_vat, 2)) != 'BE'),
			`street` = p_street,
			`street_number` = p_street_number,
			`street_pobox` = p_street_pobox,
			`zip` = p_zip,
			`city` = p_city,
			`country` = p_country,
			`phone` = p_phone,
			`email`= p_email,
			`invoice_ref` = p_invoice_ref,
			`ud` = now(),
			`ud_by` = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE `id` = p_id AND `voucher_id`= p_voucher_id
		LIMIT 1;

		SELECT p_id as id;
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_TOWING_CAUSER(  IN p_id BIGINT, IN p_voucher_id BIGINT,
										  IN p_firstname VARCHAR(255), IN p_lastname VARCHAR(255),
										  IN p_company_name VARCHAR(255), IN p_company_vat VARCHAR(255),
										  IN p_street VARCHAR(255), IN p_street_number VARCHAR(45), IN p_street_pobox VARCHAR(45),
										  IN p_zip VARCHAR(45), IN p_city VARCHAR(255), IN p_country VARCHAR(255),
										  IN p_phone VARCHAR(45), IN p_email VARCHAR(255),
										  IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		UPDATE `T_TOWING_INCIDENT_CAUSERS`
		SET
			`first_name` = p_firstname,
			`last_name` = p_lastname,
			`company_name` = p_company_name,
			`company_vat` = p_company_vat,
			`company_vat_foreign_country` = IF(TRIM(IFNULL(p_company_vat, '')) = '', null, UPPER(LEFT(p_company_vat, 2)) != 'BE'),
			`street` = p_street,
			`street_number` = p_street_number,
			`street_pobox` = p_street_pobox,
			`zip` = p_zip,
			`city` = p_city,
			`country` = p_country,
            `phone` = p_phone,
			`email` = p_email,
			`ud` = now(),
			`ud_by` = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE `id` = p_id AND `voucher_id`= p_voucher_id;

		SELECT p_id AS id;
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_TOWING_VOUCHER_ACTIVITY(IN p_voucher_id BIGINT, IN p_activity_id BIGINT, IN p_amount DOUBLE, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id, v_timeframe_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_fee_excl_vat, v_fee_incl_vat DOUBLE;
	DECLARE v_call_date DATETIME;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	d.call_date, d.timeframe_id INTO v_call_date, v_timeframe_id
		FROM 	T_TOWING_VOUCHERS tv, T_DOSSIERS d
		WHERE 	tv.id = p_voucher_id 
				AND d.id = tv.dossier_id;

		SELECT 	taf.fee_excl_vat, taf.fee_incl_vat
		INTO	v_fee_excl_vat, v_fee_incl_vat
		FROM   `P_TIMEFRAME_ACTIVITY_FEE` taf
		WHERE 	1 = 1
				AND id = p_activity_id 
				AND timeframe_id = v_timeframe_id
				AND v_call_date BETWEEN taf.valid_from AND taf.valid_until
		LIMIT 	0,1;

		INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
		VALUES (p_voucher_id, p_activity_id, p_amount, (IFNULL(p_amount, 1) * v_fee_excl_vat), (IFNULL(p_amount, 1) * v_fee_incl_vat))
		ON DUPLICATE KEY UPDATE amount = p_amount, 
								cal_fee_excl_vat = (IFNULL(p_amount, 1) * v_fee_excl_vat), 
								cal_fee_incl_vat = (IFNULL(p_amount, 1) * v_fee_incl_vat);
	END IF;
END $$

CREATE PROCEDURE R_REMOVE_TOWING_VOUCHER_ACTIVITY(IN p_voucher_id BIGINT, IN p_activity_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_fee_excl_vat, v_fee_incl_vat DOUBLE;
	DECLARE v_cal_fee_excl_vat, v_cal_fee_incl_vat, v_paid DOUBLE(10,2);
	DECLARE v_foreign_vat BOOL;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SET v_foreign_vat = F_IS_VOUCHER_VIABLE_FOR_FOREIGN_VAT(p_voucher_id);

		DELETE 
		FROM 	T_TOWING_ACTIVITIES 
		WHERE 	towing_voucher_id = p_voucher_id 
				AND activity_id = p_activity_id
		LIMIT 1;

		SELECT 	sum(cal_fee_excl_vat), sum(cal_fee_incl_vat) INTO v_cal_fee_excl_vat, v_cal_fee_incl_vat
		FROM 	T_TOWING_ACTIVITIES
		WHERE 	towing_voucher_id = p_voucher_id;

		-- SET v_paid = IFNULL(p_in_cash, 0.0) + IFNULL(p_bank_deposit, 0.0) + IFNULL(p_debit_card, 0.0) + IFNULL(p_credit_card, 0.0);
	
		UPDATE `T_TOWING_VOUCHER_PAYMENTS`
		SET
			`amount_customer` = IF(v_foreign_vat, v_cal_fee_excl_vat, v_cal_fee_incl_vat) - IFNULL(`amount_guaranteed_by_insurance`, 0.0),
			`ud` = now(),
			`ud_by` = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE `towing_voucher_id` = p_voucher_id;


		SELECT 'OK' as result;
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_TOWING_VOUCHER_PAYMENTS(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT,
												  IN p_guarantee_insurance DOUBLE(10,2),
												  IN p_in_cash DOUBLE(10,2), IN p_bank_deposit DOUBLE(10,2), IN p_debit_card DOUBLE(10,2), IN p_credit_card DOUBLE(10,2),
												  IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_cal_fee_excl_vat, v_cal_fee_incl_vat, v_paid, v_unpaid DOUBLE(10,2);
	DECLARE v_foreign_vat BOOL;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SET v_foreign_vat = F_IS_VOUCHER_VIABLE_FOR_FOREIGN_VAT(p_voucher_id);

		SELECT 	sum(cal_fee_excl_vat), sum(cal_fee_incl_vat) INTO v_cal_fee_excl_vat, v_cal_fee_incl_vat
		FROM 	T_TOWING_ACTIVITIES
		WHERE 	towing_voucher_id = p_voucher_id;

		SET v_paid = IFNULL(p_in_cash, 0.0) + IFNULL(p_bank_deposit, 0.0) + IFNULL(p_debit_card, 0.0) + IFNULL(p_credit_card, 0.0);
	
		SET v_unpaid = IF(v_foreign_vat, v_cal_fee_excl_vat, v_cal_fee_incl_vat) - IFNULL(p_guarantee_insurance, 0.0) - v_paid;

		IF v_unpaid < 0 THEN
			SET v_unpaid = 0.0;
		END IF;

		UPDATE `T_TOWING_VOUCHER_PAYMENTS`
		SET
			`amount_guaranteed_by_insurance` = p_guarantee_insurance,
			`amount_customer` = IF(v_foreign_vat, v_cal_fee_excl_vat, v_cal_fee_incl_vat) - IFNULL(p_guarantee_insurance, 0.0),
			`paid_in_cash` = p_in_cash,
			`paid_by_bank_deposit` = p_bank_deposit,
			`paid_by_debit_card` = p_debit_card,
			`paid_by_credit_card` = p_credit_card,
			`cal_amount_paid` = v_paid,
			`cal_amount_unpaid` = v_unpaid,
			`ud` = now(),
			`ud_by` = F_RESOLVE_LOGIN(v_user_id, p_token)
		WHERE `towing_voucher_id` = p_voucher_id;

		CALL R_FETCH_TOWING_PAYMENTS_BY_VOUCHER(p_dossier_id, p_voucher_id, p_token);
	END IF;
END $$

CREATE PROCEDURE R_FETCH_TOWING_COMPANY_BY_DOSSIER(IN p_dossier_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT c.`id`,
			`name`,
			`code`,
			`street`, `street_number`, `street_pobox`, `zip`, `city`,
			`phone`, `fax`, `email`,
			`website`, `vat`
		FROM `T_COMPANIES` c, `T_DOSSIERS` d
		WHERE c.id = d.company_id AND d.id = p_dossier_id
		LIMIT 0,1;

	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_DOSSIERS_BY_FILTER(IN p_filter VARCHAR(25), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		CASE p_filter
			WHEN 'NOT COLLECTED' THEN
				SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
				FROM 	`T_TOWING_VOUCHERS`t, T_TOWING_DEPOTS td,
						`T_DOSSIERS` d, 
						`P_ALLOTMENT_DIRECTIONS` ad, 
						`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
						`T_COMPANIES` c,
						`P_INCIDENT_TYPES` ip
				WHERE 	d.id = t.dossier_id
						AND td.voucher_id = t.id
						AND d.company_id IN (SELECT v_company_id UNION SELECT delegate_company_id FROM T_COMPANY_MAP WHERE supervisor_company_id = v_company_id)
						AND d.company_id = c.id
						AND d.incident_type_id = ip.id
						AND d.allotment_direction_id = ad.id
						AND d.allotment_direction_indicator_id = adi.id
						AND t.status NOT IN ('NEW', 'IN PROGRESS')
						AND vehicule_collected IS NULL
						AND td.default_depot = 1
				ORDER BY call_date DESC
				LIMIT 0,1000; 
			WHEN 'AGENCY' THEN
				SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
				FROM 	`T_TOWING_VOUCHERS`t, 
						`T_TOWING_CUSTOMERS` tc,
						`T_DOSSIERS` d, 
						`P_ALLOTMENT_DIRECTIONS` ad, 
						`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
						`T_COMPANIES` c,
						`P_INCIDENT_TYPES` ip
				WHERE 	d.id = t.dossier_id
						AND d.company_id IN (SELECT v_company_id UNION SELECT delegate_company_id FROM T_COMPANY_MAP WHERE supervisor_company_id = v_company_id)
						AND d.company_id = c.id
						AND d.incident_type_id = ip.id
						AND d.allotment_direction_id = ad.id
						AND d.allotment_direction_indicator_id = adi.id
						AND tc.voucher_id = t.id
						AND (tc.type = 'AGENCY' OR t.status = 'AGENCY')
				UNION DISTINCT
				SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
				FROM 	`T_TOWING_VOUCHERS`t, 
						`T_DOSSIERS` d, 
						`P_ALLOTMENT_DIRECTIONS` ad, 
						`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
						`T_COMPANIES` c,
						`P_INCIDENT_TYPES` ip
				WHERE 	d.id = t.dossier_id
						AND d.company_id IN (SELECT v_company_id UNION SELECT delegate_company_id FROM T_COMPANY_MAP WHERE supervisor_company_id = v_company_id)
						AND d.company_id = c.id
						AND d.incident_type_id = ip.id
						AND d.allotment_direction_id = ad.id
						AND d.allotment_direction_indicator_id = adi.id
						AND ip.code_agency IN ('SIGNA_BRANDWEER', 'VERLOREN_VOORWERP', 'SIGNA_AWV')
				UNION DISTINCT
				SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
				FROM 	`T_TOWING_VOUCHERS`t, T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, P_TIMEFRAME_ACTIVITIES tac,
						`T_DOSSIERS` d, 
						`P_ALLOTMENT_DIRECTIONS` ad, 
						`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
						`T_COMPANIES` c,
						`P_INCIDENT_TYPES` ip
				WHERE 	d.id = t.dossier_id
						AND d.company_id IN (SELECT v_company_id UNION SELECT delegate_company_id FROM T_COMPANY_MAP WHERE supervisor_company_id = v_company_id)
						AND d.company_id = c.id
						AND d.incident_type_id = ip.id
						AND d.allotment_direction_id = ad.id
						AND d.allotment_direction_indicator_id = adi.id
						AND t.id = ta.towing_voucher_id 
						AND ta.activity_id = taf.id 
						AND taf.timeframe_activity_id = tac.id  
						AND taf.timeframe_id = d.timeframe_id
						AND tac.code IN ('VERLOREN_VOORWERP', 'LOZE_RIT')
				ORDER BY call_date DESC
				LIMIT 0,1000; 
			WHEN 'ALL' THEN
				SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
				FROM 	`T_TOWING_VOUCHERS`t, 
						`T_DOSSIERS` d, 
						`P_ALLOTMENT_DIRECTIONS` ad, 
						`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
						`T_COMPANIES` c,
						`P_INCIDENT_TYPES` ip
				WHERE 	d.id = t.dossier_id
						AND d.company_id IN (SELECT v_company_id UNION SELECT delegate_company_id FROM T_COMPANY_MAP WHERE supervisor_company_id = v_company_id)
						AND d.company_id = c.id
						AND d.incident_type_id = ip.id
						AND d.allotment_direction_id = ad.id
						AND d.allotment_direction_indicator_id = adi.id
				ORDER BY call_date DESC
				LIMIT 0,1000; 
			ELSE
				SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
				FROM 	`T_TOWING_VOUCHERS`t, 
						`T_DOSSIERS` d, 
						`P_ALLOTMENT_DIRECTIONS` ad, 
						`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
						`T_COMPANIES` c,
						`P_INCIDENT_TYPES` ip
				WHERE 	d.id = t.dossier_id
						AND d.company_id IN (SELECT v_company_id UNION SELECT delegate_company_id FROM T_COMPANY_MAP WHERE supervisor_company_id = v_company_id)
						AND d.company_id = c.id
						AND d.incident_type_id = ip.id
						AND d.allotment_direction_id = ad.id
						AND d.allotment_direction_indicator_id = adi.id
						AND t.status = p_filter
				ORDER BY call_date DESC
				LIMIT 0,1000; 
		END CASE;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_DOSSIERS_ASSIGNED_TO_ME_BY_FILTER(IN p_filter VARCHAR(25), IN p_token VARCHAR(255))
BEGIN 
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
		FROM 	`T_TOWING_VOUCHERS`t, 
				`T_DOSSIERS` d, 
				`P_ALLOTMENT_DIRECTIONS` ad, 
				`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
				`T_COMPANIES` c,
				`P_INCIDENT_TYPES` ip
		WHERE 	d.id = t.dossier_id
				AND d.company_id = v_company_id
				AND d.company_id = c.id
				AND d.incident_type_id = ip.id
				AND d.allotment_direction_id = ad.id
				AND d.allotment_direction_indicator_id = adi.id
				AND t.signa_id = v_user_id
				AND t.status = p_filter
		ORDER BY call_date DESC; 	
	END IF;
END $$


CREATE PROCEDURE R_FETCH_ALL_VOUCHERS_BY_FILTER(IN p_filter VARCHAR(25), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
		FROM 	`T_TOWING_VOUCHERS`t, 
				`T_DOSSIERS` d, 
				`P_ALLOTMENT_DIRECTIONS` ad, 
				`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
				`T_COMPANIES` c,
				`P_INCIDENT_TYPES` ip
		WHERE 	d.id = t.dossier_id
				AND d.company_id = v_company_id
				AND d.company_id = c.id
				AND d.incident_type_id = ip.id
				AND d.allotment_direction_id = ad.id
				AND d.allotment_direction_indicator_id = adi.id
				AND t.status = p_filter
		ORDER BY d.call_date DESC;
	END IF;
END $$


CREATE PROCEDURE R_FETCH_ALL_AVAILABLE_ACTIVITIES(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_call_date DATE;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	IFNULL(call_date, now()) INTO v_call_date
		FROM 	T_DOSSIERS
		WHERE 	id = p_dossier_id
		LIMIT 	0,1;

		SELECT 	taf.id, ta.name, ta.code, ta.default_value, ta.is_modifiable,
				format(taf.fee_excl_vat, 2) as fee_excl_vat,
				format(fee_incl_vat, 2) as fee_incl_vat
		FROM 	`P_TIMEFRAME_ACTIVITIES` ta, `P_TIMEFRAME_ACTIVITY_FEE` taf
		WHERE 	ta.id = taf.timeframe_activity_id
				AND taf.timeframe_id = (SELECT timeframe_id FROM T_DOSSIERS WHERE id = p_dossier_id)
				AND taf.id NOT IN (SELECT activity_id FROM T_TOWING_ACTIVITIES WHERE towing_voucher_id = p_voucher_id)
				AND v_call_date BETWEEN taf.valid_from AND taf.valid_until;	
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_TOWING_ACTIVITIES(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_TOWING_ACTIVITIES_BY_VOUCHER(p_dossier_id, p_voucher_id, p_token);
END $$

CREATE PROCEDURE R_FETCH_ALL_ALLOTMENTS_BY_DIRECTION(IN p_direction_id BIGINT, IN p_indicator_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		IF p_indicator_id IS NULL THEN
			SELECT DISTINCT a.id, a.name
			FROM 			P_ALLOTMENT_MAP am, P_ALLOTMENT a 
			WHERE 			am.allotment_id = a.id
							AND am.direction_id = p_direction_id
			ORDER BY		name;
		ELSE
			SELECT DISTINCT a.id, a.name
			FROM 			P_ALLOTMENT_MAP am, P_ALLOTMENT a 
			WHERE 			am.allotment_id = a.id
							AND am.direction_id = p_direction_id
							AND am.indicator_id = p_indicator_id
			ORDER BY		name;
		END IF;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_COMPANIES_BY_ALLOTMENT(IN p_allotment_id BIGINT, IN p_token VARCHAR(255))
BEGIN 
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT c.*
		FROM T_COMPANY_ALLOTMENTS ca, T_COMPANIES c
		WHERE ca.allotment_id = 1
			AND c.id = ca.company_id;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_TRAFFIC_POSTS_BY_ALLOTMENT(IN p_allotment_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`id`, `name`, `code`, `address`, `phone`
		FROM 	`P_POLICE_TRAFFIC_POSTS` 
		WHERE 	`allotment_id` = p_allotment_id
		ORDER BY `code`;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_DOSSIER_TRAFFIC_LANES(IN p_dossier_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	d.id, d.name, true as selected 
		FROM 	P_DICTIONARY d, T_INCIDENT_TRAFFIC_LANES itl
		WHERE 	category='TRAFFIC_LANE'
				AND d.id = itl.traffic_lane_id
				AND itl.dossier_id = p_dossier_id
		UNION
		SELECT 	d.id, d.name, false as selected 
		FROM 	P_DICTIONARY d
		WHERE 	category='TRAFFIC_LANE'
				AND d.id NOT IN (SELECT traffic_lane_id FROM T_INCIDENT_TRAFFIC_LANES WHERE dossier_id=p_dossier_id)
		ORDER BY name;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_TOWING_CUSTOMER(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT	id, voucher_id, `type`, first_name, last_name, company_name, company_vat, company_vat_foreign_country, street, street_number, street_pobox, zip, city, country, phone, email, invoice_ref
		FROM 	T_TOWING_CUSTOMERS
		WHERE 	voucher_id = p_voucher_id
		LIMIT 	0,1;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_TOWING_CAUSER(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT	id, voucher_id, first_name, last_name, company_name, company_vat, company_vat_foreign_country, street, street_number, street_pobox, zip, city, country, phone, email
		FROM 	T_TOWING_INCIDENT_CAUSERS
		WHERE 	voucher_id = p_voucher_id
		LIMIT 	0,1;
	END IF;
END $$

CREATE PROCEDURE R_ADD_BLOB_TO_VOUCHER(IN p_voucher_id BIGINT, IN p_category ENUM('SIGNATURE_COLLECTOR', 'SIGNATURE_POLICE', 'SIGNATURE_CAUSER', 'ASSISTANCE_ATT', 'ATT', 'VEHICLE_DAMAGE'),
									   IN p_name VARCHAR(255), IN p_content_type VARCHAR(255), IN p_file_size INT,
									   IN p_content LONGTEXT,
									   IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_blob_id, v_doc_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO `T_DOCUMENT_BLOB`(`content`) VALUES(p_content);

		SET v_blob_id = LAST_INSERT_ID();

		INSERT INTO `T_DOCUMENTS` (`document_blob_id`, `name`, `content_type`, `file_size`, `cd`, `cd_by`)
		VALUES (v_blob_id, p_name, p_content_type, p_file_size, now(), F_RESOLVE_LOGIN(v_user_id, p_token));

		SET v_doc_id = LAST_INSERT_ID();

		IF p_category = 'VEHICLE_DAMAGE' THEN
			-- there can only be one vehicle damage report, but keep the others
			UPDATE `T_TOWING_VOUCHER_ATTS` 
			SET 
				dd = now(), 
				dd_by = F_RESOLVE_LOGIN(v_user_id, p_token) 
			WHERE 
				`towing_voucher_id` = p_voucher_id 
				AND `category` = p_category;
		END IF;
		
		INSERT INTO `T_TOWING_VOUCHER_ATTS` (`towing_voucher_id`, `document_id`, `category`, `cd`, `cd_by`) 
		VALUES (p_voucher_id, v_doc_id, p_category, now(), F_RESOLVE_LOGIN(v_user_id, p_token));
		

		SELECT LAST_INSERT_ID() as attachment_id, 'OK' as result;
	END IF;
END $$

CREATE PROCEDURE R_ADD_COLLECTOR_SIGNATURE(IN p_voucher_id BIGINT, IN p_content_type VARCHAR(255), IN p_file_size INT,
										   IN p_content LONGTEXT,
									       IN p_token VARCHAR(255))
BEGIN
	CALL R_ADD_BLOB_TO_VOUCHER(p_voucher_id, 'SIGNATURE_COLLECTOR', 'signature_collector.png', p_content_type, p_file_size, p_content, p_token);
END $$

CREATE PROCEDURE R_ADD_CAUSER_SIGNATURE(IN p_voucher_id BIGINT, IN p_content_type VARCHAR(255), IN p_file_size INT,
									    IN p_content LONGTEXT,
									    IN p_token VARCHAR(255))
BEGIN
	CALL R_ADD_BLOB_TO_VOUCHER(p_voucher_id, 'SIGNATURE_CAUSER', 'signature_causer.png', p_content_type, p_file_size, p_content, p_token);
END $$

CREATE PROCEDURE R_ADD_POLICE_SIGNATURE(IN p_voucher_id BIGINT, IN p_content_type VARCHAR(255), IN p_file_size INT,
										IN p_content LONGTEXT,
									    IN p_token VARCHAR(255))
BEGIN
	DECLARE v_dossier_id, v_timeframe_id BIGINT;

	CALL R_ADD_BLOB_TO_VOUCHER(p_voucher_id, 'SIGNATURE_POLICE', 'signature_police.png', p_content_type, p_file_size, p_content, p_token);

	UPDATE 	`T_TOWING_VOUCHERS` 
	SET 	`police_signature_dt` = now() 
	WHERE 	id = p_voucher_id 
	LIMIT 	1;

	SELECT 	dossier_id, timeframe_id INTO v_dossier_id, v_timeframe_id
	FROM 	`T_TOWING_VOUCHERS` tv, `T_DOSSIERS` d
	WHERE 	tv.id = p_voucher_id AND tv.dossier_id = d.id
	LIMIT 	0,1;

	-- ???? CALL R_UPDATE_TOWING_STORAGE_COST_FOR_VOUCHER(p_voucher_id, v_dossier_id, v_timeframe_id);
END $$

CREATE PROCEDURE  R_ADD_INSURANCE_DOCUMENT(IN p_voucher_id BIGINT, IN p_filename VARCHAR(255), 
										   IN p_content_type VARCHAR(255), IN p_file_size INT,
										   IN p_content LONGTEXT,
									       IN p_token VARCHAR(255))
BEGIN
	CALL R_ADD_BLOB_TO_VOUCHER(p_voucher_id, 'ASSISTANCE_ATT', p_filename, p_content_type, p_file_size, p_content, p_token);
END $$

CREATE PROCEDURE  R_ADD_VEHICLE_DAMAGE_DOCUMENT(IN p_voucher_id BIGINT, IN p_filename VARCHAR(255), 
									 IN p_content_type VARCHAR(255), IN p_file_size INT,
									 IN p_content LONGTEXT,
									 IN p_token VARCHAR(255))
BEGIN
	CALL R_ADD_BLOB_TO_VOUCHER(p_voucher_id, 'VEHICLE_DAMAGE', p_filename, p_content_type, p_file_size, p_content, p_token);
END $$

CREATE PROCEDURE  R_ADD_ANY_DOCUMENT(IN p_voucher_id BIGINT, IN p_filename VARCHAR(255), 
									 IN p_content_type VARCHAR(255), IN p_file_size INT,
									 IN p_content LONGTEXT,
									 IN p_token VARCHAR(255))
BEGIN
	CALL R_ADD_BLOB_TO_VOUCHER(p_voucher_id, 'ATT', p_filename, p_content_type, p_file_size, p_content, p_token);
END $$

CREATE PROCEDURE R_FETCH_SIGNATURE_BY_VOUCHER(IN p_voucher_id BIGINT, IN p_category VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_doc_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	document_id INTO v_doc_id
		FROM 	`T_TOWING_VOUCHER_ATTS`
		WHERE 	towing_voucher_id = p_voucher_id AND category = p_category
		ORDER 	BY id DESC
		LIMIT 	0,1;

		SELECT 	document_blob_id, name, content_type, file_size
		FROM	T_DOCUMENTS
		WHERE	id = v_doc_id;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_CAUSER_SIGNATURE_BY_VOUCHER(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_SIGNATURE_BY_VOUCHER(p_voucher_id, 'SIGNATURE_CAUSER', p_token); 
END $$

CREATE PROCEDURE R_FETCH_CAUSER_SIGNATURE_BLOB_BY_VOUCHER(IN p_voucher_id BIGINT, IN p_token VARCHAR(255)) 
BEGIN
	CALL R_FETCH_VOUCHER_SIGNATURE(p_voucher_id, 'SIGNATURE_CAUSER', p_token);
END $$

CREATE PROCEDURE R_FETCH_TRAFFIC_POST_SIGNATURE_BLOB_BY_VOUCHER(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_VOUCHER_SIGNATURE(p_voucher_id, 'SIGNATURE_POLICE', p_token);
END $$

CREATE PROCEDURE R_FETCH_COLLECTOR_SIGNATURE_BLOB_BY_VOUCHER(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_VOUCHER_SIGNATURE(p_voucher_id, 'SIGNATURE_COLLECTOR', p_token);
END $$

CREATE PROCEDURE R_FETCH_VOUCHER_SIGNATURE(IN p_voucher_id BIGINT, IN p_category VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_doc_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	document_id INTO v_doc_id
		FROM 	`T_TOWING_VOUCHER_ATTS`
		WHERE 	towing_voucher_id = p_voucher_id 
				AND category = p_category
		ORDER 	BY id DESC
		LIMIT 	0,1;

		SELECT 	content, name, content_type, file_size
		FROM	T_DOCUMENTS d, T_DOCUMENT_BLOB db
		WHERE	d.id = v_doc_id 
				AND d.document_blob_id = db.id;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_COLLECTOR_SIGNATURE_BY_VOUCHER(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_SIGNATURE_BY_VOUCHER(p_voucher_id, 'SIGNATURE_COLLECTOR', p_token); 
END $$

CREATE PROCEDURE R_FETCH_TRAFFIC_POST_SIGNATURE_BY_VOUCHER(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_SIGNATURE_BY_VOUCHER(p_voucher_id, 'SIGNATURE_POLICE', p_token); 
END $$

CREATE PROCEDURE R_FETCH_DOCUMENT_BY_ID(IN p_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_doc_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	name, content_type, file_size, `content` as data
		FROM 	`T_DOCUMENT_BLOB` db, `T_DOCUMENTS` d
		WHERE 	d.document_blob_id = db.id 
				AND db.id = p_id
		LIMIT 	0,1;

	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_VOUCHER_DOCUMENTS(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_doc_id BIGINT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT  d.id, d.name, d.content_type, d.file_size, tva.category
		FROM 	T_TOWING_VOUCHER_ATTS tva, T_DOCUMENTS d
		WHERE	tva.towing_voucher_id = p_voucher_id
				AND tva.document_id = d.id
				AND tva.category IN ('ASSISTANCE_ATT','ATT', 'VEHICLE_DAMAGE')
				AND tva.dd IS NULL;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_ALL_DOSSIER_COMMUNICATIONS(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, 
													IN p_type ENUM('INTERNAL', 'EMAIL'), 
													IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		IF p_voucher_id IS NULL THEN
			SELECT 	* 
			FROM 	`T_DOSSIER_COMMUNICATIONS` 
			WHERE 	dossier_id = p_dossier_id 
					AND `type` = p_type
			ORDER 	BY cd DESC;
		ELSE
			SELECT 	* 
			FROM 	`T_DOSSIER_COMMUNICATIONS` 
			WHERE 	dossier_id = p_dossier_id 
					AND towing_voucher_id = p_voucher_id 
					AND `type` = p_type
			ORDER 	BY cd DESC;
		END IF;
	END IF;

END $$

CREATE PROCEDURE R_FETCH_ALL_INTERNAL_COMMUNICATIONS(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_ALL_DOSSIER_COMMUNICATIONS(p_dossier_id, p_voucher_id, 'INTERNAL', p_token);
END $$

CREATE PROCEDURE R_FETCH_ALL_EMAIL_COMMUNICATIONS(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	CALL R_FETCH_ALL_DOSSIER_COMMUNICATIONS(p_dossier_id, p_voucher_id, 'EMAIL', p_token);
END $$

CREATE PROCEDURE R_FETCH_ALL_DOSSIER_COMM_RECIPIENTS(IN p_communication_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	`type`, `email_address`
		FROM 	`T_RECIPIENTS` r, `T_DOSSIER_COMMUNICATIONS` dc
		WHERE	r.dossier_communication_id = dc.id
				AND dc.id = p_communication_id
				AND dc.type = 'EMAIL';
		
	END IF;
END $$

CREATE PROCEDURE R_CREATE_DOSSIER_COMMUNICATION(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT,
												IN p_type ENUM('INTERNAL', 'EMAIL'),
												IN p_subject VARCHAR(255), IN p_message TEXT,
												IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO `T_DOSSIER_COMMUNICATIONS` (`dossier_id`, `towing_voucher_id`, `type`, `subject`, `message`, `cd`, `cd_by`) 
		VALUES (p_dossier_id, p_voucher_id, p_type, p_subject, p_message, now(), F_RESOLVE_LOGIN(v_user_id, p_token));

		SELECT LAST_INSERT_ID() as communication_id, 'OK' as result;
	END IF;
END $$

CREATE PROCEDURE R_CREATE_DOSSIER_COMM_RECIPIENT(IN p_communication_id BIGINT, 
											     IN p_type ENUM('TO', 'CC', 'BCC'),
												 IN p_email VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO `T_RECIPIENTS`(`dossier_communication_id`, `type`, `email_address`)
		VALUES(p_communication_id, p_type, p_email);

		SELECT LAST_INSERT_ID() as recipient, 'OK' as result;
	END IF;
END $$

CREATE PROCEDURE R_FETCH_COMM_AND_ATT_SUMMARY(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 'INTERNAL' as `type`, count(*) as `number` FROM T_DOSSIER_COMMUNICATIONS WHERE dossier_id=p_dossier_id AND type='INTERNAL'
		union
		SELECT 'EMAIL', count(*) FROM T_DOSSIER_COMMUNICATIONS WHERE dossier_id=p_dossier_id AND type='EMAIL'
		union
		SELECT 'ATT', count(*) FROM T_TOWING_VOUCHER_ATTS WHERE towing_voucher_id = p_voucher_id;
	END IF;
END $$

CREATE PROCEDURE R_SEARCH_TOWING_VOUCHER(IN p_call_number VARCHAR(45), IN p_date LONG, IN p_type VARCHAR(255), IN p_licence_plate VARCHAR(15), IN p_customer_name VARCHAR(255), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SET @sql = concat("SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
					FROM 	`T_TOWING_VOUCHERS`t, 
                            `T_TOWING_CUSTOMERS` cu,
							`T_DOSSIERS` d, 
							`P_ALLOTMENT_DIRECTIONS` ad, 
							`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
							`T_COMPANIES` c,
							`P_INCIDENT_TYPES` ip
					WHERE 	d.id = t.dossier_id
							AND d.company_id IN (SELECT ", v_company_id, " UNION SELECT delegate_company_id FROM T_COMPANY_MAP WHERE supervisor_company_id = ", v_company_id, ") 
							AND d.company_id = c.id
							AND cu.voucher_id = t.id
							AND d.incident_type_id = ip.id
							AND d.allotment_direction_id = ad.id
							AND d.allotment_direction_indicator_id = adi.id");

		IF TRIM(IFNULL(p_call_number, ""))  != '' THEN
			SET @sql = concat(@sql, " AND d.call_number LIKE '%", p_call_number, "%'");
		END IF ;

		IF TRIM(IFNULL(p_type, ""))  != '' THEN
			SET @sql = concat(@sql, " AND (t.vehicule_type LIKE '%", p_type, "%' OR t.vehicule LIKE '%", p_type, "%')");
		END IF ;

		IF TRIM(IFNULL(p_licence_plate, ""))  != '' THEN
			SET @sql = concat(@sql, " AND t.vehicule_licenceplate LIKE '%", p_licence_plate, "%'");
		END IF ;

		IF TRIM(IFNULL(p_date, ""))  != '' THEN
			SET @sql = concat(@sql, " AND UNIX_TIMESTAMP(DATE(d.call_date)) = ", p_date, "");
		END IF ;

		IF TRIM(IFNULL(p_customer_name, "")) != "" THEN
			SET @sql = concat(@sql, " AND (cu.first_name LIKE '%", p_customer_name, "%' OR cu.last_name LIKE '%", p_customer_name, "%' OR cu.company_name LIKE '%", p_customer_name, "%') ");
		END IF;

		SET @sql = concat(@sql, " ORDER BY d.call_date DESC");

		PREPARE STMT FROM @sql;
		EXECUTE STMT;
	END IF;
END $$

CREATE PROCEDURE R_SEARCH_TOWING_VOUCHER_BY_NUMBER(IN p_number VARCHAR(45), IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SET @sql = concat("SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, d.dossier_number, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
					FROM 	`T_TOWING_VOUCHERS`t, 
							`T_DOSSIERS` d, 
							`P_ALLOTMENT_DIRECTIONS` ad, 
							`P_ALLOTMENT_DIRECTION_INDICATORS` adi,
							`T_COMPANIES` c,
							`P_INCIDENT_TYPES` ip
					WHERE 	d.id = t.dossier_id
							AND d.company_id IN (SELECT ? UNION SELECT delegate_company_id FROM T_COMPANY_MAP WHERE supervisor_company_id = ?)
							AND d.company_id = c.id
							AND d.incident_type_id = ip.id
							AND d.allotment_direction_id = ad.id
							AND d.allotment_direction_indicator_id = adi.id
							AND voucher_number LIKE '%", p_number, "%'
					ORDER BY d.call_date DESC");

		SET @v_number = p_number;
		SET @v_company = v_company_id;

		PREPARE STMT FROM @sql;
		EXECUTE STMT USING @v_company, @v_company;
	END IF;
END $$

CREATE PROCEDURE R_PURGE_DOSSIER_TRAFFIC_LANES(IN p_dossier_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		DELETE FROM T_INCIDENT_TRAFFIC_LANES WHERE dossier_id = p_dossier_id;

		SELECT 'OK' as result;
	END IF;
END $$

CREATE PROCEDURE R_CREATE_DOSSIER_TRAFFIC_LANES(IN p_dossier_id BIGINT, IN p_traffic_lane_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		INSERT INTO T_INCIDENT_TRAFFIC_LANES(dossier_id, traffic_lane_id)
		VALUES(p_dossier_id, p_traffic_lane_id);

		CALL R_FETCH_ALL_DOSSIER_TRAFFIC_LANES(p_dossier_id, p_token);
	END IF;
END $$

CREATE PROCEDURE R_CREATE_VOUCHER_VALIDATION_MESSAGE(IN p_voucher_id BIGINT, IN p_code VARCHAR(45), IN p_message VARCHAR(512))
BEGIN
	INSERT IGNORE INTO T_TOWING_VOUCHER_VALIDATION_MESSAGES(`towing_voucher_id`,`code`,`message`)
	VALUES(p_voucher_id, p_code, p_message);
END $$

CREATE PROCEDURE R_FETCH_ALL_VOUCHER_VALIDATION_MESSAGES(IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	* 
		FROM 	T_TOWING_VOUCHER_VALIDATION_MESSAGES 
		WHERE 	towing_voucher_id = p_voucher_id;
	END IF;
END $$

-- ---------------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------------

CREATE TRIGGER `TRG_AI_DOSSIER` AFTER INSERT ON `T_DOSSIERS`
FOR EACH ROW
BEGIN
	CALL R_ADD_DOSSIER_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AU_DOSSIER` AFTER UPDATE ON `T_DOSSIERS` 
FOR EACH ROW
BEGIN
	DECLARE v_incident_type_code VARCHAR(45);

	CALL R_ADD_DOSSIER_AUDIT_LOG(NEW.id);

	IF OLD.incident_type_id IS NULL AND NEW.incident_type_id IS NOT NULL THEN
		CALL R_CREATE_DEFAULT_TOWING_VOUCHER_ACTIVITIES(OLD.id, NEW.incident_type_id, NEW.timeframe_id);
	END IF;
END $$

CREATE TRIGGER `TRG_AI_TOWING_VOUCHER` AFTER INSERT ON `T_TOWING_VOUCHERS`
FOR EACH ROW
BEGIN
	CALL R_ADD_TOWING_VOUCHER_AUDIT_LOG(NEW.id);

	-- automatically create a voucher payment record when creating a new towing voucher
	INSERT INTO `T_TOWING_VOUCHER_PAYMENTS` (`towing_voucher_id`, `cd`, `cd_by`) VALUES 
				(NEW.id, now(), NEW.cd_by);

	-- automatically insert a towing depot
	INSERT INTO `T_TOWING_DEPOTS`(`voucher_id`, `name`, `street`, `street_number`, `street_pobox`, `zip`, `city`, `cd`, `cd_by`)	
	VALUES(NEW.id, null, null, null, null, null, null, now(), NEW.cd_by); 

	-- prefill the customer 
	INSERT INTO `T_TOWING_CUSTOMERS` (`voucher_id`, `type`, `cd`, `cd_by`) VALUES (NEW.id, 'DEFAULT', now(), NEW.cd_by);

	-- prefill the causer
	INSERT INTO `T_TOWING_INCIDENT_CAUSERS` (`voucher_id`, `cd`, `cd_by`) VALUES (NEW.id, now(), NEW.cd_by);
END $$

CREATE TRIGGER `TRG_BU_TOWING_VOUCHER` BEFORE UPDATE ON `T_TOWING_VOUCHERS`
FOR EACH ROW
BEGIN
	DECLARE v_first_name, v_last_name, v_company, v_company_vat VARCHAR(255);
	DECLARE v_licence_plate, v_code VARCHAR(15);
	DECLARE v_score, v_count INT;
	DECLARE v_incident_type_code VARCHAR(45);
	DECLARE v_idle_ride, v_lost_object, v_signa_only, v_default_depot, v_has_insurance, v_is_agency BOOL;
	DECLARE v_customer_type ENUM('DEFAULT', 'AGENCY');

	SET v_score = 0;
	SET v_is_agency = false;

	IF NEW.signa_id IS NOT NULL THEN
		SELECT cv.licence_plate INTO v_licence_plate
		FROM T_USERS u, T_COMPANY_VEHICLES cv
		WHERE u.id = NEW.signa_id
				AND u.vehicle_id = cv.id
		LIMIT 0,1;

		SET NEW.signa_by_vehicle = v_licence_plate;
	END IF;

	IF NEW.towing_vehicle_id IS NOT NULL THEN
		SELECT 	cv.licence_plate INTO v_licence_plate
		FROM 	T_COMPANY_VEHICLES cv
		WHERE  	cv.id = NEW.towing_vehicle_id
		LIMIT 	0,1;

		SET NEW.towed_by_vehicle = v_licence_plate;

		IF NEW.towing_called IS NULL THEN
			SELECT 	code INTO v_incident_type_code
			FROM 	P_INCIDENT_TYPES it, T_DOSSIERS d
			WHERE 	it.id = d.incident_type_id
					AND d.id = OLD.dossier_id
			LIMIT 	0,1;

			IF v_incident_type_code IN ('PANNE', 'ONGEVAL', 'ACHTERGELATEN_VOERTUIG') THEN
				SET NEW.towing_called = now();
			END IF;
		END IF;
	END IF;

	IF NEW.towing_completed IS NOT NULL THEN
		-- DELETE THE VALIDATION MESSAGES
		DELETE FROM T_TOWING_VOUCHER_VALIDATION_MESSAGES WHERE towing_voucher_id = OLD.id;

		-- CHECK IF INSURANCE IS SET
		SET v_has_insurance = (NEW.insurance_id IS NOT NULL);

		IF NOT v_has_insurance THEN
			--
			-- CHECK IF CUSTOMER IS SET
			-- 
			SELECT first_name, last_name, company_name, company_vat, (type = 'AGENCY')
			INTO v_first_name, v_last_name, v_company, v_company_vat, v_is_agency
			FROM T_TOWING_CUSTOMERS WHERE voucher_id = OLD.id
			LIMIT 0,1;

			IF TRIM(IFNULL(v_company, "")) != "" THEN
				IF TRIM(IFNULL(v_company_vat, "")) = "" THEN
					SET v_score = v_score + 1;	
					CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(OLD.id, 'CUSTOMER_COMPANY_VAT', 'Het veld BTW-nummer werd niet opgegegeven bij de facturatiegegevens.');
				END IF;
			ELSE
				IF TRIM(IFNULL(v_company, "")) = "" AND TRIM(IFNULL(v_first_name, "")) = "" AND TRIM(IFNULL(v_last_name, "")) = "" THEN
					SET v_score = v_score + 1;
					CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(OLD.id, 'CUSTOMER_NAME', 'De naam van de klant ontbreekt bij de facturatiegegevens.');
				END IF;
			END IF;

		END IF;

		--
		-- check if LOZE_RIT
		-- 
		SELECT 	count(*) > 0 INTO v_idle_ride
		FROM 	T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, P_TIMEFRAME_ACTIVITIES tac
		WHERE 	ta.towing_voucher_id = OLD.id
				AND ta.activity_id = taf.id
				AND taf.timeframe_activity_id = tac.id
				AND tac.code='LOZE_RIT';

		--
		-- check if LOST_OBJECT
		-- 
		SELECT 	count(*) > 0 INTO v_lost_object
		FROM 	T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, P_TIMEFRAME_ACTIVITIES tac
		WHERE 	ta.towing_voucher_id = OLD.id
				AND ta.activity_id = taf.id
				AND taf.timeframe_activity_id = tac.id
				AND tac.code='VERLOREN_VOORWERP';

		--
		-- check if SIGNA_ONLY
		-- 
		SELECT 	count(d.id) > 0 INTO v_signa_only
		FROM 	T_DOSSIERS d, P_INCIDENT_TYPES it
		WHERE 	d.id = OLD.dossier_id
				AND d.incident_type_id = it.id
				AND it.code = 'SIGNALISATIE';

		--
		-- CHECK IF CAUSER IS SET
		-- 
		IF NOT v_idle_ride AND NOT v_lost_object AND NOT v_signa_only AND NOT v_is_agency THEN
			SELECT first_name, last_name, company_name, company_vat
			INTO v_first_name, v_last_name, v_company, v_company_vat
			FROM T_TOWING_INCIDENT_CAUSERS WHERE voucher_id = OLD.id
			LIMIT 0,1;

			IF TRIM(IFNULL(v_company, "")) != "" THEN
				IF TRIM(IFNULL(v_company_vat, "")) = "" THEN
					SET v_score = v_score + 1;
					CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(OLD.id, 'CAUSER_COMPANY_VAT', 'Er werd geen BTW-nummer opgegeven voor de hinderverwekker.');				
				END IF;
			ELSE
				IF TRIM(IFNULL(v_company, "")) = "" AND TRIM(IFNULL(v_first_name, "")) = "" AND TRIM(IFNULL(v_last_name, "")) = "" THEN
					SET v_score = v_score + 1;
					CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(OLD.id, 'CAUSER_NAME', 'De naam van de hinderverwekker ontbreekt.');
				END IF;
			END IF;
		END IF;

		--
		-- CHECK IF CUSTOMER SIGNATURE IS SET
		-- 
		IF NOT v_idle_ride AND NOT v_lost_object AND NOT v_signa_only THEN
			-- CHECK traffic_post

			SELECT code INTO v_code
			FROM P_POLICE_TRAFFIC_POSTS  ptp, T_DOSSIERS d
			WHERE ptp.id = d.police_traffic_post_id
				AND d.id = OLD.dossier_id
			LIMIT 0,1;

			-- IF code IS SET and if team was at the site
			IF v_code IS NOT NULL AND v_code = 'GNPLG' THEN
				SELECT 	count(*) INTO v_count
				FROM 	T_TOWING_VOUCHER_ATTS
				WHERE 	towing_voucher_id = OLD.id
						AND category IN ('SIGNATURE_CAUSER');
			ELSE
				-- team on site
				SELECT 	count(*) INTO v_count
				FROM 	T_TOWING_VOUCHER_ATTS
				WHERE 	towing_voucher_id = OLD.id
						AND category IN ('SIGNATURE_CAUSER', 'SIGNATURE_POLICE');
			END IF;

			IF v_count = 0 THEN
				SET v_score = v_score + 1;
				CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(OLD.id, 'SIGNATURES', 'Controleer of alle vereiste handtekening geplaatst werden.');
			END IF;
		END IF;

		--
		-- CHECK IF VEHICLE IS COLLECTED
		-- 
		IF NOT v_idle_ride AND NOT v_lost_object AND NOT v_signa_only THEN
			-- CHECK DEPOT
			SELECT 	default_depot = 1 INTO v_default_depot
			FROM 	T_TOWING_DEPOTS 
			WHERE 	voucher_id = OLD.id
			LIMIT 	0,1;

			IF v_default_depot AND NEW.vehicule_collected IS NULL THEN
				SET v_score = v_score + 1;
				CALL R_CREATE_VOUCHER_VALIDATION_MESSAGE(OLD.id, 'VEHICLE_DEPOT', 'Het voertuig bevind zich nog in het depot en werd niet afgehaald.');
			END IF;
		END IF;

		-- 
		-- CHECK SCORE, IF > 0 THEN CHANGE STATUS
		--

		IF v_score > 0 THEN
			SET NEW.status = 'TO CHECK';
		ELSE
			SELECT type INTO v_customer_type
			FROM 	T_TOWING_CUSTOMERS
			WHERE 	voucher_id = OLD.id
			LIMIT 	0,1;

			IF NOT v_idle_ride AND NOT v_lost_object THEN
				SET NEW.status = 'READY FOR INVOICE';
			ELSE			
				SET NEW.status = IF(v_customer_type = 'AGENCY', 'AGENCY', 'READY FOR INVOICE');
			END IF;
		END IF;
	END IF;
END $$

CREATE TRIGGER `TRG_AU_TOWING_VOUCHER` AFTER UPDATE ON `T_TOWING_VOUCHERS`
FOR EACH ROW
BEGIN
	DECLARE v_timeframe_id BIGINT;

	CALL R_ADD_TOWING_VOUCHER_AUDIT_LOG(NEW.id);

	SELECT 	timeframe_id INTO v_timeframe_id
	FROM 	T_DOSSIERS
	WHERE 	id = NEW.dossier_id 
	LIMIT 	0,1;

	IF (OLD.vehicule_collected IS NULL AND NEW.vehicule_collected IS NOT NULL) 
		OR (OLD.vehicule_collected != NEW.vehicule_collected) 
	THEN
		CALL R_UPDATE_TOWING_STORAGE_COST_FOR_VOUCHER(NEW.id, NEW.dossier_id, v_timeframe_id);
	END IF;
END $$

CREATE TRIGGER `TRG_BU_TOWING_ACTIVITY` BEFORE UPDATE ON `T_TOWING_ACTIVITIES`
FOR EACH ROW
BEGIN
	DECLARE v_incl_vat, v_excl_vat DOUBLE;
	
	SELECT 	sum(NEW.amount * fee_excl_vat), sum(NEW.amount * fee_incl_vat) INTO v_excl_vat, v_incl_vat
	FROM 	T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf
	WHERE 	ta.activity_id = taf.id 
			AND ta.towing_voucher_id = OLD.towing_voucher_id 
			AND ta.activity_id = OLD.activity_id;

	SET NEW.cal_fee_excl_vat = v_excl_vat;
	SET NEW.cal_fee_incl_vat = v_incl_vat;
END $$

CREATE TRIGGER `TRG_AU_TOWING_ACTIVITY` AFTER UPDATE ON `T_TOWING_ACTIVITIES`
FOR EACH ROW
BEGIN
	DECLARE v_incl_vat, v_excl_vat DOUBLE;
	DECLARE v_foreign_vat BOOL;
	
	SELECT 	sum(amount * fee_excl_vat), sum(amount * fee_incl_vat) INTO v_excl_vat, v_incl_vat
	FROM 	T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf
	WHERE 	ta.activity_id = taf.id AND ta.towing_voucher_id = NEW.towing_voucher_id;


	SET v_foreign_vat = F_IS_VOUCHER_VIABLE_FOR_FOREIGN_VAT(NEW.towing_voucher_id);


	UPDATE `T_TOWING_VOUCHER_PAYMENTS` 
	SET 	`amount_customer` = IF(v_foreign_vat, v_excl_vat, v_incl_vat), 
			`cal_amount_paid` = 0, 
			`cal_amount_unpaid` = IF(v_foreign_vat, v_excl_vat, v_incl_vat), 
			`ud` = now(), `ud_by` = (SELECT ud_by FROM T_TOWING_ACTIVITIES WHERE id = NEW.towing_voucher_id LIMIT 0,1)
	WHERE 	towing_voucher_id = NEW.towing_voucher_id
	LIMIT	1;
END $$

CREATE TRIGGER `TRG_AI_TOWING_ACTIVITY` AFTER INSERT ON `T_TOWING_ACTIVITIES`
FOR EACH ROW
BEGIN
	DECLARE v_incl_vat, v_excl_vat DOUBLE;
	DECLARE v_foreign_vat BOOL;

	SELECT 	sum(amount * fee_excl_vat), sum(amount * fee_incl_vat) INTO v_excl_vat, v_incl_vat
	FROM 	T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf
	WHERE 	ta.activity_id = taf.id AND ta.towing_voucher_id = NEW.towing_voucher_id;

	SET v_foreign_vat = F_IS_VOUCHER_VIABLE_FOR_FOREIGN_VAT(NEW.towing_voucher_id);

	UPDATE `T_TOWING_VOUCHER_PAYMENTS` 
	SET 	`amount_customer` = IF(v_foreign_vat, v_excl_vat, v_incl_vat), 
			`cal_amount_paid` = 0, 
			`cal_amount_unpaid` = IF(v_foreign_vat, v_excl_vat, v_incl_vat), 
			`ud` = now(), `ud_by` = (SELECT ud_by FROM T_TOWING_ACTIVITIES WHERE id = NEW.towing_voucher_id LIMIT 0,1)
	WHERE 	towing_voucher_id = NEW.towing_voucher_id
	LIMIT	1;
END $$

CREATE TRIGGER `TRG_AI_TOWING_CUSTOMER` AFTER INSERT ON `T_TOWING_CUSTOMERS`
FOR EACH ROW
BEGIN
	CALL R_ADD_TOWING_CUSTOMER_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AU_TOWING_CUSTOMER` AFTER UPDATE ON `T_TOWING_CUSTOMERS`
FOR EACH ROW
BEGIN
	CALL R_ADD_TOWING_CUSTOMER_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AI_TOWING_CAUSER` AFTER INSERT ON `T_TOWING_INCIDENT_CAUSERS`
FOR EACH ROW
BEGIN
	CALL R_ADD_TOWING_CAUSER_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AU_TOWING_CAUSER` AFTER UPDATE ON `T_TOWING_INCIDENT_CAUSERS`
FOR EACH ROW
BEGIN
	CALL R_ADD_TOWING_CAUSER_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AI_TOWING_DEPOT` AFTER INSERT ON `T_TOWING_DEPOTS`
FOR EACH ROW
BEGIN
	CALL R_ADD_TOWING_DEPOT_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AU_TOWING_DEPOT` AFTER UPDATE ON `T_TOWING_DEPOTS`
FOR EACH ROW
BEGIN
	CALL R_ADD_TOWING_DEPOT_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AI_TOWING_PAYMENTS` AFTER INSERT ON `T_TOWING_VOUCHER_PAYMENTS`
FOR EACH ROW
BEGIN
	CALL R_ADD_TOWING_PAYMENTS_AUDIT_LOG(NEW.id);
END $$

CREATE TRIGGER `TRG_AU_TOWING_PAYMENTS` AFTER UPDATE ON `T_TOWING_VOUCHER_PAYMENTS`
FOR EACH ROW
BEGIN
	CALL R_ADD_TOWING_PAYMENTS_AUDIT_LOG(NEW.id);
END $$


-- ----------------------------------------------------------------
-- EVENTS
-- ----------------------------------------------------------------

CREATE PROCEDURE R_UPDATE_TOWING_STORAGE_COST_FOR_VOUCHER(IN p_voucher_id BIGINT, IN p_dossier_id BIGINT, IN p_timeframe_id BIGINT)
BEGIN
	DECLARE v_voucher_id, v_dossier_id, v_timeframe_id BIGINT DEFAULT NULL;
	DECLARE v_day_count INT;
	DECLARE v_call_date DATETIME;

	SET v_voucher_id = p_voucher_id;
	SET v_dossier_id = p_dossier_id;
	SET v_timeframe_id = p_timeframe_id;
	

	SELECT	datediff(IFNULL(tv.vehicule_collected, now()), call_date), IFNULL(d.call_date, now()) INTO v_day_count, v_call_date
	FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv
	WHERE 	d.id = v_dossier_id
			AND tv.dossier_id = d.id
			AND tv.id = p_voucher_id;

	IF v_day_count > 3 THEN
		INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
		SELECT 	tv.id, t.activity_id, datediff(IFNULL(tv.vehicule_collected, now()), call_date) - 3, 
			(datediff(IFNULL(tv.vehicule_collected, now()), call_date) - 3) * t.fee_excl_vat, 
			(datediff(IFNULL(tv.vehicule_collected, now()), call_date) - 3) * t.fee_incl_vat 
		FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv,
				(SELECT taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat
				 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
				 WHERE 	taf.timeframe_activity_id = ta.id AND taf.timeframe_id = v_timeframe_id
						AND `code` = 'STALLING'
						AND v_call_date BETWEEN taf.valid_from AND taf.valid_until) t
		WHERE d.id = v_dossier_id
			AND tv.dossier_id = d.id
		ON DUPLICATE KEY UPDATE amount = datediff(IFNULL(tv.vehicule_collected, now()), call_date) - 3, 
								cal_fee_excl_vat = (amount * t.fee_excl_vat), 
								cal_fee_incl_vat = (amount * t.fee_incl_vat);
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_TOWING_STORAGE_COST()
BEGIN
	DECLARE v_voucher_id, v_dossier_id, v_timeframe_id BIGINT DEFAULT NULL;
	DECLARE no_rows_found BOOLEAN DEFAULT FALSE;
	
	DECLARE c CURSOR FOR SELECT tv.id as voucher_id, dossier_id, timeframe_id 
						 FROM 	T_TOWING_VOUCHERS tv, T_DOSSIERS d, P_INCIDENT_TYPES it, T_TOWING_DEPOTS td
						 WHERE 	tv.dossier_id = d.id
								AND vehicule_collected IS NULL
								AND datediff(now(), call_date) > 3
								AND d.incident_type_id = it.id
								AND it.code IN ('ONGEVAL', 'PANNE')
								AND tv.id = voucher_id
								AND default_depot = 1;
								  
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_rows_found = TRUE;
	
	OPEN c;
	
	REPEAT
		FETCH c INTO v_voucher_id, v_dossier_id, v_timeframe_id;
		
		CALL R_UPDATE_TOWING_STORAGE_COST_FOR_VOUCHER(v_voucher_id, v_dossier_id, v_timeframe_id);
			
	UNTIL no_rows_found END REPEAT;	
END $$

CREATE PROCEDURE R_UPDATE_EXTRA_TIME_SIGNA()
BEGIN
	DECLARE v_voucher_id, v_dossier_id, v_timeframe_id, v_extra_time BIGINT DEFAULT NULL;
	DECLARE v_call_date DATETIME;
	DECLARE no_rows_found BOOLEAN DEFAULT FALSE;
	
	DECLARE c CURSOR FOR 	SELECT 	d.id as dossier_id, tv.id as towing_voucher_id, d.timeframe_id,
									(TIMESTAMPDIFF(MINUTE, tv.signa_arrival, now()) - 60) as extra_time_signa,
									d.call_date
							FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv
							WHERE 	d.id = tv.dossier_id
									AND tv.signa_arrival IS NOT NULL
									AND tv.towing_completed IS NULL
									AND TIMESTAMPDIFF(MINUTE, tv.signa_arrival, now()) > 60;
								  
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_rows_found = TRUE;
	
	OPEN c;
	
	REPEAT
		FETCH c INTO v_dossier_id, v_voucher_id, v_timeframe_id, v_extra_time, v_call_date;
		
		INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
		SELECT 	tv.id, t.activity_id, CEIL(v_extra_time/15), t.fee_excl_vat, t.fee_incl_vat 
		FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv,
				(SELECT taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat
				 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
				 WHERE 	taf.timeframe_activity_id = ta.id AND taf.timeframe_id = v_timeframe_id
						AND `code` = 'EXTRA_SIGNALISATIE'
						AND v_call_date BETWEEN taf.valid_from AND taf.valid_until) t
		WHERE 	d.id = v_dossier_id
				AND tv.dossier_id = d.id
				AND tv.id = v_voucher_id
		ON DUPLICATE KEY UPDATE amount = CEIL(v_extra_time/15), 
								cal_fee_excl_vat = (amount * t.fee_excl_vat), 
								cal_fee_incl_vat = (amount * t.fee_incl_vat);
			
	UNTIL no_rows_found END REPEAT;	
END $$


CREATE PROCEDURE R_UPDATE_EXTRA_TIME_ACCIDENT()
BEGIN
	DECLARE v_voucher_id, v_dossier_id, v_timeframe_id, v_extra_time BIGINT DEFAULT NULL;
	DECLARE v_call_date DATETIME;
	
	DECLARE no_rows_found BOOLEAN DEFAULT FALSE;
	
	DECLARE c CURSOR FOR 	SELECT 	d.id as dossier_id, tv.id as towing_voucher_id, d.timeframe_id,
									(TIMESTAMPDIFF(MINUTE, tv.signa_arrival, now()) - 60) as extra_time_accident,
									IFNULL(d.call_date, now())
							FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv, P_INCIDENT_TYPES p
							WHERE 	d.id = tv.dossier_id
									AND d.incident_type_id = p.id AND p.code='ONGEVAL'
									AND tv.towing_completed IS NULL
									AND tv.signa_arrival IS NOT NULL
									AND (TIMESTAMPDIFF(MINUTE, tv.signa_arrival, now()) - 60) > 0;
								  
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_rows_found = TRUE;
	
	OPEN c;
	
	REPEAT
		FETCH c INTO v_dossier_id, v_voucher_id, v_timeframe_id, v_extra_time, v_call_date;
		
		INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
		SELECT 	tv.id, t.activity_id, CEIL(v_extra_time/15), t.fee_excl_vat, t.fee_incl_vat 
		FROM 	T_DOSSIERS d, T_TOWING_VOUCHERS tv,
				(SELECT taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat
				 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
				 WHERE 	taf.timeframe_activity_id = ta.id AND taf.timeframe_id = v_timeframe_id
						AND `code` = 'EXTRA_ONGEVAL'
						AND v_call_date BETWEEN taf.valid_from AND taf.valid_until) t
		WHERE 	d.id = v_dossier_id
				AND tv.dossier_id = d.id
				AND tv.id = v_voucher_id
		ON DUPLICATE KEY UPDATE amount = CEIL(v_extra_time/15), 
								cal_fee_excl_vat = (amount * t.fee_excl_vat), 
								cal_fee_incl_vat = (amount * t.fee_incl_vat);
			
	UNTIL no_rows_found END REPEAT;	
END $$

-- ----------------------------------------------------
-- RECALCULATE STORAGE COSTS ON DAILY BASIS
-- ----------------------------------------------------
CREATE EVENT E_UPDATE_TOWING_STORAGE_COST
ON SCHEDULE EVERY 1 DAY STARTS '2014-01-01 01:00:00'
DO
BEGIN
	CALL R_UPDATE_TOWING_STORAGE_COST();
END $$

-- ----------------------------------------------------
-- RECALCULATE EXTRA TIME SIGNA EVERY 15 MINUTES
-- ----------------------------------------------------
CREATE EVENT E_UPDATE_SIGNA_EXTRA_TIME
ON SCHEDULE EVERY 15 MINUTE STARTS '2014-01-01 01:00:00'
DO
BEGIN
	CALL R_UPDATE_EXTRA_TIME_SIGNA();
END $$

-- ----------------------------------------------------
-- RECALCULATE EXTRA TIME ACCIDENT EVERY 15 MINUTES
-- ----------------------------------------------------
CREATE EVENT E_UPDATE_ACCIDENT_EXTRA_TIME
ON SCHEDULE EVERY 15 MINUTE STARTS '2014-01-01 01:00:00'
DO
BEGIN
	CALL R_UPDATE_EXTRA_TIME_ACCIDENT();
END $$


DELIMITER ;