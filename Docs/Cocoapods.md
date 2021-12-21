# Cocoapods Installation

Note that macOS includes Ruby out of the box and so the command `sudo gem install cocoapods` should work.

However, in some cases Ruby might not be installed or an old version of Ruby may be present (for example in macOS 10.14 Mojave or earlier).

Hence the command might fail.

In such cases, in Terminal you can check whether Ruby is installed and its version with the `which ruby` and `ruby -v` commands respectively.

If the command `sudo gem install cocoapods` were fail to because of Ruby, in Terminal you can use Homebrew to install or update Ruby to a newer version.

A. If you are using macOS 10.14 Mojave or earlier versions (which use bash as default shell), you can refer to this tutorial to install a newer version of Ruby:

https://stackify.com/install-ruby-on-your-mac-everything-you-need-to-get-going/

In short, you need to use the bash shell and run the following commands:

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install ruby
echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

B. Starting from macOS 10.15 Catalina, zsh has become the default shell. So, if you are using 10.15 or newer, refer to this tutorial to install or update Ruby:

https://mac.install.guide/ruby/13.html

(Note that you need to edit the ~/.zshrc file per the step-by-step guide and restart Terminal.)

Then you can install Cocoapods in Terminal with the command:

```
sudo gem install cocoapods
```

If you are still having problems with the Cocoapods installation, for example you get an error like:

```
pod install
-bash: pod: command not found
```

you can try to install cocoapods with the alternate command:

```
sudo gem install -n /usr/local/bin cocoapods
```

or follow these troubleshooting suggestions: https://stackoverflow.com/questions/37904588/cocoapods-not-installing
