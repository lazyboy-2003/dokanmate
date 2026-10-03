# DokanMate Production Hardening Plan

This checklist is the release gate for a small-business bookkeeping app. Do not describe the app as production-secure until the checks below have been implemented and verified on supported Android devices.

## P0 — Protect business records
- [ ] Introduce encrypted local database storage with a documented, recoverable migration from existing SQLite data.
- [ ] Generate encryption keys using a cryptographically secure source and protect key material with Android Keystore-backed storage where supported.
- [ ] Never log customer names, phone numbers, balances, invoice contents, PINs, or encryption keys.
- [ ] Define backup/restore, retention, export, and deletion behaviour; test corrupted and wrong-account backups.
- [ ] Ensure database migrations are transactional and preserve existing users' records.

## P0 — App lock and authorization
- [ ] Keep PINs out of logs and ordinary preferences; store a salted, slow password hash rather than a reversible/plain PIN where feasible.
- [ ] Add persistent throttling/temporary lockout after repeated incorrect PIN attempts, with safe recovery behaviour.
- [ ] Require fresh authentication for destructive or sensitive actions (restore, delete all data, change lock settings, export full records).
- [ ] Re-lock after backgrounding according to a documented timeout; test activity/lifecycle and biometric cancellation paths.

## P0 — Accounting correctness and integrity
- [ ] Use database transactions for sale/purchase + line items + stock movements + ledger/payment changes.
- [ ] Prevent duplicate invoice numbers and double-submit/double-post operations.
- [ ] Validate quantities, prices, discounts, GST rates, payment amounts, and stock adjustments.
- [ ] Make edit/delete reverse prior stock and ledger effects exactly once.
- [ ] Add reconciliation tests for customer/supplier balances, inventory valuation, profit/loss, GST totals, and outstanding due.
- [ ] Use a consistent money representation/rounding policy; avoid floating-point drift for financial calculations.

## P1 — SMS reminder safety
- [ ] Treat Android's local SMS API result as a send/submission attempt, not proof that the recipient received the SMS.
- [ ] Make scheduling idempotent; prevent duplicate reminders across reboot, app restart, multiple invoices, and retries.
- [ ] Re-check the current outstanding balance and consent/settings immediately before sending.
- [ ] Do not send if the customer has paid, the phone number is invalid, or automatic reminders are disabled.
- [ ] Make timing calculations use the exact selected delay and local timezone; test 1-minute, 1-day, overdue, daylight/time changes, reboot, and denied permissions.
- [ ] Clearly disclose that normal SMS may incur carrier charges and expose payment information on the recipient's lock screen.

## P1 — Privacy and Android platform
- [ ] Review AndroidManifest permissions for least privilege; request sensitive permissions only when the feature is enabled.
- [ ] Disable unintended cloud/device backup of unencrypted database files.
- [ ] Share PDFs/exports using content URIs and temporary grants; avoid public storage by default.
- [ ] Consider screenshot/recents protection on screens displaying customer financial data.
- [ ] Verify release builds use HTTPS for all remote services and contain no API secrets.
- [ ] Review exported components, file providers, cleartext traffic, and release signing configuration.

## P1 — Resilience and support
- [ ] Implement user-controlled encrypted backup and restore with pre-restore backup, validation, and confirmation.
- [ ] Provide an export/recovery path that does not lock users into the app.
- [ ] Add schema migration tests, backup round-trip tests, and crash/restart tests.
- [ ] Test low storage, interrupted writes, force-stop, reboot, permission denial, and Android OEM battery restrictions.
- [ ] Publish privacy policy, support contact, data retention/deletion guidance, and clear limits of offline-only storage.

## Release gate
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes with meaningful unit/widget/integration tests.
- [ ] Build a signed release APK/AAB and test it on real Android devices.
- [ ] Test upgrade from the currently released database schema without data loss.
- [ ] No unresolved critical/high security findings.
- [ ] Keep a release rollback and customer data recovery plan.

## Current known review findings
- Existing code uses an ordinary sqflite database for customer and financial records; database encryption has not been identified.
- Existing PIN flow compares the entered PIN directly with the stored PIN and has no visible retry throttle.
- Automatic SMS background scheduling/timing and duplicate suppression need dedicated tests and correction before release.
- The repository must be re-audited after each hardening change; this document is a checklist, not a security certification.
