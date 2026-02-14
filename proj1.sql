-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era) AS
SELECT MAX(era)
FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
    SELECT p.nameFirst namefirst, p.nameLast namelast, p.birthyear birthyear
    FROM people p
    WHERE p.weight > 300 AND p.weight IS NOT NULL
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
    SELECT p.namefirst, p.namelast, p.birthyear
    FROM people p
    WHERE p.namefirst LIKE '% %' ORDER BY p.namefirst, p.namelast
;

-- iii. 对 people 表按 birthyear 分组，
-- 返回每个出生年份的 birthyear、平均身高（height）、该年份的球员数量。结果按 birthyear 升序排列。
-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, avg(height), count(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, avg(height), count(*)
  FROM people
  GROUP BY birthyear
  HAVING avg(height) > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, h.yearid
  FROM people p INNER JOIN halloffame h on p.playerid = h.playerid
  WHERE h.inducted = 'Y'
  ORDER BY h.yearid desc, p.playerid asc
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, s.schoolid, h.yearid
  FROM people p INNER JOIN halloffame h ON p.playerid = h.playerid
                INNER JOIN collegePlaying c ON p.playerid = c.playerid
                INNER JOIN schools s ON c.schoolid = s.schoolid
  WHERE h.inducted = 'Y' and s.schoolState = 'CA'
  ORDER BY h.yearid desc, s.schoolid asc, p.playerid asc
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, c.schoolid
  FROM people p INNER JOIN halloffame h ON p.playerid = h.playerid
              LEFT JOIN collegePlaying c ON p.playerid = c.playerid
  WHERE h.inducted = 'Y'
  ORDER BY p.playerid desc, c.schoolid asc
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, p.namefirst, p.namelast, b.yearid,
    -- 计算SLG（转浮点数避免整数除法）
    CAST( ( (b.H - b.H2B - b.H3B - b.HR)*1 + b.H2B*2 + b.H3B*3 + b.HR*4 ) AS FLOAT ) / CAST(b.AB AS FLOAT) AS slg
  FROM people p INNER JOIN batting b ON p.playerid = b.playerid
  WHERE b.AB > 50
  ORDER BY slg DESC, b.yearid ASC, p.playerid ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg) AS
    SELECT
        p.playerid,
        p.namefirst,
        p.namelast,
        CAST(
                (SUM(b.H) - SUM(b.H2B) - SUM(b.H3B) - SUM(b.HR))*1 +
                SUM(b.H2B)*2 +
                SUM(b.H3B)*3 +
                SUM(b.HR)*4
            AS FLOAT
        ) /
        CAST(SUM(b.AB) AS FLOAT) AS lslg
    FROM Batting b INNER JOIN People p ON b.playerid = p.playerid
    GROUP BY p.playerid
    HAVING SUM(b.AB) > 50
    ORDER BY lslg DESC, p.playerid ASC
    LIMIT 10;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg) AS
    WITH career_slg AS (
        SELECT
            p.playerid,
            p.namefirst,
            p.namelast,
            CAST(
                    (SUM(b.H) - SUM(b.H2B) - SUM(b.H3B) - SUM(b.HR))*1 +
                    SUM(b.H2B)*2 +
                    SUM(b.H3B)*3 +
                    SUM(b.HR)*4
                AS FLOAT
            ) / CAST(SUM(b.AB) AS FLOAT) AS lslg
        FROM Batting b
                 JOIN People p ON b.playerid = p.playerid
        GROUP BY p.playerid
        HAVING SUM(b.AB) > 50
    )
    SELECT
        namefirst,
        namelast,
        lslg
    FROM career_slg
    WHERE lslg > (
        SELECT lslg FROM career_slg WHERE playerid = 'mayswi01'
    )
    ORDER BY lslg DESC, playerid ASC;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg) AS
    SELECT
        yearid,
        MIN(salary) AS min,
        MAX(salary) AS max,
        AVG(salary) AS avg  -- SQLite自动计算浮点数平均值
    FROM Salaries
    GROUP BY yearid
    ORDER BY yearid ASC;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count) AS
    -- 第一步：计算2016年薪资的min/max和区间宽度
WITH salary_2016 AS (
    SELECT salary FROM Salaries WHERE yearid = 2016
),
     bounds AS (
         SELECT
             MIN(salary) AS min_sal,
             MAX(salary) AS max_sal,
             (MAX(salary) - MIN(salary)) / 10 AS bin_width
         FROM salary_2016
     )
-- 第二步：结合binids表生成10个区间，计算每个区间的count
SELECT
    b.binid,
    ROUND((SELECT min_sal FROM bounds) + b.binid * (SELECT bin_width FROM bounds), 2) AS low,
    CASE
        WHEN b.binid = 9 THEN (SELECT max_sal FROM bounds)
        ELSE ROUND((SELECT min_sal FROM bounds) + (b.binid + 1) * (SELECT bin_width FROM bounds), 2)
        END AS high,
    COUNT(s.salary) AS count
FROM binids b
         LEFT JOIN salary_2016 s
                   ON s.salary >= ((SELECT min_sal FROM bounds) + b.binid * (SELECT bin_width FROM bounds))
                       AND (s.salary < ((SELECT min_sal FROM bounds) + (b.binid + 1) * (SELECT bin_width FROM bounds)) OR (b.binid = 9 AND s.salary <= (SELECT max_sal FROM bounds)))
GROUP BY b.binid
ORDER BY b.binid ASC;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff) AS
WITH yearly_salary AS (
    SELECT
        yearid,
        MIN(salary) AS min_sal,
        MAX(salary) AS max_sal,
        AVG(salary) AS avg_sal
    FROM Salaries
    GROUP BY yearid
)
SELECT
    curr.yearid,
    curr.min_sal - prev.min_sal AS mindiff,
    curr.max_sal - prev.max_sal AS maxdiff,
    curr.avg_sal - prev.avg_sal AS avgdiff
FROM yearly_salary curr
         JOIN yearly_salary prev ON curr.yearid = prev.yearid + 1
ORDER BY curr.yearid ASC;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid) AS
WITH yearly_max_salary AS (
    SELECT
        yearid,
        MAX(salary) AS max_sal
    FROM Salaries
    WHERE yearid IN (2000, 2001)
    GROUP BY yearid
)
SELECT
    s.playerid,
    p.namefirst,
    p.namelast,
    s.salary,
    s.yearid
FROM Salaries s
         JOIN People p ON s.playerid = p.playerid
         JOIN yearly_max_salary m
              ON s.yearid = m.yearid AND s.salary = m.max_sal
WHERE s.yearid IN (2000, 2001)
ORDER BY s.yearid ASC, s.playerid ASC;

-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
WITH allstar_2016 AS (
    SELECT
        a.playerid,
        a.teamid AS team,
        s.salary
    FROM AllStarFull a
             LEFT JOIN Salaries s
                       ON a.playerid = s.playerid
                           AND a.yearid = 2016
                           AND s.yearid = 2016
    WHERE a.yearid = 2016
),
     team_sal_stats AS (
         SELECT
             team,  -- 用别名team分组
             MAX(salary) AS max_sal,
             MIN(salary) AS min_sal
         FROM allstar_2016
         WHERE salary IS NOT NULL
         GROUP BY team
     )
SELECT
    team,
    max_sal - min_sal AS diffAvg
FROM team_sal_stats
ORDER BY team ASC;

