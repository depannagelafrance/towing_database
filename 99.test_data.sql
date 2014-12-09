-- these are the test data settngs

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

TRUNCATE TABLE T_USERS;
TRUNCATE TABLE T_USER_PASSWORDS;
TRUNCATE TABLE T_USER_TOKENS;

INSERT INTO T_USERS(id, company_id, login, first_name, last_name, email, is_active, is_locked, locked_ts, cd, cd_by)
values(1, 1, 'admin', 'Master', 'Chief', 'kvandermast@gmail.com', 1, 0, null, now(), 'SYSTEM');
INSERT INTO `T_USER_PASSWORDS` (`id`, `user_id`, `pwd`) VALUES (1, 1, PASSWORD('T0w1nG'));
INSERT INTO `T_USER_TOKENS` (`user_id`, `token`) VALUES (1, 'TOKEN1');

INSERT INTO T_USERS(id, company_id, login, first_name, last_name, email, is_active, is_locked, locked_ts, cd, cd_by)
values(2, 1, 'gert', 'Gert', 'VDB', 'kvandermast@gmail.com', 1, 0, null, now(), 'SYSTEM');
INSERT INTO `T_USER_PASSWORDS` (`id`, `user_id`, `pwd`) VALUES (2, 2, PASSWORD('gert'));

INSERT INTO T_USERS(id, company_id, login, first_name, last_name, email, is_active, is_locked, locked_ts, cd, cd_by)
values(3, 1, 'misja', 'Misja', 'W', 'kvandermast@gmail.com', 1, 0, null, now(), 'SYSTEM');
INSERT INTO `T_USER_PASSWORDS` (`id`, `user_id`, `pwd`) VALUES (3, 3, PASSWORD('misja'));

INSERT INTO T_USERS(id, company_id, login, first_name, last_name, email, is_active, is_locked, locked_ts, cd, cd_by)
values(4, 1, 'kris', 'Kris', 'VDM', 'kvandermast@gmail.com', 1, 0, null, now(), 'SYSTEM');
INSERT INTO `T_USER_PASSWORDS` (`id`, `user_id`, `pwd`) VALUES (4, 4, PASSWORD('kris'));


INSERT INTO `T_USER_ROLES` (`role_id`, `user_id`)
SELECT id, '1' FROM P_ROLES;

INSERT INTO `T_USER_ROLES` (`role_id`, `user_id`)
SELECT id, '2' FROM P_ROLES;

INSERT INTO `T_USER_ROLES` (`role_id`, `user_id`)
SELECT id, '3' FROM P_ROLES;

INSERT INTO `T_USER_ROLES` (`role_id`, `user_id`)
SELECT id, '4' FROM P_ROLES;

INSERT INTO `T_COMPANY_DEPOTS`(`id`,`company_id`,`name`,`street`,`street_number`,`street_pobox`,`zip`,`city`)
VALUES (1,1,'DEPOT LA FRANCE','Street','123',null,'2000','Antwerpen');

INSERT INTO `P_DICTIONARY`(`category`, `name`, `cd`, `cd_by`)
VALUES	('COLLECTOR', 'Klant', now(), 'SYSTEM'),
		('COLLECTOR', 'Verzekering', now(), 'SYSTEM');


SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
