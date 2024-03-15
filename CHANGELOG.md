## 0.1.9

* Editor's console panel improvements.
* Improved BlocList's behavior upon executing a "SetValue" Action.
* Removed references to "http" package on method's arguments and return values, so the user can use any http client.
* Improved the ability for creating new property variations.
* Other minor fixes and improvements.

## 0.1.8

* Editor has now a search panel.
* Actions can now have an "onFailure" Action.
* ActionResult can now have an "failureMessage".

## 0.1.7

* New "routeName" property on Screens to allow navigating to a Screen via a name instead of an id.
* Added Badge Widget.
* Several minor fixes and improvements.

## 0.1.6

* Fixed a typo preventing the use of BottomNavigationBar.
* Fixed an error on the Editor when exposing a property from the Component itself.
* Fixed issue when a BuildCondition for a Widget would return false, _quality of life_ Widgets, like Padding or Hero,  would still be applied.
* Fixed issue where property evaluation was written to the original Model node, affecting the subsequent use of that Action.
* Fixed issue preventing Request cloning.
* Added 'page' and 'pageSize' vars to property evaluation when executing a LoadPageAction.
* SplashScreen class renamed to LowderSplashScreen.
* Added Widget CircularProgressIndicator.
* Added Widget SingleChildScrollView.
* Changed 'If' Action properties to support any condition instead of only an operator condition.
* Added a Widget panel to the Editor with all available Widgets, and drag and drop functionality.
* Logging refactor.

## 0.1.5

* Editor has now a console panel to display log data from itself, the Client and the http server.
* Fixed first Screen render when no 'Landing Screen' is defined.
* Fixed issue where creating or updating Actions on the Editor would not update the Client's model.
* Fixed issue where creating or updating Requests on the Editor would not update the Client's model.
* Fixed issue where creating or updating Language Resources on the Editor would not update the Client's model.
* Fixed issue where creating or updating Environment Variables on the Editor would not update the Client's model.

## 0.1.4

* Fixed an issue where an Action's value wasn't available on the next Actions.
* Updated example.
* Some cosmetic work and cleanup.

## 0.1.3

* Yet more file formatting to respect pub.dev standards.

## 0.1.2

* File formatting to respect pub.dev standards.

## 0.1.1

* pub.dev related updates.

## 0.1.0

* Initial release.
