# GTM Peerlist - Product Requirements Document

**Version:** 1.0  
**Date:** 2026-01-19  
**Status:** Draft  
**Author:** Development Team

---

## 1. Executive Summary

GTM Peerlist is a professional networking and discovery platform specifically designed for Go-To-Market (GTM) agencies. Similar to how Peerlist.io serves developers, GTM Peerlist enables agencies to showcase their work, build their reputation, connect with potential clients, and discover collaboration opportunities.

**Problem Statement:**
- GTM agencies struggle to showcase their work and results in a standardized, discoverable way
- Companies looking for GTM agencies have difficulty finding and evaluating agencies based on real results
- There's no centralized platform for GTM professionals to network and share knowledge
- Agencies lack a way to build credibility through verified case studies and client testimonials

**Solution:**
A platform where GTM agencies can create rich profiles, showcase case studies with metrics, display client testimonials, and connect with potential clients. Companies can discover agencies based on industry, services, and proven results.

**Who Benefits:**
- GTM agencies seeking new clients and partnerships
- Companies looking to hire GTM agencies
- GTM professionals wanting to build their personal brand
- The GTM community seeking knowledge sharing and networking

---

## 2. Goals & Success Metrics

### Goals
- Create a vibrant community of GTM agencies and professionals
- Enable agencies to showcase their work and results effectively
- Facilitate connections between agencies and potential clients
- Build trust through verified case studies and testimonials
- Provide a discovery mechanism for companies to find the right GTM agency

### Success Metrics (Future)
- **Agency Signups**: Number of agencies creating profiles (target: 100 in first 3 months)
- **Profile Completeness**: % of agencies with complete profiles (case studies, testimonials, metrics)
- **Discovery Engagement**: Number of profile views and inquiries per agency
- **Connection Rate**: % of profile views that result in inquiries/connections
- **Content Quality**: Average number of case studies per agency
- **User Retention**: Monthly active agencies and companies
- **Network Growth**: Number of connections/relationships formed

---

## 3. User Personas

### 1. Agency Owner/Founder (Primary)
- **Who**: Founder or owner of a GTM agency
- **Needs**: 
  - Showcase agency capabilities and past work
  - Attract new clients
  - Build credibility and reputation
  - Network with other agencies
  - Recruit talent
- **Pain Points**: 
  - Hard to stand out in a crowded market
  - Difficult to demonstrate ROI to prospects
  - Time-consuming to create marketing materials

### 2. Company/Buyer (Primary)
- **Who**: VP of Marketing, CMO, or founder looking to hire a GTM agency
- **Needs**:
  - Find agencies with relevant experience
  - Compare agencies based on results
  - Verify agency claims through case studies
  - Contact agencies easily
- **Pain Points**:
  - Don't know which agencies to trust
  - Hard to compare apples-to-apples
  - Lack of transparency on actual results

### 3. GTM Professional (Secondary)
- **Who**: Individual GTM consultant or employee at an agency
- **Needs**:
  - Build personal brand
  - Showcase individual contributions
  - Network with peers
  - Find new opportunities
- **Pain Points**:
  - Hard to showcase individual work within agency context
  - Need platform for personal branding

### 4. Agency Team Member (Secondary)
- **Who**: Employee at a GTM agency
- **Needs**:
  - Showcase work they've contributed to
  - Build professional reputation
  - Learn from other agencies
- **Pain Points**:
  - Credit for work often goes to agency, not individual

---

## 4. Feature Scope

### 4.1 MVP (Phase 1) - Core Platform

**Priority: HIGHEST**

Core functionality to launch the platform and enable basic agency discovery.

| Feature | Description | Priority |
|---------|-------------|----------|
| Agency Registration & Profiles | Agencies can create accounts and build comprehensive profiles with company info, logo, description, location, website | P0 |
| Case Study Creation | Agencies can create detailed case studies with client info, challenge, solution, results/metrics, timeline | P0 |
| Client Testimonials | Agencies can add client testimonials with client name, role, company, quote, and optional photo | P0 |
| Services & Specializations | Agencies can list services offered (e.g., Product Launch, Market Research, Sales Enablement) and industry focus areas | P0 |
| Agency Discovery/Listing | Public directory of agencies with search, filters (industry, services, location), and sorting | P0 |
| Agency Profile Pages | Public-facing profile pages showcasing agency info, case studies, testimonials, team, and contact info | P0 |
| Basic Authentication | User registration, login, password reset for agencies | P0 |
| Image Upload | Support for uploading agency logos, case study images, team photos | P0 |

