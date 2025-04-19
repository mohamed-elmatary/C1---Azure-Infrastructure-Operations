# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions

in this project we used terraform and packer template 
step 1 => we used packer to create image, this image contain our code, our packeges and all dependencies needed to run our application
to create our image we used (server.json) file to describe our image this file contain most required info that describe our image (os_type, location, resourceGroup, image_sku, size .. etc)
if you plan to use it you need to do some changes
1 - you need to provide your subscriptionId in variables section
2 - you need to make AppRegisteration in your EntraId and Create Client Secret for this app
3 - you need to give this App the required permissions to create image for me ( I did it through Role Based Access Control in My Subscrition I gave this app Contributor Role )
4 - you need to get client_id and client_secret from this app and provide it in server.json file
5 - you need to run this command ( packer build server.json ) in the terminal in the same folder that contain server.json 

step 2 => we used terraform to describe and create our infrastructure, in this step we will depend on  the packer image that we created in step 1 to create our virtual machines in for infrastructure, in this step we have two files main.tf and variables.tf

1 - in main.tf we include all resource that we need and we describe the relations between this resources and also inclode provider section for azure resources
    and output variables that will be printed after apply terraform 
2 - in variables.tf we include the variable that we can change according to our needs, we need change it once it we affect in all resources (DRY Principle) 
    like Count of Virtual Machines and ResourceGroupName and Location for Resources 
3 - we need use az cli to run this command (az image list) to get list of our images, we need to copy the id of our packer image, and use it in (source_image_id)
    property inside (azurerm_linux_virtual_machine) section that describe our virtual machine
4 - run command (terraform init) this command initializes a working directory containing Terraform configuration files
5 - run command (terraform plan -out solution.plan) Generates an execution plan, Saves the generated plan to a file called solution.plan, 
    which can then be used later with terraform apply
6 - run command (terraform apply solution.plan) to apply our plan , deploy our resources on azure


### Output
**Your words here**



infarastructure as code is great technology allow you to describe you infrastructrue once and use it in many places without huge changes it follow DRY (Don't repeat your self) principle, we have many tools like ARM Template, bicep and Terraform , terraform can be used with many providers like Azure, Aws, GCP .. etc, it is comfortable to use, it is more readable and easy syntax , well documented and wide spread , with it you write template one and can use it in any place for the same provider withou needing to create each resource alone and waiting to create dependencies

packer template image like docker image we can include all apps and packages and dependencies that we need to install in our image and use this image in any place without need to create virtualmachine each time and install the same apps , packages and dependencies this also follow DRY principle 



the output after apply terrafor you will find it in screenshot an in (output from terraform.txt) file

