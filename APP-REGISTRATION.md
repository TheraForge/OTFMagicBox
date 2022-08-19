# Registration on Apple Developer Portal

The following shows how to set up an app in your Apple developer account.

## Register Bundle identifier

Sign in to your Apple developer account.

Then navigate to *Certificates, Identifiers & Profiles* from the side menu.

Register an *application bundle identifier* by navigating to *Identifiers*.

Click on the *plus button* to create a new identifier, as shown in the figure below.

<img src="Docs/36-Bundle-Identifier.png">

Select the *App IDs* option to register an identifier and press continue.

<img src="Docs/48-app-ids.png">

Then select *App* and press continue.

<img src="Docs/49-app.png">

Specify a *Description* and a *Bundle ID* specific to your organization. Then press continue.

<img src="Docs/50-description-bundleID.png">

Register an identifier other than "org.theraforge.magicbox.ios" (which is already taken) otherwise you will get an error.

<img src="Docs/47-identifier-error.png" width=50% height=50%>

## Create Certificates & Profiles on your Apple Developer Account

To create a signing certificate for development and one for release, navigate to *Certificates* and click the *plus* button to create a new certificate.

<img src="Docs/37-Signing-Certificate.png">

To create a software development certificate, click on *Apple Development* and press continue.

<img src="Docs/38-Development-Certificate.png">

Then, on the next window, to generate a certificate you need a *Certificate Signing Request (CSR)* file from your computer. Select the *Choose File* option, as shown below, to upload a CSR that you have created.

<img src="Docs/39-upload-CSR-File.png">

To create a Certificate Signing Request (CSR) file open the *Keychain Access* application on your Mac (you can quickly find it using the Spotlight search function).

<img src="Docs/40-Keychain-Access.png">

Navigate to *Keychain Access* --> *Certificate Assistant* --> *Request a Certificate From a Certificate Authority*.

<img src="Docs/41-Request-Certificate.png">

A dialog box opens to enter the CSR info: enter your email address and select the option *Saved to disk*.

<img src="Docs/42-Certificate-Information.png" width=80% height=80%>

Find the saved CSR file, upload it (as shown above) to create a certificate, press continue and download the certificate.

Find and double click the downloaded certificate to install it in your keychain.

Navigate to the profiles section to create profile for development and one for release.

<img src="Docs/55-profile-section.png">

Click on the *plus* button and select the profile for development and press continue.

<img src="Docs/56-create-development-profile.png">

Next select the identifier from the drop down menu with which you want to create a provisioning profile, then press continue.

<img src="Docs/57-select-app-id.png">

You will find the certificate that you previously created, select the certificate and press continue.

<img src="Docs/58-certificate-selection.png">

If you have registered the device on *Apple Developer Account* a list of registered iPhone will appear, select the device on which you want to install the app with this profile and press continue.

<img src="Docs/59-select-device.png">

Add provisioning profile name and press continue.

<img src="Docs/60-generate-profile.png">

Finally download the profile.

<img src="Docs/61-download-profile.png">

Find and double click the downloaded profile to install it in Xcode.
