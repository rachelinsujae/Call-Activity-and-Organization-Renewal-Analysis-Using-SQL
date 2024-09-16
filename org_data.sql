CREATE DATABASE organization_data;

USE organization_data;

-- 1.Find the first connected call for all the renewed organizations from the Gujarat Location


SELECT 
    org.org_id,
    org.org_name,
    MIN(c.call_date) AS first_connected_call_date
FROM 
    organization AS org
JOIN 
    log AS c
    USING(org_id)
WHERE 
    org.org_status = 'renewed' 
    AND org.location = 'Gujarat'
    AND c.call_connected = 1  
GROUP BY 
    org.org_id, org.org_name;
    
/** 2.Find the count of organizations that had three consecutive calls (excluding Saturday 
and Sunday) within 0-4 days, 5-8 days, 8-15 days, 16-30 days,30+ days of organization 
creation.
a. Perform this analysis for both renewed and not renewed organizations **/


WITH ConsecutiveCalls AS (
    SELECT 
        org.org_id,
        org.org_status,
        org.org_date,
        c.call_date,
        DATEDIFF(c.call_date, org.org_date) AS days_since_org_creation,
        LEAD(c.call_date, 1) OVER (PARTITION BY org.org_id ORDER BY c.call_date) AS next_call_date,
        LEAD(c.call_date, 2) OVER (PARTITION BY org.org_id ORDER BY c.call_date) AS third_call_date,
        WEEKDAY(c.call_date) AS call_day
    FROM 
        organization AS org
    JOIN 
        log AS c
        ON org.org_id = c.org_id
    WHERE 
        WEEKDAY(c.call_date) BETWEEN 0 AND 4  -- Exclude Saturday (5) and Sunday (6)
),
ThreeConsecutiveCalls AS (
    SELECT 
        org_id,
        org_status,
        days_since_org_creation,
        (third_call_date IS NOT NULL AND DATEDIFF(third_call_date, call_date) <= 4) AS has_three_consecutive_calls
    FROM 
        ConsecutiveCalls
    WHERE 
        DATEDIFF(next_call_date, call_date) <= 4  -- Check if the next call is within 4 days
)
SELECT 
    org_status,
    COUNT(CASE WHEN days_since_org_creation BETWEEN 0 AND 4 THEN 1 END) AS `0-4 days`,
    COUNT(CASE WHEN days_since_org_creation BETWEEN 5 AND 8 THEN 1 END) AS `5-8 days`,
    COUNT(CASE WHEN days_since_org_creation BETWEEN 9 AND 15 THEN 1 END) AS `8-15 days`,
    COUNT(CASE WHEN days_since_org_creation BETWEEN 16 AND 30 THEN 1 END) AS `16-30 days`,
    COUNT(CASE WHEN days_since_org_creation > 30 THEN 1 END) AS `30+ days`
FROM 
    ThreeConsecutiveCalls
WHERE 
    has_three_consecutive_calls = 1
GROUP BY 
    org_status;


/** 3. Identify the location with the maximum number of connected calls for unique leads **/


SELECT org.location, COUNT(DISTINCT c.lead_id) AS unique_lead_count
FROM organization AS org
JOIN log AS c
USING(org_id)
WHERE call_connected = 1
GROUP BY org.location
ORDER BY unique_lead_count DESC
LIMIT 1;

/** 4. For calls not connected, identify the most common reason(s) for why the call was not 
connected.**/


SELECT call_not_connected_reason, COUNT(*) AS reason_count
FROM organization as org
JOIN log as c
USING(org_id)
WHERE call_connected = 0
GROUP by c.call_not_connected_reason
ORDER BY reason_count DESC;

/** 5. Create a summary for your analysis to summarize your findings and inference for the above queries.

SUMMARY:

This project involves analyzing call data for organizations, focusing on various aspects such as connected calls, call frequencies, and reasons for call failures. The analysis is segmented for renewed and not renewed organizations, enabling insights into organizational behavior based on their renewal status. Below are the key findings:

First Connected Call for Renewed Organizations from Gujarat: The first connected call for each renewed organization in the Gujarat region was identified, with a notable example being Company R, which had its first connected call on 2023-05-23 06:01:54. This data helps track the initial success of outreach efforts for organizations that eventually renew.

Consecutive Call Analysis for Renewed and Not Renewed Organizations: We analyzed the frequency of calls within certain time intervals from the date of organization creation, excluding weekends (Saturday and Sunday). 

For renewed organizations, the call distributions were as follows:

0-4 days: 8 organizations
5-8 days: 7 organizations
8-15 days: 7 organizations
16-30 days: 14 organizations
30+ days: 85 organizations

For not renewed organizations, the call distributions were:

0-4 days: 7 organizations
5-8 days: 34 organizations
8-15 days: 0 organizations
16-30 days: 0 organizations
30+ days: 61 organizations

This analysis shows that renewed organizations tended to have more calls within the 30+ day range, possibly indicating a longer engagement period leading to renewal.

Location with the Maximum Number of Connected Calls for Unique Leads: The state of Maharashtra had the maximum number of connected calls, with 76 unique leads. This highlights Maharashtra as a key location for successful outreach efforts.

Most Common Reasons for Not Connected Calls: Among the calls that were not connected, the most common reason was "NOT_PICKED", accounting for 107 instances. This information provides critical insight into challenges in outreach, emphasizing the need for strategies to improve customer engagement and reduce missed connections.

**/



