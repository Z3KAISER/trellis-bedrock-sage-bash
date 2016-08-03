	#!/bin/bash

# trellis bedrock sage

# http://linuxconfig.org/bash-scripting-tutorial
# use predefined variables to access passed arguments
#echo arguments to the shell
#echo $1 $2 $3 ' -> echo $1 $2 $3'

# We can also store arguments from bash command line in special array
#args=("$@")
#echo arguments to the shell
#echo $APP_NAME $ADMIN_EMAIL $STAGING_IP_ADDRESS ' -> args=("$@"); echo $APP_NAME $ADMIN_EMAIL $STAGING_IP_ADDRESS'

#use $@ to print out all arguments at once
#echo $@ ' -> echo $@'

# use $# variable to print out
# number of arguments passed to the bash script
#echo Number of arguments passed: $# ' -> echo Number of arguments passed: $#' 

# Create Arguments Array
args=("$@")
echo "created args array"

GITHUB_USER="${args[0]}"
APP_NAME="${args[1]}"
ADMIN_EMAIL="${args[2]}"
STAGING_IP_ADDRESS="${args[3]}"
PRODUCTION_IP_ADDRESS="${args[4]}"

# Move to wordpress directory inside of apps directory
cd ~/apps/wordpress

# Create and Navigate to the app directory from the first argument provided
mkdir $APP_NAME.com && cd $APP_NAME.com

# Clone into Trellis and remove the existing git history
git clone --depth=1 git@github.com:roots/trellis.git trellis && rm -rf trellis/.git

# Clone into Beadrock and remove the existing git history
git clone --depth=1 git@github.com:roots/bedrock.git site && rm -rf site/.git

# Clone into Sage, Rename to first argument provided and remvove existing git history
git clone git@github.com:roots/sage.git site/web/app/themes/$APP_NAME && rm -rf site/web/app/themes/$APP_NAME/.git

# Move Vagrantfile to root level
# mv trellis/ Vagrantfile .

# Update the ANSIBLE_PATH constant
# sed -i '' "s|ANSIBLE_PATH = __dir__|ANSIBLE_PATH = File\.join(__dir__, 'ansible')|g" Vagrantfile 

# Set the WP_DEFAULT_THEME to the first argument provided
# WP_DEFAULT_THEME_STR=$'define('DISALLOW_FILE_EDIT', true);n define('WP_DEFAULT_THEME', '$APP_NAME');'
# sed -i '' "s|define('DISALLOW_FILE_EDIT', true);||g" site/config/application.php
sed -i '' "s|define('DISALLOW_FILE_EDIT', true);|define('DISALLOW_FILE_EDIT', true);\
define('WP_DEFAULT_THEME', '$APP_NAME');|g" site/config/application.php

# Move into Ansible directory and run the Install Script
cd trellis && ansible-galaxy install -r requirements.yml
echo "Running trellis requirements.yml"

# Begin Trellis Config
# Update wordpress_sites.yml for staging environments

###############
# Development #
###############
echo "Configuring wordpress_sites for development"
# Update Project name to first argument provided
sed -i '' "s|example\.com|$APP_NAME\.com|g" group_vars/development/wordpress_sites.yml
#
sed -i '' "s|example|$APP_NAME|g" group_vars/development/mail.yml
#
sed -i '' "s|example|$APP_NAME|g" group_vars/development/vault.yml
# Update admin_email to second argument provided
sed -i '' "s|admin_email: admin@example\.dev|admin_email: $ADMIN_EMAIL|g" group_vars/development/wordpress_sites.yml
# Update hostname site urls for development environment
sed -i '' "s|example\.dev|$APP_NAME\.dev|g" group_vars/development/wordpress_sites.yml
# Update site_title to first argument provided
sed -i '' "s|site_title: Example Site|site_title: $APP_NAME app|g" group_vars/development/wordpress_sites.yml

###########
# Staging #
###########
echo "Configuring wordpress_sites for staging"

STAGING_URL="staging\.$APP_NAME\.com"
#
sed -i '' "s|example\.com|$STAGING_URL|g" group_vars/staging/vault.yml
# Update repository to a Discrete Units Organization Repo
sed -i '' "s|git@github\.com:example/example\.com.git|git@github\.com:$GITHUB_USER/$APP_NAME\.com\.git|g" group_vars/staging/wordpress_sites.yml
# Update Project name to first argument provided
sed -i '' "s|example\.com|$STAGING_URL|g" group_vars/staging/wordpress_sites.yml


