import {
  BarChart3,
  CalendarDays,
  Home,
  Settings2,
  UsersRound,
  WalletCards,
} from 'lucide-react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router'
import { useWorkspace } from '../features/workspace/WorkspaceContext'

const navigationItems = [
  { path: 'today', label: '首頁', icon: Home },
  { path: 'appointments', label: '預約', icon: CalendarDays },
  { path: 'customers', label: '顧客', icon: UsersRound },
  { path: 'transactions', label: '帳務', icon: WalletCards },
  { path: 'analytics', label: '分析', icon: BarChart3 },
] as const

export function AppShell() {
  const { workspace, workspaces } = useWorkspace()
  const navigate = useNavigate()
  const location = useLocation()
  const activeSection = location.pathname.split('/').filter(Boolean).at(-1) ?? 'today'

  function switchWorkspace(nextWorkspaceId: string) {
    navigate(`/app/${nextWorkspaceId}/${activeSection}`)
  }

  return (
    <div
      className="app-shell min-h-dvh pb-[calc(5.75rem+env(safe-area-inset-bottom))]"
      data-workspace-theme={workspace.theme}
    >
      <a className="skip-link" href="#workspace-content">
        跳到主要內容
      </a>

      <header className="app-header sticky top-0 z-20">
        <div className="mx-auto flex w-full max-w-2xl items-center gap-3 px-4 py-3">
          <NavLink
            to={`/app/${workspace.id}/today`}
            className="brand-mark"
            aria-label={`${workspace.name} 首頁`}
          >
            {workspace.shortName}
          </NavLink>

          <div className="min-w-0 flex-1">
            <label className="sr-only" htmlFor="workspace-switcher">
              切換工作空間
            </label>
            <select
              id="workspace-switcher"
              className="workspace-switcher w-full"
              value={workspace.id}
              onChange={(event) => switchWorkspace(event.target.value)}
            >
              {workspaces.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.name} · {item.location}
                </option>
              ))}
            </select>
          </div>

          <NavLink
            to={`/app/${workspace.id}/settings`}
            className="icon-button"
            aria-label="開啟設定"
          >
            <Settings2 aria-hidden="true" size={21} strokeWidth={1.8} />
          </NavLink>
        </div>
      </header>

      <main
        id="workspace-content"
        className="mx-auto w-full max-w-2xl px-4 pb-8 pt-5 sm:px-6 sm:pt-7"
      >
        <Outlet />
      </main>

      <nav className="bottom-navigation" aria-label="主要功能">
        <div className="mx-auto grid w-full max-w-2xl grid-cols-5 px-2 pt-2">
          {navigationItems.map(({ path, label, icon: Icon }) => (
            <NavLink
              key={path}
              to={`/app/${workspace.id}/${path}`}
              className={({ isActive }) =>
                `bottom-nav-item ${isActive ? 'is-active' : ''}`
              }
            >
              <Icon aria-hidden="true" size={21} strokeWidth={1.8} />
              <span>{label}</span>
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  )
}
