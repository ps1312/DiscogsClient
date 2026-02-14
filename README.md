# DiscogsClient

SwiftUI iOS app that integrates with the Discogs API to:

- Search artists.
- Show artist details (including band members when available).
- Browse artist releases with pagination.

## Platform And Stack

- Language: Swift
- Minimum iOS version: 17.0
- UI framework: SwiftUI
- Dependency management: Swift Package Manager (SPM)
- Networking: `URLSession` via `HTTPClient` abstraction
- Tests: XCTest
- Static analysis: SwiftLint (SPM build tool plugin)

## Setup And Run

1. Open `DiscogsClient.xcodeproj` in Xcode.
2. Ensure an iOS 17+ simulator is selected.
3. Configure Discogs token in `DiscogsClient/ApiRequestBuilder.swift` (`token` constant).
4. Build and run the `DiscogsClient` scheme.

## Run Tests

From Xcode:

- `Product` -> `Test`

## Architecture And Reasoning

The app uses an MVVM-style structure with clear separation between presentation, mapping, and networking:

- Views render UI and bind state.
- ViewModels calls async requests, pagination, and modifies UI states.
- Mappers convert API payloads into app models and validate responses.
- `HTTPClient` protocol to allow dependency injection and better testability.
- `URLSession` to make network requests by implementing an extension in `HTTPClient+URLSession.swift`.

This facilitates a lot when implementing unit tests, specially using dependency injection when creating the ViewModels. The structure also alows easy navigation between view and data components. Good separation of concerns also makes implementing new features more easily and faster. For me, tests are a must, it gives a lot of confidence when making new changes on existing code.

## Analysis And Development Process

1. Implement search flow.
2. Implement artist detail flow.
3. Implement releases flow.
4. Add tests for critical ViewModel behaviors.
5. Move requests creation to `ApiRequestBuilder.swift`
6. Add SwiftLint for quality checks.
7. Lots of tests pointing to the DiscogsApi.

- And some tasks that were continuous during all the test:

* Improving `endpoint.md` with the contracts based on testing the real DiscogsApi.
* UI improvements, using new liquid glass components.
* Keep the business logic and UI separated.

## Challenges

1. was not able to find gender when fetching `/releases`
2. Albums endpoint appears to have a lot of inconsistencies

- duplicated results (image), fixed by:
- sort not working (image), mitigated by:
- the endpoint does not support sending filters, so the filtering is done locally

3. Can use search only for albums because it returns albums from other “Nirvana” bands, we cant send an artistId. We can pass an artistId on the Releases endpoint:

## Static Analysis

SwiftLint is configured through SPM. Run by building the project in Xcode.

## Project Structure

- `DiscogsClient/ArtistSearch`: artist search feature
- `DiscogsClient/ArtistDetail`: artist detail feature
- `DiscogsClient/ArtistAlbums`: artist releases and filters
- `DiscogsClient/Models`: models and pagination metadata
- `DiscogsClientTests`: ViewModel unit tests
- `endpoint.md`: JSON response contracts
- `screenshots/`: UI screenshots
