import { ArrowUpRight } from 'lucide-react'
import { Link } from 'react-router'
import { mockWorkspaces } from '../features/workspace/workspaces'

export function AllWorkspacesPage() {
  return (
    <div className="directory-page min-h-dvh px-5 py-8" data-workspace-theme="pulipuli">
      <main className="mx-auto w-full max-w-lg">
        <p className="eyebrow">ALL WORKSPACES</p>
        <h1 className="mt-3">選一間工作室</h1>
        <p className="page-description mt-3">資料、查詢快取與主題都會跟著 Workspace 分開。</p>
        <div className="mt-8 space-y-3">
          {mockWorkspaces.map((workspace) => (
            <Link
              className="workspace-row"
              data-workspace-theme={workspace.theme}
              key={workspace.id}
              to={`/app/${workspace.id}/today`}
            >
              <span className="brand-mark">{workspace.shortName}</span>
              <span className="min-w-0 flex-1">
                <strong>{workspace.name}</strong>
                <small>{workspace.location}</small>
              </span>
              <ArrowUpRight aria-hidden="true" size={20} />
            </Link>
          ))}
        </div>
      </main>
    </div>
  )
}
