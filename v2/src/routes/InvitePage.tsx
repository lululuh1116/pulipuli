import { Link, useParams } from 'react-router'

export function InvitePage() {
  const { token } = useParams()

  return (
    <div className="auth-page min-h-dvh px-5 py-8" data-workspace-theme="pulipuli">
      <main className="auth-panel mx-auto w-full max-w-md">
        <p className="eyebrow">WORKSPACE INVITE</p>
        <h1 className="mt-3">你收到一份工作室邀請</h1>
        <p className="page-description mt-3">
          邀請流程已預留；Cloud 驗證會在後續階段接上。
        </p>
        <p className="invite-token mt-7">Token · {token}</p>
        <Link className="primary-button mt-6" to="/auth/login">
          回到登入
        </Link>
      </main>
    </div>
  )
}
