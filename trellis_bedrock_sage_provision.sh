#!/bin/bash

# trellis bedrock sage

# http://linuxconfig.org/bash-scripting-tutorial
# use predefined variables to access passed arguments
#echo arguments to the shell
#echo $1 $2 $3 ' -> echo $1 $2 $3'

# We can also store arguments from bash command line in special array
#args=("$@")
#echo arguments to the shell
#echo $DOMAIN_NAME $ADMIN_EMAIL $STAGING_IP_ADDRESS ' -> args=("$@"); echo $DOMAIN_NAME $ADMIN_EMAIL $STAGING_IP_ADDRESS'

#use $@ to print out all arguments at once
#echo $@ ' -> echo $@'

# use $# variable to print out
# number of arguments passed to the bash script
#echo Number of arguments passed: $# ' -> echo Number of arguments passed: $#'

# Create Arguments Array
args=("$@")

# Setting variables based on args ./... <GITHUB_USER> <DOMAIN_NAME> <TLD> <REPO_NAME> <ADMIN_EMAIL> <STAGING_IP_ADDRESS> <PRODUCTION_IP_ADDRESS>
GITHUB_USER="${args[0]}"
DOMAIN_NAME="${args[1]}"
TLD="${args[2]}"
REPO_NAME="${args[3]}"
ADMIN_EMAIL="${args[4]}"
STAGING_IP_ADDRESS="${args[5]}"
PRODUCTION_IP_ADDRESS="${args[6]}"

# Function Declarations
function paranoia {
  openssl rand -base64 $1
}

# Move to wordpress directory inside of apps directory
cd ~/apps/wordpress

# Create and Navigate to the app directory from the first argument provided
mkdir $REPO_NAME && cd $REPO_NAME

# Clone into Trellis and remove the existing git history
git clone --depth=1 git@github.com:roots/trellis.git trellis && rm -rf trellis/.git

# Clone into Beadrock and remove the existing git history
git clone --depth=1 git@github.com:roots/bedrock.git site && rm -rf site/.git

# Clone into Sage, Rename to first argument provided and remvove existing git history
# Temporarily specifying latest stable branch until version 9 is ready for production
git clone -b 8.5.0 git@github.com:roots/sage.git site/web/app/themes/$REPO_NAME && rm -rf site/web/app/themes/$REPO_NAME/.git

# Set the WP_DEFAULT_THEME to the first argument provided
# WP_DEFAULT_THEME_STR=$'define('DISALLOW_FILE_EDIT', true);n define('WP_DEFAULT_THEME', '$DOMAIN_NAME');'
# sed -i '' "s|define('DISALLOW_FILE_EDIT', true);||g" site/config/application.php
sed -i '' "s|define('DISALLOW_FILE_EDIT', true);|define('DISALLOW_FILE_EDIT', true);\
define('WP_DEFAULT_THEME', '$REPO_NAME');|g" site/config/application.php

# Move into Ansible directory and run the Install Script
cd trellis && ansible-galaxy install -r requirements.yml
echo "Running ansible requirements.yml"

# Begin Trellis Config
# Update wordpress_sites.yml for staging environments
#
touch .vault_pass
#
VAULT_PASS=$(paranoia 18)
#
echo $VAULT_PASS > .vault_pass
#
chmod 600 .vault_pass

#######
# All #
#######
echo "Configuring Mail PW for All"
#
VAULT_MAIL_PASS=$(paranoia 18)
#
sed -i '' "s|: smtp_password|: $VAULT_MAIL_PASS|g" group_vars/all/vault.yml

###############
# Development #
###############
echo "Configuring wordpress_sites for development"
#
DEV_VAULT_MYSQL_ROOT_PASS=$(paranoia 18)
#
DEV_VAULT_USERS_PASS=$(paranoia 18)
#
DEV_VAULT_USERS_DB_PASS=$(paranoia 18)
#
sed -i '' "s|: devpw|: $DEV_VAULT_MYSQL_ROOT_PASS|g" group_vars/development/vault.yml
#
sed -i '' "s|: admin|: $DEV_VAULT_USERS_PASS|g" group_vars/development/vault.yml
#
sed -i '' "s|: example_dbpassword|: $DEV_VAULT_USERS_DB_PASS|g" group_vars/development/vault.yml
# Update Project name to first argument provided
sed -i '' "s|example\.com|$DOMAIN_NAME$TLD|g" group_vars/development/wordpress_sites.yml
#
sed -i '' "s|example|$DOMAIN_NAME|g" group_vars/development/mail.yml
#
sed -i '' "s|example|$DOMAIN_NAME|g" group_vars/development/vault.yml
# Update admin_email to second argument provided
sed -i '' "s|admin_email: admin@example\.dev|admin_email: $ADMIN_EMAIL|g" group_vars/development/wordpress_sites.yml
# Update hostname site urls for development environment
sed -i '' "s|example\.dev|$REPO_NAME\.dev|g" group_vars/development/wordpress_sites.yml
# Update site_title to first argument provided
sed -i '' "s|site_title: Example Site|site_title: $DOMAIN_NAME app|g" group_vars/development/wordpress_sites.yml

