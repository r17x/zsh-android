reset="\033[0m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
cyan="\033[36m"
white="\033[37m"

_install_packages() {
    local DEFAULT_PACKAGES;
    local PACKAGES;
    # currently only work in `mac` for auto install openjdk8
    # TODO support linux-based for openjdk8 
    command -v brew &>/dev/null && {
      printf "$yellow > checking jdk8...$reset\n"
      HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask adoptopenjdk8 || {
        printf "$cyan > start to install adoptopenjdk8...$reset\n"
        brew tap adoptopenjdk/openjdk
        brew install --cask adoptopenjdk8
      }
      printf "$green > already installed jdk8 $reset\n"
    }
    DEFAULT_PACKAGES="platform-tools platforms;android-29 build-tools;29.0.2 emulator"
    # define $PACKAGES and install with sdkmanager
    # fallback to $DEFAULT_PACKAGES when null for $ZSH_ANDROID_PACKAGES
    PACKAGES="${ZSH_ANDROID_PACKAGES:-$DEFAULT_PACKAGES}"
    printf "$red> install $PACKAGES ...$reset\n"
    # Eyden I. — 'Arguing with a woman is 
    # like reading the Software License Agreement. 
    # In the end, you ignore everything and click I agree.'
    yes | sdkmanager --licenses 
    # start to install $PACKAGES with sdkmanager
    sdkmanager --update
    unset -f DEFAULT_PACKAGES PACKAGES
  }

_install_cmdline() {
    printf "$green > (current) cmdline-tools version: $1 $reset\n"
    local machine
    local cmdlinetools_url;
    local cmdlinetools_file;
    local tmp_cmdlinetools_file;

    case $(uname -s) in 
      Linux*) 
        machine="linux"
        ;;
      Darwin*) 
        machine="mac"
        ;;
      Windows*) 
        machine="win"
        ;;
      *) 
        echo "we dunno your machine"
        exit 1
        ;;
    esac 

    cmdlinetools_file="commandlinetools-$machine-$1.zip"
    cmdlinetools_url="https://dl.google.com/android/repository/$cmdlinetools_file"
    tmp_cmdlinetools_file=/tmp/$cmdlinetools_file
    
    test -f $tmp_cmdlinetools_file && {
     test -f $tmp_cmdlinetools_file.cache || {
      curl --continue-at - $cmdlinetools_url -o $tmp_cmdlinetools_file 
     }
    } || {
     printf "$yellow> start to download $cmdlinetools_file...$reset\n"
     curl -o $tmp_cmdlinetools_file $cmdlinetools_url
    }
    printf "$yellow> extracting cmdline-tools version $1 in $ANDROID_HOME/cmdline-tools/$1...$reset\n"
    unzip -o  $tmp_cmdlinetools_file -d  /tmp
    mkdir -p $ANDROID_HOME/cmdline-tools/$1/
    cp -r /tmp/cmdline-tools/* $ANDROID_HOME/cmdline-tools/$1/
    rm -rf /tmp/cmdline-tools
    # create flag in /tmp
    touch $tmp_cmdlinetools_file.cache
    printf "$green> success extract in $ANDROID_HOME/cmdline-tools/$1 $reset\n"
    printf "$yellow> make it as default with symlink...$reset\n"
    ln -sf $ANDROID_HOME/cmdline-tools/$1 $ANDROID_HOME/cmdline-tools/default
    printf "$green> sucess make it default $reset\n"
}

command -v sdkmanager &>/dev/null || {
  export ANDROID_HOME="${ZSH_ANDROID_HOME:-$HOME/android}"
  export ANDROID_SDK_ROOT=$ANDROID_HOME/sdk
  export PATH="$ANDROID_HOME/cmdline-tools/default/bin:$PATH"
  export PATH="$ANDROID_HOME/emulator:$PATH"
  export PATH="$ANDROID_HOME/platform-tools:$PATH"
  export PATH="$ANDROID_HOME/tools:$PATH"
  version=${ANDROID_CMDLINE_VERSION:-"6858069_latest"}
  printf"$cyan > start to install...$reset\n"
  test -d $ANDROID_SDK_ROOT || {
    printf "$cyan > created \$ANDROID_SDK_ROOT in $ANDROID_ROOT $reset\n"
    mkdir -p $ANDROID_SDK_ROOT
  }
  test -d $ANDROID_HOME || {
      printf "$cyan > created \$ANDROID_HOME in $ANDROID_HOME $reset\n"
      mkdir -p $ANDROID_HOME
      test -d $ANDOID_HOME/cmdline-tools || {
        printf "$cyan > created cmdline-tools in $ANDROID_HOME/cmdline-tools $reset\n"
        mkdir -p $ANDROID_HOME/cmdline-tools
      }
    }
  command -v sdkmanager &>/dev/null || _install_cmdline  $version
  test -d $ANDROID_HOME/licenses || _install_packages
  # TODO:next
  # 1) sdkmanager installation
  # 2) agree licenses of sdkmanager
  # #) make standalone function for java8
}

unset -f _install_packages _install_cmdline
