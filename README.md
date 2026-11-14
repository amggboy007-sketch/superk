# Super K

A fresh responsive store/inventory management web app using Supabase. The provided legacy `index.html` was used only as a visual and workflow reference; its old backend and data are not reused.

## Supabase project
- Project ref: `tataeikxoymbnvwxnwvx`
- Region: Singapore (`ap-southeast-1`)
- Frontend uses only the project's publishable key. Never put a service-role key in browser code.

## Current features in this first build
- Responsive Thai dashboard and mobile bottom navigation
- Email/password Supabase Auth
- First registered account bootstraps as admin username `kiangkai`
- Branch selector (initial branches: สำนักงานใหญ่, ศาลายา)
- Product list, add product, stock adjustments and movement history
- Employee job records
- Admin user directory and branch-role assignment
- Admin chat room schema, text/image/audio attachments, unread indicators
- Each chat message has its own `expires_at` (3 days after sending)

## Setup
1. Host `index.html` on a static host (GitHub Pages or another static host).
2. Configure Supabase Auth email confirmation and allowed redirect URLs for the chosen site domain.
3. Register the first admin account. It becomes `kiangkai` and receives manager/admin membership for the seeded branches.
4. Staff users can create an account from the website. The first account becomes `kiangkai`; later accounts are created as staff with no branch access until the admin assigns a branch in **จัดการผู้ใช้**.
5. Deploy `supabase/functions/chat-cleanup/index.ts` with JWT verification enabled. Schedule it to run periodically using a server-side service-role JWT. The function deletes expired files through the Storage API, then deletes expired message rows. Do not expose the service-role key in the website.

## Notes
This is the first implementation baseline, not a finished production POS. Sales checkout, barcode camera scanning, scheduled cleanup wiring, and end-to-end tests still need implementation and testing before production use. The cleanup Edge Function is deployed, but its recurring schedule still needs to be configured with a server-side service-role credential.
