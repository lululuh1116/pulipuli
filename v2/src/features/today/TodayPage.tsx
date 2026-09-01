import { useQuery } from '@tanstack/react-query'
import { Clock3, Sparkles } from 'lucide-react'
import { WorkspacePageHeader } from '../../components/WorkspacePageHeader'
import { useWorkspace } from '../workspace/WorkspaceContext'
import { workspaceQueryKeys } from '../workspace/queryKeys'

const mockTodayByWorkspace = {
  pulipuli: {
    bookings: 4,
    income: 8600,
    nextCustomer: '小安',
    nextService: '指甲保養 · 奶茶暈染',
    nextTime: '14:30',
  },
  'yunlin-brand': {
    bookings: 3,
    income: 6200,
    nextCustomer: '雅筑',
    nextService: '品牌諮詢 · 第 2 次會談',
    nextTime: '15:00',
  },
} as const

export function TodayPage() {
  const { workspace } = useWorkspace()
  const { data } = useQuery({
    queryKey: workspaceQueryKeys.today(workspace.id),
    queryFn: async () =>
      mockTodayByWorkspace[workspace.id as keyof typeof mockTodayByWorkspace],
  })

  if (!data) {
    return <p role="status">正在整理今天的工作…</p>
  }

  return (
    <div>
      <WorkspacePageHeader
        eyebrow="TODAY / 今日"
        title={`嗨，${workspace.name}`}
        description="把今天照顧好，就很了不起。"
      />

      <section className="today-summary mt-7" aria-labelledby="today-summary-title">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="summary-label" id="today-summary-title">
              今日收入
            </p>
            <p className="summary-amount">
              {new Intl.NumberFormat('zh-TW', {
                style: 'currency',
                currency: 'TWD',
                maximumFractionDigits: 0,
              }).format(data.income)}
            </p>
          </div>
          <div className="booking-count" aria-label={`今日 ${data.bookings} 筆預約`}>
            <span>{data.bookings}</span>
            <small>筆預約</small>
          </div>
        </div>
      </section>

      <section className="next-appointment mt-8" aria-labelledby="next-customer-title">
        <div className="flex items-center gap-2">
          <Sparkles aria-hidden="true" size={17} strokeWidth={1.8} />
          <p className="summary-label">下一位客人</p>
        </div>
        <div className="mt-4 flex items-end justify-between gap-4">
          <div className="min-w-0">
            <h2 id="next-customer-title">{data.nextCustomer}</h2>
            <p className="mt-1 truncate text-sm">{data.nextService}</p>
          </div>
          <p className="appointment-time">
            <Clock3 aria-hidden="true" size={16} />
            {data.nextTime}
          </p>
        </div>
      </section>

      <p className="studio-note mt-7">
        今天留一點空白給自己，工作室才有長久的呼吸。
      </p>
    </div>
  )
}
