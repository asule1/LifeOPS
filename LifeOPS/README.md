# LifeOPS — Full-Stack Productivity Platform

**Group 5 | Spring 2025 | CSC 4350/6350**
Guide: Dr. Tushara Sadasivuni

---

## Team Members
| Name | Role |
|------|------|
| Bhuvan Aditya Karuturi | Frontend UI & DB Design |
| John Dang | Context Diagram & Use Case Diagram |
| Aayush Kumar | Backend User Management & Group Coordinator |
| Aditya Sule | Use Cases, Requirements & Activity Diagram |

---

## Features
- User Registration & Login (JWT + bcrypt)
- Role-Based Access Control (User / Admin)
- Admin Dashboard with User Management & Audit Logs
- Projects & Task Management
- Notes & Journal with Tags
- Document Vault (PDF & Image Upload)
- Focus Mode (Pomodoro / Deep Work / Custom)
- Habit Tracker with Streak Protection & Freeze Days
- Calendar View with Task Scheduling
- Study Buddy Leaderboard
- AI Assistant & AI Weekly Planner

---

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Frontend | React 18 + Tailwind CSS + Vite |
| Backend | Node.js + Express.js |
| Database | PostgreSQL (Prisma ORM) |
| Authentication | JWT + bcrypt (cost factor 12) |
| AI Services | Claude API |
| Hosting | Vercel (frontend) + Render (backend) |

---

## Demo Credentials
| Role | Email | Password |
|------|-------|----------|
| User | user@lifeops.dev | User@1234 |
| Admin | admin@lifeops.dev | Admin@1234 |

---

## How to Run Locally

### Prerequisites
- Node.js v20+
- PostgreSQL 15+

### Backend Setup
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your database credentials
npx prisma generate
npx prisma migrate deploy
npm run start
```

### Frontend Setup
```bash
cd frontend
npm install
npm run dev
```

### Database Setup
Run the SQL script in pgAdmin or Supabase SQL Editor:
```
backend/sql/create_tables.sql
```

App runs at:
- Frontend: http://localhost:5173
- Backend API: http://localhost:3001

---

## Project Structure
```
lifeops/
├── frontend/
│   ├── src/
│   │   ├── App.jsx
│   │   ├── main.jsx
│   │   └── index.css
│   ├── index.html
│   ├── vite.config.js
│   ├── tailwind.config.js
│   ├── postcss.config.js
│   └── package.json
├── backend/
│   ├── src/
│   │   ├── index.js
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── users.js
│   │   │   └── tasks.js
│   │   └── middleware/
│   │       └── auth.js
│   ├── prisma/
│   │   └── schema.prisma
│   ├── sql/
│   │   └── create_tables.sql
│   ├── .env.example
│   └── package.json
├── .gitignore
└── README.md
```

---

## References
- Sommerville, I. (2016). Software Engineering (10th ed.). Pearson.
- Prisma Documentation: https://www.prisma.io/docs
- JWT Documentation: https://jwt.io/introduction
- OWASP Top Ten: https://owasp.org/Top10/
- PostgreSQL Documentation: https://www.postgresql.org/docs/15/