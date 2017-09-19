#!/bin/bash

# Property: core-version
# Check if the WordPress Version is present
if [ -z "$WERCKER_WP_CORE_CORE_VERSION" ]; then
  fail "Property core-version must be defined"
fi

# Property: generate-salts
# Whether to download and store fresh salts
# Must be a valid boolean (true, false, 1 or 0)
case "$WERCKER_WP_CORE_GENERATE_SALTS" in
  "true" | "1" ) WERCKER_WP_CORE_GENERATE_SALTS="1" ;;
  "false" | "0" ) WERCKER_WP_CORE_GENERATE_SALTS="0" ;;
  * ) fail "Property generate-salts must be either true or false"
esac

# Task: Identify destination directory
WERCKER_WP_CORE_PATH=`pwd`

main() {
  update_wp_cli
  create_temp
  clean_temp
  wordpress_install
  generate_salts
  delete_temp

  success "Installed WordPress core"
}

# Task: Update wp-cli
# Just in case the step hasn't been updated in a long time
update_wp_cli() {
  info "Checking wp-cli is at latest version"
  ($WERCKER_STEP_ROOT/wp-cli.phar cli update --allow-root)
  ($WERCKER_STEP_ROOT/wp-cli.phar --info --allow-root)
}

# Task: Create Temporary directory
# Extract WordPress to a temporary directory so that we can remove unsafe files
create_temp() {
  info "Creating temporary directory"
  WERCKER_WP_CORE_TEMPDIR=`mktemp -d -t wp-core.XXXXXXXXXX`
  debug "$WERCKER_WP_CORE_TEMPDIR"

  # Task: Download WordPress Core
  info "Downloading WordPress into temporary directory"
  (
    WP_CLI_CACHE_DIR="$WERCKER_CACHE_DIR/$WERCKER_STEP_OWNER/$WERCKER_STEP_NAME/" \
      $WERCKER_STEP_ROOT/wp-cli.phar core download --force --allow-root \
    	--version="$WERCKER_WP_CORE_CORE_VERSION"] \
      --path="$WERCKER_WP_CORE_TEMPDIR"
  )

  WERCKER_WP_CORE_DOWNLOAD_RESPONSE=$?

  if [ "$WERCKER_WP_CORE_DOWNLOAD_RESPONSE" -ne 0 ]; then
    fail "Failed to download WordPress core"
  fi
}

# Task: Remove dangerous files
clean_temp() {
  # Remove the wp-content/ folder (use the symlink from the project's repository)
  rm -rf "$WERCKER_WP_CORE_TEMPDIR/wp-content/"

  # Remove the readme.html file (exposes version information)
  rm -rf "$WERCKER_WP_CORE_TEMPDIR/readme.html"
}

# Task: Delete temporary directory
# Delete the temporary directory as it's not required
delete_temp() {
  info "Deleting the temporary directory"
  rm -rf $WERCKER_WP_CORE_TEMPDIR
}

# Task: Install WordPress
# Copy the files from the temporary install to the build
wordpress_install() {
  info "Installing WordPress"
  debug "$WERCKER_WP_CORE_PATH"

  # Task: Merge files and directories
  # Copy files from the temporary directory to the project
  # Sub-task to allow for the changing of directory
  (
    cd "$WERCKER_WP_CORE_TEMPDIR"

    find . -type d | while read WERCKER_WP_CORE_DIRNAME; do
      mkdir -p "$WERCKER_WP_CORE_PATH/$WERCKER_WP_CORE_DIRNAME"
    done

    find . -type f | while read WERCKER_WP_CORE_FILENAME; do
      cp -R "$WERCKER_WP_CORE_TEMPDIR/$WERCKER_WP_CORE_FILENAME" \
        "$WERCKER_WP_CORE_PATH/$WERCKER_WP_CORE_FILENAME"
    done
  )
}

generate_salts() {
  if [ "$WERCKER_WP_CORE_GENERATE_SALTS" = "0" ]; then
    info "Skipping salts, disabled"
    return
  fi

  info "Generating salts"

  WERCKER_WP_CORE_GENERATE_SALTS_RESULT="$(
    curl  -s "https://api.wordpress.org/secret-key/1.1/salt/" \
          -o "$WERCKER_STEP_TEMP/wp-salts.php" \
          -w "%{http_code}"
  )"

  if [ "$WERCKER_WP_CORE_GENERATE_SALTS_RESULT" = "200" ]; then
    info "Downloaded fresh salts to temporary directory"
  else
    fail "Could not download fresh salts"
  fi

  # Prepend the <?php tag to the beginning of the file
  echo "<?php " > "$WERCKER_WP_CORE_PATH/wp-salts.php"

  # Write the contents of the salts to the directory
  cat "$WERCKER_STEP_TEMP/wp-salts.php" >> "$WERCKER_WP_CORE_PATH/wp-salts.php"

  info "Wrote salts to $WERCKER_WP_CORE_PATH/wp-salts.php"
}

main
