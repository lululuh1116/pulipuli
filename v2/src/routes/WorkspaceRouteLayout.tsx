import { Navigate, useParams } from 'react-router'
import { AppShell } from '../components/AppShell'
import { WorkspaceProvider } from '../features/workspace/WorkspaceContext'
import { getWorkspace } from '../features/workspace/workspaces'

export function WorkspaceRouteLayout() {
  const { workspaceId } = useParams()

  if (!workspaceId || !getWorkspace(workspaceId)) {
    return <Navigate to="/app/all-workspaces" replace />
  }

  return (
    <WorkspaceProvider key={workspaceId} workspaceId={workspaceId}>
      <AppShell />
    </WorkspaceProvider>
  )
}
