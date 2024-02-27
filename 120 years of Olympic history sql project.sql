select * from olympics_history
select * from olympics_history_noc_regions

-- How many olympics games have been held 

select  count(distinct games) 
from olympics_history

-- List down all Olympics games held so far.
select distinct(games) 
from olympics_history

--Mention the total no of nations who participated in each olympics game?
 
with Total_nations as
(select games, region
 from olympics_history
 join olympics_history_noc_regions on olympics_history_noc_regions.noc=olympics_history.noc
group by games,region

 )
 select games, count(region)  as Total_countries from Total_nations
 group by games
 order by games
 
----- same with above

select games, count(distinct region) as Total_countries
 from olympics_history
 join olympics_history_noc_regions on olympics_history_noc_regions.noc=olympics_history.noc
group by games
order by games

-- Which year saw the highest and lowest no of countries participating in Olympics

SELECT
    CONCAT((SELECT CONCAT(Year, ' ', Season, ' - ', COUNT(DISTINCT region))
            FROM Olympics_history
            JOIN Olympics_history_noc_regions ON Olympics_history_noc_regions.noc = Olympics_history.noc
            GROUP BY Year, Season
            ORDER BY COUNT(DISTINCT region) ASC
            LIMIT 1), ' ') AS Lowest_Countries,
    CONCAT((SELECT CONCAT(Year, ' ', Season, ' - ', COUNT(DISTINCT region))
            FROM Olympics_history
            JOIN Olympics_history_noc_regions ON Olympics_history_noc_regions.noc = Olympics_history.noc
            GROUP BY Year, Season
            ORDER BY COUNT(DISTINCT region) DESC
            LIMIT 1), ' ') AS Highest_Countries;






----Which nation has participated in all of the olympic games

SELECT t3.sport, t3.no_of_games, t1.total_games
FROM
  (SELECT sport, COUNT(DISTINCT games) AS no_of_games
   FROM olympics_history
   WHERE season = 'Summer'
   GROUP BY sport) AS t3
JOIN
  (SELECT COUNT(DISTINCT games) AS total_games
   FROM olympics_history
   WHERE season = 'Summer') AS t1
ON t1.total_games = t3.no_of_games;


------ same with the above

WITH tot_games AS (
  SELECT COUNT(DISTINCT games) AS total_games
  FROM olympics_history
),
countries AS (
  SELECT games, nr.region AS country
  FROM olympics_history oh
  JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
  GROUP BY games, nr.region
),
countries_participated AS (
  SELECT country, COUNT(1) AS total_participated_games
  FROM countries
  GROUP BY country
)
SELECT cp.*
FROM countries_participated cp
JOIN tot_games tg ON tg.total_games = cp.total_participated_games
ORDER BY 1;
  
  

---- Identify the sport which was played in all summer olympics.

SELECT t3.sport, t3.no_of_games, t1.total_games
FROM
  (SELECT sport,  COUNT(DISTINCT games) AS no_of_games
   FROM olympics_history
   WHERE season = 'Summer'
   GROUP BY sport) AS t3
JOIN
  (SELECT COUNT(DISTINCT games) AS total_games
   FROM olympics_history
   WHERE season = 'Summer') AS t1
ON t1.total_games = t3.no_of_games;
	
---- same with the above

      with t1 as
          	(select count(distinct games) as total_games
          	from olympics_history where season = 'Summer'),
          t2 as
          	(select distinct games, sport
          	from olympics_history where season = 'Summer'),
          t3 as
          	(select sport, count(1) as no_of_games
          	from t2
          	group by sport)
      select *
      from t3
      join t1 on t1.total_games = t3.no_of_games;
			
--- Which Sports were just played only once in the olympics.

SELECT sport, 
       COUNT(DISTINCT games) AS no_of_games,
       max(games) AS games
FROM olympics_history
WHERE sport IN (
    SELECT sport
    FROM olympics_history
    GROUP BY sport
    HAVING COUNT(DISTINCT games) = 1
)
GROUP BY sport;

----- Same with the above 
  with t1 as
          	(select distinct games, sport
          	from olympics_history),
          t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where t2.no_of_games = 1
      order by t1.sport;

---- Fetch the total no of sports played in each olympic games.

select games, count(distinct sport) as Num_of_sport
from olympics_history
group by games
order by Num_of_sport desc

---- same with the above

WITH t1 AS (
    SELECT games, COUNT(DISTINCT sport) AS no_of_sports
    FROM olympics_history
    GROUP BY games
)
SELECT games, no_of_sports
FROM t1
ORDER BY no_of_sports DESC;


--- also same with the above

with t1 as
      	(select distinct games, sport
      	from olympics_history),
        t2 as
      	(select games, count(1) as no_of_sports
      	from t1
      	group by games)
      select * from t2
      order by no_of_sports desc;