###########
# Staging #
###########
echo "Configuring wordpress_sites for staging"
#
STAGE_VAULT_MYSQL_ROOT_PASS=$(paranoia 18)
#
STAGE_VAULT_USERS_PASS=$(paranoia 18)
#
STAGE_VAULT_USERS_DB_PASS=$(paranoia 18)
#
sed -i '' "s|: stagingpw|: $STAGE_VAULT_MYSQL_ROOT_PASS|g" group_vars/staging/vault.yml
#
sed -i '' "s|: example_password|: $STAGE_VAULT_USERS_PASS|g" group_vars/staging/vault.yml
#
sed -i '' "s|: example_dbpassword|: $STAGE_VAULT_USERS_DB_PASS|g" group_vars/staging/vault.yml
#
STAGING_URL="staging\.$DOMAIN_NAME$TLD"
#
sed -i '' "s|staging\.example\.com|$STAGING_URL|g" group_vars/staging/vault.yml
#
sed -i '' "s|example\.com|$STAGING_URL|g" group_vars/staging/vault.yml
# Update repository to a Discrete Units Organization Repo
sed -i '' "s|git@github\.com:example/example\.com.git|git@github\.com:$GITHUB_USER/$REPO_NAME\.git|g" group_vars/staging/wordpress_sites.yml
# Update Project name to first argument provided
sed -i '' "s|example\.com|$STAGING_URL|g" group_vars/staging/wordpress_sites.yml
# Update site_title to first argument provided
sed -i '' "s|site_title: Example Site|site_title: $DOMAIN_NAME app|g" group_vars/staging/wordpress_sites.yml
# Update to second argument provided
sed -i '' "s|admin_email: admin@example\.dev|admin_email: $ADMIN_EMAIL|g" group_vars/staging/wordpress_sites.yml
# Uncomment subtree_path when using trellis directory structure
sed -i '' "s|# subtree_path: site|subtree_path: site|g" group_vars/staging/wordpress_sites.yml
# Update hosts for Staging
sed -i '' "s|your_server_hostname|$STAGING_IP_ADDRESS|g" hosts/staging

##############
# Production #
##############
echo "Configuring wordpress_sites for production"
#
PROD_VAULT_MYSQL_ROOT_PASS=$(paranoia 18)
#
PROD_VAULT_USERS_PASS=$(paranoia 18)
#
PROD_VAULT_USERS_DB_PASS=$(paranoia 18)
#
sed -i '' "s|: productionpw|: $PROD_VAULT_MYSQL_ROOT_PASS|g" group_vars/production/vault.yml
#
sed -i '' "s|: example_password|: $PROD_VAULT_USERS_PASS|g" group_vars/production/vault.yml
#
sed -i '' "s|: example_dbpassword|: $PROD_VAULT_USERS_DB_PASS|g" group_vars/production/vault.yml
#
sed -i '' "s|example\.com|$DOMAIN_NAME$TLD|g" group_vars/production/vault.yml
# Update repository to a Discrete Units Organization Repo
sed -i '' "s|git@github\.com:example/example\.com.git|git@github\.com:$GITHUB_USER/$REPO_NAME.git|g" group_vars/production/wordpress_sites.yml
# Update Project name to first argument provided
sed -i '' "s|example\.com|$DOMAIN_NAME$TLD|g" group_vars/production/wordpress_sites.yml
# Update site_title to first argument provided
sed -i '' "s|site_title: Example Site|site_title: $DOMAIN_NAME app|g" group_vars/production/wordpress_sites.yml
# Update to second argument provided
sed -i '' "s|admin_email: admin@example.dev|admin_email: $ADMIN_EMAIL|g" group_vars/production/wordpress_sites.yml
# Uncomment subtree_path when using trellis directory structure
sed -i '' "s|# subtree_path: site|subtree_path: site|g" group_vars/production/wordpress_sites.yml
# Update hosts for Production with third argument provided
sed -i '' "s|your_server_hostname|$PRODUCTION_IP_ADDRESS|g" hosts/production

