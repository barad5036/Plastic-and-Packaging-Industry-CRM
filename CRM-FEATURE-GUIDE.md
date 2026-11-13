# SalesHub CRM Feature and Build Guide

## 1. Purpose and scope

This document describes the CRM that exists in this project: its user-facing screens, workflows, data entities, API, and implementation structure. It is intended as a product and engineering blueprint for building a similar sales CRM, not as a claim that every visible control is backed by a finished feature.

The application is called **SalesHub CRM** in the UI. It is a Flutter client with a Go/Gin REST API and PostgreSQL persistence. Some client screens include sample data or demo-mode fallbacks. The limitations section identifies features that are placeholders, disconnected, or only partially implemented.

## 2. Product overview

The CRM centers on a sales workflow:

1. Sign in, register, or enter the demo portal.
2. Create and manage prospective customers (leads).
3. Move leads through a sales pipeline.
4. Prepare quotations for a customer or lead.
5. Keep a dealer directory and track sales tasks.
6. Review dashboard KPIs and reports.

### Main navigation

| Navigation item | Purpose |
|---|---|
| Dashboard | Sales KPIs, lead activity chart, and conversion funnel |
| Leads | Lead table, status filters, add/edit/delete, follow-up notes, import/export |
| Quotation | Quote KPIs, search/filter, quote details, create/edit/delete |
| Dealers | Dealer directory, summary cards, search/status filter, add/delete |
| Reports | Analytics KPIs, charts, and conversion table |
| Pipeline | Kanban board for moving leads between sales stages |
| Settings | Account/system summary placeholder and an inactive “Clear all data” control |

On wide layouts (900 px and above), the app uses a left sidebar. On narrower layouts, it uses a drawer and a bottom bar with Home, Leads, Pipeline, Quotes, and More. The More drawer exposes the other sidebar destinations.

The source also contains a Tasks screen, but it is **not connected to the main navigation** in the current app.

## 3. User-facing features

### 3.1 Authentication and account access

The login page provides:

- Email and password sign-in.
- Account registration with full name, email, password, and confirmation. The client requires a six-character minimum password and matching confirmation.
- Password-reset email flow.
- Google sign-in.
- An “Explore Demo Portal” shortcut that enters a demo session.
- Persistent local identity and session-token storage, plus logout from the sidebar.

The client uses Firebase Authentication when Firebase is configured. It also uses the Go API for email/password login and registration. After Firebase sign-in, the app may obtain a backend JWT using credentials supplied through Firebase Remote Config so authenticated API requests can be made.

If the backend is unavailable, the app can enter demo mode and display sample records. Demo/sample changes should not be treated as durable production data.

### 3.2 Dashboard

The dashboard loads the dashboard summary and leads, then derives several metrics for display:

- Total leads.
- Hot leads (leads in Negotiation).
- Quotes pending (leads in Quotation Sent).
- Month-to-date revenue.
- Lead conversion rate (Order Confirmed leads divided by all leads).
- Average deal size.
- An “Overdue Follow-Ups” count.
- Active campaigns.

It also shows:

- **Monthly Pipeline Activity:** lead counts grouped by sales stage over a recent monthly window.
- **Conversion Funnel:** counts for New, Contacted, Quotation Sent, Negotiation, and Order Confirmed, with stage-to-stage percentages.
- A header search box whose current screen code does not wire up a search action.

Several trend captions and the active-campaign figure are currently fixed display values, not comparisons computed from historical records. The overdue-follow-up card uses the backend’s count of non-completed tasks; it is not a due-date-based overdue calculation.

### 3.3 Leads

Leads are the primary sales prospect/contact records. A lead contains:

- Name, company, email, phone.
- Customer type (the UI describes this as one-time/repeated).
- Inquiry date.
- City and state.
- Three follow-up note fields.
- Sales status and estimated value.
- Creation timestamp.

The Leads screen includes:

- A table with name, company, email, phone, status, value, customer type, date, city, state, follow-up fields, and row actions.
- Filters for **All Active**, **All Leads**, or an individual status. All Active excludes Order Confirmed and Lost.
- Add lead, edit lead, and delete lead actions.
- Inline editing for Follow Up 2 and Follow Up 3, plus full editing of lead fields. Follow Up 1 is read-only in the full edit dialog.
- A destructive Clear All action guarded by a confirmation dialog. It also unlinks quotations from leads before deleting leads on the server.
- CSV and Excel import/export.

