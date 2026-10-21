# SJewls Mobile (Saranga Jewels)

Customer mobile application built with Flutter for **Saranga Jewels**.

## Locked Brand Colour Palette

| Colour | Hex Code | Usage |
|---|---|---|
| Primary Green | `#0A3D2E` | App bars, primary buttons, bottom navigation bar |
| Gold Accent | `#D4AF37` | Icons, active tab indicators, highlights, status badges |
| Dark Text | `#1C2421` | Headings, body text, secondary interface elements |
| Background | `#FBFBFA` | Screen backgrounds, cards, light surfaces |

## Architecture & Tech Stack

- **Framework**: Flutter & Dart
- **State Management**: `flutter_riverpod`
- **Navigation**: `go_router` (`StatefulShellRoute.indexedStack` 5-tab bottom navigation: **Home**, **Chittu**, **Jewelry**, **Lottery**, **Payments**, plus top-level **Notifications** and **Profile** routes)
- **Networking**: `dio` (`ApiClient` with automatic Bearer JWT token attachment, `401` token refresh via `/api/v1/auth/token/refresh`, and `ProblemDetails` error extraction)
- **Session Storage**: `flutter_secure_storage` wrapped by `TokenStorage`

## Integrated Backend APIs (`https://sjewls-production.up.railway.app`)

1. **Customer Authentication (`/api/v1/auth/...`)**
   - `POST /api/v1/auth/otp/request`
   - `POST /api/v1/auth/otp/verify`
   - `POST /api/v1/auth/registration/complete`
   - `POST /api/v1/auth/token/refresh`
   - `POST /api/v1/auth/logout`
2. **Customer Jewellery Plans & Enrolments (`/api/v1/customer/...`)**
   - `GET /api/v1/customer/jewellery-categories`
   - `GET /api/v1/customer/jewellery-categories/{categoryId}/plans`
   - `GET /api/v1/customer/jewellery-plans`
   - `GET /api/v1/customer/jewellery-plans/{planId}`
   - `POST /api/v1/customer/jewellery-enrolments/preview`
   - `POST /api/v1/customer/jewellery-enrolments` (with `X-Idempotency-Key`)
   - `GET /api/v1/customer/jewellery-enrolments`
   - `GET /api/v1/customer/jewellery-enrolments/{enrolmentId}`
   - `GET /api/v1/customer/jewellery-enrolments/{enrolmentId}/payments`
   - `POST /api/v1/customer/jewellery-enrolments/{enrolmentId}/preview`
   - `POST /api/v1/customer/jewellery-enrolments/{enrolmentId}/quotes`
   - `GET /api/v1/customer/jewellery-quotes/{quoteId}`
   - `POST /api/v1/customer/jewellery-quotes/{quoteId}/pay` (handles HTTP `501 PaymentProviderNotConfigured` safely without altering balances)
   - `GET /api/v1/customer/notifications`
   - `POST /api/v1/customer/notifications/{notificationId}/read`
   - `POST /api/v1/customer/notifications/read-all`
3. **Customer Profile & Contacts (`/api/v1/customers/me/...`)**
   - `GET /api/v1/customers/me`
   - `POST /api/v1/customers/me/contacts/otp/request`
   - `POST /api/v1/customers/me/contacts/otp/verify`
   - `POST /api/v1/customers/me/account-closure/otp/request`
   - `POST /api/v1/customers/me/account-closure/confirm`

## Known Limitations & Paused Backend Dependencies

- **Chittu & Lottery Modules**: Backend API endpoints for Chittu plans, slot allocation, monthly instalments, and draw results are not yet published in `/openapi/v1.json` and are paused for future integration.
- **Online Payment Gateway**: `POST /api/v1/customer/jewellery-quotes/{quoteId}/pay` returns `501 PaymentProviderNotConfigured` by design while gateway integration is deferred; confirmed cash contributions are recorded in-store by branch staff.

## Running Locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