### 4.2 Phase 2 - Enhanced Discovery & Networking

**Priority: HIGH**

Features to improve discovery and enable networking.

| Feature | Description | Priority |
|---------|-------------|----------|
| Advanced Search & Filters | Filter by metrics (e.g., revenue growth achieved), company size, engagement model, pricing range | P1 |
| Agency Verification | Badge system for verified agencies (manual or automated verification) | P1 |
| Connection/Inquiry System | Companies can send inquiries to agencies, agencies can respond | P1 |
| Agency Comparison | Side-by-side comparison tool for companies to compare multiple agencies | P1 |
| Team Member Profiles | Individual team members can create profiles linked to their agency | P1 |
| Reviews & Ratings | Clients can leave public reviews and ratings for agencies | P1 |
| Saved Agencies | Companies can save/bookmark agencies they're interested in | P1 |
| Activity Feed | Feed showing new agencies, case studies, and updates | P1 |

### 4.3 Phase 3 - Community & Advanced Features

**Priority: MEDIUM**

Community features and advanced functionality.

| Feature | Description | Priority |
|---------|-------------|----------|
| Messaging System | Direct messaging between companies and agencies | P2 |
| Job Board | Agencies can post job openings, professionals can browse opportunities | P2 |
| Knowledge Sharing | Blog posts, articles, templates shared by agencies | P2 |
| Analytics Dashboard | Agencies can see profile views, inquiry stats, engagement metrics | P2 |
| Agency Badges/Achievements | Gamification with badges for milestones (e.g., "10 Case Studies", "Verified Results") | P2 |
| Integration with CRM | Connect with popular CRMs to import case study data | P2 |
| White-label Profiles | Agencies can use custom domains for their profiles | P2 |
| API Access | Public API for agencies to integrate their profiles | P2 |

---

## 5. Data Model

### 5.1 New Database Tables

```sql
-- Agencies table
CREATE TABLE agencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Basic Info
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  tagline VARCHAR(500),
  description TEXT,
  logo_url TEXT,
  website_url TEXT,
  location VARCHAR(255),
  founded_year INTEGER,
  
  -- Services & Specializations
  services TEXT[], -- Array of service types
  industries TEXT[], -- Array of industry focus areas
  company_sizes TEXT[], -- Array of target company sizes
  
  -- Engagement Info
  engagement_models TEXT[], -- e.g., "Retainer", "Project-based", "Equity"
  pricing_range VARCHAR(50), -- e.g., "$10k-$50k", "Custom"
  
  -- Status
  is_verified BOOLEAN NOT NULL DEFAULT false,
  is_featured BOOLEAN NOT NULL DEFAULT false,
  status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, inactive, pending
  
  -- Social Links
  linkedin_url TEXT,
  twitter_url TEXT,
  github_url TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Case Studies table
CREATE TABLE case_studies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  
  -- Client Info
  client_name VARCHAR(255) NOT NULL,
  client_industry VARCHAR(255),
  client_company_size VARCHAR(50),
  client_logo_url TEXT,
  
  -- Case Study Content
  title VARCHAR(255) NOT NULL,
  challenge TEXT NOT NULL,
  solution TEXT NOT NULL,
  results TEXT NOT NULL,
  
  -- Metrics (stored as JSONB for flexibility)
  metrics JSONB NOT NULL DEFAULT '{}', -- e.g., {"revenue_growth": "300%", "mql_increase": "250%"}
  
  -- Media
  cover_image_url TEXT,
  additional_images TEXT[],
  
  -- Timeline
  start_date DATE,
  end_date DATE,
  duration_months INTEGER,
  
  -- Services Used
  services_used TEXT[],
  
  -- Status
  is_featured BOOLEAN NOT NULL DEFAULT false,
  is_public BOOLEAN NOT NULL DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Testimonials table
CREATE TABLE testimonials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  
  -- Client Info
  client_name VARCHAR(255) NOT NULL,
  client_role VARCHAR(255) NOT NULL,
  client_company VARCHAR(255) NOT NULL,
  client_photo_url TEXT,
  client_linkedin_url TEXT,
  
  -- Testimonial Content
  quote TEXT NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  
  -- Related Case Study (optional)
  case_study_id UUID REFERENCES case_studies(id) ON DELETE SET NULL,
  
  -- Status
  is_featured BOOLEAN NOT NULL DEFAULT false,
  is_verified BOOLEAN NOT NULL DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Team Members table
CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Optional link to user account
  
  -- Basic Info
  name VARCHAR(255) NOT NULL,
  role VARCHAR(255) NOT NULL,
  bio TEXT,
  photo_url TEXT,
  
  -- Links
  linkedin_url TEXT,
  twitter_url TEXT,
  personal_website TEXT,
  
  -- Status
  is_featured BOOLEAN NOT NULL DEFAULT false,
  display_order INTEGER NOT NULL DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Inquiries/Connections table
CREATE TABLE inquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Inquiry Details
  subject VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  company_name VARCHAR(255),
  company_size VARCHAR(50),
  budget_range VARCHAR(50),
  timeline VARCHAR(100),
  
  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, responded, closed
  responded_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Agency Views/Analytics table
CREATE TABLE agency_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  viewer_user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Null for anonymous
  
  -- View Details
  viewed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  referrer TEXT,
  user_agent TEXT,
  
  -- What was viewed
  viewed_section VARCHAR(50) -- profile, case_study, testimonials, etc.
);

-- Saved Agencies (bookmarks)
CREATE TABLE saved_agencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(user_id, agency_id)
);
```

