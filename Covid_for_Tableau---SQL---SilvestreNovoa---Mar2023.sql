/*       Queris used for TABLEAU COVID PROJECT      //       Queris para PROYECTO de COVID en TABLEAU       //       Mar 2023       */

		--       Alejandro Silvestre NOVOA GASTALDI       //       Portafolio: https://novoa.com.mx/proyectos/       --       


--       Dashboard: https://public.tableau.com/app/profile/silvestre.novoa/viz/TableauCovidProject---SilvestreNovoa---Feb2023/Dashboard1   

/*   SKILLS:  Tableu (Maps, Bubble charts, Threemaps, Bar graphs, Line graphs)  -  SQL (Joins, CTE's, Windows Functions, Aggregate Functions, Converting Data Types)  */

		/*   Fuente de Datos: https://ourworldindata.org/covid-deaths   */




-- Know the data:
SELECT *
FROM SQLDataExploration.dbo.CovidDeaths
ORDER BY 3,4

SELECT *
FROM SQLDataExploration.dbo.CovidVaccinations
ORDER BY 3,4





---- Table 1. 

-- covid WORLD Numbers

SELECT SUM(CONVERT(int,Vac.new_vaccinations)) AS Vacunas_Aplicadas,
		SUM(Dea.new_cases)   AS Casos_Totales,
		SUM(cast(Dea.new_deaths as int))   AS Muertes_en_el_Mundo, 
		100*SUM( cast(Dea.new_deaths as int) ) / SUM(Dea.new_Cases)   AS Porcentaje_de_Fallecimiento
FROM SQLDataExploration.dbo.CovidDeaths Dea
JOIN SQLDataExploration.dbo.CovidVaccinations Vac
	On Dea.location = Vac.location
	and Dea.date = Vac.date
WHERE Dea.continent is not Null



---- Table 2. 

-- Death by CONTINENT

SELECT  location, SUM(cast(new_deaths as int)) AS TotalDeathCount
FROM SQLDataExploration.dbo.CovidDeaths
WHERE continent is null 
		and location not in ('World', 'European Union', 'International')      -- European Union is part of Europe   (dont duplicate data)
GROUP BY location
ORDER BY TotalDeathCount desc



---- Table 3. 

-- Infection Count by COUNTRY

SELECT  location, 
		population, 
		MAX(total_cases) as HighestInfectionCount,  
		100*MAX((total_cases/population)) as PercentPopulationInfected
FROM SQLDataExploration.dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc



---- Table 4. 

-- Cumulative Counts (Vaccine, Infection, Deaths)    per Date   for each COUNTRY

With cteDeaVac (location, population, date,  RollingVaccinations,  RollingCases,  RollingDeaths)
as
(
SELECT Dea.location,
		Dea.population,
		CONVERT(date, Dea.date) AS date,  
		SUM(CONVERT(int,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date) AS RollingVaccinations,
		SUM(CONVERT(int,Dea.new_cases)) OVER (Partition by Dea.location Order by Dea.location, Dea.date) AS RollingCases,
		SUM(CONVERT(int,Dea.new_deaths)) OVER (Partition by Dea.location Order by Dea.location, Dea.date) AS RollingDeaths
FROM SQLDataExploration.dbo.CovidDeaths Dea
JOIN SQLDataExploration.dbo.CovidVaccinations Vac
	On Dea.location = Vac.location
	and Dea.date = Vac.date
WHERE Dea.continent is not Null
)

Select *, 
		--no duplicate calculation
		ROUND(   100*( RollingVaccinations / population )   ,4)   AS PercentageVaccinationsPerPopulation, 
		ROUND(   100*( RollingCases / population )   ,4)   AS PercentageCasesPerPopulation, 
		ROUND(   100*( RollingDeaths / population )   ,4)   AS PercentageDeathsPerPopulation 
From cteDeaVac
Order by 1,3 desc








---- Table 5. 

-- Counts per Day (Vaccine, Infection, Deaths)       for each COUNTRY

With cteDeaVac (location, population, date,  VaccinationsPerDay,  CasesPerDay,  DeathsPerDay)
as
(
SELECT Dea.location,
		Dea.population,
		CONVERT(date, Dea.date) AS date,  
		CONVERT(int,Vac.new_vaccinations)  AS VaccinationsPerDay,
		CONVERT(int,Dea.new_cases)  AS CasesPerDay,
		CONVERT(int,Dea.new_deaths)  AS DeathsPerDay
FROM SQLDataExploration.dbo.CovidDeaths Dea
JOIN SQLDataExploration.dbo.CovidVaccinations Vac
	On Dea.location = Vac.location
	and Dea.date = Vac.date
WHERE Dea.continent is not Null
)

Select *
From cteDeaVac
Order by 1,3 desc







		--       Portafolio: https://novoa.com.mx/proyectos/       --       


--       Dashboard: https://public.tableau.com/app/profile/silvestre.novoa/viz/TableauCovidProject---SilvestreNovoa---Feb2023/Dashboard1   

/*   SKILLS:  Tableu (Maps, Bubble charts, Threemaps, Bar graphs, Line graphs)  -  SQL (Joins, CTE's, Windows Functions, Aggregate Functions, Converting Data Types)  */