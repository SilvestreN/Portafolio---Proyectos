/*       DATA CLEANING in Housing Sales by SQL       //       Limpieza de Datos de Ventas de Casa por SQL       //       Mar 2023       */

		--       Alejandro Silvestre NOVOA GASTALDI       //       Portafolio: https://novoa.com.mx/proyectos/       -- 


/*   SKILLS:  UPDATE, ALTER TABLE, ROW_NUMBER, ISNULL, CHARINDEX, SUBSTRING, PARSENAME, CONVERT, Columnas correlacionadas, etc  */
 
		/*   Fuente de Datos: https://ourworldindata.org/covid-deaths   */





-- Know the data:
SELECT *
FROM NashvilleHousing.dbo.NHousing





---- DATE Format  to  Remove hour

SELECT SaleDate, CONVERT(date, SaleDate)			-- // Se modifica el formato fecha-hora a solo fecha
FROM NashvilleHousing.dbo.NHousing

--UPDATE NashvilleHousing.dbo.NHousing
--SET SaleDate = CONVERT(date, SaleDate)            --  It could fail  //  Si falla, conviene crear una nueva columna


ALTER TABLE NashvilleHousing.dbo.NHousing
ADD SaleDateConverted date;

UPDATE NashvilleHousing.dbo.NHousing
SET SaleDateConverted = CONVERT(date, SaleDate)    --  New Column for the new Format


SELECT SaleDate, SaleDateConverted
FROM NashvilleHousing.dbo.NHousing

--ALTER TABLE NashvilleHousing.dbo.NHousing
--DROP COLUMN SaleDate                            --  To Remove Original Column   // Eliminar info repetida para ahorrar espacio







---- Null of PropertyAddress data
	--Los Nulls de PropertyAddress estan correlacionadas con ParcelID el numero de identificación del terreno, asumiendo que no cambian, 
		--se puede obtener el PropertyAddress de otras transacciones (UniqueID) asociadas al mismo ParcelID.

SELECT *
FROM NashvilleHousing.dbo.NHousing
WHERE PropertyAddress is Null			--  Recognize Nulls
ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)		-- a.PropertyAddress will be replaced by ISNULL
FROM NashvilleHousing.dbo.NHousing a
JOIN NashvilleHousing.dbo.NHousing b
	on a.ParcelID = b.ParcelID				 -- Identificacion de Terreno
	AND a.[UniqueID] <> b.[UniqueID]		 -- Different Sale		//		Transacciones diferentes
WHERE a.PropertyAddress is Null


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing.dbo.NHousing a
JOIN NashvilleHousing.dbo.NHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is Null


SELECT *
FROM NashvilleHousing.dbo.NHousing
WHERE PropertyAddress is Null         -- Dont have Nulls







---- Breaking out Address into Columns (Street, City, State)

--------- PropertyAddress
SELECT PropertyAddress, 
		CHARINDEX(',', PropertyAddress),					--  Recognize breaking index
		SUBSTRING(  PropertyAddress, 1,  CHARINDEX(',',PropertyAddress) -1  ),
		SUBSTRING(  PropertyAddress, CHARINDEX(',',PropertyAddress) +1,   LEN(PropertyAddress)  )
FROM NashvilleHousing.dbo.NHousing


ALTER TABLE NashvilleHousing.dbo.NHousing
ADD PropertyStreet nvarchar(255),
	PropertyCity nvarchar(255);

UPDATE NashvilleHousing.dbo.NHousing
SET PropertyStreet = SUBSTRING(  PropertyAddress, 1,  CHARINDEX(',',PropertyAddress) -1  ),
	PropertyCity = SUBSTRING(  PropertyAddress, CHARINDEX(',',PropertyAddress) +1,   LEN(PropertyAddress)  )                       


SELECT PropertyAddress, PropertyStreet, PropertyCity
FROM NashvilleHousing.dbo.NHousing

--ALTER TABLE NashvilleHousing.dbo.NHousing
--DROP COLUMN PropertyAddress  



--------- OwnerAddress
SELECT OwnerAddress, 
		REPLACE(OwnerAddress, ',', '.'),              -- Parsename split with '.'
		PARSENAME( REPLACE(OwnerAddress, ',', '.'), 3 )					-- 3 (street), 2 (city), 1 (state)
FROM NashvilleHousing.dbo.NHousing


ALTER TABLE NashvilleHousing.dbo.NHousing
ADD OwnerStreet nvarchar(255),
	OwnerCity nvarchar(255),
	OwnerState nvarchar(255);

UPDATE NashvilleHousing.dbo.NHousing
SET OwnerStreet = PARSENAME( REPLACE(OwnerAddress, ',', '.'),   3 ),
	OwnerCity = PARSENAME( REPLACE(OwnerAddress, ',', '.'),   2 ),
	OwnerState = PARSENAME( REPLACE(OwnerAddress, ',', '.'),   1 )                         


SELECT OwnerAddress, OwnerStreet, OwnerCity, OwnerState
FROM NashvilleHousing.dbo.NHousing

--ALTER TABLE NashvilleHousing.dbo.NHousing
--DROP COLUMN OwnerAddress  







---- Standardize SoldaAsVacant 

SELECT DISTINCT(SoldAsVacant) , COUNT(SoldAsVacant)         -- Different input for same Values  //  Entradas distintas para mismos valores
FROM NashvilleHousing.dbo.NHousing
GROUP BY SoldAsVacant


SELECT SoldAsVacant,
	CASE	WHEN SoldAsVacant = 'Y' THEN 'Yes'           -- Standardize
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
		END
FROM NashvilleHousing.dbo.NHousing

UPDATE NashvilleHousing.dbo.NHousing
SET SoldAsVacant = 	CASE	WHEN SoldAsVacant = 'Y' THEN 'Yes'
							WHEN SoldAsVacant = 'N' THEN 'No'
							ELSE SoldAsVacant
						END


SELECT DISTINCT(SoldAsVacant) , COUNT(SoldAsVacant)       
FROM NashvilleHousing.dbo.NHousing
GROUP BY SoldAsVacant







---- Remove Duplicate Data 

With DCountCTE AS (
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY ParcelID,						-- Column criteria for DuplicateCount  //  Columnas consideradas para valores duplicados  
						 PropertyAddress,
						 SalePrice,
						 SaleDate,
						 LegalReference
					ORDER BY
						UniqueID 
						)  AS DuplicateCount
	FROM NashvilleHousing.dbo.NHousing
				)

Select * 
From DCountCTE
Where DuplicateCount > 1			 -- Identify Duplicate Data
Order By ParcelID


   
With DCountCTE AS (
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY ParcelID,						
						 PropertyAddress,
						 SalePrice,
						 SaleDate,
						 LegalReference
					ORDER BY
						UniqueID 
						)  AS DuplicateCount
	FROM NashvilleHousing.dbo.NHousing
				)

DELETE 
FROM DCountCTE
WHERE DuplicateCount > 1				--  Remove







---- Delete Unused Columns  // Solo cuando se este completamente seguro

----ALTER TABLE NashvilleHousing.dbo.NHousing
----DROP COLUMN TaxDistrict  






		--       Portafolio: https://novoa.com.mx/proyectos/       -- 


/*   SKILLS:  UPDATE, ALTER TABLE, ROW_NUMBER, ISNULL, CHARINDEX, SUBSTRING, PARSENAME, CONVERT, Columnas correlacionadas, etc  */