### 5.2 New Types/Schemas

```typescript
// Agency types
type Agency = {
  id: string;
  userId: string;
  name: string;
  slug: string;
  tagline?: string;
  description?: string;
  logoUrl?: string;
  websiteUrl?: string;
  location?: string;
  foundedYear?: number;
  services: string[];
  industries: string[];
  companySizes: string[];
  engagementModels: string[];
  pricingRange?: string;
  isVerified: boolean;
  isFeatured: boolean;
  status: 'active' | 'inactive' | 'pending';
  linkedinUrl?: string;
  twitterUrl?: string;
  githubUrl?: string;
  createdAt: Date;
  updatedAt: Date;
};

// Case Study types
type CaseStudy = {
  id: string;
  agencyId: string;
  clientName: string;
  clientIndustry?: string;
  clientCompanySize?: string;
  clientLogoUrl?: string;
  title: string;
  challenge: string;
  solution: string;
  results: string;
  metrics: Record<string, string | number>; // Flexible metrics
  coverImageUrl?: string;
  additionalImages: string[];
  startDate?: Date;
  endDate?: Date;
  durationMonths?: number;
  servicesUsed: string[];
  isFeatured: boolean;
  isPublic: boolean;
  createdAt: Date;
  updatedAt: Date;
};

// Testimonial types
type Testimonial = {
  id: string;
  agencyId: string;
  clientName: string;
  clientRole: string;
  clientCompany: string;
  clientPhotoUrl?: string;
  clientLinkedinUrl?: string;
  quote: string;
  rating?: number; // 1-5
  caseStudyId?: string;
  isFeatured: boolean;
  isVerified: boolean;
  createdAt: Date;
  updatedAt: Date;
};

// Service and Industry enums
enum GTMService {
  PRODUCT_LAUNCH = 'Product Launch',
  MARKET_RESEARCH = 'Market Research',
  SALES_ENABLEMENT = 'Sales Enablement',
  DEMAND_GENERATION = 'Demand Generation',
  CONTENT_STRATEGY = 'Content Strategy',
  BRAND_POSITIONING = 'Brand Positioning',
  PR_COMMUNICATIONS = 'PR & Communications',
  PARTNERSHIP_DEVELOPMENT = 'Partnership Development',
  CUSTOMER_ACQUISITION = 'Customer Acquisition',
  GROWTH_STRATEGY = 'Growth Strategy',
}

enum Industry {
  SAAS = 'SaaS',
  FIN_TECH = 'FinTech',
  HEALTH_TECH = 'HealthTech',
  E_COMMERCE = 'E-commerce',
  MARKETPLACE = 'Marketplace',
  CONSUMER_TECH = 'Consumer Tech',
  B2B = 'B2B',
  B2C = 'B2C',
  DEEP_TECH = 'Deep Tech',
  ENTERPRISE = 'Enterprise',
}
```

### 5.3 Data Shape

For data registry integration (if applicable):

| Column | Data Shape | Description |
|--------|------------|-------------|
| agency.name | `text` | Agency company name |
| agency.website_url | `url` | Agency website |
| case_study.client_name | `text` | Client company name |
| case_study.metrics | `json` | Flexible metrics object |
| testimonial.quote | `text` | Testimonial quote content |

