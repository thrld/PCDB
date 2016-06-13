﻿CREATE OR REPLACE VIEW config_data.cc_lh_vola_sts
AS
SELECT * 
	FROM
		(SELECT lhelc_id, lh_vola_sts_computed 
			FROM
				(SELECT lhelc_id, lh_id 
					FROM config_data.lower_house
				) AS LOWER_HOUSE 
			JOIN
				(SELECT lh_id, lh_vola_sts_computed
					FROM config_data.view_lh_vola_sts
				) AS LH_VOLA_STS
			USING (lh_id)
		) AS COMPUTED
	FULL OUTER JOIN
		(SELECT lhelc_id, lhelc_vola_sts 
			FROM config_data.lh_election
		) AS RECORDED
	USING (lhelc_id)
	WHERE TRUNC(lh_vola_sts_computed::NUMERIC, 7) != TRUNC(lhelc_vola_sts::NUMERIC, 7);
