#########################################################################################
# deploy-saleor.sh
# Author:       Aaron K. Nall   http://github.com/thewhiterabbit
#########################################################################################
#!/bin/bash
set -e

#########################################################################################
# Get the actual user that logged in
#########################################################################################
# UN="$(ls -l `tty` | awk '{print $3}')"
UN="kiet"
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
sudo echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 2048 | head -n 1) >/etc/saleor/api_sk
sudo openssl genrsa -out /etc/saleor/rsa 3072
sudo chmod 644 /etc/saleor/rsa
#########################################################################################

#########################################################################################
# Set variables for the password, obfuscation string, and user/database names
#########################################################################################
# Generate an 8 byte obfuscation string for the database name & username
OBFSTR=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
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
VERSION=""
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
        sudo -u $UN python3.9 -m venv $HD/env/saleor
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
sudo -u $UN git clone https://github.com/saleor/saleor.git
wait
# Make sure we're in the project root directory for Saleor
cd $HD/saleor
wait
# Was the -v (version) option used?
if [ "$VERSION" != "" ]; then
        # Checkout the specified version
        sudo -u $UN git checkout $VERSION
        wait
fi
#sudo -u $UN cp $HD/django/saleor/asgi.py $HD/saleor/saleor/
#sudo -u $UN cp $HD/django/saleor/wsgi.py $HD/saleor/saleor/
#sudo -u $UN cp $HD/saleor/saleor/wsgi/__init__.py $HD/saleor/saleor/wsgi.py
# if [ ! -d "$HD/run" ]; then
#         sudo -u $UN mkdir $HD/run
# else
#         if [ -f "$HD/run/saleor.sock" ]; then
#                 sudo rm $HD/run/saleor.sock
#         fi
# fi
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
# if [ -f "$HD/saleor/saleor/settings.py" ]; then
#         sudo rm $HD/saleor/saleor/settings.py
# fi
# sudo cp $HD/Deploy_Saleor/resources/saleor/settings.py $HD/saleor/saleor/settings.py
# wait
# Tell the user what's happening
echo "Creating production deployment packages for Saleor API & GraphQL..."
echo ""
#########################################################################################
# Setup the environment variables for Saleor API
#########################################################################################
# Build the database URL
DB_URL="postgres://$PGSQLUSER:$PGSQLUSERPASS@$PGDBHOST:$DBPORT/$PGSQLDBNAME"
DB_REPL="postgres://$PGSQLUSER_READ:$PGSQLUSERPASS@$PGDBHOST:$DBPORT/$PGSQLDBNAME"
EMAIL_URL="smtp://$EMAIL:$EMAIL_PW@$EMAIL_HOST:/?ssl=True"
API_HOST=$(hostname -i)
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
          s/{gqlorigins}/$QL_ORIGINS/" $HD/Deploy_Saleor/resources/saleor/template.env >$HD/saleor/.env
wait
#########################################################################################

#########################################################################################
# Copy the uwsgi_params file to /saleor/uwsgi_params
#########################################################################################
#########################################################################################

#########################################################################################
# Install Saleor for production
#########################################################################################
# Activate the virtual environment
source $HD/env/saleor/bin/activate
# Update npm
npm install npm@latest
wait
# Make sure pip is upgraded
curl -sL https://bootstrap.pypa.io/get-pip.py | python3 -
wait
# Install the project requirements
pip3 install -r requirements.txt
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

sudo chown -R $UN:nginx $HD/saleor
wait
deactivate
#########################################################################################
sudo usermod -a -G nginx $UN
# sudo chown -R $UN:nginx $HD
# sudo chmod -R 775 $HD

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
# if [ "$SAME_HOST" = "no" ]; then
#         sed "s|{rm_app_host}|sudo rm -R /usr/share/nginx/$APP_HOST|g
#              s|{host}|$HOST|
#              s|{gql_port}|$GQL_PORT|
#              s|{api_port}|$API_PORT|" $HD/Deploy_Saleor/template.undeploy >$HD/Deploy_Saleor/undeploy.sh
#         wait
# else
#         BLANK=""
#         sed "s|{rm_app_host}|$BLANK|g
#              s|{host}|$HOST|
#              s|{gql_port}|$GQL_PORT|
#              s|{api_port}|$API_PORT|" $HD/Deploy_Saleor/template.undeploy >$HD/Deploy_Saleor/undeploy.sh
#         wait
# fi
#########################################################################################

#########################################################################################
# Tell the user what's happening
#########################################################################################
echo "I think we're done here."
echo "Test the installation."
#########################################################################################