---

## 6. Technical Architecture

### 6.1 External APIs Required

| Endpoint | Method | Use Case | Notes |
|----------|--------|----------|-------|
| Image upload service | POST | Upload logos, photos, case study images | Use existing image upload service or S3 |
| Email service | POST | Send inquiry notifications, verification emails | Use existing email service |
| Analytics service | POST | Track profile views, engagement | Optional for MVP |

### 6.2 New API Functions

```typescript
// Agency operations
export async function createAgency(input: CreateAgencyInput): Promise<Agency>
export async function updateAgency(id: string, input: UpdateAgencyInput): Promise<Agency>
export async function getAgencyBySlug(slug: string): Promise<Agency | null>
export async function listAgencies(filters: AgencyFilters): Promise<Agency[]>
export async function searchAgencies(query: string, filters: AgencyFilters): Promise<Agency[]>

// Case Study operations
export async function createCaseStudy(agencyId: string, input: CreateCaseStudyInput): Promise<CaseStudy>
export async function updateCaseStudy(id: string, input: UpdateCaseStudyInput): Promise<CaseStudy>
export async function deleteCaseStudy(id: string): Promise<void>
export async function getCaseStudy(id: string): Promise<CaseStudy | null>
export async function listCaseStudies(agencyId: string): Promise<CaseStudy[]>

// Testimonial operations
export async function createTestimonial(agencyId: string, input: CreateTestimonialInput): Promise<Testimonial>
export async function updateTestimonial(id: string, input: UpdateTestimonialInput): Promise<Testimonial>
export async function deleteTestimonial(id: string): Promise<void>
export async function listTestimonials(agencyId: string): Promise<Testimonial[]>

// Team Member operations
export async function createTeamMember(agencyId: string, input: CreateTeamMemberInput): Promise<TeamMember>
export async function updateTeamMember(id: string, input: UpdateTeamMemberInput): Promise<TeamMember>
export async function deleteTeamMember(id: string): Promise<void>
export async function listTeamMembers(agencyId: string): Promise<TeamMember[]>

// Inquiry operations
export async function createInquiry(agencyId: string, input: CreateInquiryInput): Promise<Inquiry>
export async function listInquiries(agencyId: string): Promise<Inquiry[]>
export async function markInquiryResponded(id: string): Promise<Inquiry>

// Analytics
export async function trackAgencyView(agencyId: string, metadata: ViewMetadata): Promise<void>
export async function getAgencyAnalytics(agencyId: string): Promise<AgencyAnalytics>
```

### 6.3 Background Jobs

1. **`job:agency-verification-email`** - Sends verification email when agency is created or verification status changes
2. **`job:inquiry-notification`** - Sends email notification to agency when new inquiry is received
3. **`job:agency-analytics-aggregation`** - Daily job to aggregate view counts and engagement metrics
4. **`job:image-optimization`** - Optimizes uploaded images (resize, compress) after upload

### 6.4 File Structure

```
apps/web/src/app/
├── agencies/                          # Public agency directory
│   ├── page.tsx                      # Agency listing/search page
│   ├── [slug]/
│   │   └── page.tsx                  # Public agency profile page
│   └── _components/
│       ├── AgencyCard.tsx
│       ├── AgencyFilters.tsx
│       ├── AgencySearch.tsx
│       └── AgencyProfile.tsx
│
├── app/[teamSlug]/agencies/          # Agency management (authenticated)
│   ├── page.tsx                      # Agency dashboard
│   ├── edit/
│   │   └── page.tsx                  # Edit agency profile
│   ├── case-studies/
│   │   ├── page.tsx                  # List case studies
│   │   ├── new/
│   │   │   └── page.tsx              # Create case study
│   │   └── [id]/
│   │       └── page.tsx              # Edit case study
│   ├── testimonials/
│   │   ├── page.tsx                  # List testimonials
│   │   ├── new/
│   │   │   └── page.tsx              # Add testimonial
│   │   └── [id]/
│   │       └── page.tsx              # Edit testimonial
│   ├── team/
│   │   ├── page.tsx                  # Manage team members
│   │   └── [id]/
│   │       └── page.tsx              # Edit team member
│   ├── inquiries/
│   │   └── page.tsx                  # View inquiries
│   └── analytics/
│       └── page.tsx                  # View analytics (Phase 2)
│
└── _components/agencies/
    ├── CaseStudyCard.tsx
    ├── CaseStudyForm.tsx
    ├── TestimonialCard.tsx
    ├── TestimonialForm.tsx
    ├── TeamMemberCard.tsx
    ├── TeamMemberForm.tsx
    └── MetricsDisplay.tsx

apps/workers/src/workers/agencies/
├── verification.worker.ts
├── inquiry-notification.worker.ts
├── analytics-aggregation.worker.ts
└── image-optimization.worker.ts
```

