_install_packages() {
    # define $ANDROID_SDK_ROOT
    export ANDROID_SDK_ROOT=$ANDROID_HOME
    local DEFAULT_PACKAGES;
    local PACKAGES;
    DEFAULT_PACKAGES="platform-tools platforms;android-29 build-tools;29.0.2 emulator"
    # define $PACKAGES and install with sdkmanager
    # fallback to $DEFAULT_PACKAGES when null for $ZSH_ANDROID_PACKAGES
    PACKAGES="${ZSH_ANDROID_PACKAGES:-$DEFAULT_PACKAGES}"
    echo "install " $PACKAGES
    # Eyden I. — 'Arguing with a woman is 
    # like reading the Software License Agreement. 
    # In the end, you ignore everything and click I agree.'
    yes | sdkmanager --licenses --sdk_root=$ANDROID_SDK_ROOT
    # start to install $PACKAGES with sdkmanager
    sdkmanager --install $PACKAGES  --sdk_root=$ANDROID_SDK_ROOT
    unset -f DEFAULT_PACKAGES PACKAGES
  }

_install_cmdline() {
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

    cmdlinetools_file="commandlinetools-$machine-6858069_latest.zip"
    cmdlinetools_url="https://dl.google.com/android/repository/$cmdlinetools_file"
    tmp_cmdlinetools_file=/tmp/$cmdlinetools_file
    
    -e $tmp_cmdlinetools_file &>/dev/null && {
     curl --continue-at - $cmdlinetools_url -o $tmp_cmdlinetools_file 
    } || {
     curl -o $tmp_cmdlinetools_file $cmdlinetools_url
    }

    rm -rf $ANDROID_HOME/cmdline-tools
    unzip $tmp_cmdlinetools_file -d $ANDROID_HOME
 
    unset -f machine cmdlinetools_file cmdlinetools_url tmp_cmdlinetools_file _install_cmdline
}

-v ANDROID_HOME &>/dev/null && {
  setopt verbose
  # when $ANDROID_HOME exist just export PATH
  export PATH=$ANDROID_HOME/cmdline-tools/bin/:$PATH
  export PATH=$ANDROID_HOME/emulator/:$PATH
  export PATH=$ANDROID_HOME/platform-tools/:$PATH 
} || {
  # define $ANDROID_HOME {default: $HOME/android}
  # make directory $ANDROID_HOME when isn't exist
  -d $ANDROID_HOME &>/dev/null || {
    mkdir -p $ANDROID_HOME
  }
  export ANDROID_HOME=$HOME/android
  # posibly bug when we extract cmdline-tools.zip and folder name not same with `cmdline-tools`
  export PATH=$ANDROID_HOME/cmdline-tools/bin:$PATH
  export PATH=$ANDROID_HOME/emulator:$PATH
  export PATH=$ANDROID_HOME/platform-tools:$PATH 
  # currently only work in `mac` for auto install openjdk8
  # TODO support linux-based for openjdk8 
  command -v brew &>/dev/null && {
    $(brew list --cask | grep adoptopenjdk/openjdk/adoptopenjdk8) &>/dev/null || {
      brew install --cask adoptopenjdk/openjdk/adoptopenjdk8
    }
  }
  command -v sdkmanager &>/dev/null || _install_cmdline 
  command -v sdkmanager &>/dev/null && _install_packages 
  unsetopt verbose
}