The add/edit forms require a name. A new lead defaults to status New, customer type “one time,” and value 0.

#### Lead import and export

Import accepts `.csv`, `.xlsx`, and `.xls` files. It reads the first worksheet for Excel files and expects a header row. Column matching is case-insensitive and tolerates several aliases for name/contact, phone, customer type, value, date, and follow-up fields. The importer normalizes common status descriptions into the CRM’s six statuses and skips rows with no name, company, or phone.

Export lets the user save a CSV or `.xlsx` containing the current client-side lead list. The export contains Name, Company, Email, Phone, Status, and Value; it does not export every field supported by the lead model.

### 3.4 Sales pipeline

Pipeline is a horizontally scrolling Kanban board with one column for each lead status:

1. New
2. Contacted
3. Quotation Sent
4. Negotiation
5. Order Confirmed
6. Lost

Each column shows its lead count and combined estimated value. Lead cards show the company/contact, email when present, and value. Users can:

- Drag a card to another column to update the lead status.
- Use the card menu to move a lead to a specific status or delete it.
- Add a lead from the board.

Status changes are sent to the lead API and reflected in the shared lead provider, so the list, pipeline, and reports use the same client-side lead state.

### 3.5 Quotations

The Quotation screen includes:

- Search and status filtering (All Status, Draft, Pending Approval, Accepted, Sent).
- Summary cards for total quote value, accepted count, pending-approval count, and draft count.
- A table displaying quote number, customer, status, amount, version column, validity date, creation date, and actions.
- View-details, edit, and delete actions. Deletion is confirmed first.

Quote details include customer and linked lead information, validity, notes/terms, line items, subtotal, tax, and total.

#### Creating and editing a quotation

The quote form is organized into Customer Details, Quote Info, and Line Items:

- Optionally link a lead. Selecting one pre-fills customer name, company, email, and phone; fields remain editable.
- Enter the required customer name and company, plus optional email and phone.
- Select a status: Draft, Pending Approval, Accepted, or Sent.
- Set a valid-until date and enter notes/terms.
- Add or remove line items, selecting a product and entering quantity, unit price, discount percentage, and GST percentage.
- Review live subtotal, GST, and grand-total calculations before saving.

The line-item calculation is:

```text
discounted amount = quantity × unit price × (1 - discount% / 100)
GST              = discounted amount × GST% / 100
line total       = discounted amount + GST
quote total      = sum of discounted amounts + sum of GST
```

The backend rounds monetary values to two decimal places and requires at least one line item. If the quote number is omitted, the backend generates one. A missing validity date defaults to approximately one month from creation; a missing status defaults to Draft.

### 3.6 Dealers

Dealers are stored as a directory separate from leads. Dealer fields include:

- Name, company, email, phone.
- City, state, address.
- GST number and dealer code.
- Status: Active, Inactive, or Suspended.
- Credit limit and notes.
- Created and updated timestamps.

The screen provides:

- Search by name, company, dealer code, city, or phone.
- Status filtering.
- Summary cards for total dealers, active dealers, inactive dealers, and total credit limit.
- A table with dealer code, name, company, phone, city, state, GST number, credit limit, status, and actions.
- Add dealer and delete dealer.

The add form requires a name. The backend generates a dealer code if one is not supplied and defaults the status to Active. The current screen does not expose the backend’s dealer-update endpoint as an edit action.

### 3.7 Tasks

The task model contains a title, description, assignee ID, status, due date, and creation timestamp. Status values used by the UI are Pending, In Progress, and Completed.

The Tasks screen supports:

- Creating a task with a required title, optional description, and selected status.
- Listing tasks with status and description.
- Marking a non-completed task Completed.
- Deleting a task after confirmation.

The current create form assigns a due date automatically rather than letting the user choose one. The task model/API has an assignee field, but the screen does not let the user assign a task to a particular employee.

**Navigation note:** this screen is implemented in `lib/screens/tasks/tasks_screen.dart`, but no main-layout route points to it. The task API and analytics still load task data.

### 3.8 Reports and analytics

The Reports screen derives its analytics from leads, quotes, and tasks. It includes:

