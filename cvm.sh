#!/usr/bin/env bash

CVM_VERSION="0.1.0"

cvm_usage() {
    echo "Composer Version Manager (v$CVM_VERSION)"
    echo ""
    echo "Usage:"
    echo "  cvm COMMAND [OPTIONS] [ARGUMENTS]"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this message"
    echo "  -v, --version     Display the application version"
    echo "  -r, --reload      Reload cvm in the current shell"
    echo ""
    echo "Commands:"
    echo "  current           Show the current version of Composer"
    echo "  install           Install a specific version of Composer"
    echo "  update            Update an installed version of Composer"
    echo "  remove            Remove a specific version of Composer"
    echo "  use               Use a specific version of Composer"
    echo "  list              Show installed versions of Composer"
}

cvm_get_version() {
    VERSION="$1"

   CVMRCPATH=$(pwd)  
   while [[ "$CVMRCPATH" != "" && ! -e "$CVMRCPATH/.cvmrc" ]]; do
       CVMRCPATH=${CVMRCPATH%/*}
   done

    if [ "$VERSION" = "" ] && [ "$CVMRCPATH" != "" ] ; then
        VERSION=$(cat $CVMRCPATH/.cvmrc)
    fi

    case "$VERSION" in
        "" | "stable" | "latest-stable")
            VERSION="stable"
            ;;
        "preview" | "latest-preview")
            VERSION="preview"
            ;;
        "snapshot" | "latest")
            VERSION="latest"
            ;;
        "1" | "1.x" | "latest-1.x")
            VERSION="1.x"
            ;;
        "2" | "2.x" | "latest-2.x")
            VERSION="2.x"
            ;;
    esac

    echo "$VERSION"
}

cvm_get_php_cli() {
    PHP_CLI="php"

    if [ -f ".php-version" ]; then
        PHP_CLI="php$(cat .php-version)"
    fi

   if [ -f "$(which $PHP_CLI)" ]; then 
       echo "$PHP_CLI"
   else
      echo "php"
   fi
}

cvm_reload() {
    source "${CVM_DIR}/cvm.sh"
}

cvm_get_url() {
    VERSION=$(cvm_get_version "$1")
    BASE_URL="https://getcomposer.org"

    case "$VERSION" in
        "stable" | "preview" | "1.x" | "2.x")
            VERSION="latest-$VERSION"
            ;;
    esac

    if [ "$VERSION" = "latest" ]; then
        URL="${BASE_URL}/composer.phar"
    else
        URL="${BASE_URL}/download/${VERSION}/composer.phar"
    fi

    echo "$URL"
}

cvm_use() {
    VERSION=$(cvm_get_version "$1")
    PHP_CLI=$(cvm_get_php_cli)

    if [ "$VERSION" = "system" ]; then
        unalias composer 2>/dev/null

        export CVM_COMPOSER_VERSION=""
        export CVM_COMPOSER_PHAR=""

        return 0
    fi

    FILE="${CVM_DIR}/versions/${VERSION}/composer.phar"

    if [ -f "$FILE" ]; then
        alias composer="$PHP_CLI $FILE"
    else
        echo "Composer version ${VERSION} is not installed"
        return 1
    fi

    export CVM_COMPOSER_VERSION="$VERSION"
    export CVM_COMPOSER_PHAR="$FILE"

    echo "Using $(composer --version)"
}

cvm_install() {
    VERSION=$(cvm_get_version "$1")
    URL=$(cvm_get_url "$1")

    # Stage the download so we can grab the exact version

    STAGING_DIR="${CVM_DIR}/versions/.staging/${VERSION}"
    STAGING_FILE="${STAGING_DIR}/composer.phar"

    echo "Downloading Composer version ${VERSION}"

    rm -rf "$STAGING_DIR"
    mkdir -p "$STAGING_DIR"
    curl -o "$STAGING_FILE" "$URL" >/dev/null 2>/dev/null
    chmod +x "$STAGING_FILE"

    STAGING_VERSION=$("$STAGING_FILE" --version 2>/dev/null | cut -d" " -f3)

    if [ -z "$STAGING_VERSION" ]; then
        echo "Failed to download Composer version ${VERSION}"
        rm -rf "$STAGING_DIR"
        return 1
    fi

    HUMAN_VERSION="$VERSION"

    if [ "$STAGING_VERSION" != "$VERSION" ]; then
        HUMAN_VERSION="${VERSION} (${STAGING_VERSION})"
    fi

    # Make sure the staging version isn't already installed

    INSTALL_DIR="${CVM_DIR}/versions/${STAGING_VERSION}"
    INSTALL_FILE="${INSTALL_DIR}/composer.phar"

    if [ -f "$INSTALL_FILE" ]; then
        echo "Composer version ${HUMAN_VERSION} is already installed"
        rm -rf "$STAGING_DIR"
        return 1
    fi

    # Install the staging version and clean up

    echo "Installing Composer version ${HUMAN_VERSION}"

    mv "$STAGING_DIR" "$INSTALL_DIR"

    if [ "$STAGING_VERSION" != "$VERSION" ]; then
        ALIAS_DIR="${CVM_DIR}/versions/${VERSION}"
        rm -rf "$ALIAS_DIR" 2>/dev/null
        ln -s "$INSTALL_DIR" "$ALIAS_DIR"
    fi

    cvm_use "$VERSION"
}

cvm_update() {
    VERSION=$(cvm_get_version "$1")
    URL=$(cvm_get_url "$1")

    STAGING_DIR="${CVM_DIR}/versions/.staging/${VERSION}"
    STAGING_FILE="${STAGING_DIR}/composer.phar"

    INSTALL_DIR="${CVM_DIR}/versions/${VERSION}"
    INSTALL_FILE="${INSTALL_DIR}/composer.phar"

    if [ ! -f "$INSTALL_FILE" ]; then
        echo "Composer version ${VERSION} is not installed"
        return 1
    fi

    case "$VERSION" in
        "stable" | "preview" | "latest" | "1.x" | "2.x")
            echo "Updating Composer version ${VERSION}"
            ;;
        *)
            echo "Composer version ${VERSION} is not eligible for updates, please try one of stable, preview, latest, 1.x, 2.x"
            return 1
            ;;
    esac

    mkdir -p "$INSTALL_DIR"
    curl -o "$INSTALL_FILE" "$URL" >/dev/null 2>/dev/null
    chmod +x "$INSTALL_FILE"

    cvm_use "$VERSION"
}

cvm_remove() {
    VERSION=$(cvm_get_version "$1")

    if [ "$VERSION" = "system" ]; then
        echo "Refusing to remove system Composer"
        return 1
    fi

    DIR="${CVM_DIR}/versions/${VERSION}"

    if [ ! -d "$DIR" ]; then
        echo "Composer version ${VERSION} is not installed"
        return 1
    fi

    CURRENT="$CVM_COMPOSER_PHAR"
    TARGET="${CVM_DIR}/versions/${VERSION}/composer.phar"

    rm -rf "$DIR" 2>/dev/null # brutal efficiency?
    find -L "${CVM_DIR}/versions" -type l -exec rm -f {} \;

    echo "Removed Composer version ${VERSION}"

    if [ ! -f "$CURRENT" ]; then
        cvm_use "system"
    fi
}

cvm_current() {
    if [ -f "$CVM_COMPOSER_PHAR" ]; then
        echo "Using $("$CVM_COMPOSER_PHAR" --version)"
        return 0
    fi

    COMMAND=$(command -v composer)

    if [ -z "$CVM_COMPOSER_PHAR" ] && [ ! -z "$COMMAND" ]; then
        echo "Using system $(composer --version)"
        return 0
    fi

    echo "Composer not found"
}

cvm_list() {
    for V in $(command ls "${CVM_DIR}/versions"); do
        if [ ! -L "${CVM_DIR}/versions/${V}" ]; then
            echo "$V"
        fi
    done

    for V in $(command ls "${CVM_DIR}/versions"); do
        if [ -L "${CVM_DIR}/versions/${V}" ]; then
            T=$(readlink "${CVM_DIR}/versions/${V}")
            echo "$V -> $(basename "$T")"
        fi
    done
}

cvm() {
    if [ "$1" = "" ]; then
        cvm_usage
        return 0
    fi

    while [ "$1" != "" ]; do
        PARAM=`echo $1 | awk -F= '{print tolower($1)}'`

        case $PARAM in
            "--help" | "-h")
                cvm_usage
                return 0
                ;;
            "--version" | "-v")
                echo "$CVM_VERSION"
                return 0
                ;;
            "--reload" | "-r")
                cvm_reload
                return 0
                ;;
            "current")
                cvm_current
                return $?
                ;;
            "install")
                shift
                cvm_install $@
                return $?
                ;;
            "update")
                shift
                cvm_update $@
                return $?
                ;;
            "remove" | "uninstall")
                shift
                cvm_remove $@
                return $?
                ;;
            "use")
                shift
                cvm_use $@
                return $?
                ;;
            "list")
                cvm_list
                return $?
                ;;
            *)
                echo "Unknown Option: ${PARAM}"
                return 1
                ;;
        esac

        shift
    done
}
