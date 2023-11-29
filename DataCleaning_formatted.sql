/*----------------------------------------------------------------------------------------------------------------------------------------------------------

										NASHVILLE HOUSING PROJECT - DATA CLEANING Cleaning Data in SQL Queries

Skills used: Joins, CTE, Temporary Tables, Subqueries, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, Stored Procedures.

-----------------------------------------------------------------------------------------------------------------------------------------------------------*/


-- Data overview.

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousingData

--------------------------------------------------- IMPROVING QUALITY OF DATA - COLUMN NAMES AND DATA TYPE --------------------------------------------------


-- Standardizing date format.

SELECT SaleDate, CONVERT(DATE,SaleDate) AS SaleDateConverted
FROM NashvilleHousing.dbo.NashvilleHousingData


-- Altering the data type of the column to have the dates stored in the desired format.

ALTER TABLE NashvilleHousingData
ALTER COLUMN SaleDate DATE


-- Renaming the 'UniqueID ' column to remove the blank space at the end.

 EXEC sp_rename 'NashvilleHousingData.UniqueID ', 'UniqueID', 'COLUMN'


 --------------------------------------------------------- IMPROVING QUALITY OF DATA - MISSING DATA --------------------------------------------------------


-- Extracting info on the properties address from other rows: records where ParcelID is the same, must have the same ProperyAddress.

SELECT a.UniqueID, a.ParcelID, a.PropertyAddress, b.UniqueID, b.ParcelID, b.PropertyAddress,
		ISNULL(a.PropertyAddress, b.PropertyAddress) PropertyAddress_filled
FROM NashvilleHousing.dbo.NashvilleHousingData a
JOIN NashvilleHousing.dbo.NashvilleHousingData b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE
	a.PropertyAddress IS NULL AND b.PropertyAddress IS NOT NULL 
ORDER BY a.ParcelID


-- Populating missing values in the PropertyAddress column.

UPDATE a
SET PropertyAddress = b.PropertyAddress
FROM NashvilleHousing.dbo.NashvilleHousingData a
JOIN NashvilleHousing.dbo.NashvilleHousingData b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL AND b.PropertyAddress IS NOT NULL


----------------------------------------------- IMPROVING QUALITY OF DATA - SPLITTING ONE COLUMN INTO THREE -----------------------------------------------


-- Breaking out the full address data into three separate pieces of information: address, city, state; each one will be stored in individual columns.
-- Having the information stored this way will make the data more useable and versatile.

ALTER TABLE NashvilleHousingData
ADD PropertyAddress_split NVARCHAR(255),
	PropertyCity_split NVARCHAR(255)

UPDATE NashvilleHousingData
SET PropertyAddress_split = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
	PropertyCity_split = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress))


ALTER TABLE NashvilleHousingData
ADD OwnerAddress_split NVARCHAR(255),
	OwnerCity_split NVARCHAR(255),
	OwnerState_split NVARCHAR(255);

UPDATE NashvilleHousingData
SET OwnerAddress_split = PARSENAME(REPLACE(OwnerAddress, ', ', '.') , 3),
	OwnerCity_split = PARSENAME(REPLACE(OwnerAddress, ', ', '.') , 2),
	OwnerState_split = PARSENAME(REPLACE(OwnerAddress, ', ', '.') , 1);


--------------------------------------------------------- IMPROVING QUALITY OF DATA - DATA FORMAT ---------------------------------------------------------


-- Counting all unique values in the 'SoldAsVacant' column

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) AS value_count
FROM NashvilleHousing.dbo.NashvilleHousingData
GROUP BY SoldAsVacant
ORDER BY 2 DESC


-- Changing 'Y' to 'Yes' and 'N' to 'No' in the "SoldAsVacant" column

UPDATE NashvilleHousingData
SET SoldAsVacant = CASE 
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
				   END

GO


----------------------------------------------------- IMPROVING QUALITY OF DATA - REMOVING DUPLICATES -----------------------------------------------------


-- After identifying the group of columns that make a row unique, I partition the NashvilleHousingData table by those columns.
-- Then I create a CTE with the same data from the NashvilleHousingData table plus one column containing the sequential number of rows within the partition. 
-- If multiple rows end up in the same partition it's because they have the same values in the group of columns that's supposed to be unique.
-- Such rows (which will have a sequential number greater than 1) will finally be deleted.

WITH CTE_Row# AS
(
--check the query works before putting it into a CTE
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID,
									PropertyAddress,
									SalePrice,
									SaleDate,
									LegalReference
					   ORDER BY UniqueID
					  ) AS Row#
FROM NashvilleHousing.dbo.NashvilleHousingData
)

DELETE FROM CTE_Row#
WHERE Row# > 1


------------------------------------------------------- IMPROVING QUALITY OF DATA - UNUSED COLUMNS -------------------------------------------------------


-- Deleting unused columns.

ALTER TABLE NashvilleHousing.dbo.NashvilleHousingData
DROP COLUMN OwnerAddress, PropertyAddress