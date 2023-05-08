select * from projectportfolio..coviddeath
select * from Projectportfolio..covidvaccination

--select data to be used---

select location, date, total_cases, new_cases, total_deaths, population
from projectportfolio..coviddeath
order by 1,2

--total cases vs total death

select location, date, total_cases, total_deaths,
(CONVERT (float ,total_deaths))/total_cases*100 as Deathpercentage
from projectportfolio..coviddeath
order by 1,2

select location, date, total_cases, total_deaths,
(cast (total_deaths as float))/total_cases*100 as Deathpercentage
from projectportfolio..coviddeath
where location = 'Nigeria'
order by 1,2

---total cases vs population
---shows what percentage of the population got Covid

select location, date, population, total_cases, 
(CONVERT (float ,total_cases))/population*100 as Percentage_infected
from projectportfolio..coviddeath
order by 1,2

select location, date, population, total_cases, 
(CONVERT (float ,total_cases))/population*100 as Percentage_infected
from projectportfolio..coviddeath
where location='Germany'
order by 1,2

---Countries with highest infection rate by population

select location, population, max(cast (total_cases as float)) as Maxcount,
max(CONVERT (float ,total_cases))/population*100 as Percentage_infected
from projectportfolio..coviddeath
group by location, population
order by Percentage_infected desc

--countries with higest death rate

select location, population, max(cast (total_deaths as float)) as Deathcount
from projectportfolio..coviddeath
where continent is not null
group by location, population
order by Deathcount desc

---deathcount by continent.

select continent, max(cast (total_deaths as float)) as Deathcount
from projectportfolio..coviddeath
where continent is not null
group by continent
order by Deathcount desc

--Global Numbers  (isnull and nullif was used cos the denominator value contains zero)

select date, sum(new_cases)as Total_cases, sum(cast (new_deaths as int)) as total_deaths,
ISNULL(sum(cast(new_deaths as int))/NULLIF(sum(new_cases),0),0)*100 as Deathpercentage
from projectportfolio..coviddeath
where continent is not null
group by date 
order by 1,2

---this give the overall total cases, total death and percentage of death
select sum(new_cases)as Total_cases, sum(cast (new_deaths as int)) as total_deaths,
ISNULL(sum(cast(new_deaths as int))/NULLIF(sum(new_cases),0),0)*100 as Deathpercentage
from projectportfolio..coviddeath
where continent is not null 
order by 1,2

---joining covid death table and covid vaccination table together

select * from
projectportfolio..coviddeath dea
join projectportfolio..covidvaccination vac
on dea.location = vac.location
and dea.date = vac.date

--looking at the total population vs vaccinated.

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations from
projectportfolio..coviddeath dea
join projectportfolio..covidvaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2

--looking at the percentage of death if patient is diabetic

select dea.location, dea.date, dea.population, dea.total_deaths,vac.diabetes_prevalence, 
(vac.diabetes_prevalence/dea.total_deaths)*100 as Percentage_death_if_diabetic   from
projectportfolio..coviddeath dea
join projectportfolio..covidvaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by Percentage_death_if_diabetic desc


-----Rolling sum of people vacinated
--this shows the sum total of people vaccinated in each location----

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert (float,vac.new_vaccinations)) 
over (partition by dea.location order by dea.location, dea.date) as RollingpeopleVaccinated
from
projectportfolio..coviddeath dea
join projectportfolio..covidvaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2

---percentage of Rolling sum of people vacinated using CTE----

with popvsvac (continent, location, date, population, new_vaccinations, RollingpeopleVaccinated)
as
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert (float,vac.new_vaccinations)) 
over (partition by dea.location order by dea.location, dea.date) as RollingpeopleVaccinated
from
projectportfolio..coviddeath dea
join projectportfolio..covidvaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)

select *, (Rollingpeoplevaccinated/population)*100 as percentagevac
from popvsvac

---percentage of Rolling sum of people vacinated using temp table---

Drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(continent nvarchar(225)
, location nvarchar(225), 
 date datetime, 
 population numeric, 
 new_vaccinations numeric, 
 RollingpeopleVaccinated numeric)
 
 insert into #percentpopulationvaccinated
 select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert (float,vac.new_vaccinations)) 
over (partition by dea.location order by dea.location, dea.date) as RollingpeopleVaccinated
from
projectportfolio..coviddeath dea
join projectportfolio..covidvaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

select *, (RollingpeopleVaccinated/population)*100 
from  #percentpopulationvaccinated 

----creating views for later visualization---

create view percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert (float,vac.new_vaccinations)) 
over (partition by dea.location order by dea.location, dea.date) as RollingpeopleVaccinated
from
projectportfolio..coviddeath dea
join projectportfolio..covidvaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

SElect * from percentpopulationvaccinated