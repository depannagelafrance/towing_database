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
