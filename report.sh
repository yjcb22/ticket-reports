#!/bin/bash

DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
source "$DIRECTORY/functions.sh"
#echo $DIRECTORY
####VARIABLES FOR MAILING########

RECIPIENTS="email1@email.com" 
FROM="ticketsReport@xmartek.com"
SUBJECT="XMARTEK Monday's Report"
REPORTFILE="$DIRECTORY/name2.pdf"

################################

####VARIABLES FOR THE REPORT####

DBUSER="user"
DBPASSWORD="password"
FILE_BY_STATE="$DIRECTORY/stackedState.txt"
FILE_BY_ELAPSED="$DIRECTORY/stackedElapsed.txt"
FILE_BY_MANUFACTURER="$DIRECTORY/stackedManufacturer.txt"
FILE_OPEN_BY_MANUFACTURER="$DIRECTORY/stackedOpenManufacturer.txt"
FILE_OPEN_BY_CLIENT="$DIRECTORY/stackedOpenClient.txt"
FILE_CLOSED_BY_MONTH="$DIRECTORY/stackedClosedByMonth.txt"
FILE_BY_REGION="$DIRECTORY/stackedByRegion.txt"
IFSBACK=$IFS
IFS=$'\n'
#################################

###EXTRACT DATA FROM DATABASE#####

##GENERATE DATA FOR "BY STATE" REPORT###
DATA=`mysql -u $DBUSER -p"$DBPASSWORD" dbvtiger -e "select status,manufacturer,count(*) from vtiger_products inner join vtiger_troubletickets where vtiger_products.productid=product_id group by status,manufacturer;" -N -B`
GNU_STATE=`formatFileForByState "$DATA" "$FILE_BY_STATE"`
#echo "$GNU_STATE"

##GENERATE DATA FOR "BY MANUFACTURER" REPORT##
mysql -u $DBUSER -p"$DBPASSWORD" dbvtiger -e "select manufacturer, count(*) from vtiger_troubletickets inner join vtiger_products where vtiger_troubletickets.product_id=vtiger_products.productid group by manufacturer;" -s -N | sed 's/\(.*\)\t\([0-9]*\)/"\1";\2/g' > $FILE_BY_MANUFACTURER
GNU_MANUFACTURER=`formatFileForByManufacturer "$FILE_BY_MANUFACTURER"`

##GENERATE DATA FOR "OPEN BY MANUFACTURER" REPORT##
mysql -u $DBUSER -p"$DBPASSWORD" dbvtiger -e "select manufacturer, count(*) from vtiger_troubletickets inner join vtiger_products where vtiger_troubletickets.product_id=vtiger_products.productid and status != 'Closed' group by manufacturer" -s -N | sed -e 's/\(.*\)\t\([0-9]*\)/"\1";\2/g' > $FILE_OPEN_BY_MANUFACTURER
GNU_OPEN_BY_MANUFACTURER=`formatFileForOpenByManufacturer "$FILE_OPEN_BY_MANUFACTURER"`

##GENERATE DATA FOR "ELAPSED TIME SINCE OPENING TO CLOSE" REPORT##
DATA=`mysql -u $DBUSER -p"$DBPASSWORD" dbvtiger -e "select (datediff(vtiger_crmentity.modifiedtime,vtiger_crmentity.createdtime)) as 'Elapsed Days', manufacturer from vtiger_troubletickets inner join vtiger_crmentity inner join vtiger_products where vtiger_troubletickets.ticketid=vtiger_crmentity.crmid and vtiger_troubletickets.product_id=vtiger_products.productid and (vtiger_troubletickets.status='Closed');" -N -B| sort -n | uniq -c | sed 's/^ *\([0-9]*\) \([0-9]*\)/\1\t\2/g'`
#echo "$DATA"
GNU_ELAPSED=`formatFileForElapsedTime "$DATA"`
#echo "$GNU_ELAPSED"

