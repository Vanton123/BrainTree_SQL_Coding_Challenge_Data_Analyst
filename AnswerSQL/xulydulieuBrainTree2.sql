select * from staging_continent_map;
select * from staging_continents;
select * from staging_countries;
select * from staging_per_capita;

-- Chuyen các dữ liệu '' thành null
UPDATE continent_map
SET
    country_code = CASE country_code WHEN '' THEN NULL ELSE country_code END,
    continent_code = CASE continent_code WHEN '' THEN NULL ELSE continent_code END;

	
-- Xu ly du lieu null, duplicated va chuan hoa du lieu
-- Continent_map
select *
from staging_continent_map
where country_code is null or continent_code is null;


-- country_code co gia tri null lien quan den continent_code OC(1), AS(3)
-- Hien thi gia tri null bang 'FOO'
select coalesce(country_code,'FOO') as country_code, count(*) as NOC
from staging_continent_map
group by country_code
having count(*) >=1
order by case when country_code is null then 0 else 1 end, country_code;



-- Với mỗi quốc gia có nhiều record trong continent_map, 
-- hãy xóa các record trùng lặp và chỉ giữ lại 1 record cho mỗi quốc gia. 
-- Record được giữ phải là record đầu tiên khi sắp xếp continent_code tăng dần theo alphabet.
-- ctid la dung để định danh row khi chuyển từ CTE sang delete (kết nối cte với row gốc)
with Unique_country as(
select 
	ctid,
	country_code,
	continent_code,
	row_number() over(partition by country_code order by continent_code asc) as rn_cc
from staging_continent_map
-- WHERE country_code IS NOT NULL
)
delete from staging_continent_map as scm
using Unique_country as uc
WHERE scm.ctid = uc.ctid
  AND uc.rn_cc > 1;


-- Liet ke cac quoc gia duoc xep hang 10-12 o moi chau luc theo phan tram tang truong hang nam giam dan tu nam 2011 den nam 2012
-- C1
with gdp_perTbale as(
	select sc.continent_name,
	spc.country_code,
	sct.country_name,
	spc.gdp_per_capita,
	spc.year,
	lag(spc.gdp_per_capita) over(partition by spc.country_code order by spc.year) as y2011
	
	from staging_countries as sct
	join staging_per_capita as spc
		on sct.country_code = spc.country_code
	join staging_continent_map as scm
		on spc.country_code=scm.country_code
	join staging_continents as sc
		on scm.continent_code=sc.continent_code
	where spc.year = 2011 or spc.year=2012
)
select *
from(
	select 
	continent_name,
	country_code,
	country_name,
	round(((gdp_per_capita-y2011)/y2011)*100.0,2) as proGDP, 
	rank() over(partition by continent_name order by((gdp_per_capita-y2011)/y2011)*100.0 desc) as rn_GDP
	from gdp_perTbale
	where year=2012 and gdp_per_capita is not null and y2011 is not null
	order by continent_name
	) 
	where rn_GDP=10 or rn_GDP=11 or rn_GDP=12;





-- C2
WITH gdp_join AS (
    SELECT
        sc.continent_name,
        sct.country_code,
        sct.country_name,
        spc.year,
        spc.gdp_per_capita
    FROM staging_countries AS sct
    JOIN staging_per_capita AS spc
        ON sct.country_code = spc.country_code
    JOIN staging_continent_map AS scm
        ON sct.country_code = scm.country_code
    JOIN staging_continents AS sc
        ON scm.continent_code = sc.continent_code
),
gdp_growth_rank AS (
    SELECT 
        t1.continent_name,
        t1.country_code,
        t1.country_name,
        ROUND(
            ((t2.gdp_2012 - t1.gdp_2011) / t1.gdp_2011) * 100,
            2
        ) AS growth_percent,
        RANK() OVER (
            PARTITION BY t1.continent_name
            ORDER BY 
                ((t2.gdp_2012 - t1.gdp_2011) / t1.gdp_2011) DESC
        ) AS drank
    FROM
        (
            SELECT
                continent_name,
                country_code,
                country_name,
                gdp_per_capita AS gdp_2011
            FROM gdp_join
            WHERE year = 2011
        ) AS t1
    INNER JOIN
        (
            SELECT
                country_code,
                gdp_per_capita AS gdp_2012
            FROM gdp_join
            WHERE year = 2012
        ) AS t2
        ON t1.country_code = t2.country_code
)
SELECT *
FROM gdp_growth_rank
WHERE drank IN (10, 11, 12)
ORDER BY continent_name, drank;



