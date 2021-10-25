-- Looking at the timeline of Covid spreading for each country ordered alphabetically. 
SELECT	location, date, total_cases, new_cases, total_deaths, population
FROM	PortfolioProject..CovidDeaths
ORDER	BY 1,2

-- This query shows the timeline of total cases, deaths, and the death percentage from Covid.
-- This query is for the US only and is orderd by date.
-- The results shows a growth in death percentage but later on stabilizes around 1.7%
SELECT   location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM	 PortfolioProject..CovidDeaths
WHERE	 location LIKE '%state%'
ORDER BY date ASC

-- Drill down view of the continent to the specific country to showcase the total cases, deaths, and Covid death rates.
-- From the broad view of the continent to the country this query shows the total Covid cases, deaths, and Covid death rates for each country. 
SELECT   continent, location, MAX(total_cases) AS Total_Cases, MAX(total_deaths) AS total_deaths, (MAX(total_deaths)/MAX(total_cases)) * 100 AS "Covid Death Rate"
FROM	 PortfolioProject..CovidDeaths
WHERE	 continent IS NOT NULL
GROUP BY continent, location
ORDER BY Total_Cases DESC

-- Looking at Countries with Highest Infection Rates compared to population
-- This query looks at what the infection rate is compared to the population of each country.
SELECT	 location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population)*100 AS "Percent Population Infected"
FROM	 PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC

-- Showing Countries with the highest Covid Deaths
-- This is a simple query that shows the total Covid deaths for each country.
SELECT	 location, MAX(CAST(total_deaths as int)) AS "Total Deaths from Covid"
FROM	 PortfolioProject..CovidDeaths
WHERE	 continent IS NOT NULL
GROUP BY location, population
ORDER BY 2 DESC

-- Now lets look at Covid deaths by continent
-- Europe has the most Covid deaths followed by South America, Asia, North America, Africa, and then Australia.
SELECT	 location, MAX(CAST(total_deaths as int)) AS "Total Deaths from Covid"
FROM	 PortfolioProject..CovidDeaths
WHERE	 continent IS NULL AND location != 'World'
GROUP BY location
ORDER BY 2 DESC

-- Timeline of new covid cases, deaths, and death percentage worldwide ordered by date.
SELECT	 date, SUM(new_cases) AS "Total Worldwide New Cases", SUM(CAST(new_deaths as int)) AS "Total Worldwide Covid Deaths",
		 (SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS "Total Worldwide Covid Death Percentage"
FROM	 PortfolioProject..CovidDeaths
WHERE	 continent IS NOT NULL
GROUP BY date 
ORDER BY 1 ASC

-- Global statistics of covid cases, deaths, and death rate. 
-- About 240 Million worldwide cases, 4.9 Million Covid Deaths, and about 2% of world's population deaths related to Covid
SELECT	 SUM(new_cases) as "Total Worldwide Covid Cases", SUM(cast(new_deaths as int)) AS "Total Worldwide Covid Deaths",
		 (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as "Total Worldwide Covid Death Percentage"
FROM	 PortfolioProject..CovidDeaths
WHERE	 continent IS NOT NULL
ORDER BY 1 ASC

-- Looking at Total Population vs Vaccination
-- Use Partition By to add up the new vaccinations per day per location to create a new column that represents the total number
-- of people vaccinated per location per day.
SELECT	 dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		 SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM	 PortfolioProject..CovidDeaths AS dea
JOIN	 PortfolioProject..CovidVaccinations AS vac
ON		 dea.location=vac.location AND dea.date=vac.date
WHERE	 dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
AS
(
SELECT	 dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		 ,SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location,
		 dea.Date) as RollingPeopleVaccinated
FROM	 PortfolioProject..CovidDeaths dea
JOIN	 PortfolioProject..CovidVaccinations vac
ON		 dea.location = vac.location
AND		 dea.date = vac.date
WHERE	 dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM PopvsVac
ORDER BY 2

-- Creating TEMP TABLE 
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location,
		dea.Date) as RollingPeopleVaccinated
FROM	PortfolioProject..CovidDeaths dea
JOIN	PortfolioProject..CovidVaccinations vac
ON		dea.location = vac.location
AND		dea.date = vac.date
WHERE	dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM #PercentPopulationVaccinated


-- Creating View to store data for Data Visualizations in Tableau
-- Table for the number of people vaccinated 
DROP VIEW IF EXISTS PercentPopulationVaccinated;
Create View PercentPopulationVaccinated AS 
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	    ,SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location,
		dea.Date) as RollingPeopleVaccinated
FROM	PortfolioProject..CovidDeaths dea
JOIN	PortfolioProject..CovidVaccinations vac
ON		dea.location = vac.location
AND		dea.date = vac.date
WHERE	dea.continent IS NOT NULL

-- Table to show the topdown statistical report of Covid.
Create view GlobalCovidReport AS
SELECT	 continent, location, MAX(total_cases) AS Total_Cases, MAX(total_deaths) AS total_deaths, (MAX(total_deaths)/MAX(total_cases)) * 100 AS "Covid Death Rate"
FROM	 PortfolioProject..CovidDeaths
WHERE	 continent IS NOT NULL
GROUP BY continent, location
--ORDER BY Total_Cases DESC

-- Table to show the effects of Covid by continent.
CREATE VIEW CovidDeathsbyContinent AS
SELECT	 location, MAX(CAST(total_deaths as int)) AS "Total Deaths from Covid"
FROM	 PortfolioProject..CovidDeaths
WHERE	 continent IS NULL AND location != 'World'
GROUP BY location
--ORDER BY 2 DESC

-- Talbe to show the overview of Covid by Country
CREATE VIEW CovidDeathsbyCountry AS 
SELECT	 location, MAX(CAST(total_deaths as int)) AS "Total Deaths from Covid"
FROM	 PortfolioProject..CovidDeaths
WHERE	 continent IS NULL AND location != 'World'
GROUP BY location
--ORDER BY 2 DESC