- KPI cards for Win Rate, Total Revenue, Pipeline Value, Average Deal Size, Total Quotes, and Task Completion.
- A sales funnel showing lead counts and relative conversion through New, Contacted, Quotation Sent, Negotiation, and Order Confirmed.
- A weekly acquisition trend chart comparing lead and quote creation over seven weeks.
- Revenue by Pipeline Stage, summing estimated lead values for each lead status.
- A task-status breakdown.
- A conversion table with stage count, share of total, conversion to next stage, and pipeline value.

These reports are calculated in the client from the records returned by the APIs. The dashboard’s server summary and the Reports screen’s client-side calculations are separate calculation paths.

### 3.9 Settings

Settings currently displays:

- Profile name and email from the current auth identity.
- A role label shown as “Admin.”
- A fixed app-version label.
- The configured backend base URL.
- A fixed “PostgreSQL” database label.

“Clear all data” is displayed but its button has no action wired up. Settings should therefore be treated as a placeholder, not a finished account or administration module.

## 4. Data model and relationships

| Entity | Main data | Notes |
|---|---|---|
| User | Name, unique email, hashed password, role, created timestamp | Roles in the model are `admin` and `employee`. |
| Lead | Contact/company data, customer type, inquiry date, city/state, three follow-up notes, status, estimated value, assigned user ID | Drives the list, Kanban board, funnel, and several KPIs. |
| Task | Title, description, assignee ID, status, due date | Not currently linked to a lead in the model. |
| Deal | Optional lead ID, amount, stage, creation timestamp | API/model exists; there is no dedicated deal-management screen in the main navigation. |
| Quotation | Quote number, embedded customer details, optional lead ID, status, validity, notes, subtotal/tax/total, timestamps | Customer fields are embedded in the quote; there is no separate customer CRUD entity in the current model migration. |
| Quotation item | Product, quantity, unit price, discount %, GST %, line total | Belongs to a quotation; deleted/replaced with the parent quote’s items. |
| Dealer | Contact/company/location data, GST number, dealer code, status, credit limit, notes, timestamps | Dealer code is unique. Dealers are not modeled as quote customers. |

Key relationships:

- A quotation can optionally reference a lead.
- A quotation has one or more line items.
- Lead deletion is explicitly handled by unlinking its quotations in the clear-all endpoint; ordinary single-lead deletion does not use the same explicit unlinking flow in the handler.
- Users, leads, tasks, and deals contain assignment/ownership fields, but the current UI does not provide a complete employee-assignment workflow.

## 5. REST API outline

The Go service exposes public health/auth routes and JWT-protected `/api` routes. Database-dependent routes return service unavailable when PostgreSQL is not connected.

| Method and path | Purpose |
|---|---|
| `GET /` | API identity/status response |
| `GET /health` | Service and database connectivity status |
| `POST /auth/register` | Register an account |
| `POST /auth/login` | Validate credentials and return a JWT plus user summary |
| `GET /api/dashboard/summary` | Task counts and revenue summary |
| `GET /api/leads` | List leads |
| `POST /api/leads` | Create a lead |
| `POST /api/leads/import` | Bulk-import leads |
| `PUT /api/leads/:id` | Update selected lead fields |
| `DELETE /api/leads/:id` | Delete one lead |
| `DELETE /api/leads` | Unlink and clear all leads |
| `GET`, `POST /api/deals` | List and create deals |
| `PUT`, `DELETE /api/deals/:id` | Update or delete a deal |
| `GET /api/tasks` | List tasks |
| `POST /api/tasks` | Create a task |
| `PUT`, `DELETE /api/tasks/:id` | Update or delete a task |
| `GET /api/quotes` | List/search/filter quotations |
| `GET /api/quotes/:id` | Get one quotation |
| `POST /api/quotes` | Create a quotation and its items |
| `PUT`, `DELETE /api/quotes/:id` | Update or delete a quotation |
| `GET /api/dealers` | List/search/filter dealers |
| `GET /api/dealers/:id` | Get one dealer |
| `POST /api/dealers` | Create a dealer |
| `PUT`, `DELETE /api/dealers/:id` | Update or delete a dealer |

Authenticated API requests use the `Authorization` header with the backend JWT. The backend hashes passwords with bcrypt and issues signed JWTs. PostgreSQL tables are created/updated through GORM auto-migration at service startup.

## 6. Technical architecture

### Client