#########
# Salts #
#########
# Leverage WP CLI Package
# NOTE: This will most likely have to be done manually or with an executable php script :D

#################
# Ansible Vault #
#################
# NOTE: This is dependent on the above step being automated :\
# ansible-vault encrypt group_vars/all/vault.yml group_vars/development/vault.yml group_vars/staging/vault.yml group_vars/production/vault.yml

#####################
# Sage Theme Config #
#####################

# Back out of trellis directory
cd ../

# Add Default Plugins
sed -i '' 's|"roots/wp-password-bcrypt": "1.0.0"|"roots/wp-password-bcrypt": "1.0.0",\
    "roots/soil": "3.7.1",\
    "wpackagist-plugin/wordpress-seo": "3.7.1",\
    "wpackagist-plugin/custom-post-type-ui": "1.4.3"|g' site/composer.json

# Update site url in manifest.json
sed -i '' "s|http:\/\/example\.dev|http:\/\/$REPO_NAME\.dev|g" site/web/app/themes/$REPO_NAME/assets/manifest.json

# Navigate to theme directory
cd site/web/app/themes/$REPO_NAME
# Install node modules
npm install
# Install bower packages
bower install
# Build theme assets
gulp

# Navigate to root directory
cd ../../../../../../$REPO_NAME
# cd ../../../../../
# Initialize Git Repository
git init
# Add codebase
git add .
# Commit codebase
git commit -m "first commit, adding trellis, beadrock, and sage files from provision script."
# Add origin
git remote add origin git@github.com:$GITHUB_USER/$REPO_NAME.git
# Push to master branch
# git push -u origin master

# Navigate to trellis directory
cd trellis
# Vagrant
vagrant up
#
# vagrant ssh
#
# cd /srv/www/$DOMAIN_NAME$TLD
#
# composer update
#
# wp package install sebastiaandegeus/wp-cli-salts-command
#
# wp salts generate
#

#

#$ ansible-playbook server.yml -e env=<environment>

# Provision Staging Server
# ansible-playbook -i '' hosts/staging server.yml
#ansible-playbook server.yml -e env=staging
# Provision Production Server
# ansible-playbook -i '' hosts/production server.yml
#ansible-playbook server.yml -e env=production

#ansible-playbook deploy.yml -e "site=roots-example-project.com env=<environment>"

# Deploy to Staging Server
# ./deploy.sh staging $DOMAIN_NAME.com
#ansible-playbook deploy.yml -e "site=$STAGING_URL env=staging"

# Deploy to Production Server
#./deploy.sh production $DOMAIN_NAME.com
#ansible-playbook deploy.yml -e "site=$DOMAIN_NAME.com env=production"


#
cd ../site/web/app/themes/$REPO_NAME
# Turn on gulp to watch for changes and fire up browsersync
gulp watch
#
echo "VAULT_PASS: ${VAULT_PASS}"
echo "VAULT_MAIL_PASS: ${VAULT_PASS}"
echo "DEV_VAULT_MYSQL_ROOT_PASS: ${VAULT_PASS}"
echo "DEV_VAULT_USERS_PASS: ${VAULT_PASS}"
echo "DEV_VAULT_USERS_DB_PASS: ${VAULT_PASS}"
echo "STAGE_VAULT_MYSQL_ROOT_PASS: ${VAULT_PASS}"
echo "STAGE_VAULT_USERS_PASS: ${VAULT_PASS}"
echo "STAGE_VAULT_USERS_DB_PASS: ${VAULT_PASS}"
echo "PROD_VAULT_MYSQL_ROOT_PASS: ${VAULT_PASS}"
echo "PROD_VAULT_USERS_PASS: ${VAULT_PASS}"
echo "PROD_VAULT_USERS_DB_PASS: ${VAULT_PASS}"
#
echo "**************************************************************"
echo "***************** SAVE THE PASSWORDS ABOVE *******************"
echo "**************************************************************"
#
echo "Don't forget to add your salts and encrypt your vault files!!!"