# Update site_title to first argument provided
sed -i '' "s|site_title: Example Site|site_title: $APP_NAME app|g" group_vars/staging/wordpress_sites.yml
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
sed -i '' "s|example\.com|$APP_NAME\.com|g" group_vars/production/vault.yml
# Update repository to a Discrete Units Organization Repo
sed -i '' "s|git@github\.com:example/example\.com.git|git@github\.com:$GITHUB_USER/$APP_NAME\.com.git|g" group_vars/production/wordpress_sites.yml
# Update Project name to first argument provided
sed -i '' "s|example\.com|$APP_NAME\.com|g" group_vars/production/wordpress_sites.yml
# Update site_title to first argument provided
sed -i '' "s|site_title: Example Site|site_title: $APP_NAME app|g" group_vars/production/wordpress_sites.yml
# Update to second argument provided
sed -i '' "s|admin_email: admin@example.dev|admin_email: $ADMIN_EMAIL|g" group_vars/production/wordpress_sites.yml
# Uncomment subtree_path when using trellis directory structure
sed -i '' "s|# subtree_path: site|subtree_path: site|g" group_vars/production/wordpress_sites.yml
# Add pre build commands for sage theme
# cat <<EOT >> group_vars/production/wordpress_sites.yml

# project_pre_build_commands_local:
#   - path: '{{ project.local_path }}/web/app/themes/$APP_NAME'
#     cmd: npm install
#   - path: '{{ project.local_path }}/web/app/themes/$APP_NAME'
#     cmd: bower install
#   - path: '{{ project.local_path }}/web/app/themes/$APP_NAME'
#     cmd: gulp --production

# project_local_files:
#   - name: compiled theme assets
#     src: '{{ project.local_path }}/web/app/themes/$APP_NAME/dist'
#     dest: web/app/themes/$APP_NAME
# EOT

# Update hosts for Production with third argument provided
sed -i '' "s|your_server_hostname|$PRODUCTION_IP_ADDRESS|g" hosts/production

# Sage Theme Config
# Back out of trellis directory
# cd ../$APP_NAME.com
cd ../

# composer create-project roots/sage site/web/app/themes/$APP_NAME
# Not necessary
# cd site
# wp theme activate $APP_NAME

# Update site url in manifest.json
sed -i '' "s|http:\/\/example\.dev|http:\/\/$APP_NAME\.dev|g" site/web/app/themes/$APP_NAME/assets/manifest.json

# Navigate to theme directory
cd site/web/app/themes/$APP_NAME
# Install node modules
npm install
# Install bower packages
bower install
# Build theme assets
gulp

# Navigate to root directory
cd ../../../../../../$APP_NAME.com
# cd ../../../../../
# Initialize Git Repository
git init
# Add codebase
git add .
# Commit codebase
git commit -m "first commit, adding trellis, beadrock, and sage files from provision script."
# Add origin
git remote add origin git@github.com:$GITHUB_USER/$APP_NAME.com.git
# Push to master branch
git push -u origin master

# Navigate to trellis directory
cd trellis
# Vagrant
vagrant up

#$ ansible-playbook server.yml -e env=<environment>

# Provision Staging Server
# ansible-playbook -i '' hosts/staging server.yml
#ansible-playbook server.yml -e env=staging
# Provision Production Server
# ansible-playbook -i '' hosts/production server.yml
#ansible-playbook server.yml -e env=production

#ansible-playbook deploy.yml -e "site=roots-example-project.com env=<environment>"

# Deploy to Staging Server
# ./deploy.sh staging $APP_NAME.com
#ansible-playbook deploy.yml -e "site=$STAGING_URL env=staging"

# Deploy to Production Server
#./deploy.sh production $APP_NAME.com
#ansible-playbook deploy.yml -e "site=$APP_NAME.com env=production"

cd ../site/web/app/themes/$APP_NAME
# Turn on gulp to watch for changes and fire up browsersync
gulp watch
echo "Done!"