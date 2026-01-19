# Technical Specifications

## System Architecture

### Overview
GTM Peerlist is a platform for GTM agencies to showcase their work and connect with potential clients. Built on the existing application infrastructure using tRPC, PostgreSQL, and Next.js.

### Components
- **Database**: PostgreSQL with 7 new tables
- **API**: tRPC router with public and protected procedures
- **Frontend**: Next.js app router pages
- **Workers**: Background jobs for notifications and image processing
- **Storage**: Image upload service for logos and photos

## Data Models

### agencies
Primary table for agency profiles.

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default gen_random_uuid() |
| user_id | UUID | FK → users(id), NOT NULL |
| name | VARCHAR(255) | NOT NULL |
| slug | VARCHAR(255) | UNIQUE, NOT NULL |
| tagline | VARCHAR(500) | |
| description | TEXT | |
| logo_url | TEXT | |
| website_url | TEXT | |
| location | VARCHAR(255) | |
| founded_year | INTEGER | |
| services | TEXT[] | |
| industries | TEXT[] | |
| company_sizes | TEXT[] | |
| engagement_models | TEXT[] | |
| pricing_range | VARCHAR(50) | |
| is_verified | BOOLEAN | DEFAULT false |
| is_featured | BOOLEAN | DEFAULT false |
| status | VARCHAR(20) | DEFAULT 'active' |
| linkedin_url | TEXT | |
| twitter_url | TEXT | |
| github_url | TEXT | |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

### case_studies
Agency case studies with flexible metrics.

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| agency_id | UUID | FK → agencies(id), NOT NULL |
| client_name | VARCHAR(255) | NOT NULL |
| client_industry | VARCHAR(255) | |
| client_company_size | VARCHAR(50) | |
| client_logo_url | TEXT | |
| title | VARCHAR(255) | NOT NULL |
| challenge | TEXT | NOT NULL |
| solution | TEXT | NOT NULL |
| results | TEXT | NOT NULL |
| metrics | JSONB | DEFAULT '{}' |
| cover_image_url | TEXT | |
| additional_images | TEXT[] | |
| start_date | DATE | |
| end_date | DATE | |
| duration_months | INTEGER | |
| services_used | TEXT[] | |
| is_featured | BOOLEAN | DEFAULT false |
| is_public | BOOLEAN | DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

### testimonials
Client testimonials with optional ratings.

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| agency_id | UUID | FK → agencies(id), NOT NULL |
| client_name | VARCHAR(255) | NOT NULL |
| client_role | VARCHAR(255) | NOT NULL |
| client_company | VARCHAR(255) | NOT NULL |
| client_photo_url | TEXT | |
| client_linkedin_url | TEXT | |
| quote | TEXT | NOT NULL |
| rating | INTEGER | CHECK (1-5) |
| case_study_id | UUID | FK → case_studies(id) |
| is_featured | BOOLEAN | DEFAULT false |
| is_verified | BOOLEAN | DEFAULT false |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

### team_members
Agency team member profiles.

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| agency_id | UUID | FK → agencies(id), NOT NULL |
| user_id | UUID | FK → users(id), optional |
| name | VARCHAR(255) | NOT NULL |
| role | VARCHAR(255) | NOT NULL |
| bio | TEXT | |
| photo_url | TEXT | |
| linkedin_url | TEXT | |
| twitter_url | TEXT | |
| personal_website | TEXT | |
| is_featured | BOOLEAN | DEFAULT false |
| display_order | INTEGER | DEFAULT 0 |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

### inquiries
Contact requests from potential clients.

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| agency_id | UUID | FK → agencies(id), NOT NULL |
| from_user_id | UUID | FK → users(id), NOT NULL |
| subject | VARCHAR(255) | NOT NULL |
| message | TEXT | NOT NULL |
| company_name | VARCHAR(255) | |
| company_size | VARCHAR(50) | |
| budget_range | VARCHAR(50) | |
| timeline | VARCHAR(100) | |
| status | VARCHAR(20) | DEFAULT 'pending' |
| responded_at | TIMESTAMPTZ | |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

### agency_views
Profile view tracking for analytics.

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| agency_id | UUID | FK → agencies(id), NOT NULL |
| viewer_user_id | UUID | FK → users(id), optional |
| viewed_at | TIMESTAMPTZ | DEFAULT now() |
| referrer | TEXT | |
| user_agent | TEXT | |
| viewed_section | VARCHAR(50) | |

