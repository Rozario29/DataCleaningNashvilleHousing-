SELECT * 
FROM "Portfolio".public."NashvilleHousing"

--------------------------------------------------------------------
-- Standardize Date Format

SELECT "SaleDate"
FROM  "Portfolio".public."NashvilleHousing"

ALTER TABLE "Portfolio".public."NashvilleHousing"
ADD COLUMN "SaleDateEdited" DATE 

UPDATE "Portfolio".public."NashvilleHousing" SET "SaleDateEdited" = CAST( "SaleDate" AS DATE);


-------------------------------------------------------------------------------------

-- Populate Property Address data


SELECT *
FROM  "Portfolio".public."NashvilleHousing"
-- WHERE "PropertyAddress" IS NULL
ORDER BY "ParcelID"


-- Here when checking PropertyAddress with NULL values we realise that  ParcelID always has the same PropertyAddress so we can allocate null values with the same Property Address

-- Coalesce to basically pick the first non null item similar to ISNULL


SELECT a."ParcelID", a."PropertyAddress" , b."ParcelID" , b."PropertyAddress" , COALESCE(a."PropertyAddress",b."PropertyAddress")
FROM  "Portfolio".public."NashvilleHousing" a  
JOIN  "Portfolio".public."NashvilleHousing" b
    ON a."ParcelID" = b."ParcelID"
    AND a."UniqueID" <> b."UniqueID"
WHERE a."PropertyAddress" IS NULL 

-- Using postgres update join as syntax


UPDATE "Portfolio".public."NashvilleHousing" a  
SET "PropertyAddress" = COALESCE(a."PropertyAddress",b."PropertyAddress")
FROM  "Portfolio".public."NashvilleHousing" b  
    WHERE  a."ParcelID" = b."ParcelID"
    AND a."UniqueID" <> b."UniqueID"
    AND a."PropertyAddress" IS NULL 
    
-----------------------------------------------------------------------

-- BREAKING out Address into Individual Columns (Address, City, State)

SELECT "PropertyAddress"
FROM  "Portfolio".public."NashvilleHousing"

-- Using substring  and position functions to separate the string from main string and using position to find the comma delimitter 

SELECT
SUBSTRING("PropertyAddress",1,POSITION(','IN "PropertyAddress")-1) AS "Address",
SUBSTRING("PropertyAddress",POSITION(','IN "PropertyAddress")+1,LENGTH("PropertyAddress")) AS "Address"
FROM  "Portfolio".public."NashvilleHousing"


ALTER TABLE "Portfolio".public."NashvilleHousing"
ADD "PropertySplitAddress" VARCHAR(255);

UPDATE "Portfolio".public."NashvilleHousing"
SET "PropertySplitAddress" = SUBSTRING("PropertyAddress",1,POSITION(','IN "PropertyAddress")-1);

ALTER TABLE "Portfolio".public."NashvilleHousing"
ADD "PropertySplitCity" VARCHAR(255);


UPDATE "Portfolio".public."NashvilleHousing"
SET "PropertySplitCity" = SUBSTRING("PropertyAddress",POSITION(','IN "PropertyAddress")+1,LENGTH("PropertyAddress"));

-- Cleaning OwnerAddress using SPLIT_PART 

SELECT
split_part( "OwnerAddress",',', 1 ),
split_part( "OwnerAddress",',', 2 ),
split_part( "OwnerAddress",',', 3)
FROM "Portfolio".public."NashvilleHousing"

ALTER TABLE "Portfolio".public."NashvilleHousing"
ADD "OwnerSplitAddress" VARCHAR(255);

UPDATE "Portfolio".public."NashvilleHousing"
SET "OwnerSplitAddress" = split_part( "OwnerAddress",',', 1 );

ALTER TABLE "Portfolio".public."NashvilleHousing"
ADD "OwnerSplitCity" VARCHAR(255);

UPDATE "Portfolio".public."NashvilleHousing"
SET "OwnerSplitCity" = split_part( "OwnerAddress",',', 2 );

ALTER TABLE "Portfolio".public."NashvilleHousing"
ADD "OwnerSplitState" VARCHAR(255);

UPDATE "Portfolio".public."NashvilleHousing"
SET "OwnerSplitState" = split_part( "OwnerAddress",',', 3 );

SELECT * 
FROM "Portfolio".public."NashvilleHousing"

----------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field


SELECT DISTINCT("SoldAsVacant"), COUNT("SoldAsVacant" )
FROM "Portfolio".public."NashvilleHousing"
GROUP BY "SoldAsVacant"
ORDER BY 2

--using case statement


SELECT "SoldAsVacant",
CASE WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
    WHEN "SoldAsVacant" = 'N' THEN 'No'
    ELSE "SoldAsVacant"
    END
FROM "Portfolio".public."NashvilleHousing"
WHERE "SoldAsVacant" IN ('Y','N')

UPDATE "Portfolio".public."NashvilleHousing"
SET "SoldAsVacant" = CASE WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
    WHEN "SoldAsVacant" = 'N' THEN 'No'
    ELSE "SoldAsVacant"
    END
    
    
--------------------------------------------------------------

-- Remove Duplicates


-- CTE and windows functions

WITH row_num_cte AS(
SELECT * , ROW_NUMBER() OVER(PARTITION BY "ParcelID",
                 "PropertyAddress",
                 "SalePrice",
                 "SaleDate",
                 "LegalReference"
                ORDER BY  "UniqueID" ) AS row_num 
FROM "Portfolio".public."NashvilleHousing"
)
SELECT *
FROM row_num_cte
WHERE row_num>1
ORDER BY "ParcelID"

--in postgres you cannot delete column from cte  we use ctid

WITH row_num_cte AS(
SELECT ctid , ROW_NUMBER() OVER(PARTITION BY "ParcelID",
                 "PropertyAddress",
                 "SalePrice",
                 "SaleDate",
                 "LegalReference"
                ORDER BY  "UniqueID" ) AS row_num 
FROM "Portfolio".public."NashvilleHousing"
)
DELETE 
FROM "Portfolio".public."NashvilleHousing"
    USING row_num_cte

    WHERE row_num_cte.row_num >1
    AND row_num_cte.ctid = "Portfolio".public."NashvilleHousing".ctid

----------------------------------------------------------------
SELECT * 
FROM "Portfolio".public."NashvilleHousing"



-- Delete unused columns 

ALTER TABLE "Portfolio".public."NashvilleHousing"
DROP COLUMN "OwnerAddress" ,DROP COLUMN "TaxDistrict" ,DROP COLUMN "SaleDate" ,DROP COLUMN "PropertyAddress"