--- Fetch oldest athletes to win a gold medal

WITH ranking AS (
    SELECT name, sex, CAST(COALESCE(NULLIF(age, 'NA'), '0') AS INT) AS age,
           team, games, city, sport, events, medal,
	RANK() OVER (ORDER BY CAST(COALESCE(NULLIF(age, 'NA'), '0') AS INT) DESC) AS rnk
           
    FROM olympics_history
    WHERE medal = 'Gold'
)
SELECT name, sex, age, team, games, city, sport, events, medal
FROM ranking
WHERE rnk = 1;

----  Find the Ratio of male and female athletes participated in all olympic game
	
	WITH t1 AS (
    SELECT sex, COUNT(*) AS cnt
    FROM olympics_history
    GROUP BY sex
), t2 AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY cnt) AS rn
    FROM t1
), min_cnt AS (
    SELECT cnt
    FROM t2
    WHERE rn = 1
), max_cnt AS (
    SELECT cnt
    FROM t2
    WHERE rn = 2
)
SELECT CONCAT('1 : ', ROUND(max_cnt.cnt::decimal / min_cnt.cnt, 2)) AS ratio
FROM min_cnt, max_cnt;

--- same with the above

with t1 as
        	(select sex, count(1) as cnt
        	from olympics_history
        	group by sex),
        t2 as
        	(select *, row_number() over(order by cnt) as rn
        	 from t1),
        min_cnt as
        	(select cnt from t2	where rn = 1),
        max_cnt as
        	(select cnt from t2	where rn = 2)
    select concat('1 : ', round(max_cnt.cnt::decimal/min_cnt.cnt, 2)) as ratio
    from min_cnt, max_cnt;

-- Fetch the top 5 athletes who have won the most gold medals.

SELECT name, total_gold_medals, rnk
FROM (
    SELECT name, count(1) AS total_gold_medals, DENSE_RANK() OVER (ORDER BY count(1) DESC) AS rnk
    FROM olympics_history
    WHERE medal = 'Gold'
    GROUP BY name
    ORDER BY count(1) DESC
) AS t
WHERE rnk <= 5;

--- same with the above

  with t1 as
            (select name, team, count(1) as total_gold_medals
            from olympics_history
            where medal = 'Gold'
            group by name, team
            order by total_gold_medals desc),
        t2 as
            (select *, dense_rank() over (order by total_gold_medals desc) as rnk
            from t1)
    select name, team, total_gold_medals
    from t2
    where rnk <= 5;

---- Fetch the top 5 athletes who have won the most medals
with t1 as

(select name, team,count(medal) as Total_medals
from olympics_history
where medal<>'NA'
GROUP BY name,team
order by Total_medals desc),
t2 as
(select *,dense_rank() over (order by Total_medals desc ) as rnk
 from t1
)
select name, team, Total_medals
from t2
where rnk<=5;


---- same with the above

 with t1 as
            (select name, team, count(1) as total_medals
            from olympics_history
            where medal in ('Gold', 'Silver', 'Bronze')
            group by name, team
            order by total_medals desc),
        t2 as
            (select *, dense_rank() over (order by total_medals desc) as rnk
            from t1)
    select name, team, total_medals
    from t2
    where rnk <= 5;
	
--- Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.	

with t1 as
(select region, count(medal) as Total_medals
from olympics_history
join  olympics_history_noc_regions on olympics_history_noc_regions.noc = olympics_history.noc
where medal<>'NA'
group by region
order by Total_medals desc),
t2 as 
(select *, dense_rank() over(order by Total_medals desc)as rnk
from t1)

select region, Total_medals from t2
where rnk<=5;

---- List down total gold, silver and bronze medals won by each country.


SELECT nr.region,
       SUM(CASE WHEN oh.medal = 'Gold' THEN 1 ELSE 0 END) AS gold,
       SUM(CASE WHEN oh.medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
       SUM(CASE WHEN oh.medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
FROM olympics_history oh
JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
WHERE oh.medal <> 'NA'
GROUP BY nr.region
ORDER BY gold DESC, silver DESC, bronze DESC;

--- Same with the above but unique for postresql

CREATE EXTENSION TABLEFUNC;

SELECT country
    	, coalesce(gold, 0) as gold
    	, coalesce(silver, 0) as silver
    	, coalesce(bronze, 0) as bronze
    FROM CROSSTAB('SELECT nr.region as country
    			, medal
    			, count(1) as total_medals
    			FROM olympics_history oh
    			JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    			where medal <> ''NA''
    			GROUP BY nr.region,medal
    			order BY nr.region,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(country varchar, bronze bigint, gold bigint, silver bigint)
    order by gold desc, silver desc, bronze desc;



--List down total gold, silver and bronze medals won by each country corresponding to each olympic games.


 SELECT substring(games,1,position(' - ' in games) - 1) as games
        , substring(games,position(' - ' in games) + 3) as country
        , coalesce(gold, 0) as gold
        , coalesce(silver, 0) as silver
        , coalesce(bronze, 0) as bronze
    FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
                , medal
                , count(1) as total_medals
                FROM olympics_history oh
                JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
                where medal <> ''NA''
                GROUP BY games,nr.region,medal
                order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint);
	
	
--Identify which country won the most gold, most silver and most bronze medals in each olympic games.


  WITH temp as
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    	 	, substring(games, position(' - ' in games) + 3) as country
            , coalesce(gold, 0) as gold
            , coalesce(silver, 0) as silver
            , coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    				  	, count(1) as total_medals
    				  FROM olympics_history oh
    				  JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint))
    select distinct games
    	, concat(first_value(country) over(partition by games order by gold desc)
    			, ' - '
    			, first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc)
    			, ' - '
    			, first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc)
    			, ' - '
    			, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
    from temp
    order by games;

--- Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

with temp as
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    		, substring(games, position(' - ' in games) + 3) as country
    		, coalesce(gold, 0) as gold
    		, coalesce(silver, 0) as silver
    		, coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    					, count(1) as total_medals
    				  FROM olympics_history oh
    				  JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint)),
    	tot_medals as
    		(SELECT games, nr.region as country, count(1) as total_medals
    		FROM olympics_history oh
    		JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    		where medal <> 'NA'
    		GROUP BY games,nr.region order BY 1, 2)
    select distinct t.games
    	, concat(first_value(t.country) over(partition by t.games order by gold desc)
    			, ' - '
    			, first_value(t.gold) over(partition by t.games order by gold desc)) as Max_Gold
    	, concat(first_value(t.country) over(partition by t.games order by silver desc)
    			, ' - '
    			, first_value(t.silver) over(partition by t.games order by silver desc)) as Max_Silver
    	, concat(first_value(t.country) over(partition by t.games order by bronze desc)
    			, ' - '
    			, first_value(t.bronze) over(partition by t.games order by bronze desc)) as Max_Bronze
    	, concat(first_value(tm.country) over (partition by tm.games order by total_medals desc nulls last)
    			, ' - '
    			, first_value(tm.total_medals) over(partition by tm.games order by total_medals desc nulls last)) as Max_Medals
    from temp t
    join tot_medals tm on tm.games = t.games and tm.country = t.country
    order by games;

---Which countries have never won gold medal but have won silver/bronze medals?
  select * from (
    	SELECT country, coalesce(gold,0) as gold, coalesce(silver,0) as silver, coalesce(bronze,0) as bronze
    		FROM CROSSTAB('SELECT nr.region as country
    					, medal, count(1) as total_medals
    					FROM OLYMPICS_HISTORY oh
    					JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc=oh.noc
    					where medal <> ''NA''
    					GROUP BY nr.region,medal order BY nr.region,medal',
                    'values (''Bronze''), (''Gold''), (''Silver'')')
    		AS FINAL_RESULT(country varchar,
    		bronze bigint, gold bigint, silver bigint)) x
    where gold = 0 and (silver > 0 or bronze > 0)
    order by gold desc nulls last, silver desc nulls last, bronze desc nulls last;
	
---- In which Sport/event, India has won highest medals.
select region,sport,events,count( medal) as Total_medal from
OLYMPICS_HISTORY
join OLYMPICS_HISTORY_NOC_REGIONS on OLYMPICS_HISTORY_NOC_REGIONS.noc = OLYMPICS_HISTORY.noc
where region = 'India' and medal<>'NA'
group by region, sport,events
order by Total_medal desc
LIMIT 1

--- Same with the above

   with t1 as
        	(select sport, count(1) as total_medals
        	from olympics_history
        	where medal <> 'NA'
        	and team = 'India'
        	group by sport
        	order by total_medals desc),
        t2 as
        	(select *, rank() over(order by total_medals desc) as rnk
        	from t1)
    select sport, total_medals
    from t2
    where rnk = 1;
	
	
-- Break down all olympic games where India won medal for Hockey and how many medals in each olympic games	

select games, count(medal) as Total_medals
from olympics_history
join OLYMPICS_HISTORY_NOC_REGIONS on OLYMPICS_HISTORY_NOC_REGIONS.noc = OLYMPICS_HISTORY.noc
where medal <> 'NA' and sport= 'Hockey' and region= 'India'
group by games
order by Total_medals desc

---- Same with the above

 select team, sport, games, count(1) as total_medals
    from olympics_history
    where medal <> 'NA'
    and team = 'India' and sport = 'Hockey'
    group by team, sport, games
    order by total_medals desc;

















	
	


	
	
		 
	
	
	
	
	




















