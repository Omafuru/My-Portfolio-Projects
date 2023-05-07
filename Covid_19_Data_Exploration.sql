/*
Covid 19 Data Exploration uptil May 2021 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Exploring CovidDeaths.xlsx
SELECT *
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;
/* The "where Continent is not null query" is necessary because we have two columns: Continent and Location, whenever data under the Continent column is null it means the corresponding data in the Location column is a Continent or even the entire World and I dont want that */  

-- Exploring CovidVaccinations.xlsx
SELECT *
FROM PortfolioProject.CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4;


-- Heres the data I am  starting with

SELECT 
    Location, 
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- Total Cases vs Total Deaths
-- This shows the likelihood of dying if you contract covid

SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- This shows the percentage of the population that has gotten Covid

SELECT
    Location,
    Population,
    MAX(total_cases) as HighestInfectionCount,  
    Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject.CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc;


-- This shows the Countries with Highest Death Count per Population

SELECT
    Location,
    MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.CovidDeaths
WHERE continent is not null 
GROUP BY Location
ORDER BY TotalDeathCount desc;


-- CATEGORIZING BY CONTINENT

-- This show Contintents with the highest death count per population

SELECT
    continent,
    MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.CovidDeaths
--WHERE location = 'Africa'
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount desc;

-- GLOBAL NUMBERS

SELECT
    SUM(new_cases) as total_cases,
    SUM(cast(new_deaths as int)) as total_deaths,
    SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject.CovidDeaths
--WHERE location = 'Africa'
WHERE continent is not null 
--GROUP BY date
ORDER BY 1,2;


-- Total Population vs Vaccinations
-- This shows the percentage of the population that has recieved at least one Covid Vaccine

SELECT 
    dth.continent, 
    dth.location, 
    dth.date, 
    dth.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dth.Location ORDER BY dth.location, dth.Date) AS RollingPeopleVaccinated
    --, (RollingPeopleVaccinated/population)*100
FROM 
    PortfolioProject.CovidDeaths dth
JOIN 
    PortfolioProject.CovidVaccinations vac ON dth.location = vac.location AND dth.date = vac.date
WHERE 
    dth.continent IS NOT NULL 
ORDER BY 
    2, 3;

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac AS (
    SELECT dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dth.Location ORDER BY dth.location, dth.Date) AS RollingPeopleVaccinated
    FROM PortfolioProject.CovidDeaths dth
    JOIN PortfolioProject.CovidVaccinations vac
    ON dth.location = vac.location
    AND dth.date = vac.date
    WHERE dth.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS ##PercentPopulationVaccinated;
CREATE TEMPORARY TABLE ##PercentPopulationVaccinated (
  Continent VARCHAR(255),
  Location VARCHAR(255),
  Date DATETIME,
  Population NUMERIC(18,2),
  New_vaccinations NUMERIC(18,2),
  RollingPeopleVaccinated NUMERIC(18,2)
) GLOBAL;

INSERT INTO ##PercentPopulationVaccinated
SELECT dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dth.Location ORDER BY dth.location, dth.Date) AS RollingPeopleVaccinated
--     (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.CovidDeaths dth
JOIN PortfolioProject.CovidVaccinations vac
	ON dth.location = vac.location
	AND dth.date = vac.date;
--WHERE dth.continent IS NOT NULL 
--ORDER BY 2,3;

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM ##PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dth.continent,
    dth.location,
    dth.date,
    dth.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (Partition by dth.Location Order by dth.location, dth.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.CovidDeaths dth
JOIN PortfolioProject.CovidVaccinations vac
	ON dth.location = vac.location
	AND dth.date = vac.date
WHERE dth.continent is not null;

