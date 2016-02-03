SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

INSERT INTO `P_ALLOTMENT_DIRECTION_INDICATORS`
(`allotment_directions_id`,
`name`,
`sequence`)
SELECT id, '- Niet gekend -', -1
FROM P_ALLOTMENT_DIRECTIONS;

INSERT INTO P_ALLOTMENT_MAP(allotment_id, direction_id, indicator_id)
SELECT 1, allotment_directions_id, id FROM P_ALLOTMENT_DIRECTION_INDICATORS WHERE sequence < 0;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;