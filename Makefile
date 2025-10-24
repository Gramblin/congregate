build_dev_appbundle:
	chmod +x increment_build_number.sh
	./increment_build_number.sh
	flutter build appbundle --release --target lib/main_dev.dart --flavor dev

build_prod_appbundle:
	chmod +x increment_build_number.sh
	./increment_build_number.sh
	flutter build appbundle --release --target lib/main_release.dart --flavor prod

cache_repair:
	flutter pub cache repair

# Fixes issues like:
# - could not find compatible versions for pod X
ios_clean:
	cd ios;\
	pod deintegrate;\
	rm -rf Podfile.lock;\
	flutter clean;\
	flutter pub get;\
	pod install;\

macos_clean:
	cd macos;\
	pod deintegrate;\
	rm -rf Podfile.lock;\
	flutter clean;\
	flutter pub get;\
	pod install;\

run_debugging_enabled:
	@echo This command enables debugging with release mode. Useful to test/debug apps when they are closed on iOS.
	flutter devices
	@echo Enter device ID: 
	@read line; flutter run -d $$line --release --target lib/main_dev.dart --flavor dev

run_flavorizr_ios:
	dart run flutter_flavorizr -p assets:download,assets:extract,ios:podfile,ios:xcconfig,ios:buildTargets,ios:schema,ios:plist,ios:dummyAssets,assets:clean
	
run_flavorizr_android:
	dart run flutter_flavorizr -p android:buildGradle,android:androidManifest

deep_link_android:
	adb shell 'am start -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE \
    -d "https://qubique.io/friend/aaa/bbb"' \
    com.qubique.suffah.dev

deep_link_ios:
	@read -p "Enter friend ID: " FRIEND_ID; \
	read -p "Enter username: " USERNAME; \
	xcrun simctl openurl booted "suffah://friend/$$FRIEND_ID/$$USERNAME"

deep_link_profile_ios:
	@read -p "Enter friend ID: " PROFILE_ID; \
	xcrun simctl openurl booted "suffah://profile/$$PROFILE_ID"

deep_link_macos:
	@read -p "Enter friend ID: " FRIEND_ID; \
	read -p "Enter username: " USERNAME; \
	open "suffah://friend/$$FRIEND_ID/$$USERNAME"

web-deploy:
	flutter build web \
	--dart-define=SUPABASE_OAUTH_REDIRECT=https://scrramble-dev-eaa17.web.app/login
	--dart-define-from-file keys.json \
	firebase deploy --only hosting

run-all:
	flutter run -d all \
	--dart-define-from-file keys.json \
	--dart-define=SOCKET_URL=http://localhost:3000 \
	--flavor dev