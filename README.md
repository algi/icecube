# IceCube

IceCube is application for launching saved configurations of Maven tasks. It allows you to save particular task
configurations for whole project such as running embedded Jetty, deploying on remote Tomcat, etc.

However, the aim of the project lies not the functionality itself, but in being a research project for as many Mac OS X technologies as possible. This Readme file captures what I learned on this project so far. I hope it will help you with some obscure, less known technologies. Please feel free to use any part of the application in your code. I’m not quite sure if this project will ever be useful as a real world application itself, since the concept of the application is basically useless…

## About application
IceCube is document-based application. Every document represents one Maven command set. It contains Maven command itself and working directory. The application parses Maven output, so it can give feedback to user about how many phases are done and how many still needs to be done.

The application needs to know path to Java and Maven installations. Since it cannot read simly environment variables (`JAVA_HOME`, `M2_HOME`), it has to provide some sort of configuration for user. When the application starts, it tries to autodetect Java installation via `/usr/libexec/java_home` command. It expects Maven installation at path `/usr/share/maven/bin/mvn`, but unfortunatelly due to recent changes in macOS (specifially because of System Integrity Protection), it’s no longer possible to install Maven in this location and also the Maven itself is no longer pre-installed for the user, as it used to be. Therefor it’s necessary to set the location of Maven manually.

## Architecture, technologies
IceCube is written in Objective-C, since Swift didn’t exist back then, when I started the implementation. I do not consider to rewrite it to Swift, because I have different projects written in Swift, so I don’t need this kind of experience in this project.

The application itself is Mac Cocoa application with no 3rd party dependencies. I’m purely interested in using Mac technologies as it is, without any kind of “wrappers” around it. For user interface, IceCube is using XIBs, because there was no such thing as storyboard back then. Everything is localized to English and Czech (my native language).

The most interesting thing about architecture of the application is, that it’s using XPC for every task invocation. Instead of using NSTask directly, it wraps the business logic in it’s own XPC module, which is reusable and safer. The only part of business logic, which is not wrapped in XPC, is output parser.

The application is scriptable, it provides it’s own Automator action and it also provides custom Spotlight importer. It also have very simple Help bundle, which shows how to include simple video and how to invoce AppleScript from help.

Following chapters will describe these technologies more closely.

## User interface
As it has been mentioned already, the application is using XIB files instead of storyboards. Because of that, parts of the application are more split, so there’s no direct connection between main menu and let’s say document window itself.

I would like to describe some interesting things about user interface. Let’s start with menu items and toolbar button validation. As you can see, there is special menu called `Project`. This menu is usable only for document window. But how do you disable those items, when document window is not active? This is being done by very clever mechanism called [Responder chain][1]. Since every menu item has it’s own target (selector), it’s easy for Cocoa to find out if current window controller can respond to the selector or not. If not, then the menu item will be disabled. You can also see that `MBTaskRunnerWindowController` implements method called `-(BOOL)validateMenuItem:`, which can additionally validate state of menu items. In this case, we don’t want to allow user to accidently run project twice, etc.

Another interesting and very powerful thing is Cocoa Bindings. It’s being used quite extensively in document window for data binding, but also for validation. For example Run button is enabled only when the build doesn’t run. You can also see some nice bindings in Preferences window, where the fields reacts to it’s own checkboxes. As a part of Cocoa bindings, I would like to also mention usage of KVO (Key-value observation), which is especially useful for watching changes in `NSUserDefaults` for validating Maven and Java home directories.

## Custom document class
Since IceCube is document-based application, it has it’s own `NSDocument` implementation. The format of the document is primitive - it’s just an XML PLIST, so no fancy serialization/deserialization there. Yet it nicely illustrates how to work with reading/writing methods of `NSDocument` and how it’s intergrated with window controller.

The good thing about being good citizen is, that you automatically get support for Time Machine, revisions, automatic save, etc. The only thing, which needs to be provided by you is `NSUndoManager` instance, which you can again take from `NSDocument`.

## XPC, NSTask
The idea behind XPC is to offload potentionally insecure and fragile logic into separate process, which is being managed by the system itself. You can schedule your XPC processes and the system will run them with appropriate priority at appropriate time, considering system load, battery level, etc.

