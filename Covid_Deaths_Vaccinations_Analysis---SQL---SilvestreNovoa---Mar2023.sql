/*       COVID 19 DATA EXPLORATION       //       EXPLORACION de DATOS de COVID 19       //       Mar 2023       */

		--       Alejandro Silvestre NOVOA GASTALDI       //       Portafolio: https://novoa.com.mx/proyectos/       -- 


/*   SKILLS:  Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types  */
 
		/*   Fuente de Datos: https://ourworldindata.org/covid-deaths   */




-- Know the data:
SELECT *
FROM SQLDataExploration.dbo.CovidDeaths
ORDER BY 3,4

SELECT *
FROM SQLDataExploration.dbo.CovidVaccinations
ORDER BY 3,4


-- Date Range of the data  //  Rango de Tiempo
SELECT CONVERT( date, MIN(date) ) AS FirstDate, CONVERT( date, MAX(date) ) AS LastDate     -- remove hour: datetime -> date
FROM SQLDataExploration.dbo.CovidDeaths


-- Key columns 
SELECT location, CONVERT(date, date) AS date , total_cases, new_cases, total_deaths, population
FROM SQLDataExploration.dbo.CovidDeaths
WHERE total_deaths is not Null
ORDER BY 1,2



---- MEXICO

-- Total Cases vs Total Deaths   //   Probabilidad de muerte al contraer la enfermedad en Mexico
SELECT location, CONVERT(date, date) AS date, total_cases, total_deaths, ROUND(  100*(total_deaths/total_cases)  ,2)  AS DeathPercentage
FROM SQLDataExploration.dbo.CovidDeaths
WHERE location LIKE '%xico'  AND total_deaths is not Null
ORDER BY 1,2

-- Total Cases vs Population
SELECT location, CONVERT(date, date) AS date, population, total_cases,  
	ROUND(  100*(total_cases/population)  ,2)  AS PercentPopulationInfected   -- Percentage of population infected by Covid
FROM SQLDataExploration.dbo.CovidDeaths
WHERE location LIKE '%xico'  AND total_cases is not Null
ORDER BY 1,2



---- COUNTRIES

-- Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, ROUND( 100*MAX(total_cases/population) ,2) AS PercentPopulationInfected
FROM SQLDataExploration.dbo.CovidDeaths
GROUP BY location, population     -- date aggregate
ORDER BY 4 DESC

-- Highest Death Count per Population
SELECT location, population, MAX(cast(total_deaths as int)) AS HighestDeathsCount, ROUND( 100*MAX(cast(total_deaths as int))/population ,2)  AS PercentPopulationDeadByCovid
FROM SQLDataExploration.dbo.CovidDeaths
WHERE continent is not Null    
GROUP BY location, population    -- date aggregate
ORDER BY 3 DESC



---- CONTINENTS

-- Highest death count per population
SELECT location,  MAX(cast(total_cases as int)) AS HighestCasesCount,  MAX(cast(total_deaths as int)) AS HighestDeathsCount
FROM SQLDataExploration.dbo.CovidDeaths
WHERE continent is Null
GROUP BY location
ORDER BY 2 DESC

-- Vaccination count
SELECT location,  MAX(cast(total_vaccinations as int)) AS HighestVaccinationsCount
FROM SQLDataExploration.dbo.CovidVaccinations
WHERE continent is Null   and total_vaccinations is not Null
GROUP BY location
ORDER BY 2 DESC



---- WORLD        

--  Covid propagation
SELECT CONVERT(date,date) AS date, MAX(new_cases) AS total_cases, MAX(cast(new_deaths as int)) AS total_deaths, ROUND( 100*MAX(cast(new_deaths as int))/MAX(new_cases) ,2)  AS PercentPopulationDeathByCovid
FROM SQLDataExploration.dbo.CovidDeaths
WHERE continent is not Null  AND new_cases is not Null
GROUP BY date
ORDER BY 1



---- VACCINATIONS

--- JOIN