---

## 7. User Interface

### 7.1 Access Point

- **Public Agency Directory**: `/agencies` (public, no auth required)
- **Public Agency Profile**: `/agencies/[slug]` (public, no auth required)
- **Agency Dashboard**: `/app/[teamSlug]/agencies` (authenticated, agency owner only)
- **Edit Agency**: `/app/[teamSlug]/agencies/edit` (authenticated, agency owner only)

### 7.2 UI Wireframes

**Agency Directory Page (`/agencies`):**
```
┌─────────────────────────────────────────────────────────────────────┐
│ GTM Agencies                                    [Search...] [Filters]│
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ Filters: [All Industries ▼] [All Services ▼] [All Locations ▼]     │
│                                                                     │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ [Logo] Agency Name                          ⭐ Verified        │ │
│ │ Tagline: Helping SaaS companies scale...                       │ │
│ │ Services: Product Launch • Demand Gen • Sales Enablement       │ │
│ │ Industries: SaaS • B2B                                        │ │
│ │ 📍 San Francisco, CA                                          │ │
│ │ [View Profile]                                                │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ [Logo] Another Agency                         ⭐ Verified        │ │
│ │ ...                                                            │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Public Agency Profile Page (`/agencies/[slug]`):**
```
┌─────────────────────────────────────────────────────────────────────┐
│ [Logo] Agency Name                    ⭐ Verified  [Contact Agency]  │
│ Tagline: Helping SaaS companies scale their GTM operations           │
│                                                                     │
│ [About] [Case Studies] [Testimonials] [Team]                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ About                                                                │
│ ─────────────────────────────────────────────────────────────────  │
│ Description text...                                                 │
│                                                                     │
│ Services: Product Launch, Demand Generation, Sales Enablement       │
│ Industries: SaaS, B2B, Enterprise                                   │
│ Location: San Francisco, CA                                         │
│ Website: agency.com                                                 │
│                                                                     │
│ Case Studies                                                         │
│ ─────────────────────────────────────────────────────────────────  │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ [Image] Case Study: Scaling Product Launch for TechCorp         │ │
│ │ Client: TechCorp | Industry: SaaS | Duration: 6 months         │ │
│ │ Results: 300% revenue growth, 250% MQL increase                │ │
│ │ [Read More]                                                     │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ Testimonials                                                         │
│ ─────────────────────────────────────────────────────────────────  │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ "They transformed our GTM strategy..." ⭐⭐⭐⭐⭐                │ │
│ │ - John Doe, CMO at TechCorp                                      │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Agency Dashboard (`/app/[teamSlug]/agencies`):**
```
┌─────────────────────────────────────────────────────────────────────┐
│ My Agency                              [Edit Profile] [View Public] │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ Overview                                                             │
│ ─────────────────────────────────────────────────────────────────  │
│ Profile Views: 245 (↑ 12% this month)                              │
│ Inquiries: 8 (3 this month)                                        │
│ Case Studies: 5                                                     │
│ Testimonials: 12                                                    │
│                                                                     │
│ Quick Actions                                                        │
│ ─────────────────────────────────────────────────────────────────  │
│ [+ Add Case Study]  [+ Add Testimonial]  [+ Add Team Member]       │
│                                                                     │
│ Recent Inquiries                                                     │
│ ─────────────────────────────────────────────────────────────────  │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ From: Company Name | 2 days ago                                 │ │
│ │ Subject: Looking for Product Launch Support                    │ │
│ │ [View Details] [Mark as Responded]                             │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ Case Studies                                                         │
│ ─────────────────────────────────────────────────────────────────  │
│ [List of case studies with edit/delete actions]                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Create Case Study Form:**
```
┌─────────────────────────────────────────────────────────────────────┐
│ Create Case Study                                            [X]    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ Client Information                                                   │
│ ─────────────────────────────────────────────────────────────────  │
│ Client Name: [________________________]                            │
│ Industry: [SaaS ▼]                                                  │
│ Company Size: [10-50 employees ▼]                                  │
│ Client Logo: [Upload Image]                                         │
│                                                                     │
│ Case Study Details                                                   │
│ ─────────────────────────────────────────────────────────────────  │
│ Title: [________________________]                                   │
│                                                                     │
│ Challenge:                                                          │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ [Text area for challenge description]                            │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ Solution:                                                           │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ [Text area for solution description]                             │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ Results:                                                            │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ [Text area for results description]                              │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ Metrics                                                              │
│ ─────────────────────────────────────────────────────────────────  │
│ Metric Name: [Revenue Growth]  Value: [300%]  [+ Add Metric]       │
│ Metric Name: [MQL Increase]    Value: [250%]  [Remove]             │
│                                                                     │
│ Timeline                                                            │
│ ─────────────────────────────────────────────────────────────────  │
│ Start Date: [MM/DD/YYYY]  End Date: [MM/DD/YYYY]                   │
│                                                                     │
│ Services Used: [Product Launch ✓] [Demand Gen ✓]                   │
│                                                                     │
│ Cover Image: [Upload Image]                                        │
│                                                                     │
│              [Cancel]  [Save Draft]  [Publish]                      │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8. API Routes

