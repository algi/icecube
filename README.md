# IceCube

IceCube is application for launching saved configurations of Maven tasks. It allows you to save particular task
configurations for whole project such as running embedded Jetty, deploying on remote Tomcat, etc.

Application uses CoreData technology for persistent store and XPC framework for secure launch of Maven process.

## Status
Current status is beta and it can be tracked in GitHub issues.
 
# Licence
MIT

## TODO

* zrušit CoreData (zde se nehodí a iCloud se dá vyzkoušet i bez nich)
* zlepšit autodetekci Mavenu - načíst ~/.profile, apod.
* opravit ukládání a změny v dokumentu - po uložení se hned přepne do módu Změněno
