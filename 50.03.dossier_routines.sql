DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_CREATE_DOSSIER $$
DROP PROCEDURE IF EXISTS R_UPDATE_DOSSIER $$
DROP PROCEDURE IF EXISTS R_CREATE_TOWING_VOUCHER $$
DROP PROCEDURE IF EXISTS R_UPDATE_TOWING_VOUCHER $$

DROP PROCEDURE IF EXISTS R_FETCH_DOSSIER_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_DOSSIER_BY_NUMBER $$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_VOUCHERS_BY_DOSSIER $$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_ACTIVITIES_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_PAYMENTS_BY_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_DOSSIERS_BY_FILTER $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_VOUCHERS_BY_FILTER $$
DROP PROCEDURE IF EXISTS R_FETCH_ALL_AVAILABLE_ACTIVITIES $$

DROP FUNCTION IF EXISTS F_NEXT_DOSSIER_NUMBER $$
DROP FUNCTION IF EXISTS F_NEXT_TOWING_VOUCHER_NUMBER $$
DROP FUNCTION IF EXISTS F_RESOLVE_TIMEFRAME_CATEGORY $$

DROP TRIGGER IF EXISTS TRG_AI_DOSSIER $$
DROP TRIGGER IF EXISTS TRG_AU_DOSSIER $$
DROP TRIGGER IF EXISTS TRG_AI_TOWING_VOUCHER $$
DROP TRIGGER IF EXISTS TRG_AI_TOWING_ACTIVITY $$



-- ---------------------------------------------------------------------
-- CREATE FUNCTIONS
-- ---------------------------------------------------------------------
CREATE FUNCTION F_NEXT_DOSSIER_NUMBER() RETURNS INT
BEGIN
	SET @v_id = 1;

	INSERT INTO T_SEQUENCES(`code`, `seq_val`)
	VALUES('DOSSIER', 1)
	ON DUPLICATE KEY UPDATE seq_val=@v_id:=seq_val+1;

	RETURN @v_id;
END $$

CREATE FUNCTION F_NEXT_TOWING_VOUCHER_NUMBER() RETURNS INT
BEGIN
	SET @v_id = 1;

	INSERT INTO T_SEQUENCES(`code`, `seq_val`)
	VALUES('TOWING_VOUCHER', 1)
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
			WHEN 0 THEN return 'SUNDAY';
			WHEN 7 THEN return 'SATURDAY';
			ELSE RETURN 'WORKDAY';
		END CASE;
	ELSE
		RETURN 'HOLIDAY';
	END IF; 
END $$

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_CREATE_DOSSIER(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id, v_towing_voucher_id BIGINT;
	DECLARE v_user_id VARCHAR(36);
	DECLARE v_timeframe_id INT;

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);


	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		-- determine the timeframe of the incident
		SELECT 	t.id INTO v_timeframe_id
		FROM 	P_TIMEFRAMES t, P_TIMEFRAME_VALIDITY tv
		WHERE	t.id = tv.timeframe_id
				AND current_time() BETWEEN `from` AND `till`
				AND tv.category = F_RESOLVE_TIMEFRAME_CATEGORY();

		-- create a new dossier
		INSERT INTO `T_DOSSIERS` (`dossier_number`, `status`, `call_date`, `timeframe_id`, `cd`, `cd_by`) 
		VALUES (F_NEXT_DOSSIER_NUMBER(), 'NEW', CURRENT_TIMESTAMP, v_timeframe_id, CURRENT_TIMESTAMP, F_RESOLVE_LOGIN(v_user_id, p_token));

		SET v_dossier_id = LAST_INSERT_ID();

		SELECT v_dossier_id as `id`;
	END IF;
END $$

