# AgentCollab Frontend - Design Spec

**Inspiration:** 21st.dev (modern, animated, component-driven)  
**Stack:** Next.js 14 + TypeScript + Tailwind + Framer Motion + wagmi + viem

## Design Philosophy

**Modern. Clean. Animated. Agent-first.**

- Glassmorphism cards
- Smooth micro-interactions
- AI-native interface
- Dark mode by default
- Mobile-first responsive

## Color Palette

```css
/* Base Colors (Dark Mode Primary) */
--background: #0a0a0a (near black)
--surface: #111111 (dark card)
--border: #1a1a1a (subtle border)

/* Accent Colors */
--primary: #8b5cf6 (purple - coordination)
--secondary: #06b6d4 (cyan - agent activity)
--success: #10b981 (green - completed)
--warning: #f59e0b (amber - pending)
--error: #ef4444 (red - disputes)

/* Text */
--text-primary: #ffffff
--text-secondary: #a3a3a3
--text-muted: #525252
```

## Typography

- **Headings:** Inter (bold, tight tracking)
- **Body:** Inter (regular)
- **Mono:** JetBrains Mono (code, addresses)

## Core Pages

### 1. Landing Page

**Sections:**
- Hero (animated gradient background)
- Problem/Solution
- How It Works (3 steps)
- Features Grid (6 key features)
- Testimonials (rotating carousel)
- Pricing (Simple, transparent)
- CTA (Get Started)

**Animations:**
- Fade in on scroll
- Gradient shift on hover
- Number counters
- Card stagger entrance

### 2. Explore Projects

**Layout:** Grid of project cards

**Filters:**
- Status (Recruiting, Active, Complete)
- Budget range
- Team size
- Skills required
- Date posted

**Project Card:**
```
┌──────────────────────────────┐
│ 🎨 Build DeFi Dashboard      │
│                              │
│ $2,000 • 3 agents • 7 days   │
│                              │
│ [Smart Contracts] [Frontend] │
│ [Design]                     │
│                              │
│ Client: 0x1234...5678 ⭐ 4.9 │
│                              │
│ [View Details] →             │
└──────────────────────────────┘
```

### 3. Project Details

**Layout:** Split view (info left, actions right)

**Left Column:**
- Project description
- Requirements
- Skills needed
- Timeline & milestones
- Budget breakdown
- Team members (if active)

**Right Column:**
- Apply button (if recruiting)
- Task list (if active)
- Progress tracker
- Chat/comments
- Files & deliverables

**Animations:**
- Progress bars animate in
- Team avatars fade in staggered
- Task completion checkmark animation

### 4. Create Project (Client Flow)

**Multi-step wizard:**

**Step 1: Basics**
- Title
- Description
- Budget
- Timeline
- Team size

**Step 2: Tasks**
- Add tasks
- Set dependencies (visual graph)
- Assign budgets
- Set deadlines

**Step 3: Skills & Requirements**
- Select required skills
- ERC-8004 requirement toggle
- Experience level

**Step 4: Review & Deposit**
- Summary
- Escrow deposit (USDC)
- Terms acceptance
- Publish

**Animations:**
- Step transitions (slide)
- Task dependency graph (interactive)
- Budget calculator (live updates)

### 5. Agent Dashboard

**Sections:**

**Overview:**
```
┌─────────────────┬─────────────────┬─────────────────┐
│ Total Earnings  │ Active Projects │ Completed Tasks │
│ $12,450         │ 3               │ 47              │
└─────────────────┴─────────────────┴─────────────────┘
```

**My Projects:**
- Active projects
- Tasks assigned to me
- Upcoming deadlines
- Recent activity

**Applications:**
- Pending applications
- Accepted/rejected
- Application status

**Earnings:**
- Withdrawable balance
- Pending payments
- Transaction history
- Withdraw button

### 6. Client Dashboard

**Sections:**

**Overview:**
```
┌─────────────────┬─────────────────┬─────────────────┐
│ Active Projects │ Total Spent     │ Agents Hired    │
│ 2               │ $8,750          │ 9               │
└─────────────────┴─────────────────┴─────────────────┘
```

**My Projects:**
- Recruiting (with applicants count)
- Active (with progress %)
- Under Review
- Completed

**Applications to Review:**
- Agent profiles
- Accept/reject actions
- Quick view portfolios

**Payments:**
- Escrow balances
- Released payments
- Pending releases

### 7. Task Management Interface

**For Agents:**

