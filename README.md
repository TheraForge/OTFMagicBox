# TheraForge MagicBox

The Open TheraForge MagicBox app is a template for creating digital health solutions that help people better manage their health.
This sample application leverages TheraForge frameworks such as [OTFTemplateBox](../../../OTFTemplateBox) to implement a zero-code solution that can be customized without requiring any code changes.
For more details on the SDK, refer to the [OTFToolBox](../../../OTFToolBox) Readme file.

# Table of Contents
* [Overview](#Overview)
* [Installation](#Installation)
* [Usage](#Usage)
* [License](#License)

# Overview
MagicBox app's source code represents an example of how to use the TheraForge SDK's frameworks.
You can use MagicBox as a reference, or you can fork it and make it the starting point for your own app. This open template can help you to create your own digital health application prototype in just a few minutes, without investing a lot of time and money, and even with limited knowledge of coding.

These are its primary characteristics:

+ No-code configuration and setup for accelerated development.
+ Informed consent process and survey generation using Apple's ResearchKit framework.
+ Care plan management using Apple's Carekit framework
+ Monitoring of health data with Apple's HealthKit framework.
+ Automatic data synchronization across the Cloud (a la Dropbox) using the OTFToolBox framework.
+ Support for various popular technologies out of the box: user authentication (Sign in with Apple in addition to standard login) with OAuth2, HIPAA- abd GDPR-compliant traffic encryption at rest and in transit (uses TLS 1.3 crypto), app notifications using HTTP 2 Server-Sent Events (SSE), etc.

MagicBox includes following features:


 Onboarding
 When a user launches your app for the first time, the onboarding process reinforces your app's value and provides instructions that highlight key benefits and features. 



 
 Consent
 Consent is the process of a user granting authorization to an application to access protected resources on their behalf. A user can be asked for consent to allow access to their organization/individual data. 



Consent form and Signature

 Consent form contains the description of the Consents included in the application. If the user agrees to the Consent form then the User has to Sign on the Consent form. 



A simplified Registration and Login  process

The workflow to get someone to sign up to your research project is already in place. Registration page of the application asks for the basic user details such as email, password, fullname, last name, Date Of Birth and Gender etc. 





 Login/Social Login


 OTFMagicBox supports different ways of login such as regular login using your registration details, Apple Login and Google Login.

User login credentials will be stored in the Keychain Services. 

 Passcode
  In order to protect the data, your app can use Passcode technology. With the Passcode, your users can provide a four or six-digit user-selected code for access.



 Activity
Number of standard tasks that you can simply include in your sample project. This includes a two finger tap test, the 6 minute walk test, a special memory test and a short walk test to measure gait and balance. These tasks include all the steps the user will need to complete in order to complete the test, these are supplied as clear instructions to the user 
 



Survey
A survey is a sequence of questions that you use to collect data from your users. Each step object handles a specific question in the survey, such as “What medications are you taking?” or “How many hours did you sleep last night?”. You can collect results for the individual steps or for the task as a whole. 

 Contacts
	Contacts include any kind of Patient’s contacts cards, which provides the basic details of Contacts like address, Phone number, messaging number,  email address etc.

 Profile
	Profile includes the basic details of your organization such as Help, Report, Support address, Withdrawal from study and logout of a patient.



Installation 
Todo: Add Installation

Usage

After following the installation steps, go to the AppSysParameters.yml file in the root of your project. This yaml file contains the complete structure of your health application. You don't need to be any developer to edit this file and create your own application, just follow the simple instructions written in the AppSysParameters.yml file. Editing this yaml file you can completely customize your health application according to your requirements. Yaml file allows you to change the complete design and flow of the application.

Application Name: 
You can modify the digital health application name to your desired application name. To do this follow the below given instructions:
Go to the root of this project.



Click on the  info.plist file 
In the info.plist file you see the list of key-value pairs. Go to the row where key named as “Bundle name”. Change the Value column of that row with your application name. As shown in the pic below.

Example: change $(PRODUCT_NAME) to “My Digital App”.  

  

 Design:
Changing the tint color, label colors or font type and size of the font will give the complete new look to your application. 

// Link to the yaml design section.

 API:
Update the API token key to your own TheraForge ToolBox API token.

// Link to the yaml API config section.


Onboarding:
To make your Onboarding attractive go to the Onboarding section in the AppSysParameters.yml file and add as many Onboarding pages as you need. Add the image type of your choice such as Emoji, SF Symbols and Assets. In the description write the text which explains about that particular Onboarding page.

// Link to the yaml Onboarding section.

 
 Consent:
 To add the Consent to your application go to the Consent section in the AppSysParameters.yml file and add required Consents to your application. Follow the instructions given in the yaml file to add the correct type of consent.

// Link to the yaml Consent section.

 
Registration and Login: 

 Go to the Registration section in AppSysParameters.yml file and change the values of Date Of Birth and Gender to true if you want to display those fields in your Registration form otherwise set it as false.

// Link to the yaml Registration section.

 Login/Social Login:

Go to the Login section in the AppSysParameters.yml file and change the values of title and messages of the login section.

If you want to use the Signup With Apple then set the value to true otherwise false.

// Link to the yaml Login section.


Passcode:
Go to the Passcode section in the AppSysParameters.yml file and change the values of passcode text and passcode type to 4 or 6 digits.

// Link to the yaml Passcode section.


CareKit:
If your application requires the tasks and contacts features then enable useCareKit key, which allows you to display the contacts and perform the tasks of the Patients.

// Link to the yaml use carekit section.


Go through the complete yaml file for all kinds of  key-value pairs and edit the values of the keys according to your application requirement, which will give you your own digital health application in just a few minutes.

Licence 
Todo: Add Licence
