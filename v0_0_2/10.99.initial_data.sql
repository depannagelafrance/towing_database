
INSERT INTO `P_ROLES` (`id`, `code`, `name`) VALUES 
	(4, 'COMMANDO', ' Federale Wegpolitie');

INSERT INTO `P_MODULES` (`id`, `code`, `name`) VALUES
	(4, 'COMMANDO', ' Federale Wegpolitie');

INSERT INTO `P_MODULE_ROLES` (`role_id`, `module_id`)
	VALUES (4, 4);

INSERT INTO `T_COMPANIES`(id, name, code, street, street_number, street_pobox, city, phone, fax, email, website) VALUES 
	(2, 'Federale Wegpolitie', 'COMMANDO', '', '', '', '', '', '', '', '');


INSERT INTO `P_COMPANY_MODULES` (`module_id`, `company_id`, `cd`, `cd_by`, `dd`, `dd_by`) 
SELECT id, 2, now(), 'SYSTEM', null, null FROM P_MODULES WHERE id = 4;

SET @user_id = UUID();

INSERT INTO T_USERS(id, company_id, login, first_name, last_name, email, is_active, is_locked, locked_ts, cd, cd_by)
values(@user_id, 2, 'fedwpol', 'Federale Wegpolitie', '', '', 1, 0, null, now(), 'SYSTEM');

INSERT INTO `T_USER_PASSWORDS` (`user_id`, `pwd`) VALUES (@user_id, PASSWORD('F3dWP0l!'));

INSERT INTO T_USER_ROLES(user_id, role_id) VALUES(@user_id, 4);

INSERT INTO `T_COMPANY_MAP`(`supervisor_company_id`, `delegate_company_id`)
VALUES (2, 1);

