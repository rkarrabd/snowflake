



list @%CUSTOMER_CSV;



use role sysadmin;
create or replace database my_db_08 comment = 'Database for chapter-8';
create schema my_schema_08 comment = 'Schema for chapter-8';
use database my_db_08;
use schema my_schema_08;

// this is how we can use it
create or replace sequence seq_01 start = 1 increment = 1 comment='This is a trial sequence';
create or replace sequence seq_02 start = 1 increment = 2 comment='This is a trial sequence';
create or replace sequence seq_03 start = 0 increment = -2 comment='This is a trial sequence with negative increment';

create or replace table my_tbl_01 (i integer);

//how to get next value
select seq_01.nextval, seq_02.nextval, seq_03.nextval;

﻿//in table field]
create or replace table my_tbl_02 (
		pk int autoincrement,
		seq1 int default seq_01.nextval,
		seq2 int default seq_02.nextval,
		seq3 int default seq_03.nextval,
		msg string
	);

//let's the desc table
desc table my_tbl_02;
select get_ddl('table', 'my_tbl_02');

insert into my_tbl_02 (msg) values ('msg-1');
select * from my_tbl_02;

show sequences;
show sequences like '%01%';

select get_ddl('sequence','seq_03');


// ================================================
// Load data from different format

DROP FILE FORMAT "MY_DB_08"."MY_SCHEMA_08".csv_ff;
CREATE OR REPLACE FILE FORMAT "MY_DB_08"."MY_SCHEMA_08".csv_ff
    TYPE = CSV
    COMPRESSION = 'AUTO'
    FIELD_DELIMITER = '|'
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 0
    FIELD_OPTIONALLY_ENCLOSED_BY = 'NONE'
    TRIM_SPACE= FALSE
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT ='AUTO'
    NULL_IF = ('\\N');

create table customer_csv(
		CUSTOMER_KEY integer,
		NAME string,
		ADDRESS string,
		COUNTRY_KEY string,
		PHONE string,
		ACCT_BAL decimal,
		MKT_SEGMENT string,
		COMMENT string
	);

//load parquet data
create table customer_par(
		my_data variant
	);

//query parquet data
select * from customer_par;

//query individual dataset
select c.key,c.value from customer_par,
lateral flatten(input => my_data) c;



//load orc data
create table customer_orc(
		my_data variant
	);

//query orc data
select * from customer_orc;

//query individual dataset
select c.key,c.value from customer_orc,
lateral flatten(input => my_data) c;

show file formats;
show file formats like '%CSV%';

select get_ddl ('file_format','csv_ff');

//======================Stage objects ======================

CREATE STAGE MY_STG
	DIRECTORY = ( ENABLE = true )
	COMMENT = 'This is my initial Stage';

--load the data via put command
--snowsql -a eg71478.east-us-2.azure u tipsadmin
--use database my_db8;
--use chema my_schema8;
list @MY_STG;
//put file:///tmp/customer.csv @MY_STG;
//put file:///tmp/customer.json @MY_STG;
//put file:///tmp/customer.snappy.orc @MY_STG;
//put file:///tmp/customer.snappy.parquet @MY_STG;

list @MY_STG;
list @%CUSTOMER_CSV;

// Load data within stage sub-directory
//put file:///tmp/customer.json @MY_STG/json;
//put file:///tmp/customer.xml @MY_STG/xml;

-- Now we can run copy command to load data from stage
-- it really does not matter if it is internal or external for copy command

select count(*) from customer_par;
copy into customer_par
	from @my_stg/customer.snappy.parquet
	file_format = (type=parquet);

select count(*) from customer_par;
select * from customer_par;

//======================Integration objects ======================

use role accountadmin;
create or replace storage integration s3_integration
	type = external_stage
	storage_provider = s3
	storage_aws_role_arn = 'arn:aws:iam::001234567890:role/myrole'
	enabled = true
	storage_allowed_locations = ('s3://mybucket1/path1/', 's3://mybucket2/path2/');

show integrations;

create or replace storage integration azure_integration
	type = external_stage
	storage_provider = azure
	enabled = true
	azure_tenant_id = '<tenant_id>'
	storage_allowed_locations = ('azure://myaccount.blob.core.windows.net/mycontainer/path1/', 'azure://myaccount.blob.core.windows.net/mycontainer/path2/');


show integrations;
show integrations like '%S3%';

//======================list pipe objects ======================
use role sysadmin;

CREATE PIPE "MY_DB_08"."MY_SCHEMA_08".MY_PIPE
	COMMENT = 'THIS IS MY 1ST PIPE OBJECT TO LOAD A SMALL CHUNK OF DATA.'
AS COPY INTO "MY_DB_08"."MY_SCHEMA_08"."CUSTOMER_CSV"
FROM @"MY_DB_08"."MY_SCHEMA_08"."MY_STG"
FILE_FORMAT = (FORMAT_NAME= "MY_DB_08"."MY_SCHEMA_08"."CSV_FF");

show pipes;
show pipes like '%MY%';
select get_ddl ('pipe','my_pipe');

//how to check if pipe is running or not
select SYSTEM$PIPE_STATUS( 'my_pipe');

//======================Stream objects ======================


create or replace stream
customer_stream on table customer_csv;

desc stream customer_stream;
show streams;

select * from customer_csv order by customer_key limit 10;
select * from customer_stream;

delete from customer_csv where customer_key=90003;
select * from customer_stream;

--update one record
update customer_csv set name = 'Customer$000090005' where customer_key= 90005;
select * from customer_stream;

 --insert one record
insert into customer_csv select * from customer_csv where customer_key= 90008;,
select * from customer_stream;

show streams;
show streams like '%CU%';
select get_ddl('stream','customer_stream');

--METADATA$ACTION
--METADATA$ISUPDATE
--METADATA$ROW_ID

--DELETE Row
--METADATA$ACTION    METADATA$ISUPDATE    METADATA$ROW_ID
--DELETE                FALSE               32 bit hash value

--UPDATE Row
--METADATA$ACTION    METADATA$ISUPDATE    METADATA$ROW_ID
--DELETE                TRUE                32 bit same hash value
--INSERT                TRUE                32 bit same hash value

--INSERT Row
--METADATA$ACTION    METADATA$ISUPDATE    METADATA$ROW_ID
--INSERT                FALSE                32 bit hash value

//======================Task objects ======================

create or replace task my_task
	warehouse = compute_wh
	schedule = '5 minutes'
as
	select current_date;

show tasks;

create or replace task my_task_insert
	warehouse = compute_wh
	schedule = '5 minutes'
WHEN
	SYSTEM$STREAM_HAS_DATA('customer_stream')
as
	insert into customer_01 select * from customer_o1 where customer_key =90008;