### 8.1 tRPC Routes

```typescript
agenciesRouter = router({
  // Public routes
  list: publicProcedure
    .input(z.object({
      search: z.string().optional(),
      industries: z.array(z.string()).optional(),
      services: z.array(z.string()).optional(),
      locations: z.array(z.string()).optional(),
      verified: z.boolean().optional(),
      limit: z.number().min(1).max(100).default(20),
      offset: z.number().min(0).default(0),
      sortBy: z.enum(['relevance', 'newest', 'most_viewed']).default('relevance'),
    }))
    .query(async ({ ctx, input }) => {
      // Return paginated list of agencies
    }),
  
  getBySlug: publicProcedure
    .input(z.object({ slug: z.string() }))
    .query(async ({ ctx, input }) => {
      // Return single agency with all related data
    }),
  
  // Protected routes (agency owner)
  create: protectedProcedure
    .input(createAgencySchema)
    .mutation(async ({ ctx, input }) => {
      // Create new agency, link to current user
    }),
  
  update: protectedProcedure
    .input(z.object({
      id: z.string().uuid(),
      data: updateAgencySchema,
    }))
    .mutation(async ({ ctx, input }) => {
      // Update agency (verify ownership)
    }),
  
  getMine: protectedProcedure
    .query(async ({ ctx }) => {
      // Get current user's agency
    }),
  
  // Case Studies
  caseStudies: router({
    list: protectedProcedure
      .input(z.object({ agencyId: z.string().uuid() }))
      .query(async ({ ctx, input }) => {
        // List case studies for agency
      }),
    
    get: publicProcedure
      .input(z.object({ id: z.string().uuid() }))
      .query(async ({ ctx, input }) => {
        // Get single case study
      }),
    
    create: protectedProcedure
      .input(createCaseStudySchema)
      .mutation(async ({ ctx, input }) => {
        // Create case study (verify agency ownership)
      }),
    
    update: protectedProcedure
      .input(z.object({
        id: z.string().uuid(),
        data: updateCaseStudySchema,
      }))
      .mutation(async ({ ctx, input }) => {
        // Update case study
      }),
    
    delete: protectedProcedure
      .input(z.object({ id: z.string().uuid() }))
      .mutation(async ({ ctx, input }) => {
        // Delete case study
      }),
  }),
  
  // Testimonials
  testimonials: router({
    list: protectedProcedure
      .input(z.object({ agencyId: z.string().uuid() }))
      .query(async ({ ctx, input }) => {
        // List testimonials for agency
      }),
    
    create: protectedProcedure
      .input(createTestimonialSchema)
      .mutation(async ({ ctx, input }) => {
        // Create testimonial
      }),
    
    update: protectedProcedure
      .input(z.object({
        id: z.string().uuid(),
        data: updateTestimonialSchema,
      }))
      .mutation(async ({ ctx, input }) => {
        // Update testimonial
      }),
    
    delete: protectedProcedure
      .input(z.object({ id: z.string().uuid() }))
      .mutation(async ({ ctx, input }) => {
        // Delete testimonial
      }),
  }),
  
  // Team Members
  teamMembers: router({
    list: protectedProcedure
      .input(z.object({ agencyId: z.string().uuid() }))
      .query(async ({ ctx, input }) => {
        // List team members
      }),
    
    create: protectedProcedure
      .input(createTeamMemberSchema)
      .mutation(async ({ ctx, input }) => {
        // Create team member
      }),
    
    update: protectedProcedure
      .input(z.object({
        id: z.string().uuid(),
        data: updateTeamMemberSchema,
      }))
      .mutation(async ({ ctx, input }) => {
        // Update team member
      }),
    
    delete: protectedProcedure
      .input(z.object({ id: z.string().uuid() }))
      .mutation(async ({ ctx, input }) => {
        // Delete team member
      }),
  }),
  
  // Inquiries
  inquiries: router({
    list: protectedProcedure
      .input(z.object({ agencyId: z.string().uuid() }))
      .query(async ({ ctx, input }) => {
        // List inquiries for agency (verify ownership)
      }),
    
    create: publicProcedure
      .input(createInquirySchema)
      .mutation(async ({ ctx, input }) => {
        // Create inquiry (can be from logged-in or anonymous user)
      }),
    
    markResponded: protectedProcedure
      .input(z.object({ id: z.string().uuid() }))
      .mutation(async ({ ctx, input }) => {
        // Mark inquiry as responded
      }),
  }),
  
  // Analytics
  analytics: router({
    get: protectedProcedure
      .input(z.object({ agencyId: z.string().uuid() }))
      .query(async ({ ctx, input }) => {
        // Get analytics for agency (Phase 2)
      }),
    
    trackView: publicProcedure
      .input(z.object({
        agencyId: z.string().uuid(),
        section: z.string().optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        // Track profile view
      }),
  }),
});
```

