
create table continents(
	continent_code varchar(10) primary key,
	continent_name varchar(100)
);
create table countries(
	country_code varchar(10) primary key,
	country_name varchar(100)
);
create table continent_map(
	country_code varchar(10) primary key,
	continent_code varchar(10),
	foreign key(continent_code) references continents(continent_code),
	foreign key(country_code) references countries(country_code)
);
create table per_capita(
	country_code varchar(10),
	year int,
	gdp_per_capita float,
	PRIMARY KEY (country_code, year),
	foreign key(country_code) references countries(country_code)
);


-- Tao bang staging truoc de xu ly du lieu va sau do moi dua vao bang chinh 
CREATE TABLE staging_continents (
    continent_code VARCHAR(10),
    continent_name VARCHAR(100)
);

CREATE TABLE staging_countries (
    country_code VARCHAR(10),
    country_name VARCHAR(100)
);

CREATE TABLE staging_continent_map (
    country_code VARCHAR(10),
    continent_code VARCHAR(10)
);

CREATE TABLE staging_per_capita (
    country_code VARCHAR(10),
    year INT,
    gdp_per_capita NUMERIC
);