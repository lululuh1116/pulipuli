import { createContext, useContext, useEffect, type ReactNode } from 'react'
import {
  getWorkspace,
  mockWorkspaces,
  type Workspace,
} from './workspaces'

type WorkspaceContextValue = {
  workspace: Workspace
  workspaces: Workspace[]
}

const WorkspaceContext = createContext<WorkspaceContextValue | null>(null)

export function WorkspaceProvider({
  workspaceId,
  children,
}: {
  workspaceId: string
  children: ReactNode
}) {
  const workspace = getWorkspace(workspaceId)

  if (!workspace) {
    throw new Error(`Unknown mock workspace: ${workspaceId}`)
  }

  useEffect(() => {
    const themeMeta = document.querySelector<HTMLMetaElement>(
      'meta[name="theme-color"]',
    )
    if (themeMeta) {
      themeMeta.content = workspace.theme === 'pulipuli' ? '#fbf8f4' : '#f4f5fb'
    }
  }, [workspace.theme])

  return (
    <WorkspaceContext.Provider value={{ workspace, workspaces: mockWorkspaces }}>
      {children}
    </WorkspaceContext.Provider>
  )
}

export function useWorkspace() {
  const context = useContext(WorkspaceContext)
  if (!context) {
    throw new Error('useWorkspace must be used inside WorkspaceProvider.')
  }
  return context
}
