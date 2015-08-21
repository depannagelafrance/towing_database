INSERT INTO `P_ROLES` (`id`, `code`, `name`) VALUES 
	(6, 'INVOICING', 'Facturatie');

INSERT INTO `P_MODULES` (`id`, `code`, `name`) VALUES
	(6, 'INVOICING', 'Facturatie');

INSERT INTO `P_MODULE_ROLES` (`role_id`, `module_id`)
	VALUES (6, 6);

INSERT INTO `P_COMPANY_MODULES` (`module_id`, `company_id`, `cd`, `cd_by`, `dd`, `dd_by`) 
SELECT id, 1, now(), 'SYSTEM', null, null FROM P_MODULES WHERE id = 6;

UPDATE T_COLLECTORS SET `type`= 'CUSTOMER' WHERE name='Eigenaar' LIMIT 1;




INSERT INTO `P_ROLES` (`id`, `code`, `name`) VALUES 
	(7, 'AWV', 'Agentschap Wegen & Verkeer');

INSERT INTO `P_MODULES` (`id`, `code`, `name`) VALUES
	(7, 'AWV', 'Agentschap Wegen & Verkeer');

INSERT INTO `P_MODULE_ROLES` (`role_id`, `module_id`)
	VALUES (7, 7);

INSERT INTO `T_COMPANIES`(id, name, code, street, street_number, street_pobox, city, phone, fax, email, website) VALUES 
	(4, 'Agentschap Wegen & Verkeer', 'AWV', '', '', '', 'Antwerpen', '', '', '', '');


INSERT INTO `P_COMPANY_MODULES` (`module_id`, `company_id`, `cd`, `cd_by`, `dd`, `dd_by`) 
SELECT id, 4, now(), 'SYSTEM', null, null FROM P_MODULES WHERE id = 7;

SET @user_id = UUID();

INSERT INTO T_USERS(id, company_id, login, first_name, last_name, email, is_active, is_locked, locked_ts, cd, cd_by)
values(@user_id, 4, 'awv_wg', 'Wim', 'Goeyvaerts', 'wim.goeyvaerts@mow.vlaanderen.be', 1, 0, null, now(), 'SYSTEM');

INSERT INTO `T_USER_PASSWORDS` (`user_id`, `pwd`) VALUES (@user_id, PASSWORD('AWW1M!'));

INSERT INTO T_USER_ROLES(user_id, role_id) VALUES(@user_id, 7);

INSERT INTO `T_COMPANY_MAP`(`supervisor_company_id`, `delegate_company_id`)
VALUES (4, 1);



UPDATE T_TOWING_VOUCHERS tv, T_DOSSIERS d
SET tv.signa_arrival = DATE_ADD(signa_arrival, INTERVAL 1 MONTH)
WHERE month(d.call_date) > month(tv.signa_arrival)
	and TIMEDIFF(tv.signa_arrival,d.call_date) < 0
	and d.id = tv.dossier_id;

UPDATE T_TOWING_VOUCHERS tv, T_DOSSIERS d
SET tv.towing_called = DATE_ADD(towing_called, INTERVAL 1 MONTH)
WHERE month(d.call_date) > month(tv.towing_called)
	and TIMEDIFF(tv.towing_called,d.call_date) < 0
	and d.id = tv.dossier_id;
    
UPDATE T_TOWING_VOUCHERS tv, T_DOSSIERS d
SET tv.towing_completed = DATE_ADD(towing_completed, INTERVAL 1 MONTH)
WHERE month(d.call_date) > month(tv.towing_completed)
	and TIMEDIFF(tv.towing_completed,d.call_date) < 0
	and d.id = tv.dossier_id;    
    
UPDATE T_TOWING_VOUCHERS tv, T_DOSSIERS d
SET tv.towing_arrival = DATE_ADD(towing_arrival, INTERVAL 1 MONTH)
WHERE month(d.call_date) > month(tv.towing_arrival)
	and TIMEDIFF(tv.towing_arrival,d.call_date) < 0
	and d.id = tv.dossier_id;
    
UPDATE T_TOWING_VOUCHERS tv, T_DOSSIERS d
SET tv.towing_start = DATE_ADD(towing_start, INTERVAL 1 MONTH)
WHERE month(d.call_date) > month(tv.towing_start)
	and TIMEDIFF(tv.towing_start,d.call_date) < 0
	and d.id = tv.dossier_id;    
    
SET @user_id = UUID();
    
INSERT INTO T_USERS(id, company_id, login, first_name, last_name, email, is_active, is_locked, locked_ts, cd, cd_by)
values(@user_id, 1, 'dlf_cron', 'CRONJOB', '', 'melissa@depannagelafrance.be', 1, 0, null, now(), 'SYSTEM');

INSERT INTO `T_USER_PASSWORDS` (`user_id`, `pwd`) VALUES (@user_id, PASSWORD('VD0A86i3t{3=q2g!'));

INSERT INTO T_USER_TOKENS VALUES(@user_id, '8E1j60y5h0570fX40m30SxTR72378Wt700HD');