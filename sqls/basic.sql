------------------------
--CHAPTER-1 LISTING STAGE
-------------------------


create database TIPSDB;
use database TIPSDB;
create schema CH09 comment = 'This is schema for chapter 9'; show schemas;
use schema CH09;



-- How to list user data
-- ---------------------

	list @~ ;

-- 1. Created for all users automatically and no storage limit
-- 2. Nobody else can access this stage locaion
-- 3. Even accountadmin or security admin can not access user stage
-- 4. All your worksheets are stored there including your worksheet metadata.
-- 5. This stage can not be associated with any file format like csv or parquet.
-- 6. As administrator, you can see the stage size but you can not see this location (biggest drawback)
-- 7. Even with snowflake account tables like STAGES, STAGE_STORAGE_USAGE_HISTORY, STORAGE USAGE do not give any hint.
-- 8. You don't need any special permission as this stage is created for individual user.
-- 9. You can load data from SnowSQL cli to this location using put command and with @~ sign.
--10. Under the hood, snowflake uses cloud object storage to store all data and files.
--11. Most of the developer expect a stage to be made available and they don't use this location for storage.


--How to list table stage
--------------------------

	list @%customer_csv; show lists;

--1. Created for all table automatically & no storage limit
--2. Only the owner of the table can access this stage
--3. If you have crated a table, you can load any amount of data to this table stage.
--4. This stage can not be associated with any file format like csv or parquet.
--5. To execute query on this stage, you can associate format with table (we will see it)
--6. As administrator, you can see the stage size but you can not see this table stage (biggest drawback)
--7. Even with snowflake account tables like STAGES, STAGE_STORAGE_USAGE_HISTORY, STORAGE_USAGE do not give any hint.
--8. You can load data from SnowSQL cli to this location using put command and with @%table_name.
--9. Under the hood, snowflake uses cloud object storage to store all data.
--10. Most of the developer expect a stage to be made available and they don't use this table stage for storage.

--How to list named stage
--------------------------

-- you can create named stages and then list them using list command
	show stages;
	list @STG01;

-- very simple contruct for internal stage
	CREATE STAGE "TIPSDB"."CH09".stg03 COMMENT = 'This is my demo internal stage';

-- if you have lot of stages, then you can use like
	show stages like '%03%';

	show stages like '%s3%';
	-- if it has credential. it will show




﻿-------------------------
--CHAPTER-2 PUT COMMAND
-------------------------



use database TIPSDB;
use schema CH09;




-- How to place files to user stages
------------------------------------

-- we can use put command

-- before that lets check if we have any data there
	list @~;

-- lets run a remove command to clean it up
	remove @~/ch09;
	list @~/ch09;

-- lets put a file to user stage
-- put file:///tmp/ch09-data/data.csv @~/ch09/;      put file://C:\Users\ravinderK\Desktop\ch07.csv  @~/ch09/;
-- put file:///tmp/ch09-data/data.html @~/ch09/html auto_compress=false;   put file://C:\Users\ravinderK\Desktop\1.png @~/ch09/png auto_compress=false;

	list @~;

-- in place of like statement, you have to use pattern if you have to search
-- something within the folder or subfolder.
	list @~ pattern='.*ch07.*';
	list @~ pattern='.*.gz';
	list @~ pattern='.*.png';



-- How to place files to table stages
-- -----------------------------------

--lets put a file to table stage
--put file:///tmp/ch09-data/test.csv @%customer/ch09/;            put file://C:\Users\ravinderK\Desktop\ch07.csv  @%customer/ch09/;

	list @%customer/;
	list @%customer/ch09/;
	list @%customer/ pattern='.*.gz';



-- How to place files to named stages
-- -----------------------------------
    create stage stg01;
--lets put a file to table stage
--put file:///tmp/ch09-data/test.csv @stg01/ch09/;	    put file://C:\Users\ravinderK\Desktop\data.csv  @stg01/ch09/;
	list @stg01/ch09/;


-- How to remove the stages or files from stages
-- ----------------------------------------------
-- since stages are temp storages, it must be removed
-- after the files are moved to permanent location

	remove @~/ch09/;
	remove @%customer/ch09/;

-- following command will remove all the data inside the customer table storages
	remove @%customer;

-- remove is not equivalent to drop
	drop stage @%customer;

-- however following will work
	drop stage stg01;

-- if you have to see the stage and stage history cost,
-- 1. you can use usage table
-- 2. account usage schema and stage views.

	use role accountadmin;

