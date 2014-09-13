SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

TRUNCATE TABLE T_COMPANIES;
TRUNCATE TABLE T_USERS;
TRUNCATE TABLE T_USER_PASSWORDS;
TRUNCATE TABLE T_USER_TOKENS;

INSERT INTO T_COMPANIES(id, name, code, street, street_number, street_pobox, city, phone, fax, email, website, depot) 
VALUES (1, 'ACUZIO BVBA', 'ACUZIO', 'Voorspoedstraat', '8', '', 'Essen', '+32472702460', '', 'kvandermast@gmail.com', '', 'Thuis Depot');

INSERT INTO T_USERS(id, company_id, login, first_name, last_name, email, is_active, is_locked, locked_ts, cd, cd_by)
values(1, 1, 'admin', 'Master', 'Chief', 'kvandermast@gmail.com', 1, 0, null, now(), 'SYSTEM');
INSERT INTO `T_USER_PASSWORDS` (`id`, `user_id`, `pwd`) VALUES (1, 1, PASSWORD('T0w1nG'));
INSERT INTO `T_USER_TOKENS` (`user_id`, `token`) VALUES (1, 'TOKEN1');

SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;