CREATE TABLE users_support
(
    support_user_id VARCHAR(80)
)
-- Populate with your necessary users.user_id values
INSERT INTO users_support
SELECT
	'supportUser1'
UNION SELECT
	'supportUser2'
UNION SELECT
	'supportUser3'
