/**
Data is from the YouTube Channel : Alex The Analyst, I made some improvisations:)

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

SKG.
**/

--total cases vs. total deaths
select d.location,d.date,d.total_cases, isnull(d.total_deaths,0) total_deaths, (isnull(d.total_deaths,0)*100)/d.total_cases as "death ratio"
from CovidDeaths d
where lower(d.location) like '%turkey%'
order by d.location, d.date

--total cases versus population
select d.location,d.date,d.total_cases, format(d.population,'###,###,###') "population",(d.total_cases /d.population) * 100 as "covid ratio"
from CovidDeaths d
where lower(d.location) like '%turkey%'
order by d.location, d.date


--countries with the highest infection rate compared to the population 
select top 10 d.location,max(d.total_cases) as "total cases", max(d.population) as"population", (max(d.total_cases)/max(d.population)) * 100 as "average covid ratio"
from CovidDeaths d
where d.continent is not null
group by d.location
order by (max(d.total_cases)/max(d.population)) * 100 desc

--countries with the highest death rate compared to the cases 
select top 10 d.location,max(d.total_deaths) as "total deaths", max(d.total_cases) as "total cases", (max(d.total_deaths)/max(d.total_cases)) * 100 as "average death ratio"
from CovidDeaths d
where d.continent is not null
group by d.location
order by (max(d.total_deaths)/max(d.total_cases)) * 100 desc


--countries with the highest and lowest infection rate compared to the population 
select t.*,b.* from  
(select top 10 ROW_NUMBER() OVER(ORDER BY (max(d.total_cases)/max(d.population)) * 100 desc) AS Row#,d.location, max(d.total_cases) as "total cases",avg(d.population) as "population",(max(d.total_cases)/max(d.population)) * 100 as "average covid ratio"
from CovidDeaths d
where d.continent is not null
group by d.location
) t,
(
select top 10 ((select count(*)+1  from CovidDeaths d) - ROW_NUMBER() OVER(ORDER BY (max(d.total_cases)/max(d.population)) * 100 asc)) AS Row#,d.location, avg(d.total_cases) as "total cases",avg(d.population) as "population",(max(d.total_cases)/max(d.population)) * 100 as "average covid ratio"
from CovidDeaths d
where d.continent is not null
group by d.location
) b
where t.Row# = (select count(*)+1  from CovidDeaths d)- b.Row#


--countries with the highest and lowest death rate compared to the infection 
select t.*,b.* from  
(select top 10 ROW_NUMBER() OVER(ORDER BY ((max(d.total_deaths)/max(d.total_cases)) * 100) desc) AS Row#,d.location, max(d.total_deaths) as "deaths",max(d.total_cases) as "cases",(max(d.total_deaths)/max(d.total_cases) * 100) as "average death ratio"
from CovidDeaths d
where d.continent is not null
group by d.location
) t,
(
select top 10 ((select count(*)+1  from CovidDeaths d) - ROW_NUMBER() OVER(ORDER BY (max(d.total_deaths)/max(d.total_cases)) * 100 asc)) AS Row#,d.location, max(d.total_deaths) as "deaths", max(d.total_cases) as "cases",(max(d.total_deaths)/max(d.total_cases)) * 100 as "average death ratio"
from CovidDeaths d
where d.continent is not null
and d.total_deaths is not null
group by d.location
) b
where t.Row# = (select count(*)+1  from CovidDeaths d)- b.Row#

--contintents with the highest death count
select d.continent, max(cast(d.total_deaths as bigint)) as "max death"
from CovidDeaths d
where d.continent is not null
group by d.continent
order by max(d.total_deaths) desc

select d.location, max(cast(d.total_deaths as bigint)) as "max death"
from CovidDeaths d
where d.continent is null
group by d.location
order by max(d.total_deaths) desc



--contintents with the highest death count per population
select d.continent, (max(cast(d.total_deaths as bigint))/ avg(d.population))*100 as "max death ratio"
from CovidDeaths d
where d.continent is not null
group by d.continent
order by max(d.total_deaths) desc


select d.location, (max(cast(d.total_deaths as bigint))/ avg(d.population))*100 as "max death ratio"
from CovidDeaths d
where d.continent is null
group by d.location
order by max(d.total_deaths) desc

--The 10 most infected dates per country
select top 10 d.location,d.date,d.new_cases
from CovidDeaths d 
where d.new_cases =
(select max(x.new_cases) from CovidDeaths x where x.location = d.location and x.continent is not null) 
order by d.new_cases desc

--The 10 most death dates per country
select top 10 d.location,d.date,d.new_deaths
from CovidDeaths d 
where d.new_deaths =
(select max(x.new_deaths) from CovidDeaths x where x.location = d.location and x.continent is not null) 
order by d.new_deaths desc



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select d.location,max(d.population) "population" ,MAX(v.people_vaccinated) "vaccinations",(MAX(v.people_vaccinated) /max(d.population))*100 "percentage" 
from CovidDeaths d, CovidVaccinations v
where d.iso_code = v.iso_code
and d.date = v.date
and d.continent is not null
and isnull(v.people_vaccinated,0) > 0
group by d.location
order by (MAX(v.people_vaccinated) /max(d.population))*100 desc


select x.*, (x.RollingPeopleVaccinated/population)*100 as RPVPercentage
from
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From CovidDeaths d, CovidVaccinations v
where d.location = v.location
and d.date = v.date
and d.continent is not null 
) x
--where x.new_vaccinations is not null
--and x.RollingPeopleVaccinated is not null
order by x.location,x.date

--Using CTE
with VacvsPop (continent, location, date, population, new_vaccinations,RollingPeopleVaccinated)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From CovidDeaths d, CovidVaccinations v
where d.location = v.location
and d.date = v.date
and d.continent is not null 
)
select *, (RollingPeopleVaccinated/population)*100 as RPVPercentage
from VacvsPop

--using temp table
drop table if exists #VaccinationPercentage
create table #VaccinationPercentage
(
continent varchar(50),
location varchar(50),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric,
RPVPercentage float
)

insert into #VaccinationPercentage

select x.*, (x.RollingPeopleVaccinated/population)*100 as RPVPercentage
from
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From CovidDeaths d, CovidVaccinations v
where d.location = v.location
and d.date = v.date
and d.continent is not null 
) x
--where x.new_vaccinations is not null
--and x.RollingPeopleVaccinated is not null
--order by x.location,x.date


select * from #VaccinationPercentage order by location,date

--create view for later visualisations
create view vVaccinationPercentage
as 
select x.*, (x.RollingPeopleVaccinated/population)*100 as RPVPercentage
from
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From CovidDeaths d, CovidVaccinations v
where d.location = v.location
and d.date = v.date
and d.continent is not null 
) x


select * from vVaccinationPercentage













