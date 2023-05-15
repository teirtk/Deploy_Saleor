#########################################################################################
echo ""
echo "Creating production deployment packages for Saleor Dashboard..."
echo ""
#########################################################################################



#########################################################################################
# Collect input from the user to assign required installation parameters
#########################################################################################
echo "Please provide details for your Saleor Dashboard installation..."
echo ""
# Get the Dashboard & GraphQL host domain
# while [ "$SAME_HOST" = "" ]
# do
#         echo -n "Are you hosting the Dashboard on the same host domain as the API (yes|no)?"
#         read SAME_HOST
# done
# # Get the API host IP or domain
# if [ "$SAME_HOST" = "no" ]; then
#         while [ "$APP_HOST" = "" ]
#         do
#                 echo ""
#                 echo -n "Enter the Dashboard host domain:"
#                 read APP_HOST
#         done
# fi
# Get the APP Mount (Dashboard) URI
APP_MOUNT_URI="dashboard"
# while [ "$APP_MOUNT_URI" = "" ]
# do
#         echo ""
#         echo -n "Enter the APP Mount (Dashboard) URI:"
#         read APP_MOUNT_URI
# done
#########################################################################################



#########################################################################################
# Clone the git and setup the environment variables for Saleor API & Dashboard install
#########################################################################################
# Make sure we're in the user's home directory
cd $HD
# Clone the Saleor Dashboard Git repository
if [ -d "$HD/saleor-dashboard" ]; then
        sudo rm -R $HD/saleor-dashboard
fi
sudo -u $UN git clone https://github.com/saleor/saleor-dashboard.git
wait
# Build the API URL
API_URL="http://$HOST/$APIURI/"
# Write the production .env file from template.env
if [ "$SAME_HOST" = "no" ]; then
        sudo sed "s|{api_url}|$API_URL|
                s|{app_mount_uri}|$APP_MOUNT_URI|
                s|{app_host}|$APP_HOST/$APP_MOUNT_URI|" $HD/Deploy_Saleor/resources/saleor-dashboard/template.env > $HD/saleor-dashboard/.env
        wait
else
        sudo sed "s|{api_url}|$API_URL|
                s|{app_mount_uri}|$APP_MOUNT_URI|
                s|{app_host}|$HOST/$APP_MOUNT_URI|" $HD/Deploy_Saleor/resources/saleor-dashboard/template.env > $HD/saleor-dashboard/.env
        wait
fi
#########################################################################################



#########################################################################################
# Build Saleor Dashboard for production
#########################################################################################
# Make sure we're in the project root directory
cd saleor-dashboard
# Was the -v (version) option used?
VERSION="3.13.2"
if [ "vOPT" = "true" ] || [ "$VERSION" != "" ]; then
        sudo -u $UN git checkout $VERSION
fi
# Update npm
# npm install -g npm@latest
# wait
# Install dependancies
sudo -u $UN npm i
wait
npm audit fix --force
wait
sudo -u $UN npm run build
wait
#########################################################################################


#########################################################################################
# Setup the nginx block and move the static build files
#########################################################################################
echo "Moving static files for the Dashboard..."
echo ""
if [ "$SAME_HOST" = "no" ]; then
        # Move static files for the Dashboard
        sudo mv $HD/saleor-dashboard/build/$APP_MOUNT_URI /usr/share/nginx/$APP_HOST/
        # Make an empry variable
        DASHBOARD_LOCATION=""
        # Clean the saleor server block
        sudo sed -i "s#{dl}#$DASHBOARD_LOCATION#" /etc/nginx/conf.d/saleor
        # Create the saleor-dashboard server block
        sudo sed "s|{hd}|$HD|g
                  s/{app_mount_uri}/$APP_MOUNT_URI/g
                  s/{host}/$APP_HOST/g" $HD/Deploy_Saleor/resources/saleor-dashboard/server_block > /etc/nginx/conf.d/saleor-dashboard
        wait
        sudo chown -R nginx /usr/share/nginx/$APP_HOST
else
        # Move static files for the Dashboard
        sudo mv $HD/saleor-dashboard/build/$APP_MOUNT_URI /usr/share/nginx/$HOST/
        # Populate the DASHBOARD_LOCATION variable
        DASHBOARD_LOCATION=$(<$HD/Deploy_Saleor/resources/saleor-dashboard/dashboard-location)
        # Modify the new server block
        sudo sed -i "s#{dl}#$DASHBOARD_LOCATION#" /etc/nginx/conf.d/saleor
        wait
        # Modify the new server block again
        sudo sed -i "s|{hd}|$HD|g
                     s|{app_mount_uri}|$APP_MOUNT_URI|g
                     s|{host}|$HOST|g" /etc/nginx/conf.d/saleor
        wait
fi
sudo systemctl restart nginx
#########################################################################################
