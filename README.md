# DiscogsClient

A SwiftUI iOS app for searching artists on Discogs, viewing artist details, and browsing artist releases with pagination.

## Features

- Artist search with loading, empty, and error states.
- Artist detail view with profile, image, and band members.
- Artist releases list with sorting and pagination.
- Unit tests for view models.

## Tech Stack

- SwiftUI
- URLSession (`HTTPClient` abstraction)
- XCTest

## Requirements

- Xcode 26+
- iOS Simulator (project target currently set to iOS 26.1)

## Run

1. Open `DiscogsClient.xcodeproj` in Xcode.
2. Select the `DiscogsClient` scheme.
3. Choose an iOS Simulator device.
4. Build and run.

## Test

Run from Xcode (`Product` -> `Test`) or terminal:

```bash
xcodebuild test \
  -project DiscogsClient.xcodeproj \
  -scheme DiscogsClientTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## API Notes

- Request construction lives in `DiscogsClient/ApiRequestBuilder.swift`.
- Response contracts used by the app are documented in `endpoint.md`.

## Project Structure

- `DiscogsClient/ArtistSearch`: search feature
- `DiscogsClient/ArtistDetail`: artist details feature
- `DiscogsClient/ArtistAlbums`: artist releases/albums feature
- `DiscogsClient/Models`: API and domain models
- `DiscogsClientTests`: unit tests for view models
- `screenshots/`: UI state screenshots

## Screenshots

- Search: `screenshots/search/`
- Details: `screenshots/details/`
- Albums: `screenshots/albums/`
