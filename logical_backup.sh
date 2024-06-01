#!/bin/bash

#Version 1.15 inclusion of while loop to database logical backup
f_d_backup()
{

TS=`date +"%d%m%y%M%S"`
#Declaring the log locatiom path
BK_LOC="${BACKUP_DESTINATION}/${RUNNER}/${BACKUP_TYPE}/${TS}"

#Declaring the backup locatiom path
LOG_DIR="${BACKUP_DESTINATION}/${RUNNER}/LOG/${TS}"

#creating LOG DIRECTORY
mkdir -p ${LOG_DIR}


#creating the backup directory and starting the backup job.... 
echo "starting the backup job at ${TS}....">>${LOG_DIR}/${LOG_FILE}
if [[ -d ${BK_LOC} ]]
then
	echo "This directory already exists; sleeping for 10 seconds">>${LOG_DIR}/${LOG_FILE}
	sleep 4
else
	echo "This directory doesnt exist,creating a new ${BK_LOC} directory for backup">>${LOG_DIR}/${LOG_FILE}
	mkdir -p ${BK_LOC}
fi

# check for exit status for critical mission command of making directory
if (( $? == 0 ))
then
	echo "the mkdir command run successfully">>${LOG_DIR}/${LOG_FILE}
else

	echo "the mkdir command failed!!">>${LOG_DIR}/${LOG_FILE}
	exit
fi

#copying file into our first backup directory
echo "Copying ${SOURCE_FILE} to ${BK_LOC}">>${LOG_DIR}/${LOG_FILE}
cp -r ${SOURCE_FILE} ${BK_LOC}
#/myfirstfile.txt_${TS}

# Backup has successfully been implemented
echo "Ending the backup job at ${TS}!!">>${LOG_DIR}/${LOG_FILE}

# listing the files in my backup directory
echo "listing all the contents in our ${BK_LOC} directory">>${LOG_DIR}/${LOG_FILE}
ls -ltr ${BK_LOC}>>${LOG_DIR}/${LOG_FILE}

# counting the numbers of files in ${BACKUP_DIR} directory"
echo "counting the files in my ${BK_LOC} directory">>${LOG_DIR}/${LOG_FILE}
ls -ltr ${BK_LOC}|wc -l>>${LOG_DIR}/${LOG_FILE}
}

#creating a delete prompt
f_d_delete()
{

TS=`date +"%d%m%y%M%S"`
#Declaring the log locatiom path
BK_LOC="${BACKUP_DESTINATION}/${RUNNER}/${BACKUP_TYPE}/${TS}"

#Declaring the backup locatiom path
LOG_DIR="${BACKUP_DESTINATION}/${RUNNER}/LOG/${TS}"

#creating LOG DIRECTORY
mkdir -p ${LOG_DIR}


echo "Starting the delete job at ${TS}">>${LOG_DIR}/${LOG_FILE}
ls ${DEL_DESTINATION} | nl -s '. '
cd ${DEL_DESTINATION}
read -p "What do you want to delete(Enter a number)??:" INPUT
outcome=`ls | nl -s '. ' | grep ${INPUT} | cut -f 2,3 -d '.'`
echo "You selected ${outcome}">>${LOG_DIR}/${LOG_FILE}

#yes or no prompt
read -p "Are you sure you want to delete ${outcome}? Enter Y(yes) or N(No)" INPUT2
if [[ ${INPUT2} == Y || ${INPUT2} == y ]]
then
        echo "You are deleting this file">>${LOG_DIR}/${LOG_FILE}
elif [[ ${INPUT2} == "N" || ${INPUT2} == "n" ]]
then
        echo "The delete action has been undone">>${LOG_DIR}/${LOG_FILE}
        exit
else
        echo "You selected a wrong option... Try again">>${LOG_DIR}/${LOG_FILE}
        exit
fi
rm -r ${outcome}
echo "You successfully deleted ${outcome} at ${TS}">>${LOG_DIR}/${LOG_FILE}
ls ${DEL_DESTINATION} | nl -s '. '
}


scp_f_d_()
{

TS=`date +"%d%m%y%M%S"`

echo "Starting the secure backup job at ${TS}"

#Login to the cloud server
echo "Sshing into the cloud server"
ssh -p 2222 ${DST_SERVER} "/backup/create_bk_dir_oluwole.sh ${BACKUP_DESTINATION} ${RUNNER} ${TS}"

#copy to cloud location
echo "Preparing to surely backup into the cloud location"
scp -rP 2222 ${SOURCE_FILE} ${DST_SERVER}:${BACKUP_DESTINATION}/${RUNNER}/${TS}
echo "Secure copy successfully done to the cloud server at ${TS}!!!"

}


