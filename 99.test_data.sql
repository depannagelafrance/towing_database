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

INSERT INTO `P_MODULE_ROLES` (`role_id`, `module_id`) 
	VALUES (1, 3), (2, 4), (3, 1), (4, 2);


INSERT INTO `T_USER_ROLES` (`role_id`, `user_id`)
SELECT id, '1' FROM P_ROLES;

SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