- Flutter and Dart, targeting web, mobile, and desktop.
- `provider` / `ChangeNotifier` for session and feature state.
- `dio` for HTTP requests.
- `shared_preferences` for locally stored token and user identity.
- `fl_chart` for charts.
- `file_picker`, `csv`, and `excel` for lead file import/export.
- Responsive navigation and layouts; desktop sidebar switches to mobile drawer/bottom navigation.
- Google Fonts and a shared light theme.

### Backend and integrations

- Go with Gin for HTTP routing and middleware.
- GORM with PostgreSQL for persistence and migrations.
- JWT authentication, bcrypt password hashing, and CORS configuration.
- Firebase Core/Auth and Google Sign-In for optional identity providers.
- Firebase Remote Config for backend admin credentials used by the Firebase-to-backend token bridge.
- API base URL can be overridden at Flutter build/run time with `API_BASE_URL`. The current client otherwise selects between its production URL and a local debug backend according to platform and health checks.

The bundled `docker-compose.yml` defines a PostgreSQL service on host port 5433. The Flutter web static server alone serves the client; it does not start the Go API or PostgreSQL.

## 7. Suggested build plan for a similar CRM

1. **Define users and permissions:** decide team roles and which records each role may view/edit. Enforce access rules in the API, not only in the client.
2. **Create the relational schema:** users, leads, tasks, deals, quotations, quotation items, and dealer/customer records. Add indexes for common filters and unique business identifiers.
3. **Build authentication and API foundations:** health checks, input validation, password hashing, short-lived access tokens, CORS, migrations, and consistent error responses.
4. **Implement leads first:** CRUD, status lifecycle, search/filter/pagination, follow-up history, and validated bulk import/export.
5. **Add pipeline and tasks:** keep stage transitions consistent with lead history; support task deadlines, ownership, and links to the related lead/deal.
6. **Add quotation creation:** customer/lead selection, line-item calculations, tax rules, numbering, status transitions, validity, and an auditable edit history.
7. **Add dealer management:** CRUD, status controls, credit-limit rules, and duplicate checks.
8. **Build dashboard/report queries:** calculate KPIs consistently on the server, define date ranges and denominators, and test against known datasets.
9. **Add responsive UI and empty/loading/error states:** use shared providers/services, accessible forms, confirmation for destructive actions, and mobile-specific navigation.
10. **Test end-to-end:** auth and permissions, CRUD/API validation, quote arithmetic and rounding, import/export edge cases, dashboard calculations, responsive UI, and migration/backup recovery.

## 8. Current implementation gaps to account for

- Tasks are implemented but not reachable from the application’s main navigation.
- Settings is informational scaffolding; its “Clear all data” control is inactive.
- The dashboard’s global search box has no search behavior wired in.
- Dashboard trend percentages and active-campaign values are hard-coded display values.
- The dashboard “Overdue Follow-Ups” count is based on non-completed tasks, not tasks whose due date has passed.
- There is an API/model for deals, but no main-navigation deal screen or deal workflow.
- There is no separate persisted customer entity; quotation customer information is embedded in the quotation.
- The UI does not expose complete user administration, role-based page access, assignment workflows, task due-date editing, or dealer editing.
- Demo/fallback data is useful for previewing the interface, but it is not a substitute for a configured API and database. Some screens also handle network failures differently, so a production clone should make online/offline behavior explicit and consistent.

## 9. Source map

| Area | Key source files |
|---|---|
| App startup and routing | `lib/main.dart`, `lib/screens/main_layout.dart`, `lib/widgets/sidebar.dart` |
| Authentication | `lib/screens/auth/login_screen.dart`, `lib/core/providers/auth_provider.dart` |
| Feature screens | `lib/screens/dashboard/`, `lib/screens/leads/`, `lib/screens/quotes/`, `lib/screens/dealers/`, `lib/screens/tasks/`, `lib/screens/analytics/` |
| Client state and API | `lib/core/providers/`, `lib/core/network/api_client.dart` |
| Server routes and schema | `server/pkg/server/router.go`, `server/internal/models/models.go`, `server/pkg/database/db.go` |
| Server feature handlers | `server/internal/auth/`, `server/internal/leads/`, `server/internal/deals/`, `server/internal/tasks/`, `server/internal/quotes/`, `server/internal/dealers/`, `server/internal/dashboard/` |
