-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - A data dictionary is included with the files for this project.

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.



-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

SELECT MIN(year) as first_year, MAX(year) as most_recent_year
FROM homegames;

--a: 1871- 2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT 
	playerid,
	namefirst || ' '|| namelast AS full_name,
	height,
	t.name AS team_name,
	(SELECT COUNT(g_all)
		FROM appearances) AS num_games_played
--		WHERE playerid = 'gaedeed01' (don't need this)
FROM people p
INNER JOIN appearances a
	USING (playerid)
LEFT JOIN teams t
	USING (teamid)
ORDER BY height
LIMIT 1


--a: Eddie Gaedel, 43", St Louis Browns, 1 game
-- he batted. I bet he got walked! Let's see
SELECT *
FROM batting
WHERE playerid = 'gaedeed01'
--yup.

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

--this gives me playerids for vandy kids
SELECT DISTINCT(playerid)
FROM collegeplaying
JOIN
	(SELECT s.schoolID,
	schoolname
	FROM schools AS s
	WHERE schoolname LIKE 'Vanderbilt%') AS v
	USING (schoolid)

--goal: vandy kids names
SELECT namefirst,
	namelast
FROM people 
WHERE playerid IN
	(SELECT DISTINCT(playerid)
	FROM collegeplaying
	JOIN
	(SELECT s.schoolID,
	schoolname
	FROM schools AS s
	WHERE schoolname LIKE 'Vanderbilt%') AS v
	USING (schoolid));

--goal: find salaries of vandy kids
SELECT namefirst,
	namelast,
	SUM(salary) AS total_salary
FROM salaries
INNER JOIN people
	USING (playerid)
WHERE playerid IN
--	(SELECT DISTINCT(playerid)
--don't need distinct in the subquery bc it is already acting like a filter
	(SELECT playerid
	FROM collegeplaying
	JOIN
	(SELECT s.schoolID,
	schoolname
	FROM schools AS s
	WHERE schoolname LIKE 'Vanderbilt%') AS v
	USING (schoolid))
GROUP BY namefirst, namelast
ORDER BY total_salary DESC;

--a: David Price, $81,851,296

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

--1ST PART OF Q
SELECT
--	playerid,
	CASE WHEN pos = 'OF' THEN 'outfield'
	WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'infield'
	WHEN pos = 'P' OR pos = 'C' THEN 'battery'
	END AS position,
	SUM(po)
FROM fielding
WHERE yearid = 2016
GROUP BY position

--2ND PART OF Q. ABOVE ISN'T SUMMING THE PUTOUTS 
--added in POs. 

-- "battery"	41424
-- "outfield"	29560
-- "infield"	58934

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

--corrected to >1920s
--corrected the hr to the so math (the /2 part), and commented out the avg test

SELECT 
	CONCAT(LEFT(CAST(yearid AS varchar),3),'0s') AS decade,
	ROUND(SUM(so::numeric)/SUM(g::numeric/2),2) AS avg_so_pg
FROM teams
WHERE yearid>=1920
GROUP BY decade
ORDER BY decade

--now for homeruns

SELECT 
	CONCAT(LEFT(CAST(yearid AS varchar),3),'0s') AS decade,
	ROUND(SUM((hr::numeric))/SUM(g::numeric/2),2) AS av_hr_pg
FROM teams
WHERE yearid >=1920
GROUP BY decade
ORDER BY decade 



-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.


SELECT
	namefirst,
	namelast,
	(sb::numeric)/(sb::numeric + cs::numeric)*100 AS success_rate
FROM batting
LEFT JOIN people
	USING (playerid)
WHERE (sb+cs)>=20
	AND yearid=2016
GROUP BY namefirst,namelast,sb,cs
ORDER BY success_rate DESC

--a: chris owings
--if were multiple years, would need to use SUMs, and then a HAVING statement instead of WHERE. here it works bc it's 1 yr


-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT 
	teamid,
	yearid,
--	max(w) AS total_wins_wsl,
--Amanda says don't need max but it increases rows a ton not to?
	w AS total_wins_wsl,
	wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin LIKE 'N'
--GROUP BY yearid, teamid, w, wswin
ORDER BY total_wins_wsl 

--largest wins: 116
--fewest wins ws-Y: 63. now explore

select yearid, AVG(w) as avg_w
from teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY yearid
ORDER BY avg_w 

--1981 has only 53 avg wins/team/year
--exclude 1981 

SELECT 
	yearid,
	w AS total_wins_wsw,
--removing MIN from here too
	wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND yearid <> 1981
	AND wswin LIKE 'Y'
--GROUP BY yearid, wswin,
ORDER BY total_wins_wsw

--new answer: 83


--last part: How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
WITH most_per_year AS(
SELECT 
	yearid as years,
	max(w) AS max_wins
--	wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY yearid
ORDER BY yearid 
)
SELECT 
	COUNT(yearid) as max_win_wsw_winners, --counting years of max winners bc of inner join and filter
	COUNT(yearid)::numeric/((SELECT COUNT(DISTINCT years) FROM most_per_year)::numeric)*100 AS high_score_wsw_percentage -- count of years of max winners / count of total years
FROM teams
JOIN most_per_year
ON most_per_year.max_wins = teams.w AND teams.yearid = most_per_year.years
WHERE wswin = 'Y'


-- 12	25.53191489361702127700

--alternate method:
select
	sum(case
		when wswin = 'Y' then 1 else 0
	end) as wins,
	count(*) numGames,
	sum(case
		when wswin = 'Y' then 1 else 0
	end)::numeric /
	count(*) * 100 -- as `percent`
from 
(
	select
		yearid,
		wswin,
		teamid,
		w,
		row_number() OVER(partition by yearid order by w desc) maxWin
	from teams
	where yearid > 1969
		and yearid not in (1981)
	order by yearid desc, w desc
) a
where maxwin = 1

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

(SELECT 
 'lowest attendance' type,
 park_name, 
	team,
	SUM(attendance)/SUM(games) AS avg_att_gm
FROM homegames
INNER JOIN parks
	USING (park)
WHERE year=2016
	AND games>=10
GROUP BY team, park_name
ORDER BY avg_att_gm 
LIMIT 5)
UNION
(SELECT 
 	'highest attendance' type,
	park_name, 
	team,
	SUM(attendance)/SUM(games) AS avg_att_gm
FROM homegames
INNER JOIN parks
	USING (park)
WHERE year=2016
	AND games>=10
GROUP BY team, park_name
ORDER BY avg_att_gm DESC
LIMIT 5)
ORDER BY avg_att_gm

-- "lowest attendance"	"Tropicana Field"	"TBA"	15878
-- "lowest attendance"	"Oakland-Alameda County Coliseum"	"OAK"	18784
-- "lowest attendance"	"Progressive Field"	"CLE"	19650
-- "lowest attendance"	"Marlins Park"	"MIA"	21405
-- "lowest attendance"	"U.S. Cellular Field"	"CHA"	21559
-- "highest attendance"	"Wrigley Field"	"CHN"	39906
-- "highest attendance"	"AT&T Park"	"SFN"	41546
-- "highest attendance"	"Rogers Centre"	"TOR"	41877
-- "highest attendance"	"Busch Stadium III"	"SLN"	42524
-- "highest attendance"	"Dodger Stadium"	"LAN"	45719


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

WITH nl AS(
SELECT 
	a.playerid AS nl_manager,
	a.awardid,
	a.lgid,
	a.yearid
FROM awardsmanagers a
WHERE awardid LIKE 'TSN Manager of the Year'
 	AND a.lgid LIKE 'NL'
),
al AS(
SELECT 
	a.playerid AS al_manager,
	a.awardid,
	a.lgid,
	a.yearid
FROM awardsmanagers a
WHERE awardid LIKE 'TSN Manager of the Year'
 	AND a.lgid LIKE 'AL'
	ORDER BY yearid
)
SELECT
	DISTINCT(namefirst || ' '|| namelast) AS manager_name,
	a.lgid,
	t.name AS team_name
FROM awardsmanagers a
INNER JOIN al
	ON a.playerid = al.al_manager
INNER JOIN nl
	ON a.playerid = nl.nl_manager
INNER JOIN people p
	USING (playerid)
INNER JOIN managers m
	using (playerid)
INNER JOIN teams t
	on t.teamid = m.teamid AND t.yearid = a.yearid
WHERE al_manager=nl_manager
	AND a.yearid = m.yearid

--would have been WAY easier to do this with INTERSECT


-- "Davey Johnson"	"AL"	"Baltimore Orioles"
-- "Davey Johnson"	"NL"	"Washington Nationals"
-- "Jim Leyland"	"AL"	"Detroit Tigers"
-- "Jim Leyland"	"NL"	"Pittsburgh Pirates"


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

-- player names - people
-- max hr >=1 -batting?
-- 2016 
-- league 10+yr - player (finalgame - debut need to cast as #)

--players in 2016
WITH hr_sixteen AS
	(SELECT playerid, yearid, hr as player_hr_sixteen
	FROM batting
	WHERE yearid = 2016
	--GROUP by playerid, yearid, hr
	ORDER BY player_hr_sixteen DESC),

-- tenure as (
-- 	SELECT  playerid,
-- 			DATE_PART('year',finalgame::date)
-- 			-DATE_PART('YEAR',debut::date)+1 AS tenure
-- FROM people
-- order by playerid ),
--above gives 12 players, not 9

--alternate below:
tenure AS (
	SELECT COUNT(DISTINCT yearid) AS tenure, playerid
	FROM batting
	GROUP BY playerid),

--each player's max hr in a year
max_hrs AS (
	SELECT playerid, yearid, hr AS hr_yearly,
		MAX(hr) OVER(PARTITION BY playerid) AS best_year_hrs
	FROM batting
	GROUP BY playerid, yearid, hr)

SELECT playerid, max_hrs.yearid, namefirst, namelast, hr_yearly AS total_hr_2016, tenure
FROM max_hrs
INNER JOIN hr_sixteen
USING(playerid)
INNER JOIN tenure
USING(playerid)
INNER JOIN people
USING(playerid)
WHERE best_year_hrs = player_hr_sixteen
	AND hr_yearly > 0
	AND max_hrs.yearid = 2016
	AND tenure >= 10
ORDER BY playerid

-- "Robinson"	"Cano"	39
-- "Bartolo"	"Colon"	1
-- "Rajai"	"Davis"	12
-- "Edwin"	"Encarnacion"	42
-- "Francisco"	"Liriano"	1
-- "Mike"	"Napoli"	34
-- "Angel"	"Pagan"	12
-- "Justin"	"Upton"	31
-- "Adam"	"Wainwright"	2