### saved_agencies
User bookmarks for agencies.

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users(id), NOT NULL |
| agency_id | UUID | FK → agencies(id), NOT NULL |
| created_at | TIMESTAMPTZ | DEFAULT now() |

Unique constraint on (user_id, agency_id).

## API Specifications

### Public Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| agencies.list | query | List agencies with pagination, filters, search |
| agencies.getBySlug | query | Get single agency with all related data |
| caseStudies.get | query | Get single case study |
| inquiries.create | mutation | Submit inquiry to agency |
| analytics.trackView | mutation | Track profile view |

### Protected Endpoints (Agency Owner)

| Endpoint | Method | Description |
|----------|--------|-------------|
| agencies.create | mutation | Create new agency |
| agencies.update | mutation | Update agency profile |
| agencies.getMine | query | Get current user's agency |
| caseStudies.list | query | List agency case studies |
| caseStudies.create | mutation | Create case study |
| caseStudies.update | mutation | Update case study |
| caseStudies.delete | mutation | Delete case study |
| testimonials.list | query | List agency testimonials |
| testimonials.create | mutation | Create testimonial |
| testimonials.update | mutation | Update testimonial |
| testimonials.delete | mutation | Delete testimonial |
| teamMembers.list | query | List team members |
| teamMembers.create | mutation | Create team member |
| teamMembers.update | mutation | Update team member |
| teamMembers.delete | mutation | Delete team member |
| inquiries.list | query | List received inquiries |
| inquiries.markResponded | mutation | Mark inquiry as responded |
| analytics.get | query | Get agency analytics |

### Filter Parameters (agencies.list)

| Parameter | Type | Description |
|-----------|------|-------------|
| search | string | Full-text search on name, tagline, description |
| industries | string[] | Filter by industry |
| services | string[] | Filter by service type |
| locations | string[] | Filter by location |
| verified | boolean | Filter verified agencies only |
| limit | number | Page size (1-100, default 20) |
| offset | number | Pagination offset |
| sortBy | enum | relevance, newest, most_viewed |

## User Interface Requirements

### Public Pages

**Agency Directory (/agencies)**
- Search bar with instant search
- Filter dropdowns: industries, services, locations
- Sort dropdown: relevance, newest, most viewed
- Paginated agency card grid
- AgencyCard: logo, name, tagline, services, location, verified badge

**Agency Profile (/agencies/[slug])**
- Header: logo, name, tagline, verified badge, contact button
- Tab navigation: About, Case Studies, Testimonials, Team
- About tab: description, services list, industries, location, website, social links
- Case Studies tab: card grid with title, client, metrics, expand for details
- Testimonials tab: cards with quote, client info, rating
- Team tab: member cards with photo, name, role, links

### Authenticated Pages

**Agency Dashboard (/app/[teamSlug]/agencies)**
- Stats overview: views, inquiries, case studies count
- Quick actions: add case study, testimonial, team member
- Recent inquiries list

**Edit Agency (/app/[teamSlug]/agencies/edit)**
- Form with all agency fields
- Logo upload with preview
- Multi-select for services, industries
- Save/cancel buttons

**Case Studies (/app/[teamSlug]/agencies/case-studies)**
- List with edit/delete actions
- Create/edit form with client info, content, metrics, images

**Testimonials (/app/[teamSlug]/agencies/testimonials)**
- List with edit/delete actions
- Create/edit form with client info, quote, rating

**Team (/app/[teamSlug]/agencies/team)**
- Draggable list for ordering
- Create/edit form with photo, name, role, bio, links

**Inquiries (/app/[teamSlug]/agencies/inquiries)**
- List with status filter
- Inquiry detail view
- Mark as responded action

## Performance Requirements

- Agency list page load: < 2s
- Profile page load: < 1.5s
- Search response: < 500ms
- Image upload: < 5s for 5MB file
- API response times: < 200ms for reads, < 500ms for writes

### Caching Strategy
- Public agency profiles: 5-10 minute TTL
- Agency list: 2 minute TTL
- Invalidate on profile update

### Pagination
- Default page size: 20
- Maximum page size: 100
- Lazy load case studies and testimonials on profile page

## Security Considerations

### Authentication
- Agency profile creation requires authentication
- Public profiles viewable without auth
- Inquiries require authentication (logged-in users only)

### Authorization
- Users can only edit their own agency
- One agency per user account
- 403 returned for unauthorized access attempts

### Validation
- Slug uniqueness check before creation
- Reserved slug blocking: `new`, `edit`, `admin`, `api`, `settings`, `dashboard`, `search`
- Image file type validation (JPEG, PNG, WebP)
- Image file size limit (5MB)
- Input sanitization for all text fields
- Metrics JSONB must be key-value pairs with string or number values

