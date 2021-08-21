#!/bin/bash

### SETTINGS START ###
basedir="/mnt/f/database/test/"

dbuser="root"
dbpassword="123"
dbname="nextcloud"
dbdir="/var/lib/mysql/"

data_in=$basedir"db/"
data_out=$basedir"csv/"

tmpdir=$basedir"tmpdir/"
tmptablefile=$tmpdir".tmptables"
tmpfileCSV=$tmpdir".temptable.csv"
### SETTINGS END ###


### CODE START ###

# (1) create directory where temporary files get stored
sudo mkdir $tmpdir

# (2) stop mysql(or mariadb)
sudo service mysql stop

# (3) copy database folder and ibdata1 file to database directory
sudo rsync -av --progress $data_in$dbname $dbdir
sudo rsync -av --progress $data_in"ibdata1" $dbdir

# (4) start mysql
sudo service mysql start

# (5) get all tables of the chosen database and save it in file
sudo mysql -u $dbuser --password=$dbpassword $dbname -e "SHOW TABLES;" > $tmptablefile

# (6) loop through all tables from database and save every table in a .csv file
tail -n +2 $tmptablefile | while read line
do
	# (!) defining variable for table name and the output file name 
   	TABLE=$line
	FNAME=$data_out$line".csv"

	# (6.1) creates empty file and sets up column names using the information_schema
	mysql -u $dbuser --password=$dbpassword $dbname -B -e "SELECT COLUMN_NAME FROM information_schema.COLUMNS C WHERE table_name = '$TABLE';" | awk '{print $1}' | grep -iv ^COLUMN_NAME$ | sed 's/^/"/g;s/$/"/g' | tr '\n' ',' > $FNAME

	# (6.2) appends newline to mark beginning of data vs. column titles
	echo "" >> $FNAME

	# (6.3) dumps data from DB into /var/mysql/tempfile.csv
	mysql -u $dbuser --password=$dbpassword $dbname -B -e "SELECT * INTO OUTFILE '$tmpfileCSV' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' FROM $TABLE;"

	# (6.4) merges data file and file w/ column names
	cat $tmpfileCSV >> $FNAME

	# (6.5) deletes tempfile
	rm -rf $tmpfileCSV

	# (!) message
	echo $FNAME" in .csv done."
done
sudo rm -rf $tmpdir
### CODE END ###
