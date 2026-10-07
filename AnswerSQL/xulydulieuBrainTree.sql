select * from staging_continent_map;
select * from staging_continents;
select * from staging_countries;
select * from staging_per_capita;

-- Xu ly du lieu null, duplicated va chuan hoa du lieu
-- Continent_map
select *
from staging_continent_map
where country_code is null;
-- Co 4 gia tri country code la gia tri null

-- Kiem tra gia tri trung lap
select *, count(*)
from staging_continent_map
group by country_code, continent_code
having count(*)>1;