##GENERATE DATA FOR "CLOSED BY MONTH" REPORT##
DATA=`mysql -u $DBUSER -p"$DBPASSWORD" dbvtiger -e "select monthname(modifiedtime), manufacturer from vtiger_troubletickets inner join vtiger_crmentity inner join vtiger_products where vtiger_troubletickets.ticketid=vtiger_crmentity.crmid and vtiger_troubletickets.product_id=vtiger_products.productid and (vtiger_troubletickets.status='Closed');" -N -B | sort | uniq -c | sed 's/^ *\([0-9]*\) \(.*\)\t\(.*\)/\"\2\" \"\3\" \1/g'`
#echo "$DATA"
GNU_MONTH=`formatFileForClosedByMonth "$DATA" "$FILE_CLOSED_BY_MONTH"`
#echo "$GNU_MONTH"


##GENERATE DATA FOR "OPEN BY CLIENT##
mysql -u $DBUSER -p"$DBPASSWORD" dbvtiger -e "select accountname, count(*) from vtiger_troubletickets inner join vtiger_account where vtiger_troubletickets.parent_id=vtiger_account.accountid and vtiger_troubletickets.status!='Closed' group by accountname;" -N -B | sort | sed 's/\(.*\)\t\([0-9]*\)/"\1";\2/g' > $FILE_OPEN_BY_CLIENT
GNU_OPEN_BY_CLIENT=`formatFileForOpenByClient "$FILE_OPEN_BY_MANUFACTURER"`

##GENERATE DATA FOR "TICKETS BY REGION"##
mysql -u root -pXmartek111 dbvtiger -e "select cf_715, count(*) from vtiger_ticketcf inner join vtiger_troubletickets where vtiger_troubletickets.ticketid=vtiger_ticketcf.ticketid and vtiger_ticketcf.cf_715!='' group by cf_715;" -N -B | sed 's/\(.*\)\t\([0-9]*\)/"\1";\2/g' > $FILE_BY_REGION
GNU_REGION=`formatFileForByRegion "$FILE_BY_REGION"`

##################################


rm -f $REPORTFILE
cd $DIRECTORY
#######GENERATE GRAPHS WITH GNUPLOT#######

/usr/bin/gnuplot << EOF
set terminal postscript portrait enhanced color dashed lw 1 "DejaVuSans" 12
set output '| /usr/bin/ps2pdf - name2.pdf'
#set output 'YeisonStackedReport.eps'
set multiplot layout 3,1 title "XMARTEK MONDAY'S TICKETS REPORT"
set grid
set style data histograms
set style histogram rowstacked
set boxwidth 0.5
set style fill solid 1.0 border -1
set datafile separator ";"
set title "Tickets by Status"
plot "$FILE_BY_STATE" $GNU_STATE
#plot "$FILE_BY_STATE" u 2:xtic(1) t "2N" lc rgb "blue", "" u 3 t "Sangoma" lc rgb "gray"
set title "Elapsed Time since Creation to Close (in Days)"
plot "$FILE_BY_ELAPSED" $GNU_ELAPSED
set title "Tickets Closed by Month"
plot "$FILE_CLOSED_BY_MONTH" $GNU_MONTH
unset key
set multiplot layout 2,2 title "XMARTEK MONDAY'S TICKETS REPORT"
set xtics rotate by 90 
set title "Tickets by Manufacturer"
plot "$FILE_BY_MANUFACTURER" $GNU_MANUFACTURER
set title "Tickets Opened by Manufacturer"
plot "$FILE_OPEN_BY_MANUFACTURER" $GNU_OPEN_BY_MANUFACTURER
set xtics rotate by 90 
#set xtics rotate
#set multiplot layout 2,1 title "MONDAY'S TICKETS REPORT"
set title "Tickets Opened by Client"
plot "$FILE_OPEN_BY_CLIENT" $GNU_OPEN_BY_CLIENT
set title "Tickets  by Region"
plot "$FILE_BY_REGION" $GNU_REGION


EOF
###########################################

while true
do
	if [ -f $REPORTFILE ]
	then
		sleep 5
		echo "This is the monday's tickets report. Created by Yeison Camargo for XMARTEK." | mail -s "$SUBJECT"  -r "$FROM" -a "$REPORTFILE" "$RECIPIENTS"
		break 2
	fi
done



		


scp -r $DIRECTORY yeison@172.16.10.245:/home/yeison/Dropbox/XMARTEK/development