IceCube is using XPC as a layer of protection and separation of concerns. If Maven or `java_home` process would crash, it won’t crash the whole application. It can also impose different security privileges, if IceCube will ever adopt sandboxing.

There is one interesting thing about XPC behaviour. Even though the calls are asychronous from the nature of XPC architecture, they are actually queued. Originally the Maven call used to have callback block, so it wasn’t possible to cancel the build. The command has been send, but it has been processed AFTER the build ended (which was of course too late). Yet, in the application itself, it didn’t block the thread. I originally thought that NSTask is unable to send SIGINT to shell script (aka Maven project), but when I was debugging XPC module, I found that the message has been send after runMaven finished…

Apart from this catch, you can see how nicely and easily you can send data between XPC service and the application itself. If you use normal data (like NSString, etc.), you don’t need to worry about `NSSecureCoding` protocol at all.

## Scripting support
IceCube supports OSA architecture, so it’s possible to use AppleScript or JavaScript to call some of it’s functions. Following example shows how to build all opened projects:

```
tell application "IceCube"
	repeat with projectItem in every project
		run project projectItem
	end repeat
end tell
```

This example is also contained in Apple Help (see below). It’s written in AppleScript.

There is one BIG catch in creatining scripting dictionary. You have to use appropriate codes, when creating your own classes, actions, etc. Let’s have a look at file `IceCube.sdef`. As you can see from the comment there, **commands** MUST HAVE 8 characters code. If you fail to do this, Script Editor.app will ignore your command and will not tell you anything. Also be aware of **properties**, which needs to have exactly 4 character codes. Again, if you don’t want 4 characters, put some empty spaces there.

Apart from that, the rest of definition file is quite self explanatory. You can also see that IceCube has it’s own `NSApplication` subclass. This is purely for scripting support, where the application provides `projects` element, so the user can iterate easily through it and invoke commands on each project. It also provides access to application preferences.

## Automation support
The application contains one bundled Automator action for invoking build without running application itself. It basically just wraps Maven command in Automator action, so it doesn’t use anything like XPC, etc.

There are two things about Automator actions, which I would like to mention: logging and debugging. Let’s start with logging. As you can see from the source code, I’m not using normal logging there. The reason is, that user will not likely look into Console.app for error messages, so it’s better idea to support feedback with built-in logging support. This also means that if the action will fail for some reason, you can just log error message and that’s it. Automator will catch this error message, display it to the user and will stop the execution. You can also provide back the `NSError` in case that something goes really wrong. But as you can see, I’m not using this mechanism at all.

The second thing is debugging. This is a tricky one. Before macOS gained support for SIP (System Integrity Protection), it was possible to debug Automator with your action. Xcode even provided this functionality by itself. If you would like to debug your Automator action now with LLDB debugger, you have to [turn off SIP first][2]. I usually turn off wifi too, but you still have no guarantee that some rogue malware won’t use this opportunity to infect your Mac, so be careful, or use virtualization, if available. Once you attach LLDB to Automator, you can easily put a breakpoint in your action and then just run Automator workflow with your action.

Last thing about testing Automator action in IceCube is to not forget about: 1) build whole application (not just the action itself), 2) restart Automator, since it doesn’t reload the action by itself. Nice thing about Mac is, that it automatically detects your application in Xcode build folder, so you don’t have to copy it to `/Applications` folder.

## Spotlight
IceCube provides it’s own Spotlight importer plugin. The purpose of the plugin is to provide metadata and text for indexing to Spotlight, so the user can find the document using it. For some reason, it shows in “Other” result section, instead of in “Documents”…

There are two ways how to develop a Spotlight plugin - using `mdimport` command line utility to dry test the import (see `IceCubeSpotlight` Run configuration in Xcode scheme), which can show you what Spotlight will get from your plugin. Or you can try to debug the code with LLDB and `mdimport` command. Here again you have to turn off SIP, otherwise LLDB won’t be able to connect to the process.

There’s Apple example for how to index CoreData document, so my example is actually very simple. It just grabs the Maven command from the document and pass it to Spotlight.

## Help support
This is very old technology and little bit obscure one. Help files for application are stored in bundle `IceCube.help`. Also notice that this bundle is being referenced in application’s `IceCube-Info.plist`.

The bundle itself contains two localized help folders, along with `scripts` folder, which contains one example AppleScript. Every localized folder contains one HTML file and one index file, which you can create either with `Help Indexer.app`, or with command-line utility `hiutil`.

The help system itself is quite complex. Not only you can include images, you can also include QuickTime movie, which is going to start immediately after user opens the page. You can also invoke AppleScript from the link, in order to help user with some more difficult parts, or to show some functionality in the application. Or do some nasty things, because as you can see, you can also use system-wide actions, which allows you to start applications (like `Calculator.app`), etc.

It is possible to reference help pages from UI, but this is not currently being used in IceCube project. It’s easy to test the help, just hit `Cmd-?` and help window will pop-up. I usually restart the application, in order to test the bundle, but you can also double click the bundle from Finder and then just restart the help viewer.

## Localization
Everything is localized in IceCube. You can see how XIB files are localized via Localized.strings, you can also see even localized `IceCube-Info.plist` file, which is using `InfoPlist.strings` file, because the PLIST will be renamed to `Info.plist` during build process.

All user-facing messages has been localized in the code using macro NSLocalizedString. This macro takes two arguments: actual message (in English, since it is app’s development region) and the comment for translator. This is very important even if you don’t have any translator, since it helps you to understand context of the message, once you open `strings` file, so you don’t have to search in the meaining of the message in code all the time.

You can also generate these `strings` files using command-line utility called `genstrings`. Instead of passing list of files, you can always do something like `genstrings *.m` and then move the output to appropriate folder (or use some switch for that).

For more information about localization and formating, see excelent article from [NSHipster][4].

## Error handling
Error handling in Cocoa is very robust and nicely implemented. If you would like to see how to create nice error sheet for user, head to `MBMavenServiceTask` clas, where you can see how to create proper `NSError` object, which you can pass to the application. It’s unfortunatelly not possible to pass custom recovery attempter object from XPC, so it needs to be injected manually in the application code.

The injection of custom attempter is done in `MBApplication` class via custom `MBRecoveryAttempter`, which will inject itself to supported error. Once the attempter has been injected, the error can be processed by standard `NSApplication` error handling routine. You can either display it as an alert window (see `MBAppDelegate`), or as an error sheet (see `MBTaskRunnerWindowController`). As you can see, it’s always delegated through object `NSApp`, so there’s no need to get instance of `MBApplication` directly.

## Unit testing
I should rather say “unit” testing in quotation marks, becase you cannot write truly unit test in Cocoa. It will always run as a part of application. There’s only one test at the time being and that is for parser. It’s fairly standalone one, so it doesn’t depend on application state. I’m using new `XCTest` framework from Xcode, which is simple to understand and it’s nicely integrated to the Xcode.

If you would like to write more tests, be aware of the fact, that all tests runs in same instance of the application. So if you are testing CoreData, well - good luck with that. Especially if you want to preinsert some data, etc. It’s good idea to use in-memory store, but this is actually out of scope for this project.

The only noteworthy thing in my project is, that I wrote special static method for loading text files, which are used for parser testing. It not only reads the test file, but it also launches the parser itself, so I don’t have to repeat this code each and every time.

## Logging
The application no longer uses good old `NSLog()` macro, but it uses new `os_log` facility. You can find very nice [documentation][3] about it from Apple. It’s plays nicely with `Console.app` and you can configure it via command-line or via system configuration file.

New logging facility tries to carefuly respect user’s privacy, so it logs only static strings. If you try to log dynamic string, you receive `<private>` in log instead of the actual value itself. If you are conviced that the information is actually not private (like path, etc.), you can specify it as public by using designated modifier. For NSString, the format is: `%{public}@`. You can see the usage for example in class `MBJavaHomeServiceTask`.

Normally you can only see error messages from your application in `Console.app`.  You can always see all messages in Xcode’s Console output window.

# Licence
MIT - see LICENCE file

[1]: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/EventOverview/EventArchitecture/EventArchitecture.html
[2]: https://developer.apple.com/library/content/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html#//apple_ref/doc/uid/TP40016462-CH5-SW1
[3]: https://developer.apple.com/reference/os/logging?language=objc
[4]: http://nshipster.com/nslocalizedstring/