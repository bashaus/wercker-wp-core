# WordPress Core

Wercker step to install the WordPress Core and generate salts.

## Notes

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Sample Usage

    deploy:
      box: php:7.1
      steps:
        - bashaus/wp-core:
          cwd: $WERCKER_ROOT/public/
          core-version: "4.9.4"

&nbsp;

## Step Properties

### core-version (required)

The version of WordPress you would like to download.

* Since: `0.0.1`
* Property is `Required`
* Recommendation location: `Inline`
* `Validation` rules:
  * Must be a valid [WordPress version](https://codex.wordpress.org/WordPress_Versions)
  * Must be a String

&nbsp;

### generate-salts

Whether or not to download fresh salts and store in the `wp-salts.php` file.

* Since: `0.0.1`
* Property is `Optional`
* Recommendation location: `Inline`
* Default value is: `true`
* `Validation` rules:
  * Must be either `true`, `false`, `1` or `0`

&nbsp;
