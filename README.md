# Sliver Solution 🪙
### LLC Compliance Navigator

> Built for the wave of new LLC owners who don't know what they don't know.

Sliver Solution is a React-based compliance dashboard that guides new LLC owners through the landmines of contractor tracking, 1099-NEC filing, state SOS deadlines, franchise taxes, K-1s, and more — with an AI assistant powered by Claude built right in.

---

## Why This Exists

Most new LLC owners get blindsided by compliance requirements that nobody told them about:
- Paying a contractor without collecting a W-9 first
- Missing the January 31st 1099-NEC deadline (extensions don't apply)
- Not knowing their state's SOS annual report deadline until the LLC gets dissolved
- Confusing a tax extension with a 1099 filing extension
- Not knowing what a K-1 is until tax season hits

Sliver Solution puts all of it in one place with an AI assistant that answers questions in plain English.

---

## Features

| Tab | What It Does |
|---|---|
| **Dashboard** | At-a-glance compliance status, urgent items, key annual deadlines |
| **Checklist** | 14 compliance items across Formation, Contractors, Expenses, State, and Federal Tax |
| **Contractor Tracker** | Track W-9 status and auto-flag 1099-NEC requirements at $600 threshold |
| **States** | All 50 states — SOS deadlines, franchise tax info, and filing notes |
| **AI Assistant** | Claude-powered chat, pre-loaded with LLC compliance context |

---

## Tech Stack

- **React** (JSX, hooks)
- **Tailwind CSS** utility classes
- **Anthropic Claude API** — `claude-sonnet-4-20250514`
- No backend required for current version
- No external dependencies beyond React

---

## Getting Started

### Option 1 — Bolt.new (Fastest)
1. Go to [bolt.new](https://bolt.new)
2. Paste the contents of `src/App.jsx`
3. Add your Anthropic API key as an environment variable: `VITE_ANTHROPIC_API_KEY`
4. Deploy to Netlify in one click

### Option 2 — Local Development
```bash
# Requirements: Node.js 18+
npx create-react-app sliver-solution
cd sliver-solution
# Replace src/App.js with the contents of src/App.jsx
npm start
# Opens at http://localhost:3000
```

### Option 3 — Vercel Deployment
1. Push this repo to GitHub
2. Go to [vercel.com](https://vercel.com) → Import GitHub repo
3. Add environment variable: `VITE_ANTHROPIC_API_KEY = your_key_here`
4. Deploy — live URL in 60 seconds

---

## Environment Variables

```env
VITE_ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

> ⚠️ Never hardcode your API key in source code. Use environment variables in all deployments.

Get your API key at [console.anthropic.com](https://console.anthropic.com)

---

## Project Structure

```
sliver-solution/
├── src/
│   └── App.jsx          # Main application (single file)
├── public/
│   └── index.html
├── .env                 # API key (never commit this)
├── .gitignore
└── README.md
```

---

## Roadmap

**Phase 1 — Current (Validation)**
- [x] Compliance checklist
- [x] Contractor W-9 / 1099-NEC tracker
- [x] All 50 state SOS and franchise tax info
- [x] AI compliance assistant

**Phase 2 — If Validated**
- [ ] User accounts and persistent data
- [ ] Deadline reminders and notifications
- [ ] Expense tracking integration

**Phase 3 — Expansion**
- [ ] Background compliance agent
- [ ] QuickBooks / accounting software integration
- [ ] Multi-LLC support

> Feature requests drive the roadmap. If you're using this and want something built, open an issue.

---

## Important Disclaimers

- Sliver Solution is a compliance aid, not legal or tax advice
- Always verify state deadlines directly with your Secretary of State
- Consult a licensed CPA or attorney for your specific situation
- State requirements change — information may not reflect the most current rules

---

## License

MIT — use it, fork it, build on it.

---

## About

Built by [StevoKeano](https://github.com/stevokeano) — electronics, firmware, aviation safety software, and now LLC compliance tools.

> *"The W-9 bit me in the ass. Built this so it doesn't bite you."*
