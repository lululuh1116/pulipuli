import {
  BarChart3,
  CalendarDays,
  SlidersHorizontal,
  UsersRound,
  WalletCards,
} from 'lucide-react'
import { WorkspacePageHeader } from '../components/WorkspacePageHeader'

const pageCopy = {
  appointments: {
    eyebrow: 'APPOINTMENTS / 預約',
    title: '預約',
    description: '接下來會在這裡整理行程、服務與可預約時段。',
    detail: 'Calendar foundation ready',
    icon: CalendarDays,
  },
  customers: {
    eyebrow: 'CUSTOMERS / 顧客',
    title: '顧客',
    description: '每位顧客都只屬於目前的 Workspace。',
    detail: "Query key · ['customers', workspaceId]",
    icon: UsersRound,
  },
  transactions: {
    eyebrow: 'TRANSACTIONS / 帳務',
    title: '帳務',
    description: '收入與支出會以 Workspace 為界線分開整理。',
    detail: "Query key · ['transactions', workspaceId, …]",
    icon: WalletCards,
  },
  analytics: {
    eyebrow: 'ANALYTICS / 分析',
    title: '分析',
    description: '未來在這裡看見工作室的節奏與成長。',
    detail: 'Workspace-scoped analytics foundation',
    icon: BarChart3,
  },
  settings: {
    eyebrow: 'SETTINGS / 設定',
    title: '設定',
    description: 'Workspace 名稱、主題與成員設定的預留入口。',
    detail: 'No cloud settings connected',
    icon: SlidersHorizontal,
  },
} as const

type WorkspaceSection = keyof typeof pageCopy

export function WorkspacePlaceholderPage({
  section,
}: {
  section: WorkspaceSection
}) {
  const page = pageCopy[section]
  const Icon = page.icon

  return (
    <div>
      <WorkspacePageHeader
        eyebrow={page.eyebrow}
        title={page.title}
        description={page.description}
      />
      <section className="placeholder-panel mt-8" aria-label={`${page.title} Foundation`}>
        <Icon aria-hidden="true" size={25} strokeWidth={1.7} />
        <p>{page.detail}</p>
        <span>Phase 6A</span>
      </section>
    </div>
  )
}
