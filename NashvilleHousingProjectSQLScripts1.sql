/*

Cleaning Data in SQL Queries

Data is from the YouTube Channel : Alex The Analyst, I made some improvisations:)

Skills used: Data format standardization, data populating, Breaking out a column into Individual Columns, 
			 Data value standardization, Removal of duplicates, deletion of unused columns

SKG.
*/


--select * from NashvilleHousing

/*
Standardize Date Format
*/
--select convert(date, n.SaleDate) from NashvilleHousing n

update NashvilleHousing set SaleDate = convert(date, SaleDate) --did not work,so I ran the codes below.


	alter table NashvilleHousing add SaleDateConverted date
	update NashvilleHousing set SaleDateConverted = convert(date, SaleDate)
	alter table NashvilleHousing drop column SaleDate
	EXEC sys.sp_rename @objname = N'NashvilleHousing.SaleDateConverted', @newname = 'SaleDate', @objtype = 'COLUMN'




/*
Populate Property Address data
*/

select * from NashvilleHousing n where PropertyAddress is null --There are 29 rows without property address
select * from NashvilleHousing n where n.ParcelID = '025 07 0 031.00'

--Looking at the parcel ID, there are properties actually have address, but in another row of that parcel.
update n
set n.PropertyAddress = h.PropertyAddress
from NashvilleHousing n, NashvilleHousing h
where n.ParcelID = h.ParcelID
and n.PropertyAddress is null
and h.PropertyAddress is not null


/*
Break out Address into Individual Columns (Address, City, State)
*/
select n.PropertyAddress, 
PARSENAME(replace(n.PropertyAddress,',','.'),1) "city",
PARSENAME(replace(n.PropertyAddress,',','.'),2) "address"
from NashvilleHousing n

select n.OwnerAddress, 
PARSENAME(replace(n.OwnerAddress,',','.'),1) "state",
PARSENAME(replace(n.OwnerAddress,',','.'),2) "city",
PARSENAME(replace(n.OwnerAddress,',','.'),3) "address"
from NashvilleHousing n

alter table NashvilleHousing
add PropertySplitAddress NVarchar(255),
	PropertySplitCity NVarchar(255),
	OwnerSplitAddress NVarchar(255),
	OwnerSplitCity NVarchar(255),
	OwnerSplitState NVarchar(255)

update NashvilleHousing
set PropertySplitAddress = PARSENAME(replace(PropertyAddress,',','.'),2),
	PropertySplitCity = PARSENAME(replace(PropertyAddress,',','.'),1),
	OwnerSplitAddress = PARSENAME(replace(OwnerAddress,',','.'),3),
	OwnerSplitCity = PARSENAME(replace(OwnerAddress,',','.'),2),
	OwnerSplitState = PARSENAME(replace(OwnerAddress,',','.'),1)

/*
Change Y and N to Yes and No in "Sold as Vacant" field
*/
--select soldasvacant, count(*) from NashvilleHousing group by soldasvacant

update NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'N' then 'No' when SoldAsVacant = 'Y' then 'Yes' else SoldAsVacant end


/*
Remove Duplicates
*/
--If these columns are the same, there is duplicate. ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference

drop table if exists #duplicates 

create table #duplicates
(
uniqueId Numeric,
ParcelID Nvarchar(50),
PropertyAddress Nvarchar(50),
SalePrice Nvarchar(50),
SaleDate date,
LegalReference Nvarchar(50))

select * from #duplicates

insert into #duplicates
select a.uid, ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference from
(
select min(uniqueID) uid,count(*) countx, ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
from NashvilleHousing
group by ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference
) a
where a.countx>1

select * from #duplicates order by ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference

delete NashvilleHousing
from NashvilleHousing n inner join #duplicates d
on n.ParcelID = d.ParcelID
and n.PropertyAddress = d.PropertyAddress
and n.SalePrice = d.SalePrice
and n.SaleDate = d.SaleDate
and n.LegalReference = d.LegalReference
and n.UniqueID <> d.uniqueId

/*
Correct the content and convert the data type of SalePrice column
*/

select SalePrice, replace(replace(SalePrice,'$',''),'.','') 
from NashvilleHousing
--where SUBSTRING(salePrice,1,1) = '$' 
order by SalePrice


update NashvilleHousing
set SalePrice = convert(int, replace(replace(SalePrice,'$',''),'.',''))
where SUBSTRING(salePrice,1,1) = '$' 

alter table NashvilleHousing
add SalePriceX int

update NashvilleHousing
set SalePriceX = replace(SalePrice,'.','')

alter table NashvilleHousing
drop column SalePrice

EXEC sys.sp_rename @objname = N'NashvilleHousing.SalePriceX', @newname = 'SalePrice', @objtype = 'COLUMN'


/*
Delete Unused Columns
*/

alter table NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress



