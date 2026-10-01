<img width="1024" height="500" alt="image" src="https://github.com/user-attachments/assets/53647731-4524-448f-9779-a56067a0e6ac" />
# yjeek_driver

A new Flutter project.

Yjeek Champ / Yjeek Driver is a Flutter delivery-driver app for Bahrain. Version 1.0.0+9. Live API: https://api.yjeektech.com/api/v1.

There is no AI inside the app. It is a standard driver product: OTP login, jobs, maps, chat, earnings, documents.

Tech stack
Flutter + Provider
Google Maps + GPS (geolocator)
Firebase Cloud Messaging + local notifications
Image picker (camera/gallery)
English + Arabic (RTL)
Flow: splash → login → main bottom navigation
Main 5 tabs
Home — map, online/offline, auto-accept, banners, SOS
Orders — instant and scheduled jobs
Earnings — daily / weekly / monthly, payout, transactions
Performance — driver score
Account — profile, documents, vehicle, settings
Features by module
Auth
Phone OTP (send / verify / resend). Unregistered-number screen. Logout and delete-account APIs exist.

Dashboard
Go online/offline, location updates, driver status, auto-accept, CMS banners, force-update and can’t-go-online screens.

Instant jobs
Offer → accept/decline → restaurant → confirm pickup → customer → complete. Also cash, age-restricted, luxury/secure, returns, wait report, unable-to-deliver, contact attempts. Job board: active / completed / history.

Scheduled jobs
New / confirm / on track / completed. Vendor pickup, vape, restricted, luxury, release/reject.

Incidents / Safety
Pickup/dropoff issues, vendor not ready, damage, can’t reach customer, wrong address, breakdown, missing items, handover, SOS. Some screens hit the API. Can’t-reach chat is mock (hardcoded bubbles).

Chat
Dispatch inbox, load messages, send, mark-read, quick replies, 3-second polling. Starting a new chat from an order is not fully wired in the UI. Customer peer is not used (client hardcodes dispatch).

Profile
Name, phone change (OTP), avatar, vehicle, documents (CPR, license, registration, passport, visa). The profile Auto-Accept switch is UI only; the real API is used from Home / Go Online.

Notifications
In-app list + FCM tray. No dedicated chat push.

Settings
Language EN/AR, notification toggle, privacy policy, open-source licenses.

Job APIs (core work)
Accept, decline, release, arrive pickup/customer, confirm order/pickup, complete, SOS, contact-attempts, report, report-wait, unable-to-deliver, resend-code, return, age-restricted return, confirm-return, board, history.

Known gaps
Area	Status
Profile Auto-Accept
Does not call the API
Order → new dispatch chat
openDispatchChat is not used from UI
Customer chat
Endpoints exist; client always uses dispatch
Can’t-reach chat
Dummy UI
Nested duplicate folders
Removed; lib is back at repo root
In short: the driver can go online, pick up and deliver orders, report incidents, see earnings, and upload documents. Chat and Auto-Accept still have incomplete pieces.