-- you can not load data to external named stage

	show stages like 'TIPS_S3_EXTERNAL_STAGE';
	list @TIPS_S3_EXTERNAL_STAGE;
	put file:///tmp/ch09-data/test.csv @TIPS_S3_EXTERNAL_STAGE;




﻿--------------------------
--CHAPTER-3 LOAD TO TABLE
--------------------------


use database TIPSDB;
use schema CH09;




-- How to load and query data from table stage
-- --------------------------------------------

-- table stages are un-nammed stages
-- it can not be modified, so it is hard to associate a file format with it
-- easy to work with csv but hard for semi-structured data dumps.

-- create a customer table and add a file format
		create or replace table customer_parquet_ff(
			my_data variant
		)
		STAGE_FILE_FORMAT = (TYPE = PARQUET);

-- load parquet data
-- put file:///tmp/customer.parquet/customer.snappy.parquet @%customer_parquet_ff/;

	list @%customer_parquet_ff/;

-- now lets query the data using $ notation
	select
		metadata$filename,
		metadata$file_row_number,
		$1:CUSTOMER_KEY::varchar,
		$1:NAME::varchar,
		$1:ADDRESS::varchar,
		$1:COUNTRY_KEY::varchar,
		$1:PHONE::varchar,
		$1:ACCT_BAL::decimal(10,2),
		$1:MKT SEGMENT::varchar,
		$1:COMMENT::varchar
	from @%customer_parquet_ff;

-- Parquest file format has only one column called $1
-- If you have loaded multiple files, the metadata$filename and row_number will give you additional information
-- if you remove the stage from table definition, the above query will not work
-- even if you give a file format properties to a table, it will still not work

-- Now you can run copy command to load the data
		copy into customer_parquet_ff from @%customer_parquet_ff/customer.snappy.parquet;

		select from customer_parquet_ff;

-- Once data is loaded, you can see the load_history table to see the history

-- if you try to load the same file again and again, it will not load the data
-- copy + tables have metdata which remembers last 64 days of data load history

-- you can use option
-- "FORCE = TRUE | FALSE"
-- to re-load the same data file, by default this flag is false.
-- if you truncate or delete all the data, without force=true, it does no load data.

		copy into customer_parquet_ff
		from @%customer_parquet_ff/customer.snappy. parquet
		force=true;
-- making it true may cause duplicdate data set.

		select count(*) from customer_parquet_ff;


- you can run any copy command from any stage area be it user, table or named,
- all works in the same way.


-- account usage - using role accountrole
		use role accountadmin;
-- copy history table
		select * from "SNOWFLAKE"."ACCOUNT_USAGE"."COPY_HISTORY";

-- load history table
		select * from "SNOWFLAKE"."ACCOUNT_USAGE"."LOAD_HISTORY";

--stages
		select * from "SNOWFLAKE"."ACCOUNT_USAGE"."STAGES";
--equivalent to show stages but this is specific to schema

--This is an Account Usage view that is used to query data loading history for the last 365 days,
--for both batch loading (COPY INTO <table>) and continuous loading (with Snowpipe).
SELECT * FROM "SNOWFLAKE"."ACCOUNT_USAGE"."COPY_HISTORY"

--This is also an Account Usage view, but excludes files loaded with Snowpipe.
--This view may also be subject to latency of up to 90 mins.
SELECT * FROM "SNOWFLAKE"."ACCOUNT_USAGE"."LOAD_HISTORY"

--This is an Information Schema view that is used to query the history of data loaded into tables using the COPY INTO <table> command within the last 14 days.
--The view displays one row for each file loaded, and does not include data loaded with Snowpipe.
SELECT * FROM "SNOWFLAKE"."INFORMATION_SCHEMA"."LOAD_HISTORY"

--This is just a specific example of the previous one, but since the Snowflake database is a system-defined, shared, read-only database,
--querying this view probably won't return anything (useful).
SELECT * FROM "DATABASE_NAME"."INFORMATION_SCHEMA"."LOAD_HISTORY"




﻿------------------------------
--CHAPTER-4 FILE FORMAT OPTION
------------------------------

﻿

use database TIPSDB;
use schema CH09;



-- file format and named stage files
-- ---------------------------------

-- create a file format
	create or replace file format my_parquet_ff type = 'parquet';
	create or replace file format my_json_ff type = 'json';
	create or replace file format my_csv_ff type = 'csv';

	show file formats;
