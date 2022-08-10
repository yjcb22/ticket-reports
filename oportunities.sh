#!/bin/bash

REPORTFILE="name.pdf"
RECIPIENTS="email1@email.com, email2@email.com"
#RECIPIENTS="email1@email.com"
FROM="ticketsReport@xmartek.com"
SUBJECT="XMARTEK Monday's Opportunities Report"


cd /root/reporting

IFS=$'\n'; for i in `mysql -u user -p"password" dbvtiger -e "select createdtime,first_name from vtiger_potential inner join vtiger_crmentity inner join vtiger_users where potentialid=crmid and id=smcreatorid;" -N -B`; 
do 
	CREATED=`echo $i | awk '{print $1}'`; CREATOR=`echo $i | awk '{print $3}'`; CREATED2=`date -d"$CREATED" "+%Y %B"`; echo "$CREATED2 $CREATOR"; 
	
done | sort -k2M > dataOportunitiesRAW.txt

COUNTED=`cat dataOportunitiesRAW.txt | uniq -c | awk '{print $2,$3,$4,$1}'`
#echo "$COUNTED"

DATE=`cat dataOportunitiesRAW.txt | awk '{print $1"-"$2}' | uniq`
#echo $DATE

PEOPLE=$(echo "$COUNTED" | awk '{print $3}' | sort | uniq)
#echo "$PEOPLE" 


echo "" > dataOportunities.txt



for i in $DATE
do
	echo -n "\"$i\";" >> dataOportunities.txt
	MESSAGE=$(echo "$COUNTED" | grep `echo $i | awk -F"-" '{print $1" "$2}'`)
	#echo "PRIMERO $MESSAGE"
	
	
	for j in $PEOPLE
	do
		NUMBER=$(echo "$MESSAGE" | grep "$j" | awk '{print $4}')
		if [ -z "$NUMBER" ]
		then
			NUMBER=0
		fi
		#echo "$i $j NUMER $NUMBER"
		echo -n "$NUMBER;" >> dataOportunities.txt
	done
	echo "" >> dataOportunities.txt
			
done

sed -i '/^$/d' dataOportunities.txt

#####GENERATE GNUPLOT COMMAND#####
COMMAND=""
COUNTER1=0
PARAMETERS=2
for i in $PEOPLE
do
	#echo "$i"
	if [ $COUNTER1 -eq 0 ]
	then
		COMMAND="$COMMAND using $PARAMETERS:xticlabels(1) t \"$i\", "
		COUNTER1=$(( COUNTER1 + 1 ))
        PARAMETERS=$(( PARAMETERS + 1 ))
	else
		COMMAND="$COMMAND\"\" using $PARAMETERS t \"$i\", "
	fi
done
COMMAND=`echo $COMMAND | sed "s/^ //" | sed 's/.\{2\}$//'`
#echo $COMMAND

##################################

rm -f $REPORTFILE

#######GENERATE GRAPHS WITH GNUPLOT#######
/usr/bin/gnuplot << EOF
set terminal postscript portrait enhanced color dashed lw 1 "DejaVuSans" 12
set output '| /usr/bin/ps2pdf - name.pdf'
set style data histograms
set boxwidth 1 relative
set style fill solid 1.0 border -1
set datafile separator ";"
set title "Opportunities created per Month"
#plot "dataOportunities.txt" using 2:xticlabels(1) t "Var 1", '' using 3:xticlabels(1) t "Var 2"
plot "dataOportunities.txt" $COMMAND
EOF
###########################################

while true
do
        if [ -f $REPORTFILE ]
        then
                sleep 5
                echo "This is the monday's opportunities report. Created by Yeison Camargo for XMARTEK." | mail -s "$SUBJECT"  -r "$FROM" -a "$REPORTFILE" "$RECIPIENTS"
                break 2
        fi
done
