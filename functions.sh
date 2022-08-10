###This file defines the functions for generating the tickets report"####
##You will find all the functions here and you can call them in the main Script##

#Function: generateGNUPlotCommand
#This functions generates the parameter to pass
#to the GNUPlot program to generate the plots

generateGNUPlotCommand() {

local ROW=`echo "$1" | sed 's/\"//g'`
local COLOR=""
#echo "$ROW"
local PARAMETERS=2
local COUNTER2=0
for i in `echo "$ROW"` 
do
	local MANUFACTURER_VALUE=`echo "$i" | tr [:upper:] [:lower:]`
	if [[ $MANUFACTURER_VALUE =~ .*2n.* ]]
	then
		#echo "$MANUFACTURER_VALUE, $i"
		COLOR="royalblue"
		#echo $COLOR
	elif [[ $MANUFACTURER_VALUE =~ .*snom.* ]]
	then
		#echo "$MANUFACTURER_VALUE, $i"
		COLOR="yellow"
		#echo $COLOR
	elif [[ $MANUFACTURER_VALUE =~ .*sangoma.* ]]
	then	
		#echo "$MANUFACTURER_VALUE, $i"
		COLOR="green"
		#echo $COLOR
	elif [[ $MANUFACTURER_VALUE =~ .*ezvoice.* ]]
	then
		#echo "$MANUFACTURER_VALUE, $i"
		COLOR="orange"
		#echo $COLOR
	elif [[ $MANUFACTURER_VALUE =~ .*hiperpbx.* ]]
	then
		#echo "$MANUFACTURER_VALUE, $i"
		COLOR="dark-green"
		#echo $COLOR
	elif [[ $MANUFACTURER_VALUE =~ .*patton.* ]]
	then
		#echo "$MANUFACTURER_VALUE, $i"
		COLOR="grey0"
		#echo $COLOR
	elif [[ $MANUFACTURER_VALUE =~ .*mikrotik.* ]]
	then
		#echo "$MANUFACTURER_VALUE, $i"
		COLOR="grey1"
		#echo $COLOR
	fi
	
	if [ $COUNTER2 -eq 0 ] 
	then
		GNUPLOT_COMMAND="$GNUPLOT_COMMAND u $PARAMETERS:xtic(1) t \"$i\" lc rgb \"$COLOR\", "
        COUNTER2=$(( COUNTER2 + 1 ))
        PARAMETERS=$(( PARAMETERS + 1 ))
    else    
        GNUPLOT_COMMAND="$GNUPLOT_COMMAND\"\" u $PARAMETERS t \"$i\" lc rgb \"$COLOR\", "
        PARAMETERS=$(( PARAMETERS + 1 ))
    fi

done
echo $GNUPLOT_COMMAND | sed 's/.\{2\}$//' | sed 's/^ //g'

}


#Function: formatFileForByState
#This functions format the file for being passed
#to GNUPlot and generate the plot "Tickets By Status"

formatFileForByState() {
local QUERY="$1"
local FILE="$2"
local GNUPLOT_COMMAND=""
#echo "$FILE"
#echo "$QUERY"
local COLUMN=`awk -F'\t' '{print $1}' <<< "$QUERY" | sort | uniq`
local TITLE=`awk -F'\t' '{print $2}' <<< "$QUERY" | sort | uniq`
echo "" > $FILE
IFSBACK=$IFS
IFS=$'\n'

for i in $COLUMN
do
	echo -n "\"$i\";" >> $FILE
	for j in $TITLE
	do
		VALUE=`echo "$QUERY" | grep "$i" | grep "$j" | cut -s -f3`
		#echo $VALUE
		if [ -z $VALUE ]
		then
			VALUE=0
		fi
		echo -n "$VALUE;" >> $FILE
	done
	echo -e "\n" >>  $FILE
done

sed -i '/^$/d' $FILE

generateGNUPlotCommand "$TITLE"
}


#Function: formatFileForByManufacturer
#This function format the file for being passed
#to GNUPlot and generate the plot "Tickets By Manufacturer"

formatFileForByManufacturer() {
local FILE="$1"
local GNUPLOT_COMMAND="using 2:xtic(1) lc rgb \"royalblue\""
echo $GNUPLOT_COMMAND
}


#Function: formatFileForOpenByManufacture
#This function format the file for being passed
#to GNUPlot and generate the plot "Tickets Opened By Manufacturer"

formatFileForOpenByManufacturer() {
local FILE="$1"
local GNUPLOT_COMMAND="using 2:xtic(1) lc rgb \"royalblue\""
echo $GNUPLOT_COMMAND
}

#Function: formatFileForElapsedTime
#This function format the file for being passed
#to GNUPlot and generate the plot "Elapsed Time since Creation to Close (in Days)"

