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

## Staging deployment

`Staging Plugin Dry Run` validates the deployment plan without modifying
WordPress.

`Staging WordPress.org Plugin Deployment` is a manually triggered workflow.
It requires explicit confirmation, reruns the preflight and dry-run checks,
then installs only the plugins listed in the WordPress.org manifests. It
verifies plugin checksums and expected active/inactive states after installation.

External and manually managed plugins, including Paid Memberships Pro, are not
installed or modified by the WordPress.org deployment workflow.
