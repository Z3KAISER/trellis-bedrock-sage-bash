# trellis bedrock sage

This bash script will provision and deploy an app to a development, staging, and produciton server of your choice. It takes 4 arguments:

1. The name of the project i.e. bloglyfe – This will output "bloglyfe.com" for the production host and "bloglyfe" as the WordPress theme.
2. The admin email for the project
3. The staging IP
4. The production IP

for example
	./trellis_bedrock_sage_provision.sh bloglyfe hola@bloglyfe.com 0.0.0.0 0.0.0.0

Et voila! Hit enter and wait for Gulp and Browsersync to launch your new app in your default browser.

To-do's:

1. Add flags to prevent the provisioning/deployment of staging, and/or production servers