formatFileForElapsedTime() {
local QUERY="$1"
#echo "$QUERY"
local COLUMN=("0-3" "4-7" "More week" "More Month")
local MANUFACTURERS=`awk -F'\t' '{print $3}' <<< "$QUERY" | sort | uniq`
local GNUPLOT_COMMAND=""
#echo "$TIMES"

#echo "$MANUFACTURERS"
local k
local m
local n

echo "" > $DIRECTORY/stackedElapsed.txt
for k in ${COLUMN[*]} 
do
	#echo "Column $k"
  	echo -n "\"$k\";" >> $DIRECTORY/stackedElapsed.txt
	for m in `echo "$MANUFACTURERS"`
  	do
		local FILTERED=`echo "$QUERY" | grep "$m"`
		#echo "Manufacturer $m"
		if [ $k = "0-3" ]	
		then
			#echo "$m"
			#echo "$QUERY"
			local COUNTER=0;
			#echo "after filter: $FILTERED"
			for n in `echo "$FILTERED"`
			do
			local DAYS=`awk -F'\t' '{print $2}' <<< "$n"`
			local TIMES=`awk -F'\t' '{print $1}' <<< "$n"`
			if [ $DAYS -ge 0 ] && [ $DAYS -le 3 ]
 			then
					#echo "counter $COUNTER"
					COUNTER=$(( $COUNTER + $TIMES ))
					#echo "Times $TIMES"
					#echo "count $COUNTER"
					#echo "nnnn: $n"
			fi
			done
			echo -n "$COUNTER;" >> $DIRECTORY/stackedElapsed.txt
			#echo "after filter delete (0-3): $FILTERED"
				 
			
		elif [ $k = "4-7" ]
		then
			local COUNTER=0;
			#echo "FILTER: $FILTERED"
			for n in `echo "$FILTERED"`
			do
			local DAYS=`awk -F'\t' '{print $2}' <<< "$n"`
   	                local TIMES=`awk -F'\t' '{print $1}' <<< "$n"`
			if [ $DAYS -ge 4 ] && [ $DAYS -le 7 ]
				then
					COUNTER=$(( $COUNTER + $TIMES ))
			fi
			done
			echo -n "$COUNTER;" >> $DIRECTORY/stackedElapsed.txt
		elif [ $k = "More week" ]
		then
			local COUNTER=0;
  	                #echo "FILTER: $FILTERED"
			for n in `echo "$FILTERED"`
			do
			local DAYS=`awk -F'\t' '{print $2}' <<< "$n"`
			local TIMES=`awk -F'\t' '{print $1}' <<< "$n"`
			if [ $DAYS -ge 7 ] && [ $DAYS -le 30 ]
			then
				COUNTER=$(( $COUNTER + $TIMES ))	
			fi	
			done
			echo -n "$COUNTER;" >> $DIRECTORY/stackedElapsed.txt
		elif [ $k = "More Month" ]
		then
			local COUNTER=0;
  	                #echo "FILTER: $FILTERED"
			for n in `echo "$FILTERED"`
			do
			local DAYS=`awk -F'\t' '{print $2}' <<< "$n"`
			local TIMES=`awk -F'\t' '{print $1}' <<< "$n"`
			if [ $DAYS -gt 30 ]
			then
				COUNTER=$(( $COUNTER + $TIMES ))	
			fi	
			done
			echo -n "$COUNTER;" >> $DIRECTORY/stackedElapsed.txt
		fi
	done
	echo -e "" >> $DIRECTORY/stackedElapsed.txt
done
sed -i '/^$/d' $DIRECTORY/stackedElapsed.txt
generateGNUPlotCommand "$MANUFACTURERS"
}


#Function: formatFileForClosedByMonth
#This function format the file for being passed
#to GNUPlot and generate the plot "Tickets Closed by Month"

formatFileForClosedByMonth() {
local QUERY="$1"
local FILE="$2"
local COLUMN=`echo "$QUERY" | awk '{print $1}' | sort | uniq`
local TITLE=`echo "$QUERY" | awk '{print $2}' | sort | uniq`
#echo "$QUERY"
#echo "$TITLE"
echo "" > $FILE

for i in $COLUMN
do
	echo -n "$i;" >> $FILE
	for j in $TITLE
	do
		VALUE=`echo "$QUERY" | grep "$i" | grep "$j" | cut -d' ' -f3`
		#echo "$VALUE"
		if [ -z $VALUE ]
		then
			VALUE=0
		fi
		echo -n "$VALUE;" >> $FILE
	done
	echo -e "\n" >>  $FILE
done 
sed -i '/^$/d' $FILE
generateGNUPlotCommand "$TITLE"
}

#Function: formatFileForOpenByClient
#This function format the file for being passed
#to GNUPlot and generate the plot "Tickets Opened by Client"

formatFileForOpenByClient() {
local FILE="$1"
local GNUPLOT_COMMAND="using 2:xtic(1) lc rgb \"royalblue\""
echo $GNUPLOT_COMMAND
}

#Function: formatFileForByRegion
#This function format the file for being passed
#to GNUPlot and generate the plot "Tickets  by Region"

formatFileForByRegion() {
local FILE="$1"
local GNUPLOT_COMMAND="using 2:xtic(1) lc rgb \"royalblue\""
echo $GNUPLOT_COMMAND
}

