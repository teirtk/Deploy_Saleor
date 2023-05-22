#########################################################################################
# deploy-saleor.sh
# Author:       Aaron K. Nall   http://github.com/thewhiterabbit
#########################################################################################
#!/bin/sh
set -e

#########################################################################################
# Get the actual user that logged in
#########################################################################################
UN="$(ls -l `tty` | awk '{print $3}')"
if [[ "$UN" != "root" ]]; then
        HD="/home/$UN"
else
        HD="/root"
fi
cd $HD
#########################################################################################



#########################################################################################
# Get the operating system
#########################################################################################
IN=$(uname -a)
arrIN=(${IN// / })
IN2=${arrIN[3]}
arrIN2=(${IN2//-/ })
# OS=${arrIN2[1]}
OS="Ubuntu"
#########################################################################################

#########################################################################################
# Generate a secret key file
#########################################################################################
# Create randomized 2049 byte key file
if [ ! -d "/etc/saleor" ]; then
        sudo mkdir /etc/saleor
else
        # Does the key file exist?
        if [ -f "/etc/saleor/api_sk" ]; then
                # Yes, remove it.
                sudo rm /etc/saleor/api_sk
        fi
fi
sudo echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 2048| head -n 1) > /etc/saleor/api_sk
sudo openssl genrsa -out /etc/saleor/rsa 3072
#########################################################################################

#########################################################################################
# Set variables for the password, obfuscation string, and user/database names
#########################################################################################
# Generate an 8 byte obfuscation string for the database name & username 
OBFSTR=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8| head -n 1)
# Append the database name for Saleor with the obfuscation string
PGSQLDBNAME="saleor_db_$OBFSTR"
# Append the database username for Saleor with the obfuscation string
PGSQLUSER="saleor_dbu_$OBFSTR"
# Generate a 128 byte password for the Saleor database user
# TODO: Add special characters once we know which ones won't crash the python script
PGSQLUSERPASS=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 128 | head -n 1)
PGSQLUSER_READ="saleor_$OBFSTR"
#########################################################################################



#########################################################################################
# Tell the user what's happening
#########################################################################################
echo "Finished setting up security feature details"
echo ""
sleep 2
echo "Creating database..."
echo ""
sleep 2
#########################################################################################



#########################################################################################
# Create a superuser for Saleor
#########################################################################################
# Create the role in the database and assign the generated password
sudo -i -u postgres psql -c "CREATE ROLE $PGSQLUSER PASSWORD '$PGSQLUSERPASS' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;"
# Create the database for Saleor
sudo -i -u postgres psql -c "CREATE DATABASE $PGSQLDBNAME;"
# TODO - Secure the postgers user account
sudo -i -u postgres psql -c "CREATE USER $PGSQLUSER_READ WITH PASSWORD '$PGSQLUSERPASS';"
sudo -i -u postgres psql -c "GRANT CONNECT ON DATABASE $PGSQLDBNAME TO $PGSQLUSER_READ;"
sudo -i -u postgres psql -c "GRANT USAGE ON SCHEMA public TO $PGSQLUSER_READ;"
sudo -i -u postgres psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO $PGSQLUSER_READ;"
sudo -i -u postgres psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $PGSQLUSER_READ;"
#########################################################################################



#########################################################################################
# Tell the user what's happening
#########################################################################################
echo "Finished creating database" 
echo ""
sleep 2
#########################################################################################



#########################################################################################
# Collect input from the user to assign required installation parameters
#########################################################################################
echo "Please provide details for your Saleor API instillation..."
echo ""
# Get the API host domain
HOST="localhost"
ADMIN_EMAIL="admin@dmt.com"
ADMIN_PASS="vmtriet"
# while [ "$HOST" = "" ]
# do
#         echo -n "Enter the API host domain:"
#         read HOST
# done
# Get an optional custom Static URL
# if [ "$STATIC_URL" = "" ]; then
        # echo -n "Enter a custom Static Files URI (optional):"
        # read STATIC_URL
        # if [ "$STATIC_URL" != "" ]; then
                # STATIC_URL="/$STATIC_URL/"
        # fi
# else
#         STATIC_URL="/$STATIC_URL/"
# fi
# Get an optional custom media URL
# if [ "$MEDIA_URL" = "" ]; then
        # echo -n "Enter a custom Media Files URI (optional):"
        # read MEDIA_URL
        # if [ "$MEDIA_URL" != "" ]; then
                # MEDIA_URL="/$MEDIA_URL/"
        # fi
# else
#         MEDIA_URL="/$MEDIA_URL/"
# fi
# Get the Admin's email address
# while [ "$ADMIN_EMAIL" = "" ]
# do
#         echo ""
#         echo -n "Enter the Dashboard admin's email:"
#         read ADMIN_EMAIL
# done
# # Get the Admin's desired password
# while [ "$ADMIN_PASS" = "" ]
# do
#         echo ""
#         echo -n "Enter the Dashboard admin's desired password:"
#         read -s ADMIN_PASS
# done
#########################################################################################



#########################################################################################
# Set default and optional parameters
#########################################################################################
if [ "$PGDBHOST" = "" ]; then
        PGDBHOST="localhost"
fi
#
if [ "$DBPORT" = "" ]; then
        DBPORT="5432"
fi
#
if [[ "$GQL_PORT" = "" ]]; then
        GQL_PORT="9000"
fi
#
if [[ "$API_PORT" = "" ]]; then
        API_PORT="8000"
fi
#
if [ "$APIURI" = "" ]; then
        APIURI="graphql" 
fi
#
if [ "$vOPT" = "true" ]; then
        if [ "$VERSION" = "" ]; then
                VERSION="3.13.12"
        fi
else
        VERSION="3.13.12"
fi
#
if [ "$STATIC_URL" = "" ]; then
        STATIC_URL="/static/" 
fi
#
if [ "$MEDIA_URL" = "" ]; then
        MEDIA_URL="/media/" 
fi
#########################################################################################



#########################################################################################
# Open the selected ports for the API and APP
#########################################################################################
# Open GraphQL port
sudo ufw allow $GQL_PORT
# Open API port
sudo ufw allow $API_PORT
#########################################################################################



#########################################################################################
# Create virtual environment directory
if [ ! -d "$HD/env" ]; then
        sudo -u $UN mkdir $HD/env
        wait
fi
# Does an old virtual environment for Saleor exist?
if [ ! -d "$HD/env/saleor" ]; then
        # Create a new virtual environment for Saleor
        sudo -u $UN python3 -m venv $HD/env/saleor
        wait
fi
#########################################################################################



#########################################################################################
# Clone the Saleor Git repository
#########################################################################################
# Make sure we're in the user's home directory
cd $HD
# Does the Saleor Dashboard already exist?
if [ -d "$HD/saleor" ]; then
        # Remove /saleor directory
        sudo rm -R $HD/saleor
        wait
fi
#
echo "Cloning Saleor from github..."
echo ""
# Check if the -v (version) option was used
if [ "$vOPT" = "true" ]; then
        # Get the Mirumee repo
        sudo -u $UN git clone https://github.com/saleor/saleor.git
else
        # Was a repo specified?
        if [ "$REPO" = "saleor" ]; then
                # Get the Mirumee repo
                sudo -u $UN git clone https://github.com/saleor/saleor.git
        else
                # Get the Mirumee repo
                sudo -u $UN git clone https://github.com/saleor/saleor.git

                ###### For possible later use ######
                # Get the forked repo from thewhiterabbit
                #git clone https://github.com/saleor/saleor.git
                ###### For possible later use ######
        fi
fi
wait
# Make sure we're in the project root directory for Saleor
cd $HD/saleor
wait
# Was the -v (version) option used?
if [ "vOPT" = "true" ] || [ "$VERSION" != "" ]; then
        # Checkout the specified version
        sudo -u $UN git checkout $VERSION
        wait
fi
#sudo -u $UN cp $HD/django/saleor/asgi.py $HD/saleor/saleor/
#sudo -u $UN cp $HD/django/saleor/wsgi.py $HD/saleor/saleor/
#sudo -u $UN cp $HD/saleor/saleor/wsgi/__init__.py $HD/saleor/saleor/wsgi.py
if [ ! -d "$HD/run" ]; then
        sudo -u $UN mkdir $HD/run
else
        if [ -f "$HD/run/saleor.sock" ]; then
                sudo rm $HD/run/saleor.sock
        fi
fi
#########################################################################################



#########################################################################################
# Tell the user what's happening
#########################################################################################
echo "Github cloning complete"
echo ""
sleep 2
#########################################################################################



#########################################################################################
# Replace any parameter slugs in the template files with real paramaters & write them to
# the production files
#########################################################################################
# Replace the settings.py with the production version
if [ -f "$HD/saleor/saleor/settings.py" ]; then
        sudo rm $HD/saleor/saleor/settings.py
fi
sudo cp $HD/Deploy_Saleor/resources/saleor/settings.py $HD/saleor/saleor/settings.py
# # Replace the populatedb.py file with the production version
# if [ -f "$HD/saleor/saleor/core/management/commands/populatedb.py" ]; then
#         sudo rm $HD/saleor/saleor/core/management/commands/populatedb.py
# fi
# sudo cp $HD/Deploy_Saleor/resources/saleor/populatedb.py $HD/saleor/saleor/core/management/commands/populatedb.py
# Replace the test_core.py file with the production version
#if [ -f "$HD/saleor/saleor/core/tests/test_core.py" ]; then
#        sudo rm $HD/saleor/saleor/core/tests/test_core.py
#fi
#sudo cp $HD/Deploy_Saleor/resources/saleor/test_core.py $HD/saleor/saleor/core/tests/
wait
# Does an old saleor.service file exist?
if [ -f "/etc/systemd/system/saleor.service" ]; then
        # Remove the old service file
        sudo rm /etc/systemd/system/saleor.service
fi
###### This following section is for future use and will be modified to allow an alternative repo clone ######
# Was the -v (version) option used or Mirumee repo specified?
if [ "vOPT" = "true" ] || [ "$REPO" = "saleor" ]; then
        # Create the saleor service file
        sudo sed "s/{un}/$UN/
                  s|{hd}|$HD|g" $HD/Deploy_Saleor/resources/saleor/template.service > /etc/systemd/system/saleor.service
        wait
        # Does an old server block exist?
        if [ -f "/etc/nginx/conf.d/saleor" ]; then
                # Remove the old service file
                sudo rm /etc/nginx/conf.d/saleor
        fi
        # Create the saleor server block
        sudo sed "s|{hd}|$HD|g
                  s/{host}/$HOST/g
                  s|{static}|$STATIC_URL|g
                  s|{media}|$MEDIA_URL|g" $HD/Deploy_Saleor/resources/saleor/server_block > /etc/nginx/conf.d/saleor
        wait
else
        # Create the new service file
        sudo sed "s/{un}/$UN/
                  s|{hd}|$HD|g" $HD/Deploy_Saleor/resources/saleor/template.service > /etc/systemd/system/saleor.service
        wait
        # Does an old server block exist?
        if [ -f "/etc/nginx/conf.d/saleor" ]; then
                # Remove the old service file
                sudo rm /etc/nginx/conf.d/saleor
        fi
        # Create the new server block
        sudo sed "s|{hd}|$HD|g
                  s/{api_host}/$API_HOST/
                  s/{host}/$HOST/g
                  s|{static}|$STATIC_URL|g
                  s|{media}|$MEDIA_URL|g
                  s/{api_port}/$API_PORT/" $HD/Deploy_Saleor/resources/saleor/server_block > /etc/nginx/conf.d/saleor
        wait
fi
# Create the production uwsgi initialization file
sudo sed "s|{hd}|$HD|g
          s/{un}/$UN/" $HD/Deploy_Saleor/resources/saleor/template.uwsgi > $HD/saleor/saleor/wsgi/prod.ini
if [ -d "/usr/share/nginx/$HOST" ]; then
        sudo rm -R /usr/share/nginx/$HOST
        wait
fi
# Create the host directory in /usr/share/nginx/
sudo mkdir /usr/share/nginx/$HOST
wait
# Create the media directory
sudo mkdir /usr/share/nginx/$HOST$MEDIA_URL
# Static directory will be moved into /usr/share/nginx/$HOST/ after collectstatic is performed
#########################################################################################



#########################################################################################
# Tell the user what's happening
echo "Creating production deployment packages for Saleor API & GraphQL..."
echo ""
#########################################################################################



#########################################################################################
# Setup the environment variables for Saleor API
#########################################################################################
# Build the database URL
DB_URL="postgres://$PGSQLUSER:$PGSQLUSERPASS@$PGDBHOST:$DBPORT/$PGSQLDBNAME"
DB_REPL="postgres://$PGSQLUSER_READ:$PGSQLUSERPASS@$PGDBHOST:$DBPORT/$PGSQLDBNAME"
EMAIL_URL="smtp://$EMAIL:$EMAIL_PW@$EMAIL_HOST:/?ssl=True"
API_HOST=$(hostname -i);
# Build the chosts and ahosts lists
C_HOSTS="$HOST,$API_HOST,localhost,127.0.0.1"
A_HOSTS="$HOST,$API_HOST,localhost,127.0.0.1"
QL_ORIGINS="$HOST,$API_HOST,localhost,127.0.0.1"
# Write the production .env file from template.env
sudo sed "s|{dburl}|$DB_URL|
          s|{repl}|$DB_REPL|
          s|{emailurl}|$EMAIL_URL|
          s/{chosts}/$C_HOSTS/
          s/{ahosts}/$A_HOSTS/
          s/{host}/$HOST/g
          s|{static}|$STATIC_URL|g
          s|{media}|$MEDIA_URL|g
          s/{adminemail}/$ADMIN_EMAIL/
          s/{gqlorigins}/$QL_ORIGINS/" $HD/Deploy_Saleor/resources/saleor/template.env > $HD/saleor/.env
wait
#########################################################################################



#########################################################################################
# Copy the uwsgi_params file to /saleor/uwsgi_params
#########################################################################################
sudo cp $HD/Deploy_Saleor/resources/saleor/uwsgi_params $HD/saleor/uwsgi_params
#########################################################################################



#########################################################################################
# Install Saleor for production
#########################################################################################
# Does an old virtual environment vassals for Saleor exist?
if [ -d "$HD/env/saleor/vassals" ]; then
        sudo rm -R $HD/env/saleor/vassals
        wait
fi
# Create vassals directory in virtual environment
sudo -u $UN mkdir $HD/env/saleor/vassals
wait
# Simlink to the prod.ini
sudo ln -s $HD/saleor/saleor/wsgi/prod.ini $HD/env/saleor/vassals
wait
# Activate the virtual environment
source $HD/env/saleor/bin/activate
# Update npm
npm install npm@latest
wait
# Make sure pip is upgraded
python3 -m pip install --upgrade pip
wait
# Install Django
pip3 install Django
wait
# Create a Temporary directory to generate some files we need
#sudo -u $UN mkdir $HD/django
#cd django
# Create the project folder
#sudo -u $UN django-admin.py startproject saleor
# Install uwsgi
pip3 install uwsgi
wait
# Install the project requirements
pip3 install -r requirements.txt
wait
# Install the decoupler for .env file
pip3 install python-decouple
wait
# Set any secret Environment Variables
export ADMIN_PASS="$ADMIN_PASS"
# Install the project
npm install
wait
# Run an audit to fix any vulnerabilities
#sudo -u $UN npm audit fix
#wait
# Establish the database
python3 manage.py migrate
wait
python3 manage.py populatedb --createsuperuser
wait
# Collect the static elemants
python3 manage.py collectstatic
wait
# Build the schema
npm run build-schema
wait
# Build the emails
# npm run build-emails
# wait
# Exit the virtual environment here? _#_
deactivate
# Set ownership of the app directory to $UN:nginx
sudo chown -R $UN:nginx $HD/saleor
wait
# Run the uwsgi socket and create it for the first time
sudo uwsgi --ini $HD/saleor/saleor/wsgi/uwsgi.ini --uid nginx --gid nginx --pidfile $HD/saleortemp.pid
sleep 5
# Stop the uwsgi processes
uwsgi --stop $HD/saleortemp.pid
# Move static files to /usr/share/nginx/$HOST
echo HOST
sudo mv $HD/saleor/static /usr/share/nginx/${HOST}${STATIC_URL}
sudo chown -R nginx:nginx /usr/share/nginx/$HOST
#sudo chmod -R 776 /usr/share/nginx/$HOST
#########################################################################################



#########################################################################################
# Tell the user what's happening
#########################################################################################
echo ""
echo "Finished creating production deployment packages for Saleor API & GraphQL"
echo ""
#########################################################################################



#########################################################################################
# Call the dashboard deployment script - Disabled until debugged
#########################################################################################
source $HD/Deploy_Saleor/deploy-dashboard.sh
#########################################################################################


#########################################################################################
# Enable the Saleor service
#########################################################################################
# Enable
sudo systemctl enable saleor.service
# Reload the daemon
sudo systemctl daemon-reload
# Start the service
sudo systemctl start saleor.service
#########################################################################################



#########################################################################################
# Tell the user what's happening
echo "Creating undeploy.sh for undeployment scenario..."
#########################################################################################
if [ "$SAME_HOST" = "no" ]; then
        sed "s|{rm_app_host}|sudo rm -R /usr/share/nginx/$APP_HOST|g
             s|{host}|$HOST|
             s|{gql_port}|$GQL_PORT|
             s|{api_port}|$API_PORT|" $HD/Deploy_Saleor/template.undeploy > $HD/Deploy_Saleor/undeploy.sh
        wait
else
        BLANK=""
        sed "s|{rm_app_host}|$BLANK|g
             s|{host}|$HOST|
             s|{gql_port}|$GQL_PORT|
             s|{api_port}|$API_PORT|" $HD/Deploy_Saleor/template.undeploy > $HD/Deploy_Saleor/undeploy.sh
        wait
fi
#########################################################################################



#########################################################################################
# Tell the user what's happening
#########################################################################################
echo "I think we're done here."
echo "Test the installation."
#########################################################################################