CREATE PROCEDURE R_UPDATE_DOSSIER(IN p_dossier_id BIGINT, IN p_call_number VARCHAR(45), IN p_company_id BIGINT, 
                                  IN p_incident_type_id INT, IN p_allotment_id INT, IN p_direction_id INT, 
                                  IN p_direction_indicator_id INT, IN p_traffic_lane_id INT, IN p_police_traffic_post_id INT,
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
			traffic_lane_id 		= p_traffic_lane_id,
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
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

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
			INSERT INTO `T_TOWING_VOUCHERS` (`dossier_id`, `voucher_number`, `cd`, `cd_by`) 
			VALUES (v_dossier_id, F_NEXT_TOWING_VOUCHER_NUMBER(), now(), F_RESOLVE_LOGIN(v_user_id, p_token));
		END IF;
	END IF;
END $$

CREATE PROCEDURE  R_UPDATE_TOWING_VOUCHER(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT,
										  IN p_insurance_id BIGINT, IN p_insurance_dossier_nr VARCHAR(45), IN p_warranty_holder VARCHAR(255),
										  IN p_collector_id BIGINT,
										  IN p_vehicule_type VARCHAR(255), IN p_vehicule_licence_plate VARCHAR(15), IN p_vehicule_country VARCHAR(5),
										  IN p_signa_by VARCHAR(255), IN p_signa_by_vehicule VARCHAR(15), IN p_signa_arrival DATETIME, 
										  IN p_towed_by VARCHAR(255), IN p_towed_by_vehicule VARCHAR(15), IN p_towing_depot VARCHAR(512), 
										  IN p_towing_called DATETIME, IN p_towing_arrival DATETIME, IN p_towing_start DATETIME, IN p_towing_end DATETIME,
										  IN p_police_signature DATE, IN p_recipient_signature DATE, IN p_vehicule_collected DATE,
										  IN p_cic DATETIME,
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
			police_signature_dt 	= p_police_signature,
			recipient_signature_dt 	= p_recipient_signature, 
			vehicule_type 			= p_vehicule_type, 
			vehicule_licenceplate 	= p_vehicule_licence_plate, 
			vehicule_country 		= p_vehicule_country,
			vehicule_collected 		= p_vehicule_collected, 
			towed_by 				= p_towed_by, 
			towed_by_vehicle 		= p_towed_by_vehicule, 	
			towing_called 			= p_towing_called, 
			towing_arrival 			= p_towing_arrival, 
			towing_start 			= p_towing_start, 
			towing_completed 		= p_towing_end, 
			towing_depot 			= p_towing_depot, 
			signa_by 				= p_signa_by, 
			signa_by_vehicle 		= p_signa_by_vehicule, 
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
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

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
			SELECT	`id`, `dossier_number`, `status`, `call_date`, `call_number`, `police_traffic_post_id`, `incident_type_id` 
			FROM 	T_DOSSIERS 
			WHERE	`id` = v_dossier_id
			LIMIT	0, 1;
		END IF;
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
		WHERE	`dossier_number` = p_dossier_nr;

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
			SELECT	*
			FROM 	T_TOWING_VOUCHERS
			WHERE	`dossier_id` = v_dossier_id;
		END IF;
	END IF;
END $$


CREATE PROCEDURE R_FETCH_TOWING_ACTIVITIES_BY_VOUCHER(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
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
			SELECT ta.towing_voucher_id, ta.activity_id, tia.code, tia.name, taf.fee_incl_vat, taf.fee_excl_vat, ta.amount, ta.cal_fee_excl_vat, ta.cal_fee_incl_vat 
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
			SELECT	*
			FROM 	T_TOWING_VOUCHER_PAYMENTS
			WHERE	`towing_voucher_id` = p_voucher_id;
		END IF;
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
		SELECT 	`id`, `dossier_number`, `status`, `call_date`, `call_number`, `police_traffic_post_id` 
		FROM 	`T_DOSSIERS` d
		WHERE	company_id = v_company_id
				AND d.status = p_filter
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
		SELECT 	d.id, d.id as 'dossier_id', t.id as 'voucher_id', d.call_number, d.call_date, t.voucher_number, ad.name 'direction_name', adi.name 'indicator_name', c.code as `towing_service`, ip.name as `incident_type`
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
				AND d.status = p_filter
		ORDER BY d.call_date DESC;
	END IF;
END $$


CREATE PROCEDURE R_FETCH_ALL_AVAILABLE_ACTIVITIES(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT, IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
	DECLARE v_user_id VARCHAR(36);

	CALL R_RESOLVE_ACCOUNT_INFO(p_token, v_user_id, v_company_id);

	IF v_user_id IS NULL OR v_company_id IS NULL THEN
		CALL R_NOT_AUTHORIZED;
	ELSE
		SELECT 	taf.id, ta.name, ta.code 
		FROM 	`P_TIMEFRAME_ACTIVITIES` ta, `P_TIMEFRAME_ACTIVITY_FEE` taf
		WHERE 	ta.id = taf.timeframe_activity_id
				AND taf.timeframe_id = (SELECT timeframe_id FROM T_DOSSIERS WHERE id = p_dossier_id)
				AND taf.id NOT IN (SELECT activity_id FROM T_TOWING_ACTIVITIES WHERE towing_voucher_id = p_voucher_id)
				AND CURRENT_DATE BETWEEN taf.valid_from AND taf.valid_until;	
	END IF;
END $$
-- ----------------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------------

CREATE TRIGGER `TRG_AI_DOSSIER` AFTER INSERT ON `T_DOSSIERS`
FOR EACH ROW
BEGIN
	-- automatically insert a new towing voucher for each new dossier
	INSERT INTO `T_TOWING_VOUCHERS` (`dossier_id`, `voucher_number`, `cd`, `cd_by`) 
	VALUES (NEW.id, F_NEXT_TOWING_VOUCHER_NUMBER(), now(), NEW.cd_by);
END $$

CREATE TRIGGER `TRG_AU_DOSSIER` AFTER UPDATE ON `T_DOSSIERS` 
FOR EACH ROW
BEGIN
	DECLARE v_incident_type_code VARCHAR(45);

	IF OLD.incident_type_id IS NULL AND NEW.incident_type_id IS NOT NULL THEN
		-- attach default activities based on selected timeframe
		SELECT 	`code` INTO v_incident_type_code
		FROM	`P_INCIDENT_TYPES`
		WHERE 	id = NEW.incident_type_id
		LIMIT	0,1;

		CASE v_incident_type_code
			WHEN 'PANNE' OR 'ONGEVAL' OR 'ACHTERGELATEN_VOERTUIG' THEN
				INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
				SELECT 	id, t.activity_id, 1.00, t.fee_excl_vat, t.fee_incl_vat 
				FROM 	T_TOWING_VOUCHERS tv,
						(SELECT taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat
						 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
						 WHERE 	taf.timeframe_activity_id = ta.id AND taf.timeframe_id = NEW.timeframe_id
								AND `code` IN (v_incident_type_code, 'SIGNALISATIE')
								AND current_date BETWEEN taf.valid_from AND taf.valid_until) t
				WHERE tv.dossier_id = OLD.id;
			ELSE
				INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount, cal_fee_excl_vat, cal_fee_incl_vat)
				SELECT 	id, t.activity_id, 1.00, t.fee_excl_vat, t.fee_incl_vat 
				FROM 	T_TOWING_VOUCHERS tv,
						(SELECT taf.id as activity_id, taf.fee_excl_vat, taf.fee_incl_vat
						 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
						 WHERE 	taf.timeframe_activity_id = ta.id AND taf.timeframe_id = NEW.timeframe_id
								AND `code` IN (v_incident_type_code)
								AND current_date BETWEEN taf.valid_from AND taf.valid_until) t
				WHERE tv.dossier_id = OLD.id;		
		END CASE;
	END IF;
END $$

CREATE TRIGGER `TRG_AI_TOWING_VOUCHER` AFTER INSERT ON `T_TOWING_VOUCHERS`
FOR EACH ROW
BEGIN
	-- automatically create a voucher payment record when creating a new towing voucher
	INSERT INTO `T_TOWING_VOUCHER_PAYMENTS` (`towing_voucher_id`, `cd`, `cd_by`) VALUES 
				(NEW.id, now(), NEW.cd_by);
 
END $$

CREATE TRIGGER `TRG_AI_TOWING_ACTIVITY` AFTER INSERT ON `T_TOWING_ACTIVITIES`
FOR EACH ROW
BEGIN
	DECLARE v_incl_vat, v_excl_vat DOUBLE;
	
	SELECT 	sum(amount * fee_excl_vat), sum(amount * fee_incl_vat) INTO v_excl_vat, v_incl_vat
	FROM 	T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf
	WHERE 	ta.activity_id = taf.id AND ta.towing_voucher_id = NEW.towing_voucher_id;


	UPDATE `T_TOWING_VOUCHER_PAYMENTS` 
	SET 	`amount_customer` = v_incl_vat, 
			`cal_amount_paid` = 0, 
			`cal_amount_unpaid` = v_incl_vat, 
			`ud` = now(), `ud_by` = 'TODO'
	WHERE 	towing_voucher_id = NEW.towing_voucher_id
	LIMIT	1;
END $$

DELIMITER ;