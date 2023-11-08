# Magisk - Conscrypt Trust User Certs

This module makes all installed user certificates part of the APEX module com.android.conscrypt certificate store in Android 14, so that they will automatically be used when building the trust chain. This module makes it unnecessary to add the network_security_config property to an application's manifest.

### Installation
1. Install Magisk
2. Zip files `zip -r ConscryptTrustUserCerts.zip ./*` or download the ZIP file from releases
3. Install in Magisk
4. Install client certificates through [normal flow](https://support.portswigger.net/customer/portal/articles/1841102-installing-burp-s-ca-certificate-in-an-android-device)
5. Restart your device. Certificate copying happens during boot.
6. The installed user certificates are now part of the trusted certificates of APEX package com.android.conscrypt .

### Adding certificates
Install the certificate as a user certificate and restart the device.

### Removing certificates
Remove the certificate from the user store through the settings, and restart the device.

### Changelog

#### v0.1
* Initial release