-- Cumulative vaccines by date     //     Vacunas realizadas por día y su acumulacion
SELECT Dea.location, CONVERT(date, Dea.date) AS date, Dea.population, Vac.new_vaccinations as VaccinationsPerDay, 
	SUM(CONVERT(int,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date) AS RollingVaccinations, 
	ROUND(   100*( (SUM(CONVERT(int,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date)) / Dea.population )   ,2)  AS PercentageVaccinationsPerPopulation
																	-- partition to accumulate data day per day
FROM SQLDataExploration.dbo.CovidDeaths Dea
JOIN SQLDataExploration.dbo.CovidVaccinations Vac
	On Dea.location = Vac.location
	and Dea.date = Vac.date
WHERE Dea.continent is not Null  AND Vac.new_vaccinations is not NULL
ORDER BY 1,2 



--- CTE  and  PARTITION

-- efficiency?  CTE vs. duplicate calculations       //    cuanto cuesta CTE computacionalmente? 
With cteDeaVac (location, date, population, VaccinationsPerDay, RollingVaccinations)
as
(
SELECT Dea.location, CONVERT(date, Dea.date) AS date, Dea.population, Vac.new_vaccinations as VaccinationsPerDay, 
	SUM(CONVERT(int,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date) AS RollingVaccinations
FROM SQLDataExploration.dbo.CovidDeaths Dea
JOIN SQLDataExploration.dbo.CovidVaccinations Vac
	On Dea.location = Vac.location
	and Dea.date = Vac.date
WHERE Dea.continent is not Null
)

Select *, ROUND(   100*( RollingVaccinations / population )   ,2)   AS PercentageVaccinationsPerPopulation --no duplicate calculation of RollingVaccinations
From cteDeaVac
WHERE RollingVaccinations is not Null   --in CTE is easy to remove the null values from the calculations
ORDER BY 1,2 



--- Temp Table  and  PARTITION

DROP TABLE if exists #PercentageVaccinationsPerPopulation  -- clean first
CREATE TABLE #PercentageVaccinationsPerPopulation
(
Location nvarchar(255),
Date date,
Population int,
VaccinationsPerDay int,
RollingVaccinations float     -- to round and  //  dividir
)

INSERT INTO #PercentageVaccinationsPerPopulation
SELECT Dea.location, CONVERT(date, Dea.date) AS date, Dea.population, Vac.new_vaccinations as VaccinationsPerDay, 
	SUM(CONVERT(int,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date) AS RollingVaccinations
FROM SQLDataExploration.dbo.CovidDeaths Dea
JOIN SQLDataExploration.dbo.CovidVaccinations Vac
	On Dea.location = Vac.location
	and Dea.date = Vac.date
WHERE Dea.continent is not Null

Select *, ROUND(   100*( RollingVaccinations / Population )   ,2)   AS PercentageVaccinationsPerPopulation --no duplicate calculation of RollingVaccinations
From #PercentageVaccinationsPerPopulation
WHERE RollingVaccinations is not Null  --in Temp Table is easy to remove the null values from the calculations
ORDER BY 1,2 



--- DATE AGGREGATE

-- Percentage of Population that has recieved at least one Covid Vaccine   //   hasta la fecha disponible
SELECT Dea.location, Dea.population, SUM(CONVERT(int,Vac.new_vaccinations)) AS TotalVaccinations,
	ROUND(  100*( SUM(CONVERT(int,Vac.new_vaccinations)) / Dea.population )  ,2)  AS PercentageVaccinationsPerPopulation,
	ROUND(  100*( MAX(CONVERT(int,Vac.people_vaccinated)) / Dea.population )  ,2)  AS PercentagePeopleWithOneVaccine
FROM SQLDataExploration.dbo.CovidDeaths Dea
JOIN SQLDataExploration.dbo.CovidVaccinations Vac
	On Dea.location = Vac.location
	and Dea.date = Vac.date
WHERE Dea.continent is not Null
GROUP BY Dea.location, Dea.population
ORDER BY 1




--- CREATING VIEW

DROP VIEW if exists PercentageVaccinationsPerPopulation  -- clean first

-- Store data for later visualizations
CREATE VIEW PercentageVaccinationsPerPopulation AS
SELECT Dea.location, CONVERT(date, Dea.date) AS date, Dea.population, Vac.new_vaccinations as VaccinationsPerDay, 
	SUM(CONVERT(int,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date) AS RollingVaccinations, 
	ROUND(   100*( (SUM(CONVERT(int,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date)) / Dea.population )   ,2)  AS PercentageVaccinationsPerPopulation
	-- partition to acumulate data day per day
FROM SQLDataExploration.dbo.CovidDeaths Dea
JOIN SQLDataExploration.dbo.CovidVaccinations Vac
	On Dea.location = Vac.location
	and Dea.date = Vac.date
WHERE Dea.continent is not Null

SELECT *
FROM PercentageVaccinationsPerPopulation
WHERE VaccinationsPerDay is not Null






		--       Portafolio: https://novoa.com.mx/proyectos/       -- 


/*   SKILLS:  Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types  */