database_export_()
{

TS=`date +"%d%m%y%M%S"`
PRACTICEDIR="/home/oracle/scripts/praticedir_oluwole_june24"

#Declaring the backup locatiom path
FINAL_BK_LOC=${BACKUP_LOC}/${RUNNER}/${TS}

echo "checking database status..."
if ( ps -ef | grep pmon | grep ${DATABASE} )
then
        echo "${DATABASE} is up and running"
else
        echo "${DATABASE} failed...startup database to begin backup.."
	     exit
fi

echo "Pointing to the oracle envronment.."
. ${PRACTICEDIR}/oracle_env_ORCL.sh

echo "Logging in to the database.. to start backup operation"
sqlplus -s stack_temp/kirchoffW1<<EOF
select * from global_name;
select sum(bytes/1024/1024/1024) from dba_data_files;
show user;

create or replace directory DATA_EXPORT_IMPORT as '${FINAL_BK_LOC}';
select directory_name, directory_path from all_directories where directory_name='DATA_EXPORT_IMPORT';

spool ${PRACTICEDIR}/database_users.log
set heading off pagesize 0
select username from all_users where username like '%TEST%';
spool off
EOF


#Creating backup location
echo "creating database backup location at ${TS}"
if [[ -d ${FINAL_BK_LOC} ]]
then
        echo "The backup location exists"
             sleep 10
else
        echo "Backup location doesnt exist, creating a new backup location"
             mkdir -p ${FINAL_BK_LOC}


#checking for exit status
	if (( $? == 0 ))
	then
       		echo "Backup command run successfully"
	else

        	echo "Backup command failed"
	fi
fi

#Creating counter lopp
counter=1
while read SCHEMA
do
if (( ${counter} < 4 ))
then
	echo "schema ${counter} is ${SCHEMA}"
	echo "userid='/ as sysdba'">>expdp_${SCHEMA}_${TS}.par
	echo "schemas=${SCHEMA}">>expdp_${SCHEMA}_${TS}.par
	echo "dumpfile=expdp_${SCHEMA}_${TS}.dmp">>expdp_${SCHEMA}_${TS}.par
	echo "logfile=expdp_${SCHEMA}_${TS}.log">>expdp_${SCHEMA}_${TS}.par
	echo "directory=DATA_EXPORT_IMPORT">> expdp_${SCHEMA}_${TS}.par
	echo "Starting the export job at ${TS}"
	
	#Starting the parfile backup job

	expdp parfile=${PRACTICEDIR}/expdp_${SCHEMA}_${TS}.par
	if (( $? == 0 ))
	then
echo "Database successfully exported to ${FINAL_BK_LOC} at ${TS}"
	else
		echo "Te backup job failed, ceck the parfile configuration"
	fi
	(( counter ++ ))
else
	break
fi


done<${PRACTICEDIR}/database_users.log
}




#Mainbody
TS=`date +"%d%m%y%M%S"`
        CONTROL_FLAG=$1

