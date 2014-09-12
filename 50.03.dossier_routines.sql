DELIMITER $$

-- ---------------------------------------------------------------------
-- DROP ROUTINES
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS R_CREATE_DOSSIER $$
DROP PROCEDURE IF EXISTS R_UPDATE_DOSSIER $$
DROP PROCEDURE IF EXISTS R_CREATE_TOWING_VOUCHER $$
DROP PROCEDURE IF EXISTS R_FETCH_DOSSIER_BY_ID $$
DROP PROCEDURE IF EXISTS R_FETCH_TOWING_VOUCHERS_BY_DOSSIER $$

DROP FUNCTION IF EXISTS F_NEXT_DOSSIER_NUMBER $$
DROP FUNCTION IF EXISTS F_NEXT_TOWING_VOUCHER_NUMBER $$
DROP FUNCTION IF EXISTS F_RESOLVE_TIMEFRAME_CATEGORY $$

DROP TRIGGER IF EXISTS TRG_AU_DOSSIER $$



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
	CASE dayofweek(now())
		WHEN 0 THEN return 'SUNDAY';
		WHEN 7 THEN return 'SATURDAY';
		ELSE RETURN 'WORKDAY';
	END CASE;
END $$

-- ---------------------------------------------------------------------
-- CREATE ROUTINES
-- ---------------------------------------------------------------------
CREATE PROCEDURE R_CREATE_DOSSIER(IN p_token VARCHAR(255))
BEGIN
	DECLARE v_company_id, v_dossier_id BIGINT;
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
		VALUES (F_NEXT_DOSSIER_NUMBER(), 'NEW', curdate(), v_timeframe_id, now(), F_RESOLVE_LOGIN(v_user_id, p_token));

		SET v_dossier_id = LAST_INSERT_ID();

		INSERT INTO `T_TOWING_VOUCHERS` (`dossier_id`, `voucher_number`, `cd`, `cd_by`) 
		VALUES (v_dossier_id, F_NEXT_TOWING_VOUCHER_NUMBER(), now(), F_RESOLVE_LOGIN(v_user_id, p_token));

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
			company_id 				= p_company_id
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
			SELECT	`id`, `dossier_number`, `status`, `call_date`, `call_number`, `police_traffic_post_id` 
			FROM 	T_DOSSIERS 
			WHERE	`id` = v_dossier_id
			LIMIT	0, 1;
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
				INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount)
				SELECT 	id, t.activity_id, 1.00
				FROM 	T_TOWING_VOUCHERS tv,
						(SELECT taf.id as activity_id
						 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
						 WHERE 	taf.timeframe_activity_id = ta.id AND taf.timeframe_id = NEW.timeframe_id
								AND `code` IN (v_incident_type_code, 'SIGNALISATIE')
								AND current_date BETWEEN taf.valid_from AND taf.valid_until) t
				WHERE tv.dossier_id = OLD.id;
			ELSE
				INSERT INTO T_TOWING_ACTIVITIES(towing_voucher_id, activity_id, amount)
				SELECT 	id, t.activity_id, 1.00
				FROM 	T_TOWING_VOUCHERS tv,
						(SELECT taf.id as activity_id
						 FROM 	`P_TIMEFRAME_ACTIVITY_FEE` taf, `P_TIMEFRAME_ACTIVITIES` ta
						 WHERE 	taf.timeframe_activity_id = ta.id AND taf.timeframe_id = NEW.timeframe_id
								AND `code` IN (v_incident_type_code)
								AND current_date BETWEEN taf.valid_from AND taf.valid_until) t
				WHERE tv.dossier_id = OLD.id;		
		END CASE;
	END IF;
END $$

DELIMITER ;