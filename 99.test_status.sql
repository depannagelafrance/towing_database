DELIMITER $$
DROP PROCEDURE IF EXISTS R_CHECK_STATUS $$ 

CREATE PROCEDURE R_CHECK_STATUS(IN p_dossier_id BIGINT, IN p_voucher_id BIGINT)
BEGIN
	DECLARE v_first_name, v_last_name, v_company, v_company_vat VARCHAR(255);
	DECLARE v_licence_plate, v_code VARCHAR(15);
	DECLARE v_score, v_count INT;
	DECLARE v_incident_type_code VARCHAR(45);
	DECLARE v_idle_ride, v_lost_object, v_signa_only, v_default_depot, v_has_insurance, v_is_agency BOOL;
	DECLARE v_customer_type ENUM('DEFAULT', 'AGENCY');

	SET v_score = 0;
	SET v_is_agency = false;

	
	SELECT insurance_id IS NOT NULL INTO v_has_insurance
	FROM T_TOWING_VOUCHERS
	WHERE id = p_voucher_id;

	SELECT v_has_insurance;


	IF NOT v_has_insurance THEN
		--
		-- CHECK IF CUSTOMER IS SET
		-- 
		SELECT first_name, last_name, company_name, company_vat, (type = 'AGENCY')
		INTO v_first_name, v_last_name, v_company, v_company_vat, v_is_agency
		FROM T_TOWING_CUSTOMERS WHERE voucher_id = p_voucher_id
		LIMIT 0,1;

		IF TRIM(IFNULL(v_company, "")) != "" THEN
			IF TRIM(IFNULL(v_company_vat, "")) = "" THEN
				SET v_score = v_score + 1;		

				SELECT "No company vat for customer: ", v_score;

			END IF;
		ELSE
			IF TRIM(IFNULL(v_company, "")) = "" AND TRIM(IFNULL(v_first_name, "")) = "" AND TRIM(IFNULL(v_last_name, "")) = "" THEN
				SET v_score = v_score + 1;
				SELECT "No first or last name for customer: ", v_score;
			END IF;
		END IF;

	END IF;

		--
		-- check if LOZE_RIT
		-- 
		SELECT 	count(*) > 0 INTO v_idle_ride
		FROM 	T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, P_TIMEFRAME_ACTIVITIES tac
		WHERE 	ta.towing_voucher_id = p_voucher_id
				AND ta.activity_id = taf.id
				AND taf.timeframe_activity_id = tac.id
				AND tac.code='LOZE_RIT';

		SELECT "Idle ride: ", v_idle_ride;
		--
		-- check if LOST_OBJECT
		-- 
		SELECT 	count(*) > 0 INTO v_lost_object
		FROM 	T_TOWING_ACTIVITIES ta, P_TIMEFRAME_ACTIVITY_FEE taf, P_TIMEFRAME_ACTIVITIES tac
		WHERE 	ta.towing_voucher_id = OLD.id
				AND ta.activity_id = taf.id
				AND taf.timeframe_activity_id = tac.id
				AND tac.code='VERLOREN_VOORWERP';

		SELECT "Lost object: ", v_lost_object;

		--
		-- check if SIGNA_ONLY
		-- 
		SELECT 	count(d.id) > 0 INTO v_signa_only
		FROM 	T_DOSSIERS d, P_INCIDENT_TYPES it
		WHERE 	d.id = OLD.dossier_id
				AND d.incident_type_id = it.id
				AND it.code = 'SIGNALISATIE';

		SELECT "Signa only: ", v_signa_only;

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
					SELECT "No company set for causer: ", v_score;	
				END IF;
			ELSE
				IF TRIM(IFNULL(v_company, "")) = "" AND TRIM(IFNULL(v_first_name, "")) = "" AND TRIM(IFNULL(v_last_name, "")) = "" THEN
					SET v_score = v_score + 1;
					SELECT "No first or last name for causer: ", v_score;
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

				SELECT "Signature causer: ", v_count;
			ELSE
				-- team on site
				SELECT 	count(*) INTO v_count
				FROM 	T_TOWING_VOUCHER_ATTS
				WHERE 	towing_voucher_id = OLD.id
						AND category IN ('SIGNATURE_CAUSER', 'SIGNATURE_POLICE');

				SELECT "Signature causer/police", v_count;
			END IF;

			IF v_count = 0 THEN
				SELECT "No signatures: ", v_score;
				SET v_score = v_score + 1;
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

			SELECT "Default depot? ", v_default_depot;

			IF v_default_depot AND NEW.vehicule_collected IS NULL THEN
				SET v_score = v_score + 1;
				SELECT "Not collected from default depot?: ", v_score;
			END IF;
		END IF;

		-- 
		-- CHECK SCORE, IF > 0 THEN CHANGE STATUS
		--

		SELECT "End score:" ,v_score;

END $$


DELIMITER ;