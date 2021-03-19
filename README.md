# Artificien

This is the iOS library for the Artificien platform. It enables developers registered on Artificien.com to expose their data to Artificien's servers for on-device training. Full instructions for installing and configuring this Pod can be found [here](artificien.com/app_developer_documentation).

## Setup
Artificien's training functions are accessible through the Artificien CocoaPod. If your iOS app already uses CocoaPods, jump straight to installing the Artificien pod. Otherwise, start directly below.

### Install and initialize CocoaPods
Note: for the latest instructions on setting up CocoaPods, follow the official documentation.

To start, run the following code via the command line, in any directory. This will install CocoaPods, a package and dependency manager for iOS, on your machine. Your machine may ask for your password before beginning the installation.

```
sudo gem install cocoapods
```

Now run the following via the command line, in the root directory of your iOS project (the one that contains your `.xcodeproj` file). This creates a Podfile that you will use to configure CocoaPod dependencies.

```
pod init
```

### Install the Artificien Pod
Open your Podfile and add Artificien as a dependency to your project with the following line. Our pod is distributed through this open-source Github repository.

```
pod 'Artificien', :git => 'https://github.com/dartmouth-cs98/artificien_ios_library.git'
```

Your Podfile should now look something like this.

```
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Sample-App' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Sample-App
  pod 'Artificien', :git => 'https://github.com/dartmouth-cs98/artificien_ios_library.git'
  ...

end
```

Now run the following, in the same directory as your Podfile, to download Artificien. This will install the Artificien package and create a new file with the `.xcworkspace` extension in your current directory. Use this file, instead of the standard `.xcodeproj` file, for future development in order for your app to access Artificien's functions.

```
pod install
```

At this point, open the `.xcworkspace` file to view your project in Xcode.

## Architecture

The `Artificien` top-level directory contains the Swift code and configuration for Artificien's training functions

The `Example` top-level directory contains an example Swift app that imports the Artificien library and calls its functions for testing. To run this example project, clone the repo, and run `pod install` from the `Example` directory.

## Author

Shreyas Agnihotri

## License

Artificien is available under the MIT license. See the LICENSE file for more info.
