import { useWorkspace } from '../features/workspace/WorkspaceContext'

export function WorkspacePageHeader({
  eyebrow,
  title,
  description,
}: {
  eyebrow: string
  title: string
  description: string
}) {
  const { workspace } = useWorkspace()

  return (
    <header className="page-heading">
      <p className="eyebrow">{eyebrow}</p>
      <h1>{title}</h1>
      <p className="page-description">{description}</p>
      <p className="workspace-scope" data-testid="workspace-id">
        Workspace scope · {workspace.id}
      </p>
    </header>
  )
}
