.PHONY: setup run clean build test lint get

setup: get
	@echo "Setup complete."

get:
	@flutter pub get

run:
	@flutter run

clean:
	@flutter clean

build-apk:
	@flutter build apk --release

test:
	@flutter test

lint:
	@flutter analyze