-- for csv, you have lot of option
	/*
		compression = 'auto'
		field_delimiter=','
		record_delimiter = '\n'
		skip_header = 0
		date_format = 'auto'
		timestamp_format = 'auto
	*/


	create or replace stage stg_csv
		file_format = my_csv_ff
		comment = 'stage will use csv file format';

-- you can attach a file format during the definition and you don't need to define later.
	create or replace stage stg_none
		comment = 'no file format attached';


-- load csv data
-- put file:///tmp/ch09-data/customer.csv/customer_000.csv @stg_csv/ AUTO_COMPRESS=false;
-- put file:///tmp/ch09-data/customer.csv/customer_000.csv @stg_none/ AUTO_COMPRESS=false;

-- put file://C:\Users\ravinderK\Desktop\data.csv @stg_csv/ AUTO_COMPRESS=false;
-- put file://C:\Users\ravinderK\Desktop\data.csv @stg_none/ AUTO_COMPRESS=false;

		list @stg_none/;
		list @stg_csv;
-- no file format required
		select * from customer_csv_ff;
		copy into customer_csv_ff from @stg_csv;


-- file format required
		select * from customer_csv_none;
		copy into customer_csv_none from @stg_none
		file_format = (format_name= my_csv_ff);






﻿------------------------
--CHAPTER-5 QUERY STAGE
------------------------


﻿

use database TIPSDB;
use schema CH09;



-- Query stage data without loading
---------------------------------------

-- creating a table called my_customer
	create or replace TABLE my_customer (
		CUST_KEY NUMBER (38,0),
		NAME VARCHAR(25),
		ADDRESS VARCHAR(40),
		NATION_KEY NUMBER (38,0),
		PHONE VARCHAR(15),
		ACCOUNT_BALANCE NUMBER(12,2),
		MARKET_SEGMENT VARCHAR(10),
		COMMENT VARCHAR(117)
	);

-- lets query it
select * from my_customer;

-- create a file format
create or replace file format parquet_ff type ='parquet';

-- lets create stage object

	create or replace stage my_stg
		file_format = parquet_ff
		comment = 'stage will use parquet file format';

-- lets load some data to stage
-- put file:///tmp/ch09-data/parquet/customer.snappy.parquet @my_stg/my_data/;
﻿
	list @my_stg/my_data/;

	select
		$1:CUSTOMER_KEY::varchar,
		$1:NAME: varchar,
		$1:ADDRESS::varchar,
		$1:COUNTRY_KEY::varchar,
		$1:PHONE::varchar,
		$1:ACCT_BAL::decimal(10,2),
		$1:MKT_SEGMENT::varchar,
		$1:COMMENT::varchar
	from @my_stg/my_data/;

-- basic trnasformation
-- function substr(t.$2,4)
-- to_decimal(t.$2, '99.9', 9, 5)
-- seq1.nextval
		create or replace sequence seq_01 start = 1 increment = 1 comment='This is a trial sequence';


	select
		seq_01.next_val,
		substr($1:CUSTOMER_KEY::varchar,2),
		$1:CUSTOMER_KEY::varchar,
		$1:NAME: varchar,
		$1:ADDRESS::varchar,
		$1:COUNTRY_KEY::varchar,
		$1:PHONE::varchar,
		$1:ACCT_BAL::decimal(10,2),
		$1:MKT_SEGMENT::varchar,
		$1:COMMENT::varchar
	from @my_stg/my_data/;





﻿------------------------------------
--CHAPTER-6 FILE PATTERN VALIDATION
------------------------------------


use database TIPSDB;
use schema CH09;


Stage File Validation During Copy Command
//========================================
-- Following kind of file pattern can be used to copy data to stage

-- Examples-01
	copy into t1 from @%t1/region/state/city/2021/06/01/11/
		files ('mydata1.csv', 'mydata1.csv');

-- Example-02
	copy into t1 from @%t1/region/state/city/2021/2016/06/01/11/
		pattern='.*mydata[^[0-9]{1,3}$$].csv';

-- Example-03
	copy into people_data from @%people_data/data1/
		pattern=' .*person_data[^0-9{1,3}$$].csv';


-- lets create a table
		create or replace TABLE my_customer_csv (
			CUST_KEY NUMBER(38,0),
			NAME VARCHAR(25),
			ADDRESS VARCHAR(40),
			NATION_KEY NUMBER (38,0),
			PHONE VARCHAR(15),
			ACCOUNT_BALANCE NUMBER (12,2),
			MARKET_SEGMENT VARCHAR(10),
			COMMENT VARCHAR(117)
		);

