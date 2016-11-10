# trellis bedrock sage

This bash script will provision and deploy an app to a development, staging, and production server of your choice. It takes 7 arguments:

for example this:

	./trellis_bedrock_sage_provision.sh <GITHUB_USER> <DOMAIN_NAME> <TLD> <REPO_NAME> <ADMIN_EMAIL> <STAGING_IP_ADDRESS> <PRODUCTION_IP_ADDRESS>

could be:

	./trellis_bedrock_sage_provision.sh discreteunits elevateyourintake .com elevateyourintake hi@discreteunits.com 0.0.0.0 0.0.0.0

Et voila! Hit enter and wait for Gulp and Browsersync to launch your new app in your default browser.

To-do's:

1. Add flags to prevent the provisioning/deployment of staging, and/or production servers
