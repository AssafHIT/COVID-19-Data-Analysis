Select * From PortfolioProject..CovidDeaths
order by 3,4

-- Looking at total Covid19 cases
Select location, continent, date,new_cases, total_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- looking at total cases VS total deaths
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
where continent != ' '
ORDER BY 1,2;

-- Looking a percentage of the population got covid
SELECT 
    location, 
    date, 
    population, 
    total_cases, 
    ROUND((CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100, 6) AS PopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2;

-- Look at Countries with highest infection rate compared to population
SELECT location, population,MAX(total_cases) as MaximumTotalCase, 
    MAX(ROUND((CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100, 6)) AS PopulationPercentageInfected
FROM PortfolioProject..CovidDeaths
Group by Location, Population
order by PopulationPercentageInfected desc;

-- Countries with Highest death count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCases
FROM PortfolioProject..CovidDeaths
WHERE continent != ''
GROUP BY location
ORDER BY TotalDeathCases DESC;

-- Continents with Highest death count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCases
FROM PortfolioProject..CovidDeaths
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCases DESC;


-- GLOBAL NUMBERS
-- Aggregated data for each date
SELECT date, 
       SUM(CAST(new_cases AS INT)) AS TotalNewCases, 
	   SUM(TRY_CAST(new_deaths AS INT)) AS TotalNewDeaths,
       (SUM(TRY_CAST(new_deaths AS INT)) * 1.0) / NULLIF(SUM(CAST(new_cases AS INT)), 0) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent != ''
GROUP BY date
ORDER BY TotalNewCases asc;

-- Looking at total population VS vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM( CAST(vac.new_vaccinations AS INT)) OVER (Partition by dea.Location order by dea.location, dea.date) as vaccinations_sum
from PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVaccinations vac
		on dea.location = vac.location
		and
		dea.date = vac.date
		and vac.new_vaccinations != ' '
	where dea.continent != ' ' 
	ORDER BY 2,3;


-- Using CTE
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, vaccinations_sum) AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population,
           vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS BIGINT)) 
           OVER (PARTITION BY dea.Location ORDER BY dea.date) AS vaccinations_sum
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac 
        ON dea.location = vac.location
        AND dea.date = vac.date
		and new_vaccinations != ' '
    WHERE dea.continent != ' ' 
)
SELECT *, 
    ROUND((CAST(vaccinations_sum AS FLOAT) / NULLIF(CAST(Population AS FLOAT), 0)) * 100, 2) AS VaccinationPercentage
FROM PopvsVac
ORDER BY Location, Date;


-- Most vaccinanated populations -- (Over 100% includes boosters)
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, vaccinations_sum) AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population,
           vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS BIGINT)) 
           OVER (PARTITION BY dea.Location ORDER BY dea.date) AS vaccinations_sum
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac 
        ON dea.location = vac.location
        AND dea.date = vac.date
        AND vac.new_vaccinations != ' '
    WHERE dea.continent != ' ' 
)
SELECT p.Continent, p.Location, p.Date, p.Population, p.vaccinations_sum,
    ROUND((CAST(p.vaccinations_sum AS FLOAT) / NULLIF(CAST(p.Population AS FLOAT), 0)) * 100, 2) AS VaccinationPercentage
FROM PopvsVac p
WHERE p.Date = (SELECT MAX(Date) FROM PopvsVac WHERE Location = p.Location)
ORDER BY VaccinationPercentage DESC; 


-- Creating a View
Create View PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population,
           vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS BIGINT)) 
           OVER (PARTITION BY dea.Location ORDER BY dea.date) AS vaccinations_sum
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac 
        ON dea.location = vac.location
        AND dea.date = vac.date
		and new_vaccinations != ' '
    WHERE dea.continent != ' ' 

select * from PercentPopulationVaccinated



/*
Queries used for Tableau:
*/
-- 1.
SELECT 
    SUM(CAST(new_cases AS INT)) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    (SUM(CAST(new_deaths AS INT)) * 1.0) / NULLIF(SUM(CAST(new_cases AS INT)), 0) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- 2. 
Select location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent = ' ' and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

-- 3.
SELECT 
    Location, 
    Population, 
    MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,  
    MAX(CAST(total_cases AS BIGINT)) * 1.0 / NULLIF(CAST(Population AS BIGINT), 0) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
Where location not in ('International')
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- 4.
Select Location, Population,date, MAX(CAST(total_cases AS BIGINT)) * 1.0 / NULLIF(CAST(Population AS BIGINT), 0)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location not in ('International', 'Northern Cyprus')
Group by Location, Population, date
order by PercentPopulationInfected desc
