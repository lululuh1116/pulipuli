import { zodResolver } from '@hookform/resolvers/zod'
import { ArrowRight } from 'lucide-react'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { Link } from 'react-router'
import { z } from 'zod'

const loginSchema = z.object({
  email: z.email('請輸入有效的 Email，例如 name@example.com。'),
})

type LoginValues = z.infer<typeof loginSchema>

export function LoginPage() {
  const [message, setMessage] = useState('')
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '' },
  })

  return (
    <div className="auth-page min-h-dvh px-5 py-8 sm:py-12" data-workspace-theme="pulipuli">
      <main className="auth-panel mx-auto w-full max-w-md">
        <div className="brand-mark brand-mark-large" aria-hidden="true">
          P
        </div>
        <p className="eyebrow mt-6">PULIPULI V2</p>
        <h1 className="mt-3">回到你的工作室</h1>
        <p className="page-description mt-3">
          為個人工作室整理預約、顧客與每天的收支。
        </p>

        <form
          className="mt-8"
          onSubmit={handleSubmit(() =>
            setMessage('登入串接將在後續階段啟用；目前為 Foundation 預覽。'),
          )}
          noValidate
        >
          <label className="field-label" htmlFor="email">
            Email
          </label>
          <input
            id="email"
            type="email"
            inputMode="email"
            autoComplete="email"
            spellCheck="false"
            aria-invalid={errors.email ? 'true' : 'false'}
            aria-describedby={errors.email ? 'email-error' : undefined}
            placeholder="name@example.com…"
            {...register('email')}
          />
          {errors.email ? (
            <p className="field-error" id="email-error" role="alert">
              {errors.email.message}
            </p>
          ) : null}
          <button className="primary-button mt-5" type="submit">
            繼續
            <ArrowRight aria-hidden="true" size={18} />
          </button>
        </form>

        <div className="foundation-link mt-7">
          <span>先看 Foundation</span>
          <Link to="/app/pulipuli/today">進入 Mock Workspace</Link>
        </div>
        <p className="sr-only" role="status" aria-live="polite">
          {message}
        </p>
        {message ? <p className="form-message mt-5">{message}</p> : null}
      </main>
    </div>
  )
}
