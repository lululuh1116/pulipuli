import { Navigate, type RouteObject } from 'react-router'
import { LoginPage } from '../features/auth/LoginPage'
import { TodayPage } from '../features/today/TodayPage'
import { AllWorkspacesPage } from '../routes/AllWorkspacesPage'
import { InvitePage } from '../routes/InvitePage'
import { WorkspacePlaceholderPage } from '../routes/WorkspacePlaceholderPage'
import { WorkspaceRouteLayout } from '../routes/WorkspaceRouteLayout'

export const appRoutes: RouteObject[] = [
  {
    path: '/',
    element: <Navigate to="/auth/login" replace />,
  },
  {
    path: '/auth/login',
    element: <LoginPage />,
  },
  {
    path: '/invite/:token',
    element: <InvitePage />,
  },
  {
    path: '/app',
    element: <Navigate to="/app/all-workspaces" replace />,
  },
  {
    path: '/app/all-workspaces',
    element: <AllWorkspacesPage />,
  },
  {
    path: '/app/:workspaceId',
    element: <WorkspaceRouteLayout />,
    children: [
      { index: true, element: <Navigate to="today" replace /> },
      { path: 'today', element: <TodayPage /> },
      {
        path: 'appointments',
        element: <WorkspacePlaceholderPage section="appointments" />,
      },
      {
        path: 'customers',
        element: <WorkspacePlaceholderPage section="customers" />,
      },
      {
        path: 'transactions',
        element: <WorkspacePlaceholderPage section="transactions" />,
      },
      {
        path: 'analytics',
        element: <WorkspacePlaceholderPage section="analytics" />,
      },
      {
        path: 'settings',
        element: <WorkspacePlaceholderPage section="settings" />,
      },
    ],
  },
  {
    path: '*',
    element: <Navigate to="/auth/login" replace />,
  },
]
