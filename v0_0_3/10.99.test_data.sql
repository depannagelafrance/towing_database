
INSERT INTO `T_COMPANIES`(id, name, code, street, street_number, street_pobox, city, phone, fax, email, website) VALUES 
	(3, 'ACUZIO BVBA', 'ACUZIO', '', '', '', '', '', '', '', '');

INSERT INTO T_COMPANY_ALLOTMENTS(company_id, allotment_id) VALUES(3,1);

INSERT INTO `P_COMPANY_MODULES` (`module_id`, `company_id`, `cd`, `cd_by`, `dd`, `dd_by`) 
SELECT id, 3, now(), 'SYSTEM', null, null FROM P_MODULES WHERE id != 4;


SET @user_id = UUID();

INSERT INTO T_USERS(id, company_id, login, first_name, last_name, email, is_active, is_locked, locked_ts, cd, cd_by)
values(@user_id, 3, 'acuzio', 'ACUZIO', 'BVBA', '', 1, 0, null, now(), 'SYSTEM');

INSERT INTO `T_USER_PASSWORDS` (`user_id`, `pwd`) VALUES (@user_id, PASSWORD('ACuZ10]'));

INSERT INTO T_USER_ROLES(user_id, role_id) VALUES(@user_id, 1);