-- Trong năm 2012, mỗi khu vực Asia, Europe và Rest of World chiếm bao nhiêu phần trăm trong tổng GDP per capita?
-- Kết quả phải trả về 1 dòng và 3 cột.
select 
	round(sum(case when scm.continent_code='AS' then spc.gdp_per_capita else 0 end) /sum(spc.gdp_per_capita)*100.0,2) as Asia,
	round(sum(case when scm.continent_code='EU' then spc.gdp_per_capita else 0 end)/sum(spc.gdp_per_capita)*100.0,2) as Europe,
	round(sum(case when scm.continent_code!='AS' and scm.continent_code!='EU' then spc.gdp_per_capita else 0 end)/sum(spc.gdp_per_capita)*100.0,2) as Rest_of_world
from staging_continent_map as scm
join staging_per_capita as spc
	on scm.country_code = spc.country_code
where spc.year=2012;




-- A. trong năm 2007, tìm số lượng quốc gia và tổng GDP per capita của những quốc gia có tên chứa "an", không phân biệt chữ hoa/chữ thường.
-- B. Thực hiện lại tương tự, nhưng lần này việc tìm "an" phải phân biệt chữ hoa/chữ thường.
-- A.
select count(*) as number_of_country, round(sum(spc.gdp_per_capita),2) as totalGDP
from staging_per_capita as spc
join staging_countries as sc
	on spc.country_code=sc.country_code
where spc.year=2007 and (lower(sc.country_name) like '%an%' or lower(sc.country_name) like '%an');

-- B.
SELECT
    COUNT(*) AS country_count,
    SUM(spc.gdp_per_capita) AS total_gdp_per_capita
FROM staging_countries AS sct
JOIN staging_per_capita AS spc
    ON sct.country_code = spc.country_code
WHERE spc.year = 2007
  AND sct.country_name LIKE '%an%';


SELECT
    COUNT(*) FILTER (
        WHERE sct.country_name LIKE '%an%'
    ) AS count_an,

    SUM(spc.gdp_per_capita) FILTER (
        WHERE sct.country_name LIKE '%an%'
    ) AS total_gdp_an,

    COUNT(*) FILTER (
        WHERE sct.country_name LIKE '%An%'
    ) AS count_AN,

    SUM(spc.gdp_per_capita) FILTER (
        WHERE sct.country_name LIKE '%An%'
    ) AS total_gdp_AN

FROM staging_countries AS sct
JOIN staging_per_capita AS spc
    ON sct.country_code = spc.country_code
WHERE spc.year = 2007;



-- For each year before 2012, calculate the sum of GDP per capita 
-- and the number of countries for countries whose GDP per capita in 2012 is NULL,
-- while GDP per capita in that particular year is NOT NULL.
-- tim tong gdp va so luong quoc gia ma cac quoc gia co gdp la null trong nam 2012, sau do tinh 
-- gdp tro ve truoc co chua cac gdp la ko null
select year, sum(gdp_per_capita) as total_gdp_per_capita, count(*) as numberOfcountry
from staging_per_capita
where 
	year<2012 and 
	gdp_per_capita is not null 
	and country_code in(
						select country_code 
						from staging_per_capita
						where year = 2012 and gdp_per_capita is NULL
						)
group by year
order by year;



-- 6. Using a single query, return the first record for each continent
-- where the running total of GDP per capita for 2009 reaches or exceeds 70,000.
-- The records should be ordered by continent ascending, then by characters 2–4 of the country name descending.
with luykeGDP_2009 as(
select *, row_number() over(partition by continent_code order by SUBSTRING(country_name, 2, 3)desc) as rn
from (
select scm.continent_code, sc.country_name,
		spc.year,
		spc.gdp_per_capita,
		sum(spc.gdp_per_capita) over(PARTITION BY scm.continent_code order by 
		SUBSTRING(country_name, 2, 3)desc) as luy_keGDP
from staging_countries as sc
join staging_per_capita as spc
	on sc.country_code=spc.country_code
join staging_continent_map as scm
	on spc.country_code=scm.country_code
where spc.year=2009)
where luy_keGDP >= 70000)
select *
from luykeGDP_2009
where rn = 1;


-- 7. What continent has the highest average GDP per capita for all years? 
-- Compare your results with the supplied dataset and describe all mistakes you find.
-- Include the code you used to identfy the mistakes.

select sc.continent_code as continent_code, sc.continent_name as continent_name, avg(gdp_per_capita) as avg_gdp
from staging_per_capita as spc
join staging_continent_map as scm
	on spc.country_code=scm.country_code
JOIN staging_continents AS sc
    ON scm.continent_code = sc.continent_code
group by sc.continent_code,  sc.continent_name
order by avg_gdp desc
limit 1;

select * 
from staging_per_capita as spc
right join staging_continent_map as scm
	on spc.country_code=scm.country_code
where spc.country_code is null;


SELECT *
FROM staging_countries AS c
LEFT JOIN staging_continent_map AS cm
    ON c.country_code = cm.country_code
WHERE cm.country_code IS NULL;
