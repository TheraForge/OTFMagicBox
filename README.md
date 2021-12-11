# TheraForge MagicBox 1.0.0-beta

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
+ Care plan management using Apple's Carekit framework.
+ Monitoring of health data with Apple's HealthKit framework.
+ Automatic data synchronization across the Cloud (a la Dropbox) using the OTFToolBox SDK.
+ Support for various popular technologies out of the box: user authentication (Sign in with Apple in addition to standard login) with OAuth2, HIPAA- abd GDPR-compliant traffic encryption at rest and in transit (uses TLS 1.3 crypto), app notifications using HTTP 2 Server-Sent Events (SSE), etc.

MagicBox includes the following features:


## Onboarding

When a user launches an app for the first time, the onboarding process presents the app's goals and provides instructions that highlight key benefits and features. 

## Consent

The informed consent is the process of a user granting authorization to an application to access specific resources on their behalf (for exammple, health sensors) and/or to perform certain actions (for example, as part of a medical study). Users will be asked for consent to allow access to their personal data.

## Consent Form and Signature

The consent form contains the description of the items included in the application that require explicit user consent. The user can agree to the clauses by signing the form.

## Simplified Registration and Login Process

The app includes screens to get a user to sign up to use a medical intervention, telemedicine account or research project. The registration page of the application asks for basic user details such as email, password, fullname, last name, date Of birth and gender, etc. Date of birth can be used for example for minimum eligibility to the use of the app.

## Login/Social Login

MagicBox supports different login strategies: regular login using registration details, Sign in with Apple and Sign in with Google.

User login credentials are securely stored in the device's keychain. 

## Passcode

In order to protect access, the app can optionally require a four- or six-digit user-selected passcode.

## Activity

There are a number of pre-defined task types that you can include in your project: for example, a two finger tap test, the 6 minute walk test, a special memory test and a short walk test to measure gait and balance. These tasks include the instructions for the steps to perform to complete them.

## Surveys

A survey is a sequence of questions that you use to collect data from the users. Each step addresses a specific question in the survey, such as “What medications are you taking?” or “How many hours did you sleep last night?”. You can collect results for the individual steps or for the task as a whole. 

## Contacts

Contacts are cards that contain doctor and family member details, such as address, phone number, messaging number, email address, etc.

## User Profile

The profile section includes the user account view as well as additional information, actions and links such as help, report, customer support address, withdrawal from study, and logout.

# Installation

Todo: Add Installation

# Usage

After following the installation steps, go to the AppSysParameters.yml file in the root folder of your project. This yaml file contains the complete structure of your health application. You don't need to be any developer to edit this file and create your own application, just follow the simple instructions written in the AppSysParameters.yml file. Editing this yaml file you can completely customize your health application according to your requirements. Yaml file allows you to change the complete design and flow of the application.

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