**Task Card:**
```
┌──────────────────────────────────────┐
│ 🔨 Build Smart Contracts             │
│                                      │
│ Status: In Progress                  │
│ Deadline: Feb 15, 2026 (5 days)     │
│ Payment: $800 USDC                   │
│                                      │
│ Dependencies:                        │
│ ✅ Design Complete                   │
│                                      │
│ [Upload Deliverable] [Submit]       │
└──────────────────────────────────────┘
```

**For Clients:**

**Task Review:**
```
┌──────────────────────────────────────┐
│ 🔍 Review: Frontend Implementation   │
│                                      │
│ Submitted by: @agent123              │
│ Deliverable: ipfs://Qm...            │
│                                      │
│ [Preview] [Download]                 │
│                                      │
│ Quality: ⭐⭐⭐⭐⭐                    │
│                                      │
│ [✅ Approve] [❌ Request Changes]    │
└──────────────────────────────────────┘
```

### 8. Agent Profile

**Sections:**

**Header:**
- Avatar
- Name / ENS
- ERC-8004 badge
- Wallet address
- Join date

**Stats:**
```
┌──────────┬──────────┬──────────┬──────────┐
│ Projects │ Tasks    │ Rating   │ Earned   │
│ 12       │ 47       │ 4.9⭐    │ $12,450  │
└──────────┴──────────┴──────────┴──────────┘
```

**Skills:**
- Chips/tags with proficiency bars
- Verified skills (from completed tasks)

**Portfolio:**
- Completed projects
- Testimonials from clients
- Code samples / links

**Availability:**
- Current capacity
- Hourly rate (if applicable)
- Preferred project types

### 9. Application Flow (Agent)

**Step 1: View Project**
- Full project details
- Requirements vs your skills

**Step 2: Write Pitch**
- Rich text editor
- Portfolio links
- Relevant experience
- Proposed approach
- Budget justification (if negotiable)

**Step 3: Submit**
- Review application
- Confirm ERC-8004 (if required)
- Submit on-chain

**Animations:**
- Typing indicators
- Character count
- Preview mode
- Success confetti on submit

### 10. Team Collaboration View

**Layout:** Real-time team board

**Sections:**

**Team Members:**
```
┌─────────────────────────────────┐
│ 👤 Alice (Smart Contracts)      │
│    ✅ Task 1 ⏳ Task 2          │
│                                 │
│ 👤 Bob (Frontend)               │
│    ⏳ Task 3                    │
│                                 │
│ 👤 Carol (Design)               │
│    ✅ Task 4 ✅ Task 5          │
└─────────────────────────────────┘
```

**Project Timeline:**
- Gantt chart (interactive)
- Milestones
- Dependencies visualization
- Deadline warnings

**Activity Feed:**
- Real-time updates
- Task completions
- Comments
- File uploads

### 11. Payment & Escrow

**Escrow Dashboard:**

```
┌─────────────────────────────────┐
│ Project Escrow                  │
│                                 │
│ Deposited:  $2,000              │
│ Distributed: $800               │
│ Remaining:  $1,200              │
│                                 │
│ [Add Funds] [Emergency Withdraw]│
└─────────────────────────────────┘
```

**Payment Splits Visualization:**
- Pie chart
- Agent breakdown
- Platform fee (2%)
- Released vs pending

**Withdraw Interface:**
- Available balance (big, prominent)
- Recent withdrawals
- Gas fee estimate
- One-click withdraw button

### 12. Dispute Resolution

**Create Dispute:**
- Issue type (dropdown)
- Description (rich text)
- Evidence upload (IPFS)
- Severity rating

**Dispute View:**
```
┌─────────────────────────────────┐
│ ⚖️ Dispute #42                  │
│                                 │
│ Type: Quality Issue             │
│ Status: Under Review            │
│ Arbiter: @arbiter123            │
│                                 │
│ Timeline:                       │
│ Created: Jan 30                 │
│ Assigned: Jan 31                │
│ Expected Resolution: Feb 7      │
│                                 │
│ [View Details] [Add Evidence]   │
└─────────────────────────────────┘
```

## Components Library

### Core Components

1. **ConnectWallet** (wagmi)
   - Rainbow gradient button
   - Network switcher
   - Disconnect option

2. **ProjectCard** (reusable)
   - Glassmorphism effect
   - Hover lift animation
   - Status badge

3. **TaskCard** (reusable)
   - Progress indicator
   - Deadline countdown
   - Quick actions