-- create csv file format
		create or replace file format csv_ff type = 'csv'
		FIELD_OPTIONALLY_ENCLOSED_BY = '\042';
﻿
-- create stage again
		create or replace stage my_stg
		file_format = csv_ff
		comment = 'stage will use csv file format';


-- lets load some data to stade
-- remove @my_stg/my_data/;
-- put file:///tmp/ch09-data/csv-error/*.csv @my_stg/my_data/ auto_compress=false;

		list @my_stg/my_data/;

-- access the field via $ notation
		select $1, $2, $3, $4, $5, $6, $7, $8 from @my_stg/my_data/customer_000.csv ;

	select * from my_customer_csv;
-- select specific files
		copy into my_customer_csv from
			@my_stg/my_data/
			files=('customer_000.csv', 'customer_101.csv');

		copy into my_customer_csv from
			@my_stg/my_data/
			pattern='.customer_10[[0-9]$$].csv';


-- check the error file without loading the file
		copy into my_customer_csv from
			@my_stg/my_data/
			files-('custoher_483_error.csv')
			validation_mode = 'RETURN_ERRORS' ;

-- check handful of roles as dry run without loading it
		copy into my_customer_csv from
			@my_stg/my_data/
			files=('customer_201.csv')
			validation_mode = 'RETURN_10_ROWS';





﻿------------------------
--CHAPTER-7 PERFORMANCE
------------------------


use database TIPSDB;
use schema CH09;

    --------------------------------------------------
    CSV None Performance
    -------------------------------------------------

	use warehouse CSV_NONE_VWH_MEDIUM;

	drop table customer_performance_csv_none;

	create table customer_performance_csv_none as select
		C_CUSTKEY as CUST_KEY,
		C_NAME as NAME,
		C_ADDRESS as ADDRESS,
		C_NATIONKEY as NATION_KEY,
		C_PHONE as PHONE,
		C_ACCTBAL AS ACCOUNT_BALANCE,
		C_MKTSEGMENT as MARKET_SEGMENT,
		C_COMMENT as COMMENT
	from SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.CUSTOMER limit 1;

	delete from customer_performance_csv_none;

    select count(*) from customer_performance_csv_none;

    list @stg_performance/csv/64mb/none;

    	copy into customer_performance_csv_none from
		@stq_performance/csv/64mb/none
		file_format = (type=csv compression= 'none' );

    --------------------------------------------------
    CSV GZIP Performance
    -------------------------------------------------
    use warehouse CSV_GZIP_VWH_MEDIUM;

    	drop table customer_performance_csv_gzip;

	create table customer_performance_csv_gzip as select
		C_CUSTKEY as CUST_KEY,
		C_NAME as NAME,
		C_ADDRESS as ADDRESS,
		C_NATIONKEY as NATION_KEY,
		C_PHONE as PHONE,
		C_ACCTBAL AS ACCOUNT_BALANCE,
		C_MKTSEGMENT as MARKET_SEGMENT,
		C_COMMENT as COMMENT
	from SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.CUSTOMER limit 1;

	delete from customer_performance_csv_gzip;

    select count(*) from customer_performance_csv_gzip;

	list @stg_performance/csv/64mb/gzip;
		copy into customer_performance_csv_gzip from
		@stq_performance/csv/64mb/gzip
		file_format = (type=csv compression= 'gzip' );

    --------------------------------------------------
    Parquet None Performance
    -------------------------------------------------
     use warehouse PARQUET_NONE_VWH_MEDIUM;

    	drop table customer_performance_parquet_none;

		copy into customer_performance_parquet_none from (
			select
				$1:CUSTOMER_KEY::number
				$1:NAME::varchar,
				$1: ADDRESS::varchar,
				$1:COUNTRY KEY::number,
				$1: PHONE::varchar,
				$1 ACCT_BAL::decimal(12,2),
				$1: MKT_SEGMENT::varchar,
				$1 COMMENT::varchar
			from @stg_performance/parquet/64mb/none
		)
		file_format (type=parquet compression='none')

	delete from customer_performance_parquet_none;

    select count(*) from customer_performance_parquet_none;

	list @stg_performance/parquet/64mb/none;
		copy into customer_performance_parquet_none from
		@stq_performance/parquet/64mb/none
		file_format = (type=parquet compression= 'none' );

    --------------------------------------------------
    Parquet Snappy Performance
    -------------------------------------------------
     use warehouse PARQUET_SNAPPY_VWH_MEDIUM;

    	drop table customer_performance_parquet_snappy;

		copy into customer_performance_parquet_snappy from (
			select
				$1:CUSTOMER_KEY::number
				$1:NAME::varchar,
				$1: ADDRESS::varchar,
				$1:COUNTRY KEY::number,
				$1: PHONE::varchar,
				$1 ACCT_BAL::decimal(12,2),
				$1: MKT_SEGMENT::varchar,
				$1 COMMENT::varchar
			from @stg_performance/parquet/64mb/snappy
		)
		file_format (type=parquet compression='snappy')

	delete from customer_performance_parquet_snappy;

    select count(*) from customer_performance_parquet_snappy;

	list @stg_performance/parquet/64mb/snappy;
		copy into customer_performance_parquet_snappy from
		@stq_performance/parquet/64mb/snappy
		file_format = (type=parquet compression= 'snappy' );


    --------------------------------------------------
    Small vs Big
    -------------------------------------------------

    drop table customer_4node;
	create table customer_4node as select
		C_CUSTKEY as CUST_KEY,
		C_NAME as NAME,
		C_ADDRESS as ADDRESS,
		C_NATIONKEY as NATION_KEY,
		C_PHONE as PHONE,
		C_ACCTBAL AS ACCOUNT_BALANCE,
		C_MKTSEGMENT as MARKET SEGMENT,
		C_COMMENT as COMMENT
	from SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.CUSTOMER limit 1;
	delete from customer_4node;

	drop table customer_8node;
	create table customer_8node as select
		C_CUSTKEY as CUST_KEY,
		C_NAME as NAME,
		C_ADDRESS as ADDRESS,
		C_NATIONKEY as NATION_KEY,
		C_PHONE as PHONE,
		C_ACCTBAL AS ACCOUNT_BALANCE,
		C_MKTSEGMENT as MARKET SEGMENT,
		C_COMMENT as COMMENT
	from SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.CUSTOMER limit 1;
	delete from customer_8node;

	drop table customer_16node;
	create table customer_16node as select
		C_CUSTKEY as CUST_KEY,
		C_NAME as NAME,
		C_ADDRESS as ADDRESS,
		C_NATIONKEY as NATION_KEY,
		C_PHONE as PHONE,
		C_ACCTBAL AS ACCOUNT_BALANCE,
		C_MKTSEGMENT as MARKET SEGMENT,
		C_COMMENT as COMMENT
	from SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.CUSTOMER limit 1;
	delete from customer_16node;

