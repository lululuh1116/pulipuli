export type WorkspaceTheme = 'pulipuli' | 'yunlin'

export type Workspace = {
  id: string
  name: string
  shortName: string
  theme: WorkspaceTheme
  location: string
}

export const mockWorkspaces: Workspace[] = [
  {
    id: 'pulipuli',
    name: 'PuliPuli',
    shortName: 'P',
    theme: 'pulipuli',
    location: '埔里工作室',
  },
  {
    id: 'yunlin-brand',
    name: '雲林品牌',
    shortName: '雲',
    theme: 'yunlin',
    location: '雲林工作室',
  },
]

export function getWorkspace(workspaceId: string) {
  return mockWorkspaces.find((workspace) => workspace.id === workspaceId)
}
