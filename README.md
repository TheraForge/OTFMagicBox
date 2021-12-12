# TheraForge MagicBox 1.0.0-beta

The Open TheraForge MagicBox app is a template for creating digital health solutions that help people better manage their health.
This sample application leverages TheraForge frameworks such as [OTFTemplateBox](../../../OTFTemplateBox) to implement a zero-code solution that can be customized without requiring any code changes.

For more details on the SDK, refer to the [OTFToolBox](../../../OTFToolBox) Readme file.

# Table of Contents

* [Overview](#Overview)
* [Installation](#Installation)
* [Usage](#Usage)
* [License](#License)

# Overview <a name="Overview"></a>

MagicBox app's source code represents an example of how to use the TheraForge SDK's frameworks.
You can use MagicBox as a reference, or you can fork it and make it the starting point for your own app. This open template can help you to create your own digital health application prototype in just a few minutes, without investing a lot of time and money, and even with limited knowledge of coding.

These are its primary characteristics:

+ No-code configuration and setup for accelerated development.
+ Informed consent process and survey generation using Apple's ResearchKit framework.
+ Care plan management using Apple's Carekit framework.
+ Monitoring of health data with Apple's HealthKit framework.
+ Automatic data synchronization across the Cloud (a la Dropbox) using the OTFToolBox SDK.
+ Support for various popular technologies out of the box: user authentication (Sign in with Apple in addition to standard login) with OAuth2, HIPAA- abd GDPR-compliant traffic encryption at rest and in transit (uses TLS 1.3 crypto), app notifications using HTTP 2 Server-Sent Events (SSE), etc.
+ SF Symbols 1.1 support (available on iOS/iPadOS 13 and watchOS 6, and later releases)


MagicBox includes the following customizable features:

## Onboarding

When a user launches an app for the first time, the onboarding process presents the app’s goals and provides instructions that highlight key benefits and features. 

## Consent

The informed consent is the process of a user granting authorization to an application to access specific resources on their behalf (for exammple, health sensors) and/or to perform certain actions (for example, as part of a medical study). Users will be asked for consent to allow access to their personal data.

## Consent Form and Signature

The consent form contains the description of the items included in the application that require explicit user consent. The user can agree to the clauses by signing the form.

## Simplified Registration and Login Process

The app includes screens to get a user to sign up to use a medical intervention, telemedicine account or research project. The registration page of the application asks for basic user details such as email, password, fullname, last name, date of birth and gender, etc. For example, date of birth can be used for a minimum age eligibility check to limit the use of the app.

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

# Installation <a name="Installation"></a>

Todo: Add Installation

# Usage <a name="Usage"></a>

After following the installation steps, go to the `AppSysParameters.yml` file in the root folder of your project. This yaml file contains a list of customizable parameters of your health application.
You don’t need to be a developer to edit this file and customize the application, just use a common editor (e.g., TextEdit or Xcode) and follow the simple instructions present in the `AppSysParameters.yml` file.
By editing this yaml file you can customize the health application according to your requirements, for example you can modify the app styling and flow.

## App Name: 

You can modify the app name. To do this follow the instructions given below:

Go to the root of this project.



Click on the `info.plist` file 
In the info.plist file you see the list of settings (key-value pairs). Go to the row where key named as “Bundle name”. Change the Value column of that row with your application name. As shown in the pic below.

Example: change $(PRODUCT_NAME) to “My Digital App”.  

  

## Design:

You can change the tint color, the label colors, font type and size to customize the look of your application. 

// Link to the yaml design section.

## API Key:

Update the API key to access the TheraForge Secure Cloud.

// Link to the yaml API config section.


## Onboarding:

To customize the onboarding process, go to the onboarding section in the `AppSysParameters.yml` file and add as many onboarding pages as you need. You can add the image types of your choice such as Emoji, SF Symbols and assets. In the description you can write the text explaining each particular onboarding page.

// Link to the yaml Onboarding section.

 
## Consent:

To customize the Consent process of your application go to the Consent section in the `AppSysParameters.yml` file and add/modify the required sections. Follow the instructions given in the yaml file to add the correct type of consent sections.

// Link to the yaml Consent section.

 
## Registration and Login: 

Go to the Registration section in the `AppSysParameters.yml` file and change the settings for *Date Of Birth* and *Gender* to `true` if you want to display those fields in your Registration form, otherwise set them to `false`.

// Link to the yaml Registration section.

## Login/Social Login:

Go to the Login section in the `AppSysParameters.yml` file and customize the title and the description.

If you want to use the *Sign up With Apple* feature, then change the corresponding setting to `true`.

// Link to the yaml Login section.


## Passcode:

Go to the Passcode section in the `AppSysParameters.yml` file and change the settings of passcode text and passcode type to 4 or 6 digits.

// Link to the yaml Passcode section.


## CareKit:

If your application requires support for tasks (for example, for a care plan) and contacts, then enable the `useCareKit` key, which allows you to display the contacts and list the tasks of the patients.

// Link to the yaml use carekit section.


Review the complete yaml file to learn about the available settings (also called *key-value pairs*) and edit the values of the keys according to your application's requirements, which will allow you to customize your digital health application in just a few minutes.

# License <a name="License"></a>

Todo: Add License