﻿

	select count(*) from customer_4node;
	select count(*) from customer_8node;
	select count(*) from customer_16node;


	ALTER SESSION SET QUERY_TAG= 'load-speed';
	list @stg_performance/demo/;

 -- 4 node cluster
    use warehouse VWH_4NODE_MID;
	copy into customer_4node from (
		select
			$1:CUSTOMER KEY::number,
			$1:NAME::varchar,
			$1:ADDRESS::varchar,
			$1:COUNTRY_KEY::number,
			$1:PHONE::varchar,
			$1:ACCT_BAL::decimal(12,2),
			$1:MKT_SEGMENT::varchar,
			$1:COMMENT::varchar
		from @stg_performance/demo/
	)
file_format (type=parquet compression= 'snappy');

-- 8 node cluster
use warehouse VWH_8MODE_LARGE;
copy into customer_8node from (
		select
			$1:CUSTOMER KEY::number,
			$1:NAME::varchar,
			$1:ADDRESS::varchar,
			$1:COUNTRY_KEY::number,
			$1:PHONE::varchar,
			$1:ACCT_BAL::decimal(12,2),
			$1:MKT_SEGMENT::varchar,
			$1:COMMENT::varchar
		from @stg_performance/demo/
	)
file_format (type=parquet compression= 'snappy');

-- 16 node cluster
use warehouse VWH_16MODE_XLARGE;
copy into customer_16node from (
		select
			$1:CUSTOMER KEY::number,
			$1:NAME::varchar,
			$1:ADDRESS::varchar,
			$1:COUNTRY_KEY::number,
			$1:PHONE::varchar,
			$1:ACCT_BAL::decimal(12,2),
			$1:MKT_SEGMENT::varchar,
			$1:COMMENT::varchar
		from @stg_performance/demo/
	)
file_format (type=parquet compression= 'snappy');