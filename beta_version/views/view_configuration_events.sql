﻿CREATE OR REPLACE VIEW beta_version.view_configuration_events
AS
WITH 
	start_dates AS (SELECT cab_sdate AS sdate, ctr_id 
				FROM beta_version.cabinet
			UNION
			SELECT lh_sdate AS sdate, ctr_id 
				FROM beta_version.lower_house
			UNION
			SELECT uh_sdate AS sdate, ctr_id 
				FROM beta_version.upper_house
			UNION 
			SELECT prs_sdate AS sdate, ctr_id 
				FROM beta_version.presidential_election
			UNION
			SELECT vto_inst_sdate AS sdate, ctr_id 
				FROM beta_version.veto_points 
				WHERE vto_inst_sdate >= '1995-01-01'::DATE -- note that here, too, only post 1995's subset is considered 
			ORDER BY ctr_id, sdate NULLS FIRST ) , -- WITH AS start_dates
	cabinets AS (SELECT ctr_id, cab_sdate, cab_id FROM beta_version.cabinet) ,
	lower_houses AS (SELECT ctr_id, lh_sdate, lh_id, lhelc_id FROM beta_version.lower_house) ,
	upper_houses AS (SELECT ctr_id, uh_sdate, uh_id FROM beta_version.upper_house) ,
	presidents AS (SELECT ctr_id, prs_sdate, prselc_id FROM beta_version.presidential_election),
	configs AS (SELECT DISTINCT ON (ctr_id, sdate) start_dates.ctr_id, start_dates.sdate, 
				cabinets.cab_id, lower_houses.lh_id, lower_houses.lhelc_id, upper_houses.uh_id, presidents.prselc_id, 
				DATE_PART('year', sdate)::NUMERIC AS year,
				NULL::DATE AS edate
			FROM 
			  start_dates 
			  LEFT OUTER JOIN cabinets 
			    ON (start_dates.ctr_id = cabinets.ctr_id 
			        AND start_dates.sdate = cabinets.cab_sdate)
			  LEFT OUTER JOIN lower_houses 
			    ON (start_dates.ctr_id = lower_houses.ctr_id 
			        AND start_dates.sdate = lower_houses.lh_sdate)
			  LEFT OUTER JOIN upper_houses 
			    ON (start_dates.ctr_id = upper_houses.ctr_id 
			        AND start_dates.sdate = upper_houses.uh_sdate)
			  LEFT OUTER JOIN presidents 
			    ON (start_dates.ctr_id = presidents.ctr_id 
			        AND start_dates.sdate = presidents.prs_sdate))
SELECT *, 
	CASE
		WHEN cab_id IS NOT NULL THEN
			CASE WHEN (lh_id, lhelc_id, uh_id, prselc_id) IS NULL THEN 'change in cabinet composition'::TEXT	     
			     WHEN lh_id IS NOT NULL THEN
				CASE WHEN lhelc_id IS NOT NULL THEN
					CASE WHEN uh_id IS NOT NULL AND prselc_id IS NULL THEN 'change in cabinet, LH (due to election) and UH composition'::TEXT
					     WHEN prselc_id IS NOT NULL AND uh_id IS NULL THEN 'change in cabinet and LH (due to election) composition, and presidency'::TEXT
					     WHEN (uh_id, prselc_id) IS NOT NULL THEN 'change in cabinet, LH (due to election) and UH composition, and presidency'::TEXT
					     ELSE 'change in cabinet and LH (due to election) composition'::TEXT
					END
				ELSE 
					CASE WHEN uh_id IS NOT NULL AND prselc_id IS NULL THEN 'change in cabinet, LH (due to party split/merger) and UH composition'::TEXT
					     WHEN prselc_id IS NOT NULL AND uh_id IS NULL THEN 'change in cabinet and LH (due to party split/merger) composition, and presidency'::TEXT
					     WHEN (uh_id, prselc_id) IS NOT NULL THEN 'change in cabinet, LH (due to party split/merger) and UH composition, and presidency'::TEXT
					     ELSE 'change in cabinet and LH (due to party split/merger) composition'::TEXT
					END
				END
			     WHEN uh_id IS NOT NULL THEN
				CASE WHEN prselc_id IS NULL THEN 'change in cabinet and UH composition'::TEXT
				     WHEN prselc_id IS NOT NULL THEN 'change in cabinet and UH composition, and presidency'::TEXT
				END
			     WHEN prselc_id IS NOT NULL THEN 'change in cabinet  composition and presidency'::TEXT
			END
		WHEN lh_id IS NOT NULL THEN
			CASE WHEN lhelc_id IS NOT NULL THEN
				CASE WHEN uh_id IS NOT NULL AND prselc_id IS NULL THEN 'change in LH (due to election) and UH composition'::TEXT
				     WHEN prselc_id IS NOT NULL AND uh_id IS NULL THEN 'change in LH composition (due to election) and presidency'::TEXT
				     WHEN (uh_id, prselc_id) IS NOT NULL THEN 'change in LH (due to election) and UH composition, and presidency'::TEXT
				     ELSE 'change in LH composition (due to election)'::TEXT
				END
			     ELSE 
				CASE WHEN uh_id IS NOT NULL AND prselc_id IS NULL THEN 'change LH (due to party split/merger) and UH composition'::TEXT
				     WHEN prselc_id IS NOT NULL AND uh_id IS NULL THEN 'change LH composition (due to party split/merger) and presidency'::TEXT
				     WHEN (uh_id, prselc_id) IS NOT NULL THEN 'change LH (due to party split/merger) and UH composition, and presidency'::TEXT
				     ELSE 'change LH composition (due to party split/merger)'::TEXT
				END
			END
		WHEN uh_id IS NOT NULL THEN
			CASE WHEN prselc_id IS NULL THEN 'change UH composition'::TEXT
			     ELSE 'change UH composition and presidency'::TEXT
			END
		WHEN prselc_id IS NOT NULL THEN 'change in presidency'::TEXT
		ELSE 'change in institutional veto power (constitutional change)'::TEXT
	END AS type_of_change
FROM configs  
ORDER BY ctr_id, sdate ASC