### Data Privacy
- Inquiry details visible only to agency owner
- Analytics visible only to agency owner
- User emails not exposed in public profiles

## Image Requirements

| Type | Dimensions | Aspect Ratio | Max Size |
|------|------------|--------------|----------|
| Logo | 400x400px min | Square | 5MB |
| Case study cover | 1200x600px | 16:9 | 5MB |
| Team member photo | 400x400px | Square | 5MB |

Supported formats: JPEG, PNG, WebP

## Background Jobs

| Job | Trigger | Description |
|-----|---------|-------------|
| inquiry-notification | inquiry.create | Email agency owner about new inquiry |
| image-optimization | image upload | Resize and compress uploaded images |
| analytics-aggregation | daily cron | Aggregate view counts and engagement metrics |

## Enums

### GTMService
- Product Launch
- Market Research
- Sales Enablement
- Demand Generation
- Content Strategy
- Brand Positioning
- PR & Communications
- Partnership Development
- Customer Acquisition
- Growth Strategy

### Industry
- SaaS
- FinTech
- HealthTech
- E-commerce
- Marketplace
- Consumer Tech
- B2B
- B2C
- Deep Tech
- Enterprise

### Agency Status
- active
- inactive
- pending

### Inquiry Status
- pending
- responded
- closed

## Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| Duplicate agency slug | Validate uniqueness, suggest alternatives (append -1, -2, etc.) |
| Multiple agencies per user | Reject with error: "One agency per account allowed" |
| Missing required fields | Show field-level validation errors, prevent submission |
| Image upload failure | Show error toast, allow retry, preserve form data |
| Anonymous profile view | Track view without user_id, no auth required |
| Inquiry to inactive agency | Show warning banner, allow submission, notify owner |
| Deleting case study with linked testimonials | Show confirmation with affected testimonials list, unlink on confirm |
| Empty search results | Show helpful message: "No agencies match your filters", suggest broadening criteria, show featured agencies |
| Unauthorized edit attempt | Return 403 Forbidden, redirect to unauthorized page |
| Invalid metrics JSON | Show error: "Metrics must be key-value pairs (e.g., {\"growth\": \"300%\"})" |
| Slug conflicts with reserved routes | Block creation, suggest alternative slug |

## Foreign Key Behaviors

| Relationship | ON DELETE Behavior |
|--------------|-------------------|
| agencies.user_id → users | CASCADE (delete agency when user deleted) |
| case_studies.agency_id → agencies | CASCADE (delete case studies when agency deleted) |
| testimonials.agency_id → agencies | CASCADE (delete testimonials when agency deleted) |
| testimonials.case_study_id → case_studies | SET NULL (preserve testimonial, unlink case study) |
| team_members.agency_id → agencies | CASCADE (delete team members when agency deleted) |
| team_members.user_id → users | SET NULL (preserve team member, unlink user) |
| inquiries.agency_id → agencies | CASCADE (delete inquiries when agency deleted) |
| inquiries.from_user_id → users | CASCADE (delete inquiry when sender deleted) |
| agency_views.agency_id → agencies | CASCADE (delete views when agency deleted) |
| agency_views.viewer_user_id → users | SET NULL (preserve view, unlink viewer) |
| saved_agencies.user_id → users | CASCADE |
| saved_agencies.agency_id → agencies | CASCADE |

## Slug Generation Rules

1. Convert agency name to lowercase
2. Replace spaces with hyphens
3. Remove special characters (keep alphanumeric and hyphens)
4. Collapse multiple hyphens to single hyphen
5. Trim leading/trailing hyphens
6. Check uniqueness in database
7. If duplicate, append incrementing number (-1, -2, etc.)
8. Reject if matches reserved slug list

### Reserved Slugs
- `new`
- `edit`
- `admin`
- `api`
- `settings`
- `dashboard`
- `search`
- `compare`
- `saved`

## Notification Emails

### Inquiry Notification
- **Trigger**: New inquiry created
- **Recipient**: Agency owner email
- **Subject**: "New inquiry from [Company Name]"
- **Content**: Inquiry subject, message preview, sender company info, link to inquiries page

### Verification Status Change
- **Trigger**: Agency verification status updated by admin
- **Recipient**: Agency owner email
- **Subject**: "Your agency has been verified" / "Verification status update"
- **Content**: Status change details, next steps if applicable