---

## 9. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| Agency tries to create duplicate slug | Validate slug uniqueness, suggest alternatives |
| User tries to create multiple agencies | Allow only one agency per user (or require team account) |
| Case study with missing required fields | Show validation errors, prevent submission |
| Image upload fails | Show error message, allow retry |
| Agency profile viewed by anonymous user | Track view, don't require authentication |
| Inquiry sent to inactive agency | Show warning, still allow but notify agency owner |
| Agency tries to delete case study with linked testimonial | Show warning, allow deletion but unlink testimonial |
| Search returns no results | Show helpful message with suggestions to broaden filters |
| User tries to edit another agency's profile | Return 403 Forbidden error |
| Invalid metrics format in case study | Validate JSON structure, show clear error |
| Agency slug conflicts with existing route | Check against reserved routes, suggest alternative |

---

## 10. Security & Privacy

### Authentication
- Agencies must be authenticated to create/edit their profiles
- Public profiles are viewable without authentication
- Inquiries can be sent by both authenticated and anonymous users (with different fields)

### Authorization
- **Agency Owners**: Can edit their own agency profile, case studies, testimonials, team members
- **Public Users**: Can view public profiles, send inquiries
- **Admins**: Can verify agencies, feature agencies, moderate content

### Data Privacy
- Client names in case studies are public (agencies should get permission)
- Testimonials are public by default
- Inquiry details are private to agency owner only
- Analytics data is private to agency owner
- User email addresses are not exposed in public profiles

### Content Moderation
- Agencies can be flagged for review
- Admin can verify agencies and case studies
- Testimonials can be marked as verified (requires admin action)

---

## 11. Implementation Phases

### Phase 1: MVP (Target: 4-6 weeks)
- [ ] Database schema and migrations
- [ ] Agency registration and authentication
- [ ] Agency profile creation and editing
- [ ] Case study creation and management
- [ ] Testimonial creation and management
- [ ] Basic team member management
- [ ] Public agency directory with search
- [ ] Public agency profile pages
- [ ] Basic inquiry system
- [ ] Image upload functionality
- [ ] Agency slug generation and validation

### Phase 2: Enhanced Discovery (Target: 2-3 weeks)
- [ ] Advanced search and filtering
- [ ] Agency verification system
- [ ] Inquiry management dashboard
- [ ] Agency comparison tool
- [ ] Saved agencies (bookmarks)
- [ ] Basic analytics dashboard
- [ ] Activity feed

### Phase 3: Community Features (Target: 3-4 weeks)
- [ ] Direct messaging system
- [ ] Job board
- [ ] Knowledge sharing/blog
- [ ] Enhanced analytics
- [ ] Badges and achievements
- [ ] Reviews and ratings
- [ ] API access

---

## 12. Open Questions

