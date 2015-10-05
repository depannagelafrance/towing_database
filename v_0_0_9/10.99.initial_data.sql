INSERT INTO T_SEQUENCES(code, company_id, seq_val, valid_from, valid_until)
VALUES('INVOICE', 1, 2016000000, '2015-10-01', '2016-09-30')
ON DUPLICATE KEY UPDATE seq_val = 2016000000, valid_from='2015-10-01', valid_until='2016-09-30';

INSERT INTO T_SEQUENCES(code, company_id, seq_val, valid_from, valid_until)
VALUES('CN', 1, 2016000000, '2015-10-01', '2016-09-30')
ON DUPLICATE KEY UPDATE seq_val = 2016000000, valid_from='2015-10-01', valid_until='2016-09-30';
