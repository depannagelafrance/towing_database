
INSERT INTO `P_ROLES` (`id`, `code`, `name`) VALUES 
	(1, 'ADMIN', 'Algemeen beheerder'),
	(2, 'COMPANY_ADMIN', 'Beheerder'),
	(3, 'FAST_DISPATCH', 'FAST Dispatch'),
	(4, 'FAST_MANAGER', 'FAST Dossier beheerder');


INSERT INTO `P_INCIDENT_TYPES` (`name`, `code`) VALUES 
	('Panne', 					'PANNE'),
	('Ongeval', 				'ONGEVAL'),
	('Achtergelaten voertuig', 	'ACHTERGELATEN_VOERTUIG'),
	('Enkel signalisatie', 		'SIGNALISATIE'),
	('Verloren voorwerp', 		'VERLOREN_VOORWERP'),
	('Botsabsorbeerder', 		'BOTSABSORBEERDER');


INSERT INTO `P_HOLIDAYS` (`id`, `year`, `holiday`, `cd`, `cd_by`)  VALUES 
	(1, 2014, '2014-11-01', now(), 'SYSTEM'),
	(2, 2014, '2014-11-11', now(), 'SYSTEM'),
	(3, 2014, '2014-12-25', now(), 'SYSTEM'),
	(4, 2014, '2014-12-31', now(), 'SYSTEM');

INSERT INTO `P_TIMEFRAMES` (`id`, `name`) VALUES 
	(1, 'Basistarief'),
	(2, 'Tarief I'),
	(3, 'Tarief II');

-- category can be ENUM('WORKDAY', 'SATURDAY', 'SUNDAY', 'HOLIDAY')
INSERT INTO `P_TIMEFRAME_VALIDITY` (`id`, `timeframe_id`, `category`, `from`, `till`) VALUES 
	(1, 1, 'WORKDAY', 	'08:00:00', '16:59:59'), -- Basistarief, valid on workdays from 08:00 - 17:00
	(2, 2, 'WORKDAY', 	'17:00:00', '23:59:59'), -- Tarief I, valid on workdays from 17:00 - 24:00
	(3, 2, 'SATURDAY', 	'08:00:00', '23:59:59'), -- Tarief I, valid on saturday from 08:00 - 24:00
	(4, 3, 'WORKDAY', 	'00:00:00', '07:59:59'), -- Tarief II, valid on workdays from 00 - 08:00
	(5, 3, 'SATURDAY', 	'00:00:00', '07:59:59'), -- Tarief II, valid on saturday from 00 - 08:00
	(6, 3, 'SUNDAY', 	'00:00:00', '23:59:59'), -- Tarief II, valid on sunday from 00 - 24:00	
	(7, 3, 'HOLIDAY', 	'00:00:00', '23:59:59'); -- Tarief II, valid on holidays from 00 - 24:00


INSERT INTO `P_TIMEFRAME_ACTIVITIES` (`id`, `name`, `code`) VALUES 
	(1, 'Type I (Panne)', 				'PANNE'),
	(2, 'Type II (Achterg)', 			'ACHTERGELATEN_VOERTUIG'),
	(3, 'Type III (Ongeval)', 			'ONGEVAL'),
	(4, 'Signalisatie', 				'SIGNALISATIE'),
	(5, 'Extra tijd Type III (15 min)', 'EXTRA_ONGEVAL'),
	(6, 'Extra tijd Signal (15 min)', 	'EXTRA_SIGNALISATIE'),
	(7, 'Verloren voorwerp', 			'VERLOREN_VOORWERP'),
	(8, 'Loze rit', 					'LOZE_RIT'),
	(9, 'Botsabsorbeerder (uur)', 		'BOTSABSORBEERDER');


INSERT INTO `P_TIMEFRAME_ACTIVITY_FEE` (`id`, `timeframe_id`, `timeframe_activity_id`, `fee_incl_vat`, `fee_excl_vat`, `valid_from`, `valid_until`) VALUES 
	(1, 1, 1, 141.58,	100.00,	'2014-01-01', '2020-12-31'),
	(2, 1, 2, 176.74, 	100.00,	'2014-01-01', '2020-12-31'),
	(3, 1, 3, 219.41, 	100.00,	'2014-01-01', '2020-12-31'),
	(4, 1, 4, 72.60, 	100.00,	'2014-01-01', '2020-12-31'),
	(5, 1, 5, 18.15, 	100.00,	'2014-01-01', '2020-12-31'),
	(6, 1, 6, 18.15, 	100.00,	'2014-01-01', '2020-12-31'),
	(7, 1, 7, 121.00, 	100.00,	'2014-01-01', '2020-12-31'),
	(8, 1, 8, 72.60, 	100.00,	'2014-01-01', '2020-12-31'),
	(9, 1, 9, 72.60, 	100.00,	'2014-01-01', '2020-12-31');

INSERT INTO `P_TIMEFRAME_ACTIVITY_FEE` (`id`, `timeframe_id`, `timeframe_activity_id`, `fee_incl_vat`, `fee_excl_vat`, `valid_from`, `valid_until`) VALUES 
	(10, 2, 1, 212.38, 	100.00,	'2014-01-01', '2020-12-31'),
	(11, 2, 2, 265.12, 	100.00,	'2014-01-01', '2020-12-31'),
	(12, 2, 3, 329.12, 	100.00,	'2014-01-01', '2020-12-31'),
	(13, 2, 4, 108.90, 	100.00,	'2014-01-01', '2020-12-31'),
	(14, 2, 5, 24.20, 	100.00,	'2014-01-01', '2020-12-31'),
	(15, 2, 6, 24.20, 	100.00,	'2014-01-01', '2020-12-31'),
	(16, 2, 7, 121.00, 	100.00,	'2014-01-01', '2020-12-31'),
	(17, 2, 8, 90.75, 	100.00,	'2014-01-01', '2020-12-31'),
	(18, 2, 9, 90.75, 	100.00,	'2014-01-01', '2020-12-31');

INSERT INTO `P_TIMEFRAME_ACTIVITY_FEE` (`id`, `timeframe_id`, `timeframe_activity_id`, `fee_incl_vat`, `fee_excl_vat`, `valid_from`, `valid_until`) VALUES 
	(19, 3, 1, 283.16, 	100.00,	'2014-01-01', '2020-12-31'),
	(20, 3, 2, 353.49, 	100.00,	'2014-01-01', '2020-12-31'),
	(21, 3, 3, 438.82, 	100.00,	'2014-01-01', '2020-12-31'),
	(22, 3, 4, 145.20, 	100.00,	'2014-01-01', '2020-12-31'),
	(23, 3, 5, 30.25, 	100.00,	'2014-01-01', '2020-12-31'),
	(24, 3, 6, 30.25, 	100.00,	'2014-01-01', '2020-12-31'),
	(25, 3, 7, 121.00, 	100.00,	'2014-01-01', '2020-12-31'),
	(26, 3, 8, 108.90, 	100.00,	'2014-01-01', '2020-12-31'),
	(27, 3, 9, 108.90, 	100.00,	'2014-01-01', '2020-12-31');

UPDATE `P_TIMEFRAME_ACTIVITY_FEE` SET fee_excl_vat = (fee_incl_vat/121)*100 WHERE id > 0 and id < 28;