if [[ ${CONTROL_FLAG} == "scheduled" ]]
then
        SELECTION=$2
        SOURCE_FILE=$3
        BACKUP_DESTINATION=$4
        RUNNER=$5
        BACKUP_TYPE=$6
        DST_SERVER=$7
        LOG_FILE=$8

        if [[ ${SELECTION} == "1" ]]
        then
                SELECTION=$2
                SOURCE_FILE=$3
                BACKUP_DESTINATION=$4
                RUNNER=$5
                BACKUP_TYPE=$6
                LOG_FILE=$7

	  TS=`date +"%d%m%y%M%S"`
	  #Declaring the log locatiom path
	  BK_LOC="${BACKUP_DESTINATION}/${RUNNER}/${BACKUP_TYPE}/${TS}"

	  #Declaring the backup locatiom path
	  LOG_DIR="${BACKUP_DESTINATION}/${RUNNER}/LOG/${TS}"

	  #creating LOG DIRECTORY
	  mkdir -p ${LOG_DIR}

	  #Command line numbering
		echo "The first command line argument is $1">>${LOG_DIR}/${LOG_FILE}
		echo "The second command line argument is $2">>${LOG_DIR}/${LOG_FILE}
		echo "The third command line argument is $3">>${LOG_DIR}/${LOG_FILE}
		echo "The fouth command line argument is $4">>${LOG_DIR}/${LOG_FILE}
		echo "The fifth command line argument is $5">>${LOG_DIR}/${LOG_FILE}
		echo "The sixth command line argument is $6">>${LOG_DIR}/${LOG_FILE}
		echo "The seventh command line argument is $7">>${LOG_DIR}/${LOG_FILE}
		echo "There are $# command line arguments in this script">>${LOG_DIR}/${LOG_FILE}


	  #Setting usage

	   if (( $# != 7 ))
	   then
		echo "This script FAILED!!
		Check the following usage:
		The first command line arg is CONTROL_FLAG
		The second command line arg is SELECTION
		The third command line arg is FILE_SOURCE
		The fourth command line arg is BACKUP_DESTINATION
		The fifth command line arg is RUNNER
 		The sixth command line arg is BACKUP_TYPE
           	The  seventh command line arg is LOG_FILE
           	"
 		exit
	   fi


	   #backup type substitution
	   if [[ ${BACKUP_TYPE} == "f" || ${BACKUP_TYPE} == "F" ]]
	   then
		echo "${BACKUP_TYPE} is a file">>${LOG_DIR}/${LOG_FILE}
        	BACKUP_TYPE="file"
	   else
        	echo "${BACKUP_TYPE} is a directory">>${LOG_DIR}/${LOG_FILE}
        	BACKUP_TYPE="directory"
	   fi


        fi

	if [[ ${SELECTION} == "2" ]]
        then
                SELECTION=$2
                DEL_DESTINATION=$3
                RUNNER=$4
                FILE_DEL_TYPE=$5
                LOG_FILE=$6


	    TS=`date +"%d%m%y%M%S"`
	    #Declaring the log locatiom path
	    BK_LOC="${DEL_DESTINATION}/${RUNNER}/${FILE_DEL_TYPE}/${TS}"

	    #Declaring the backup locatiom path
            LOG_DIR="${DEL_DESTINATION}/${RUNNER}/LOG/${TS}"

            #creating LOG DIRECTORY
            mkdir -p ${LOG_DIR}

            #Command line numbering
		echo "The first command line argument is $1">>${LOG_DIR}/${LOG_FILE}
                echo "The second command line argument is $2">>${LOG_DIR}/${LOG_FILE}
                echo "The third command line argument is $3">>${LOG_DIR}/${LOG_FILE}
                echo "The fouth command line argument is $4">>${LOG_DIR}/${LOG_FILE}
                echo "The fifth command line argument is $5">>${LOG_DIR}/${LOG_FILE}
                echo "The sixth command line argument is $6">>${LOG_DIR}/${LOG_FILE}
                echo "There are $# command line arguments in this script">>${LOG_DIR}/${LOG_FILE}



	    #Error declaration
		if (( $# != 6 ))
                then
                       echo "This script FAILED!!
                              Check the following usage:
                              The first command line arg is CONTROL_FLAG
                              The second command line arg is SELECTION
                              The third command line arg is FILE_SOURCE
                              The fourth command line arg is BACKUP_DESTINATION
                              The fifth command line arg is RUNNER
                              The sixth command line arg is BACKUP_TYPE
                              The  seventh command line arg is LOG_FILE
                            "
                            exit
                fi
		  #backup type substitution
		if [[ ${FILE_DEL_TYPE} == "f" || ${FILE_DEL_TYPE} == "F" ]]
		then
     			echo "${FILE_DEL_TYPE} is a file">>${LOG_DIR}/${LOG_FILE}
     			BACKUP_TYPE="file"
		else
     			echo "${FILE_DEL_TYPE} is a directory">>${LOG_DIR}/${LOG_FILE}
     			BACKUP_TYPE="directory"
		fi
	fi



#SECURE BACKUP TO CLOUD SERVER

        if [[ ${SELECTION} == "3" ]]
        then
                SELECTION=$2
                SOURCE_FILE=$3
                BACKUP_DESTINATION=$4
                RUNNER=$5
                DST_SERVER=$6

            
		#Command line numbering
                echo "The first command line argument is $1"
                echo "The second command line argument is $2"
                echo "The third command line argument is $3"
                echo "The fouth command line argument is $4"
                echo "The fifth command line argument is $5"
                echo "The sixth command line argument is $6"
                echo "There are $# command line arguments in this script"



                #Error declaration
                if (( $# != 6 ))
                then
                       echo "USAGE: This script FAILED!!
                              	    Check the following usage:
                              	    The first command line arg is CONTROL_FLAG
                              	    The second command line arg is SELECTION
                              	    The third command line arg is FILE_SOURCE
                              	    The fourth command line arg is BACKUP_DESTINATION
                              	    The fifth command line arg is RUNNER
                              	    The sixth command line arg is BACKUP_TYPE
                            "
                            exit



                fi
        fi




#DATABASE LOGICAL BACKUP


        if [[ ${SELECTION} == "4" ]]
        then
                SELECTION=$2
                BACKUP_LOC=$3
		RUNNER=$4
                DATABASE=$5
		#PARFILE_LOC=$6


            TS=`date +"%d%m%y%M%S"`
	    PRACTICEDIR="/home/oracle/scripts/praticedir_oluwole_june24"
	    
	    #Declaring the backup locatiom path
            FINAL_BK_LOC=${BACKUP_LOC}/${RUNNER}/${TS}


            #Command line numbering
                echo "The first command line argument is $1"
                echo "The second command line argument is $2"
                echo "The third command line argument is $3"
                echo "The fouth command line argument is $4"
                echo "The fifth command line argument is $5"
               # echo "The sixth command line argument is $6"
                echo "There are $# command line arguments in this script"

                #Error declaration
                if (( $# != 5 ))
                then
                       echo "This script FAILED!!
                              Check the following usage:
                              The first command line arg is CONTROL_FLAG
                              The second command line arg is SELECTION
                              The third command line arg is BACKUP_LOC
                              The fourth command line arg is RUNNER
                              The fifth command line arg is DATABASE
                            "
                            exit

    		fi

 	fi






elif [[ ${CONTROL_FLAG} == "notscheduled" ]]
then
        read -p "Select one of the following option:
        Enter 1 for for file or directory backup
        Enter 2 for file or directory delete
        Enter 3 for secure backup to a cloud server
	Enter 4 for database logical base
        Answer:" SELECTION

          if [[ ${SELECTION} == "1" ]]
          then
                read -p "Enter the backup file name:" SOURCE_FILE
                read -p "Enter the backup destination:" BACKUP_DESTINATION
                read -p "Enter the runner:" RUNNER
                read -p "Enter the backup type:" BACKUP_TYPE
                read -p "Enter the log directory name:" LOG_FILE
          fi
          if [[ ${SELECTION} == "2" ]]
          then
                read -p "Enter the delete destination:" DEL_DESTINATION
                read -p "Enter the runner:" RUNNER
                read -p "Enter the delete type:" FILE_DEL_TYPE
                read -p "Enter the log directory name:" LOG_FILE
          fi

	  if [[ ${SELECTION} == "3" ]]
          then
                read -p "Enter file or directory to backup:" SOURCE_FILE
		read -p "Enter the backup destination:" BACKUP_DESTINATION
                read -p "Enter the runner's name:" RUNNER
		read -p "Enter the destination server:" DST_SERVER
          fi
	  
	  if [[ ${SELECTION} == "4" ]]
          then
                read -p "Enter database backup location:" BACKUP_LOC
                read -p "Enter the runner's name:" RUNNER
                read -p "Enter the database name:" DATABASE
		#read -p "Enter the parfile location name:" PARFILE_LOC
          fi

fi

case ${SELECTION} in
  1) echo "You selected the backup function.."
    f_d_backup ${CONTROL_FLAG} ${SELECTION} ${SOURCE_FILE} ${BACKUP_DESTINATION} ${RUNNER} ${BACKUP_TYPE} ${LOG_FILE};;

  2) echo "You selected the delete function..."
    f_d_delete ${CONTROL_FLAG} ${SELECTION} ${DEL_DESTINATION} ${RUNNER} ${FILE_DEL_TYPE} ${LOG_FILE};;

  3) echo "You selected the secure copy function..."
    scp_f_d_ ${CONTROL_FLAG} ${SELECTION} ${SOURCE_FILE} ${BACKUP_DESTINATION} ${RUNNER} ${DST_SERVER};;

  4) echo "You selected the logical backup function..."
    database_export_ ${CONTROL_FLAG} ${SELECTION} ${BACKUP_LOC} ${RUNNER} ${DATABASE};;

  *) echo "You made a wrong selection..Try again";;
esac
















