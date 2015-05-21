INSERT INTO `P_ROLES` (`id`, `code`, `name`) VALUES 
	(6, 'INVOICING', 'Facturatie');

INSERT INTO `P_MODULES` (`id`, `code`, `name`) VALUES
	(6, 'INVOICING', 'Facturatie');

INSERT INTO `P_MODULE_ROLES` (`role_id`, `module_id`)
	VALUES (6, 6);

INSERT INTO `P_COMPANY_MODULES` (`module_id`, `company_id`, `cd`, `cd_by`, `dd`, `dd_by`) 
SELECT id, 1, now(), 'SYSTEM', null, null FROM P_MODULES WHERE id = 6;

UPDATE T_COLLECTORS SET `type`= 'CUSTOMER' WHERE name='Eigenaar' LIMIT 1;