# Shortcuts. `make web` is the fastest way to run the app (no emulator).
.PHONY: web web-demo web-build web-serve web-deploy android test rules-test screenshots

web:            ## Run in Chrome with hot reload (r = reload, R = restart), live Firebase
	flutter run -d chrome --web-port 5000

web-demo:       ## Run in Chrome on offline demo data (no Firebase)
	flutter run -d chrome --web-port 5000 --dart-define=FAKE_BACKEND=true

web-build:      ## Optimised release build (WebAssembly + JS fallback) into build/web
	flutter build web --release --wasm

web-serve: web-build  ## Serve the release build at http://localhost:8080
	cd build/web && python3 -m http.server 8080

web-deploy: web-build ## Publish to Firebase Hosting (https://campusfix-alu-2026.web.app)
	firebase deploy --only hosting

android:        ## Run on a connected Android device/emulator
	flutter run -d android

test:           ## App unit + widget tests
	flutter test

rules-test:     ## Firestore security-rule tests (emulator, needs Java)
	cd rules-test && npm test

screenshots:    ## Re-render report screenshots into docs/screenshots
	flutter test tool/screenshots_test.dart --update-goldens
