INSERT INTO `P_ROLES` (`id`, `code`, `name`) VALUES 
	(5, 'FAST_IPAD', 'F.A.S.T. iPad');

INSERT INTO `P_MODULES` (`id`, `code`, `name`) VALUES
	(5, 'FAST_IPAD', 'F.A.S.T. iPad');

INSERT INTO `P_MODULE_ROLES` (`role_id`, `module_id`)
	VALUES (5, 5);

INSERT INTO `P_COMPANY_MODULES` (`module_id`, `company_id`, `cd`, `cd_by`, `dd`, `dd_by`) 
SELECT id, 1, now(), 'SYSTEM', null, null FROM P_MODULES WHERE id = 5;

INSERT INTO `P_DICTIONARY`(`category`, `name`, `cd`, `cd_by`)
VALUES	('TRAFFIC_LANE', 'Links', now(), 'SYSTEM'),
		('TRAFFIC_LANE', 'Rechts', now(), 'SYSTEM'),
        ('TRAFFIC_LANE', 'Midden', now(), 'SYSTEM');