1. **One agency per user or multiple?** 
   - Decision: One agency per user account initially, can expand later

2. **How to handle agency verification?**
   - Decision: Manual verification by admins initially, automated checks later

3. **Should case studies require client approval?**
   - Decision: No approval required, but agencies should get permission (legal disclaimer)

4. **Pricing model for agencies?**
   - Decision: Free for MVP, consider premium features later

5. **How to prevent fake testimonials?**
   - Decision: Verification badge system, require LinkedIn profile for verified testimonials

6. **Should agencies be able to hide certain case studies?**
   - Decision: Yes, allow private/public toggle per case study

7. **How to handle agency name conflicts?**
   - Decision: Use unique slugs, allow similar names with different slugs

---

## 13. References

- **Peerlist.io**: https://peerlist.io - Inspiration for developer-focused platform
- **Clutch.co**: https://clutch.co - B2B service provider directory
- **GoodFirms**: https://www.goodfirms.co - Software and service provider reviews
- **Design patterns**: Reference existing profile and directory pages in codebase
- **Image upload**: Use existing image upload service patterns

---

## Appendix

### A. API Response Examples

**Get Agency by Slug:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "GTM Experts",
  "slug": "gtm-experts",
  "tagline": "Helping SaaS companies scale their GTM operations",
  "description": "We specialize in product launches, demand generation, and sales enablement...",
  "logoUrl": "https://cdn.example.com/logos/gtm-experts.png",
  "websiteUrl": "https://gtmexperts.com",
  "location": "San Francisco, CA",
  "foundedYear": 2020,
  "services": ["Product Launch", "Demand Generation", "Sales Enablement"],
  "industries": ["SaaS", "B2B", "Enterprise"],
  "companySizes": ["10-50", "50-200"],
  "engagementModels": ["Retainer", "Project-based"],
  "pricingRange": "$10k-$50k",
  "isVerified": true,
  "isFeatured": false,
  "linkedinUrl": "https://linkedin.com/company/gtm-experts",
  "caseStudies": [
    {
      "id": "...",
      "title": "Scaling Product Launch for TechCorp",
      "clientName": "TechCorp",
      "metrics": {
        "revenue_growth": "300%",
        "mql_increase": "250%"
      },
      "coverImageUrl": "..."
    }
  ],
  "testimonials": [
    {
      "id": "...",
      "clientName": "John Doe",
      "clientRole": "CMO",
      "clientCompany": "TechCorp",
      "quote": "They transformed our GTM strategy...",
      "rating": 5
    }
  ],
  "teamMembers": [
    {
      "id": "...",
      "name": "Jane Smith",
      "role": "Founder & CEO",
      "photoUrl": "..."
    }
  ]
}
```

**Create Case Study:**
```json
{
  "agencyId": "550e8400-e29b-41d4-a716-446655440000",
  "clientName": "TechCorp",
  "clientIndustry": "SaaS",
  "clientCompanySize": "50-200",
  "title": "Scaling Product Launch for TechCorp",
  "challenge": "TechCorp needed to launch a new product...",
  "solution": "We developed a comprehensive GTM strategy...",
  "results": "The launch exceeded all expectations...",
  "metrics": {
    "revenue_growth": "300%",
    "mql_increase": "250%",
    "cac_reduction": "40%"
  },
  "startDate": "2024-01-01",
  "endDate": "2024-06-30",
  "servicesUsed": ["Product Launch", "Demand Generation"]
}
```

### B. Additional Technical Details

**Slug Generation:**
- Convert agency name to lowercase
- Replace spaces and special characters with hyphens
- Ensure uniqueness by appending number if needed
- Reserved slugs: "new", "edit", "admin", "api", etc.

**Image Requirements:**
- Logo: 400x400px minimum, square aspect ratio
- Case study cover: 1200x600px recommended, 16:9 aspect ratio
- Team member photos: 400x400px, square aspect ratio
- Max file size: 5MB per image
- Supported formats: JPEG, PNG, WebP

**Search Implementation:**
- Full-text search on agency name, tagline, description
- Filter by services, industries, location
- Sort by relevance (default), newest, most viewed
- Consider using PostgreSQL full-text search or Elasticsearch for Phase 2

**Performance Considerations:**
- Cache public agency profiles (5-10 minute TTL)
- Lazy load case studies and testimonials on profile page
- Paginate agency listings (20 per page default)
- Optimize images on upload (resize, compress)
