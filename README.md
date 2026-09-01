# WordPress Plugin Deploy

Repository for reproducible WordPress plugin installation and deployment.

The repository contains plugin manifests and deployment scripts.

It DOES NOT contain:

- plugin ZIP files
- license keys
- SSH private keys
- WordPress credentials
- database credentials
- vendor API tokens

## Plugin manifests

### WordPress.org

`manifests/wporg-active.txt`

Plugins installed from WordPress.org and activated.

`manifests/wporg-inactive.txt`

Plugins installed from WordPress.org but kept inactive.

### External plugins

`manifests/external-active.txt`

Premium, private, vendor or custom plugins that should be active.

`manifests/external-inactive.txt`

Premium, private, vendor or custom plugins that should remain inactive.

External plugin format:

plugin-folder|zip-file

Example:

advanced-custom-fields-pro|advanced-custom-fields-pro.zip

## Security

Plugin binaries are never stored in this public repository.

External plugin ZIP files must be downloaded from trusted official sources
and stored outside the public web root of the WordPress server.