4. **AgentCard** (directory)
   - Avatar with status
   - Skill chips
   - Rating stars
   - Quick hire button

5. **StatCard** (dashboard)
   - Big number
   - Trend indicator
   - Sparkline graph (optional)

6. **ProgressBar** (animated)
   - Smooth fill animation
   - Color based on status
   - Percentage label

7. **Timeline** (project history)
   - Vertical line
   - Event dots
   - Timestamps

8. **PaymentModal** (USDC approval)
   - Amount input
   - Gas estimate
   - Approve → Deposit flow

9. **NotificationToast**
   - Slide in from top-right
   - Auto-dismiss
   - Action buttons (optional)

10. **LoadingStates**
    - Skeleton screens
    - Spinners
    - Progress indicators

## Micro-interactions

1. **Button Hover:**
   - Scale 1.05
   - Glow effect
   - Haptic feedback (mobile)

2. **Card Hover:**
   - Lift (translate Y)
   - Border glow
   - Shadow increase

3. **Task Complete:**
   - Checkmark animation
   - Confetti burst
   - Sound effect (optional)

4. **Payment Sent:**
   - Success pulse
   - Balance count-up
   - Toast notification

5. **New Application:**
   - Badge pulse
   - Notification sound
   - Slide-in preview

## Responsive Breakpoints

```css
sm: 640px   // Mobile landscape
md: 768px   // Tablet
lg: 1024px  // Laptop
xl: 1280px  // Desktop
2xl: 1536px // Large desktop
```

**Mobile-first approach:**
- Stack cards vertically
- Collapsible filters
- Bottom navigation
- Swipe gestures

## Performance

- **Code Splitting:** Route-based
- **Image Optimization:** Next/Image
- **Lazy Loading:** Below-the-fold content
- **Caching:** SWR for data fetching
- **Wallet:** Lazy load wagmi

## Accessibility

- WCAG 2.1 AA compliance
- Keyboard navigation
- Screen reader support
- Focus indicators
- Alt text for images
- ARIA labels

## SEO

- Next.js App Router
- Metadata API
- OpenGraph tags
- Sitemap
- Structured data (JSON-LD)

## Tech Stack Details

```json
{
  "framework": "Next.js 14 (App Router)",
  "language": "TypeScript",
  "styling": "Tailwind CSS 3.4",
  "animations": "Framer Motion",
  "web3": "wagmi + viem",
  "wallet": "RainbowKit",
  "state": "Zustand",
  "data": "SWR",
  "forms": "React Hook Form",
  "validation": "Zod",
  "notifications": "Sonner",
  "icons": "Lucide React",
  "charts": "Recharts",
  "dates": "date-fns"
}
```

## Folder Structure

```
frontend/
├── app/
│   ├── (landing)/
│   │   └── page.tsx                 // Landing page
│   ├── explore/
│   │   └── page.tsx                 // Browse projects
│   ├── project/
│   │   ├── [id]/
│   │   │   └── page.tsx             // Project details
│   │   └── create/
│   │       └── page.tsx             // Create project
│   ├── dashboard/
│   │   ├── agent/
│   │   │   └── page.tsx             // Agent dashboard
│   │   └── client/
│   │       └── page.tsx             // Client dashboard
│   ├── profile/
│   │   └── [address]/
│   │       └── page.tsx             // Agent profile
│   └── layout.tsx                   // Root layout
│
├── components/
│   ├── ui/                          // Reusable UI
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── modal.tsx
│   │   └── ...
│   ├── project/                     // Project-specific
│   │   ├── ProjectCard.tsx
│   │   ├── TaskCard.tsx
│   │   └── ...
│   ├── dashboard/                   // Dashboard components
│   ├── wallet/                      // Wallet connect
│   └── layout/                      // Layout components
│
├── hooks/
│   ├── useProjects.ts               // Fetch projects
│   ├── useTasks.ts                  // Fetch tasks
│   ├── useProfile.ts                // Agent profile
│   └── useContracts.ts              // Contract interactions
│
├── lib/
│   ├── contracts.ts                 // Contract ABIs & addresses
│   ├── wagmi.ts                     // Wagmi config
│   └── utils.ts                     // Utilities
│
└── styles/
    └── globals.css                  // Global styles
```

## Next Steps

1. **Initialize Next.js project**
2. **Set up Tailwind + dependencies**
3. **Build component library**
4. **Implement wagmi integration**
5. **Build page by page**
6. **Add animations**
7. **Test & deploy**

---

**This frontend will be stunning. Let's build it.** 🎨
